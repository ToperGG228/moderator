import { NextResponse } from 'next/server';
import { z } from 'zod';
import { prisma } from '../../../lib/prisma';
import { applyBonusSpend, calculateEarnedBonus } from '../../../lib/bonus';
import { OrderStatus } from '../../../lib/types';
import { getServerSession } from 'next-auth';
import { authOptions } from '../auth/[...nextauth]/options';

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
  bonusToSpend: z.number().min(0).default(0),
  paymentMethod: z.string().optional()
});

export async function POST(req: Request) {
  const body = await req.json();
  const parsed = orderSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.flatten() }, { status: 400 });
  }
  const data = parsed.data;
  const total = data.items.reduce((acc, item) => acc + item.price * item.quantity, 0);
  const session = await getServerSession(authOptions);
  const sessionUser = session?.user?.email
    ? await prisma.user.findUnique({ where: { email: session.user.email } })
    : null;
  const userId = data.userId || sessionUser?.id || null;

  if (!userId && data.bonusToSpend > 0) {
    return NextResponse.json({ error: 'Бонусы доступны только для зарегистрированных пользователей.' }, { status: 400 });
  }

  let availableBonus = 0;
  if (userId) {
    const aggregate = await prisma.bonusTransaction.aggregate({
      where: { userId },
      _sum: { amount: true }
    });
    availableBonus = aggregate._sum.amount || 0;
  }

  const maxSpendPercent = Number(process.env.BONUS_MAX_PERCENT || 30);
  const safeBonusToSpend = Math.min(data.bonusToSpend, availableBonus);
  const { spend, remainingToPay } = applyBonusSpend(total, safeBonusToSpend, maxSpendPercent);
  const bonusEarned = calculateEarnedBonus(remainingToPay, Number(process.env.BONUS_PERCENT || 5));
  const order = await prisma.order.create({
    data: {
      userId,
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

  if (userId && spend > 0) {
    await prisma.bonusTransaction.create({
      data: { userId, orderId: order.id, amount: -spend, operation: 'SPEND' }
    }).catch(() => undefined);
  }

  if (userId && bonusEarned > 0) {
    await prisma.bonusTransaction.create({
      data: { userId, orderId: order.id, amount: bonusEarned, operation: 'EARN' }
    }).catch(() => undefined);
  }

  return NextResponse.json({ order });
}
