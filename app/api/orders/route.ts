import { NextResponse } from 'next/server';
import { z } from 'zod';
import { prisma } from '../../../lib/prisma';
import { applyBonusSpend, calculateEarnedBonus } from '../../../lib/bonus';
import { OrderStatus } from '../../../lib/types';

const orderSchema = z.object({
  userId: z.string().optional(),
  items: z.array(
    z.object({
      productId: z.string(),
      variantId: z.string().nullable().optional(),
      quantity: z.number().min(1),
      price: z.number().min(0)
    })
  ),
  phone: z.string(),
  comment: z.string().optional(),
  deliveryType: z.enum(['pickup', 'delivery']),
  address: z.string().optional(),
  deliveryDate: z.string().optional(),
  bonusToSpend: z.number().min(0).default(0)
});

export async function POST(req: Request) {
  const body = await req.json();
  const parsed = orderSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.flatten() }, { status: 400 });
  }
  const data = parsed.data;
  const total = data.items.reduce((acc, item) => acc + item.price * item.quantity, 0);
  const { spend, remainingToPay } = applyBonusSpend(total, data.bonusToSpend, Number(process.env.BONUS_MAX_PERCENT || 30));
  const bonusEarned = calculateEarnedBonus(remainingToPay, Number(process.env.BONUS_PERCENT || 5));
  const order = await prisma.order.create({
    data: {
      userId: data.userId,
      status: OrderStatus.NEW,
      total,
      bonusUsed: spend,
      bonusEarned,
      comment: data.comment,
      phone: data.phone,
      deliveryType: data.deliveryType,
      address: data.address,
      deliveryDate: data.deliveryDate ? new Date(data.deliveryDate) : null,
      items: {
        create: data.items.map((item) => ({
          productId: item.productId,
          variantId: item.variantId || undefined,
          quantity: item.quantity,
          price: item.price
        }))
      }
    },
    include: { items: true }
  });

  await prisma.bonusTransaction.create({
    data: { userId: data.userId!, orderId: order.id, amount: bonusEarned, operation: 'EARN' }
  }).catch(() => undefined);

  return NextResponse.json({ order });
}
