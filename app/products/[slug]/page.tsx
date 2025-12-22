import { prisma } from '../../../lib/prisma';
import { notFound } from 'next/navigation';
import Image from 'next/image';

export default async function ProductPage({ params }: { params: { slug: string } }) {
  const product = await prisma.product.findUnique({
    where: { slug: params.slug },
    include: { category: true, variants: true, inventory: true }
  });
  if (!product) return notFound();

  return (
    <div className="container-section space-y-6 py-10">
      <div className="grid gap-6 md:grid-cols-2">
        <div className="relative h-96 overflow-hidden rounded-2xl bg-orange-50">
          <Image src={product.imageUrl || '/placeholder.svg'} alt={product.name} fill className="object-cover" />
        </div>
        <div className="space-y-4">
          <p className="text-sm uppercase tracking-[0.1em] text-brand">{product.category?.name}</p>
          <h1 className="text-3xl font-semibold">{product.name}</h1>
          <p className="text-slate-700">{product.description}</p>
          <div className="space-y-2">
            <p className="text-lg font-semibold">Вариации</p>
            <ul className="space-y-2">
              {product.variants.map((variant) => (
                <li key={variant.id} className="flex items-center justify-between rounded-lg border px-3 py-2">
                  <span>{variant.name}</span>
                  <span className="font-semibold text-brand">{variant.price} ₽</span>
                </li>
              ))}
            </ul>
          </div>
          <div>
            <p className="text-sm text-slate-600">Остатки:</p>
            <ul className="text-sm text-slate-700">
              {product.inventory.map((i) => (
                <li key={i.id}>Вариант {i.variantId || 'базовый'} — {i.stock} шт.</li>
              ))}
            </ul>
          </div>
          <button className="rounded-md bg-brand px-5 py-2 text-white">Добавить в корзину</button>
        </div>
      </div>
      <section className="grid gap-4 md:grid-cols-3">
        <div className="rounded-xl border border-orange-100 bg-white p-4">
          <h3 className="font-semibold">Состав и аллергены</h3>
          <p className="text-sm text-slate-600">Уточняйте состав перед покупкой, укажите аллергии в комментарии к заказу.</p>
        </div>
        <div className="rounded-xl border border-orange-100 bg-white p-4">
          <h3 className="font-semibold">Хранение</h3>
          <p className="text-sm text-slate-600">Заморозка при -18°C до 3 месяцев или охлаждение до 48 часов.</p>
        </div>
        <div className="rounded-xl border border-orange-100 bg-white p-4">
          <h3 className="font-semibold">Доставка и самовывоз</h3>
          <p className="text-sm text-slate-600">Выберите удобное время при оформлении заказа. Самовывоз бесплатно.</p>
        </div>
      </section>
    </div>
  );
}
