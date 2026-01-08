import { prisma } from '../../lib/prisma';
import { UserRole } from '../../lib/types';
import { getServerSession } from 'next-auth';
import { authOptions } from '../api/auth/[...nextauth]/options';
import Link from 'next/link';

export const dynamic = 'force-dynamic';

async function getCounts() {
  const [products, orders, users] = await Promise.all([
    prisma.product.count(),
    prisma.order.count(),
    prisma.user.count()
  ]);
  return { products, orders, users };
}

export default async function AdminPage() {
  const session = await getServerSession(authOptions);
  if (!session || session.user?.role !== UserRole.ADMIN) {
    return <div className="container-section py-10">Нет доступа</div>;
  }
  const counts = await getCounts();
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold">Админ-панель</h1>
      <div className="grid gap-4 md:grid-cols-3">
        {[
          { label: 'Товары', value: counts.products, href: '/admin/products' },
          { label: 'Заказы', value: counts.orders, href: '/admin/orders' },
          { label: 'Пользователи', value: counts.users, href: '/admin/users' }
        ].map((item) => (
          <Link
            key={item.label}
            href={item.href}
            className="rounded-xl border border-orange-100 bg-white p-6 shadow-sm"
          >
            <p className="text-sm text-slate-600">{item.label}</p>
            <p className="text-3xl font-bold text-brand">{item.value}</p>
          </Link>
        ))}
      </div>
      <p className="text-sm text-slate-600">
        Для редактирования данных используйте API Prisma Studio или подключите UI-редактор по своему вкусу.
      </p>
    </div>
  );
}
