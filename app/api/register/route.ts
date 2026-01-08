import { NextResponse } from 'next/server';
import { z } from 'zod';
import { hash } from 'bcryptjs';
import { prisma } from '../../../lib/prisma';

const registerSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  password: z.string().min(8)
});

export async function POST(req: Request) {
  const body = await req.json();
  const parsed = registerSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: 'Некорректные данные' }, { status: 400 });
  }
  const { name, email, password } = parsed.data;
  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    return NextResponse.json({ error: 'Пользователь уже существует' }, { status: 409 });
  }
  const passwordHash = await hash(password, 10);
  await prisma.user.create({
    data: {
      name,
      email,
      passwordHash,
      role: 'CUSTOMER'
    }
  });
  return NextResponse.json({ ok: true });
}
