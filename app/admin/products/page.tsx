import { prisma } from '../../../lib/prisma';
import { createProduct, updateProductFlags } from '../actions';
import Link from 'next/link';

export const dynamic = 'force-dynamic';

async function getProducts() {
  return prisma.product.findMany({
    include: {
      category: true,
      inventory: true,
      variants: true
    },
    orderBy: { createdAt: 'desc' }
  });
}

export default async function AdminProductsPage() {
  const categories = await prisma.category.findMany({ orderBy: { name: 'asc' } });
  const products = await getProducts();
  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">Товары</h1>
          <p className="text-sm text-slate-600">Управляйте публикацией, витринными подборками и остатками.</p>
        </div>
        <Link href="/catalog" className="rounded-md border border-brand px-3 py-2 text-sm text-brand">
          Перейти в каталог
        </Link>
      </div>
      <div className="rounded-xl border border-orange-100 bg-white p-4">
        <h2 className="text-sm font-semibold text-slate-700">Новый товар</h2>
        <form action={createProduct} className="mt-4 grid gap-3 md:grid-cols-2">
          <input
            name="name"
            placeholder="Название"
            className="rounded-md border px-3 py-2 text-sm"
            required
          />
          <input
            name="slug"
            placeholder="Слаг (например, pelmeni-domashnie)"
            className="rounded-md border px-3 py-2 text-sm"
            required
          />
          <input
            name="price"
            type="number"
            min="0"
            placeholder="Цена"
            className="rounded-md border px-3 py-2 text-sm"
            required
          />
          <select
            name="categoryId"
            className="rounded-md border px-3 py-2 text-sm"
            defaultValue=""
          >
            <option value="">Без категории</option>
            {categories.map((category) => (
              <option key={category.id} value={category.id}>
                {category.name}
              </option>
            ))}
          </select>
          <input
            name="imageUrl"
            placeholder="URL фото"
            className="rounded-md border px-3 py-2 text-sm md:col-span-2"
          />
          <textarea
            name="description"
            placeholder="Описание товара"
            className="min-h-[96px] rounded-md border px-3 py-2 text-sm md:col-span-2"
            required
          />
          <button type="submit" className="rounded-md bg-brand px-3 py-2 text-sm text-white md:col-span-2">
            Добавить товар
          </button>
        </form>
      </div>
      <div className="overflow-x-auto rounded-xl border border-orange-100 bg-white">
        <table className="w-full text-left text-sm">
          <thead className="bg-orange-50 text-slate-700">
            <tr>
              <th className="px-4 py-3">Название</th>
              <th className="px-4 py-3">Категория</th>
              <th className="px-4 py-3">Цена</th>
              <th className="px-4 py-3">Вариации</th>
              <th className="px-4 py-3">Остаток</th>
              <th className="px-4 py-3">Витрина</th>
            </tr>
          </thead>
          <tbody>
            {products.map((product) => {
              const stock = product.inventory.reduce((sum, item) => sum + item.stock, 0);
              return (
                <tr key={product.id} className="border-t">
                  <td className="px-4 py-3">
                    <div className="font-medium text-slate-900">{product.name}</div>
                    <div className="text-xs text-slate-500">/{product.slug}</div>
                  </td>
                  <td className="px-4 py-3">{product.category?.name ?? 'Без категории'}</td>
                  <td className="px-4 py-3">{product.price} ₽</td>
                  <td className="px-4 py-3">{product.variants.length}</td>
                  <td className="px-4 py-3">{stock}</td>
                  <td className="px-4 py-3">
                    <form action={updateProductFlags} className="flex flex-col gap-2 text-xs">
                      <input type="hidden" name="productId" value={product.id} />
                      <label className="flex items-center gap-2">
                        <input type="checkbox" name="isPublished" defaultChecked={product.isPublished} />
                        Публикация
                      </label>
                      <label className="flex items-center gap-2">
                        <input type="checkbox" name="isFeatured" defaultChecked={product.isFeatured} />
                        Витрина
                      </label>
                      <button type="submit" className="rounded-md border border-brand px-2 py-1 text-brand">
                        Сохранить
                      </button>
                    </form>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
