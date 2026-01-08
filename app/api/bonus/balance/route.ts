import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '../../auth/[...nextauth]/options';
import { prisma } from '../../../../lib/prisma';

export async function GET() {
  const session = await getServerSession(authOptions);
  if (!session?.user?.email) {
    return NextResponse.json({ balance: 0 });
  }
  const user = await prisma.user.findUnique({ where: { email: session.user.email } });
  if (!user) {
    return NextResponse.json({ balance: 0 });
  }
  const aggregate = await prisma.bonusTransaction.aggregate({
    where: { userId: user.id },
    _sum: { amount: true }
  });
  const balance = aggregate._sum.amount || 0;
  return NextResponse.json({ balance });
}
