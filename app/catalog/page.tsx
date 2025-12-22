import { prisma } from '../../lib/prisma';
import { ProductCard } from '../../components/product-card';
import { Suspense } from 'react';

async function CatalogList({ searchParams }: { searchParams?: { q?: string; type?: string } }) {
  const q = searchParams?.q;
  const type = searchParams?.type;
  const where: any = { isPublished: true };
  if (q) where.name = { contains: q, mode: 'insensitive' };
  if (type) where.category = { name: { contains: type, mode: 'insensitive' } };
  const products = await prisma.product.findMany({ where, include: { category: true, variants: true } });
  return (
    <div className="grid gap-4 md:grid-cols-3">
      {products.map((product) => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  );
}

export default function CatalogPage({ searchParams }: { searchParams?: { q?: string; type?: string } }) {
  return (
    <div className="container-section space-y-6 py-10">
      <div className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
        <div>
          <h1 className="text-3xl font-semibold">Каталог</h1>
          <p className="text-slate-600">Фильтры: по типу категории и поиску</p>
        </div>
        <form className="flex gap-2" method="get">
          <input
            name="q"
            placeholder="Поиск..."
            defaultValue={searchParams?.q}
            className="rounded-md border px-3 py-2"
          />
          <select name="type" defaultValue={searchParams?.type} className="rounded-md border px-3 py-2">
            <option value="">Все</option>
            <option value="Пельмени">Еда</option>
            <option value="Вязан">Вязание</option>
          </select>
          <button type="submit" className="rounded-md bg-brand px-4 py-2 text-white">Найти</button>
        </form>
      </div>
      <Suspense fallback={<p>Загрузка...</p>}>
        {/* @ts-expect-error Async Server Component */}
        <CatalogList searchParams={searchParams} />
      </Suspense>
    </div>
  );
}
