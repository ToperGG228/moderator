import { prisma } from '../../../lib/prisma';
import { OrderStatus } from '../../../lib/types';
import { updateOrderStatus } from '../actions';

export const dynamic = 'force-dynamic';

async function getOrders() {
  return prisma.order.findMany({
    include: {
      user: true,
      items: { include: { product: true, variant: true } }
    },
    orderBy: { createdAt: 'desc' }
  });
}

const statusLabels: Record<OrderStatus, string> = {
  NEW: 'Новый',
  CONFIRMED: 'Подтвержден',
  COOKING: 'Готовится',
  READY: 'Готов',
  DELIVERING: 'Доставка',
  DONE: 'Выполнен',
  CANCELED: 'Отменен'
};

export default async function AdminOrdersPage() {
  const orders = await getOrders();
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">Заказы</h1>
        <p className="text-sm text-slate-600">Обновляйте статусы и проверяйте состав заказа.</p>
      </div>
      <div className="space-y-4">
        {orders.map((order) => (
          <div key={order.id} className="rounded-xl border border-orange-100 bg-white p-4">
            <div className="flex flex-wrap items-center justify-between gap-4">
              <div>
                <p className="text-sm text-slate-500">Заказ #{order.id.slice(0, 6)}</p>
                <p className="text-base font-semibold">{order.total} ₽</p>
                <p className="text-xs text-slate-500">
                  {order.user?.email ?? 'Гость'} · {new Date(order.createdAt).toLocaleString('ru-RU')}
                </p>
              </div>
              <form action={updateOrderStatus} className="flex items-center gap-2 text-sm">
                <input type="hidden" name="orderId" value={order.id} />
                <select name="status" defaultValue={order.status} className="rounded-md border px-2 py-1 text-sm">
                  {Object.values(OrderStatus).map((status) => (
                    <option key={status} value={status}>
                      {statusLabels[status]}
                    </option>
                  ))}
                </select>
                <button type="submit" className="rounded-md border border-brand px-3 py-1 text-brand">
                  Обновить
                </button>
              </form>
            </div>
            <div className="mt-3 text-sm text-slate-700">
              <p>
                Телефон: <span className="font-medium">{order.phone}</span>
              </p>
              <p>
                Доставка: <span className="font-medium">{order.deliveryType}</span>
                {order.address ? ` · ${order.address}` : ''}
              </p>
            </div>
            <ul className="mt-4 space-y-2 text-sm text-slate-700">
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
            Пока нет заказов.
          </div>
        )}
      </div>
    </div>
  );
}
