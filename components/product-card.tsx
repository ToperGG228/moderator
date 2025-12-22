import Image from 'next/image';
import Link from 'next/link';
import { ProductWithRelations } from '../lib/types';

export function ProductCard({ product }: { product: ProductWithRelations }) {
  const price = product.variants[0]?.price || product.price;

  return (
    <div className="rounded-2xl border border-orange-100 bg-white p-4 shadow-sm transition hover:-translate-y-0.5 hover:shadow">
      <Link href={`/products/${product.slug}`}>
        <div className="relative h-48 w-full overflow-hidden rounded-xl bg-orange-50">
          <Image
            src={product.imageUrl || '/placeholder.svg'}
            alt={product.name}
            fill
            className="object-cover"
          />
        </div>
        <div className="mt-3 space-y-1">
          <p className="text-sm uppercase tracking-[0.08em] text-brand">{product.category?.name}</p>
          <p className="text-lg font-semibold text-slate-900">{product.name}</p>
          <p className="text-sm text-slate-600 line-clamp-2">{product.description}</p>
          <p className="text-lg font-bold text-brand">{price ? `${price} ₽` : 'По запросу'}</p>
        </div>
      </Link>
    </div>
  );
}
