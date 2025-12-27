import Link from 'next/link';

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="container-section py-10">
      <div className="flex flex-col gap-6 md:flex-row">
        <aside className="w-full md:w-64">
          <h2 className="text-lg font-semibold">Админ-панель</h2>
          <nav className="mt-4 flex flex-col gap-2 text-sm text-slate-700">
            <Link href="/admin" className="rounded-md border px-3 py-2 hover:border-brand hover:text-brand">
              Обзор
            </Link>
            <Link href="/admin/products" className="rounded-md border px-3 py-2 hover:border-brand hover:text-brand">
              Товары
            </Link>
            <Link href="/admin/orders" className="rounded-md border px-3 py-2 hover:border-brand hover:text-brand">
              Заказы
            </Link>
            <Link href="/admin/users" className="rounded-md border px-3 py-2 hover:border-brand hover:text-brand">
              Пользователи
            </Link>
          </nav>
        </aside>
        <main className="flex-1">{children}</main>
      </div>
    </div>
  );
}
