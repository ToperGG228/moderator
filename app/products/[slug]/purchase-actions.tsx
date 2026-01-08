'use client';

import { useRouter } from 'next/navigation';
import { useCart } from '../../../components/cart-context';

type ProductPayload = {
  id: string;
  name: string;
  price: number;
  imageUrl?: string | null;
};

export function ProductPurchaseActions({ product }: { product: ProductPayload }) {
  const router = useRouter();
  const { addItem, replace } = useCart();

  const handleAddToCart = () => {
    addItem(product, 1);
  };

  const handleBuyNow = () => {
    replace([{ ...product, quantity: 1 }]);
    router.push('/checkout');
  };

  return (
    <div className="flex flex-wrap gap-3">
      <button
        type="button"
        onClick={handleAddToCart}
        className="rounded-md border border-brand px-5 py-2 text-brand"
      >
        В корзину
      </button>
      <button
        type="button"
        onClick={handleBuyNow}
        className="rounded-md bg-brand px-5 py-2 text-white"
      >
        Купить сейчас
      </button>
    </div>
  );
}
