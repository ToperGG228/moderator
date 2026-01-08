import Link from 'next/link';
import { getFeaturedProducts, getLatestProducts } from '../lib/products';
import { ProductCard } from '../components/product-card';

export default async function HomePage() {
  const [featured, latest] = await Promise.all([
    getFeaturedProducts(),
    getLatestProducts()
  ]);

  return (
    <div className="space-y-16 pb-16">
      <section className="container-section grid gap-8 pt-12 md:grid-cols-2 md:items-center">
        <div className="space-y-6">
          <p className="inline-flex rounded-full bg-orange-100 px-4 py-1 text-xs font-semibold uppercase tracking-[0.1em] text-brand">
            Домашние продукты и уютные вещи
          </p>
          <h1 className="text-4xl font-bold leading-tight text-slate-900 md:text-5xl">
            Бабушкины вкусности и рукоделие
          </h1>
          <p className="text-lg text-slate-700">
            Домашние пельмени, вареники, колбаски, пироги, а еще теплые носки и
            пледы ручной работы. Всё с любовью и из натуральных ингредиентов.
          </p>
          <div className="flex gap-4">
            <Link
              href="/catalog"
              className="rounded-md bg-brand px-5 py-2 text-white shadow hover:bg-brand-dark"
            >
              Перейти в каталог
            </Link>
            <Link
              href="#popular"
              className="rounded-md border border-brand px-5 py-2 text-brand hover:bg-orange-50"
            >
              Популярное
            </Link>
          </div>
        </div>
        <div className="rounded-3xl bg-gradient-to-br from-orange-100 via-white to-orange-200 p-10 shadow-inner">
          <div className="grid grid-cols-2 gap-4 text-center text-sm font-medium text-slate-700">
            <div className="rounded-2xl bg-white p-6 shadow">
              <p className="text-3xl font-bold text-brand">100% домашнее</p>
              <p>Всегда свежие продукты</p>
            </div>
            <div className="rounded-2xl bg-white p-6 shadow">
              <p className="text-3xl font-bold text-brand">Тепло</p>
              <p>Вязаные изделия с заботой</p>
            </div>
            <div className="rounded-2xl bg-white p-6 shadow">
              <p className="text-3xl font-bold text-brand">Доставка</p>
              <p>Самовывоз или курьер</p>
            </div>
            <div className="rounded-2xl bg-white p-6 shadow">
              <p className="text-3xl font-bold text-brand">Бонусы</p>
              <p>Копите и оплачивайте покупки</p>
            </div>
          </div>
        </div>
      </section>

      <section id="popular" className="container-section space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-2xl font-semibold">Популярное</h2>
          <Link href="/catalog" className="text-brand hover:underline">
            Смотреть всё
          </Link>
        </div>
        <div className="grid gap-4 md:grid-cols-3">
          {featured.map((product) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>
      </section>

      <section className="container-section space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-2xl font-semibold">Новинки</h2>
          <Link href="/catalog" className="text-brand hover:underline">
            Каталог
          </Link>
        </div>
        <div className="grid gap-4 md:grid-cols-4">
          {latest.map((product) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>
      </section>

      <section className="container-section space-y-6">
        <h3 className="text-2xl font-semibold">Категории</h3>
        <div className="grid gap-4 md:grid-cols-4">
          {['Пельмени и вареники', 'Колбаски', 'Выпечка', 'Вязание'].map((item) => (
            <div key={item} className="rounded-2xl border border-orange-100 bg-white p-6 shadow-sm">
              <p className="text-lg font-semibold text-brand">{item}</p>
              <p className="text-slate-700">Подробнее в каталоге</p>
            </div>
          ))}
        </div>
      </section>

      <section className="container-section space-y-6">
        <h3 className="text-2xl font-semibold">Отзывы</h3>
        <div className="grid gap-4 md:grid-cols-3">
          {[1, 2, 3].map((i) => (
            <div key={i} className="rounded-2xl border border-orange-100 bg-white p-6 shadow-sm">
              <p className="text-sm text-slate-600">Оставьте отзыв после покупки — мы добавим его сюда.</p>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
