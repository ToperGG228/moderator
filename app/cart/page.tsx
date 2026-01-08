'use client';

import Link from 'next/link';
import Image from 'next/image';
import { useCart } from '../../components/cart-context';

export default function CartPage() {
  const { items, total, updateQuantity, removeItem } = useCart();

  return (
    <div className="container-section py-10 space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Корзина</h1>
        <Link href="/catalog" className="text-sm text-brand">
          Продолжить покупки
        </Link>
      </div>
      {items.length === 0 ? (
        <div className="rounded-xl border border-dashed border-orange-200 p-6 text-sm text-slate-600">
          Корзина пуста.
        </div>
      ) : (
        <div className="grid gap-6 lg:grid-cols-[1.5fr_1fr]">
          <div className="space-y-4">
            {items.map((item) => (
              <div key={item.id} className="flex gap-4 rounded-xl border border-orange-100 bg-white p-4">
                <div className="relative h-20 w-20 overflow-hidden rounded-lg bg-orange-50">
                  <Image src={item.imageUrl || '/placeholder.svg'} alt={item.name} fill className="object-cover" />
                </div>
                <div className="flex-1">
                  <div className="flex items-start justify-between gap-4">
                    <div>
                      <p className="font-medium">{item.name}</p>
                      <p className="text-sm text-slate-600">{item.price} ₽</p>
                    </div>
                    <button
                      type="button"
                      onClick={() => removeItem(item.id)}
                      className="text-xs text-slate-500 hover:text-red-500"
                    >
                      Удалить
                    </button>
                  </div>
                  <div className="mt-3 flex items-center gap-2">
                    <button
                      type="button"
                      className="h-8 w-8 rounded-md border"
                      onClick={() => updateQuantity(item.id, Math.max(1, item.quantity - 1))}
                    >
                      -
                    </button>
                    <span className="min-w-8 text-center text-sm">{item.quantity}</span>
                    <button
                      type="button"
                      className="h-8 w-8 rounded-md border"
                      onClick={() => updateQuantity(item.id, item.quantity + 1)}
                    >
                      +
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
          <div className="rounded-xl border border-orange-100 bg-white p-4 space-y-3 h-fit">
            <h2 className="text-lg font-semibold">Итого</h2>
            <div className="flex items-center justify-between text-sm">
              <span>Товары</span>
              <span>{total} ₽</span>
            </div>
            <Link href="/checkout" className="block rounded-md bg-brand px-4 py-2 text-center text-white">
              Оформить заказ
            </Link>
          </div>
        </div>
      )}
    </div>
  );
}
