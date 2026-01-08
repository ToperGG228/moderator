import { redirect } from 'next/navigation';
import { getServerSession } from 'next-auth';
import { authOptions } from '../api/auth/[...nextauth]/options';
import { prisma } from '../../lib/prisma';
import { OrderStatus } from '../../lib/types';

export const dynamic = 'force-dynamic';

const statusLabels: Record<OrderStatus, string> = {
  NEW: 'Новый',
  CONFIRMED: 'Подтвержден',
  COOKING: 'Готовится',
  READY: 'Готов',
  DELIVERING: 'Доставка',
  DONE: 'Выполнен',
  CANCELED: 'Отменен'
};

export default async function ProfilePage() {
  const session = await getServerSession(authOptions);
  if (!session?.user?.email) {
    redirect('/login');
  }
  const orders = await prisma.order.findMany({
    where: { user: { email: session.user.email } },
    include: { items: { include: { product: true, variant: true } } },
    orderBy: { createdAt: 'desc' }
  });

  return (
    <div className="container-section py-10 space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">Мой профиль</h1>
        <p className="text-sm text-slate-600">История заказов и статусы покупок.</p>
      </div>
      <div className="grid gap-4">
        {orders.map((order) => (
          <div key={order.id} className="rounded-xl border border-orange-100 bg-white p-4">
            <div className="flex flex-wrap items-center justify-between gap-4">
              <div>
                <p className="text-sm text-slate-500">Заказ #{order.id.slice(0, 6)}</p>
                <p className="text-base font-semibold">{order.total} ₽</p>
              </div>
              <span className="rounded-full border px-3 py-1 text-xs text-slate-700">
                {statusLabels[order.status]}
              </span>
            </div>
            <ul className="mt-3 space-y-2 text-sm text-slate-700">
              {order.items.map((item) => (
                <li key={item.id} className="flex flex-wrap justify-between gap-2">
                  <span>
                    {item.product.name}
                    {item.variant ? ` (${item.variant.name})` : ''} × {item.quantity}
                  </span>
                  <span>{item.price} ₽</span>
                </li>
              ))}
            </ul>
          </div>
        ))}
        {orders.length === 0 && (
          <div className="rounded-xl border border-dashed border-orange-200 p-6 text-sm text-slate-600">
            Заказов пока нет.
          </div>
        )}
      </div>
    </div>
  );
}
