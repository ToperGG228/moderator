'use client';

import { FormEvent, useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { useSession } from 'next-auth/react';
import { useCart } from '../../components/cart-context';

type BonusState = { balance: number };

export default function CheckoutPage() {
  const { data: session } = useSession();
  const { items, total, clear } = useCart();
  const [bonus, setBonus] = useState<BonusState>({ balance: 0 });
  const [bonusToSpend, setBonusToSpend] = useState(0);
  const [deliveryType, setDeliveryType] = useState<'pickup' | 'delivery'>('pickup');
  const [paymentMethod, setPaymentMethod] = useState('card');
  const [phone, setPhone] = useState('');
  const [comment, setComment] = useState('');
  const [address, setAddress] = useState('');
  const [date, setDate] = useState('');
  const [consent, setConsent] = useState(false);
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const [error, setError] = useState('');

  useEffect(() => {
    fetch('/api/bonus/balance')
      .then((res) => res.json())
      .then((data) => setBonus({ balance: data.balance || 0 }))
      .catch(() => setBonus({ balance: 0 }));
  }, []);

  const remainingToPay = useMemo(() => Math.max(total - bonusToSpend, 0), [total, bonusToSpend]);

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (bonusToSpend > bonus.balance) {
      setError('Недостаточно бонусов для списания.');
      return;
    }
    if (!consent) {
      setError('Нужно согласиться с обработкой персональных данных.');
      return;
    }
    if (items.length === 0) {
      setError('Корзина пуста.');
      return;
    }
    setStatus('loading');
    setError('');

    const res = await fetch('/api/orders', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        items: items.map((item) => ({
          productId: item.id,
          quantity: item.quantity,
          price: item.price
        })),
        phone,
        comment,
        deliveryType,
        address: deliveryType === 'delivery' ? address : undefined,
        deliveryDate: date || undefined,
        bonusToSpend,
        paymentMethod
      })
    });

    if (!res.ok) {
      const data = await res.json().catch(() => ({ error: 'Ошибка оформления' }));
      setStatus('error');
      setError(data.error || 'Ошибка оформления');
      return;
    }
    setStatus('success');
    clear();
  };

  return (
    <div className="container-section py-10 space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Оформление заказа</h1>
        <Link href="/cart" className="text-sm text-brand">
          Назад в корзину
        </Link>
      </div>
      <div className="grid gap-6 lg:grid-cols-[1.2fr_1fr]">
        <form onSubmit={onSubmit} className="space-y-4 rounded-xl border border-orange-100 bg-white p-5">
          <div>
            <p className="text-sm font-semibold text-slate-700">Контактные данные</p>
            <input
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="Телефон"
              className="mt-2 w-full rounded-md border px-3 py-2 text-sm"
              required
            />
          </div>
          <div>
            <p className="text-sm font-semibold text-slate-700">Способ получения</p>
            <div className="mt-2 flex gap-4 text-sm">
              <label className="flex items-center gap-2">
                <input type="radio" checked={deliveryType === 'pickup'} onChange={() => setDeliveryType('pickup')} />
                Самовывоз
              </label>
              <label className="flex items-center gap-2">
                <input type="radio" checked={deliveryType === 'delivery'} onChange={() => setDeliveryType('delivery')} />
                Доставка
              </label>
            </div>
            {deliveryType === 'delivery' && (
              <input
                value={address}
                onChange={(e) => setAddress(e.target.value)}
                placeholder="Адрес доставки"
                className="mt-3 w-full rounded-md border px-3 py-2 text-sm"
                required
              />
            )}
          </div>
          <div>
            <p className="text-sm font-semibold text-slate-700">Дата и время</p>
            <input
              type="datetime-local"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              className="mt-2 w-full rounded-md border px-3 py-2 text-sm"
            />
          </div>
          <div>
            <p className="text-sm font-semibold text-slate-700">Способ оплаты</p>
            <div className="mt-2 flex flex-wrap gap-3 text-sm">
              {[
                { id: 'card', label: 'Карта онлайн' },
                { id: 'cash', label: 'Наличными при получении' },
                { id: 'transfer', label: 'Перевод' }
              ].map((option) => (
                <label key={option.id} className="flex items-center gap-2">
                  <input
                    type="radio"
                    checked={paymentMethod === option.id}
                    onChange={() => setPaymentMethod(option.id)}
                  />
                  {option.label}
                </label>
              ))}
            </div>
          </div>
          <div>
            <p className="text-sm font-semibold text-slate-700">Комментарий</p>
            <textarea
              value={comment}
              onChange={(e) => setComment(e.target.value)}
              placeholder="Пожелания по заказу"
              className="mt-2 min-h-[88px] w-full rounded-md border px-3 py-2 text-sm"
            />
          </div>
          <div className="rounded-lg border border-orange-100 bg-orange-50 p-3 text-sm">
            <p className="font-medium">Бонусы</p>
            <p className="text-slate-600">
              Доступно: {bonus.balance} бонусов {session ? '' : '(нужен вход)'}
            </p>
            <input
              type="number"
              min="0"
              max={bonus.balance}
              value={bonusToSpend}
              onChange={(e) => {
                const nextValue = Number(e.target.value);
                if (Number.isNaN(nextValue)) {
                  setBonusToSpend(0);
                  return;
                }
                if (nextValue > bonus.balance) {
                  setError('Недостаточно бонусов для списания.');
                  setBonusToSpend(bonus.balance);
                  return;
                }
                if (error) {
                  setError('');
                }
                setBonusToSpend(Math.max(0, nextValue));
              }}
              className="mt-2 w-full rounded-md border px-3 py-2 text-sm"
            />
          </div>
          <label className="flex items-start gap-2 text-xs text-slate-600">
            <input type="checkbox" checked={consent} onChange={(e) => setConsent(e.target.checked)} />
            <span className="space-x-1">
              <span>Я согласен на обработку персональных данных и с условиями оплаты.</span>
              <Link href="/privacy" className="text-brand underline underline-offset-2">
                Политика конфиденциальности
              </Link>
              <span>/</span>
              <Link href="/terms" className="text-brand underline underline-offset-2">
                согласие на обработку данных
              </Link>
            </span>
          </label>
          {error && <p className="text-sm text-red-600">{error}</p>}
          {status === 'success' && (
            <p className="text-sm text-emerald-600">Заказ оформлен. Мы скоро свяжемся с вами!</p>
          )}
          <button type="submit" className="rounded-md bg-brand px-4 py-2 text-white">
            Подтвердить заказ
          </button>
        </form>
        <div className="rounded-xl border border-orange-100 bg-white p-5 space-y-3 h-fit">
          <h2 className="text-lg font-semibold">Ваш заказ</h2>
          {items.length === 0 ? (
            <p className="text-sm text-slate-600">Корзина пуста.</p>
          ) : (
            <ul className="space-y-2 text-sm text-slate-700">
              {items.map((item) => (
                <li key={item.id} className="flex justify-between">
                  <span>
                    {item.name} × {item.quantity}
                  </span>
                  <span>{item.price * item.quantity} ₽</span>
                </li>
              ))}
            </ul>
          )}
          <div className="border-t pt-3 text-sm">
            <div className="flex justify-between">
              <span>Сумма</span>
              <span>{total} ₽</span>
            </div>
            <div className="flex justify-between text-slate-600">
              <span>Бонусы</span>
              <span>-{bonusToSpend} ₽</span>
            </div>
            <div className="mt-2 flex justify-between font-semibold">
              <span>К оплате</span>
              <span>{remainingToPay} ₽</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
