'use client';

import { FormEvent, useState } from 'react';
import Link from 'next/link';

type RegisterState = 'idle' | 'loading' | 'success' | 'error';

export default function RegisterPage() {
  const [state, setState] = useState<RegisterState>('idle');
  const [error, setError] = useState('');
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setState('loading');
    setError('');
    const res = await fetch('/api/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, email, password })
    });
    if (!res.ok) {
      const data = await res.json().catch(() => ({ error: 'Ошибка регистрации' }));
      setState('error');
      setError(data.error || 'Ошибка регистрации');
      return;
    }
    setState('success');
  };

  return (
    <div className="container-section max-w-md py-16">
      <h1 className="text-2xl font-semibold">Регистрация</h1>
      <p className="mt-2 text-sm text-slate-600">
        Создайте аккаунт, чтобы оформлять заказы и смотреть историю покупок.
      </p>
      <form onSubmit={onSubmit} className="mt-6 space-y-4">
        <input
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Имя"
          className="w-full rounded-md border px-3 py-2"
          required
        />
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="Email"
          className="w-full rounded-md border px-3 py-2"
          required
        />
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          placeholder="Пароль (мин. 8 символов)"
          className="w-full rounded-md border px-3 py-2"
          required
          minLength={8}
        />
        {state === 'success' ? (
          <p className="rounded-md border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-700">
            Аккаунт создан. Теперь можно <Link href="/login" className="font-semibold text-emerald-700">войти</Link>.
          </p>
        ) : (
          <button
            type="submit"
            disabled={state === 'loading'}
            className="w-full rounded-md bg-brand py-2 text-white disabled:opacity-60"
          >
            {state === 'loading' ? 'Создаем аккаунт…' : 'Зарегистрироваться'}
          </button>
        )}
        {state === 'error' && <p className="text-sm text-red-600">{error}</p>}
      </form>
      <p className="mt-4 text-sm text-slate-600">
        Уже есть аккаунт? <Link href="/login" className="text-brand">Войти</Link>
      </p>
    </div>
  );
}
