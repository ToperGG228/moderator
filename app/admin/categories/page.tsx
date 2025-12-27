import { prisma } from '../../../lib/prisma';
import { createCategory } from '../actions';

export const dynamic = 'force-dynamic';

async function getCategories() {
  return prisma.category.findMany({
    include: {
      _count: { select: { products: true } }
    },
    orderBy: { createdAt: 'desc' }
  });
}

export default async function AdminCategoriesPage() {
  const categories = await getCategories();
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">Категории</h1>
        <p className="text-sm text-slate-600">Добавляйте категории и фото для карточек каталога.</p>
      </div>
      <div className="rounded-xl border border-orange-100 bg-white p-4">
        <h2 className="text-sm font-semibold text-slate-700">Новая категория</h2>
        <form action={createCategory} className="mt-4 grid gap-3 md:grid-cols-2">
          <input
            name="name"
            placeholder="Название"
            className="rounded-md border px-3 py-2 text-sm"
            required
          />
          <input
            name="slug"
            placeholder="Слаг (например, vareniki)"
            className="rounded-md border px-3 py-2 text-sm"
            required
          />
          <input
            name="imageUrl"
            placeholder="URL фото"
            className="rounded-md border px-3 py-2 text-sm md:col-span-2"
          />
          <button type="submit" className="rounded-md bg-brand px-3 py-2 text-sm text-white md:col-span-2">
            Добавить категорию
          </button>
        </form>
      </div>
      <div className="overflow-x-auto rounded-xl border border-orange-100 bg-white">
        <table className="w-full text-left text-sm">
          <thead className="bg-orange-50 text-slate-700">
            <tr>
              <th className="px-4 py-3">Название</th>
              <th className="px-4 py-3">Слаг</th>
              <th className="px-4 py-3">Фото</th>
              <th className="px-4 py-3">Товаров</th>
            </tr>
          </thead>
          <tbody>
            {categories.map((category) => (
              <tr key={category.id} className="border-t">
                <td className="px-4 py-3 font-medium">{category.name}</td>
                <td className="px-4 py-3 text-slate-600">/{category.slug}</td>
                <td className="px-4 py-3 text-slate-600">
                  {category.imageUrl ? category.imageUrl : '—'}
                </td>
                <td className="px-4 py-3">{category._count.products}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {categories.length === 0 && (
          <div className="p-6 text-sm text-slate-600">Категорий пока нет.</div>
        )}
      </div>
    </div>
  );
}
