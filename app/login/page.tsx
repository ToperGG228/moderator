'use client';

import { signIn } from 'next-auth/react';
import { FormEvent, useState } from 'react';
import Link from 'next/link';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault();
    const res = await signIn('credentials', {
      redirect: false,
      email,
      password
    });
    if (res?.error) {
      setError('Неверные данные');
    } else {
      window.location.href = '/';
    }
  };

  return (
    <div className="container-section max-w-md py-16">
      <h1 className="text-2xl font-semibold">Вход</h1>
      <form onSubmit={onSubmit} className="mt-6 space-y-4">
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
          placeholder="Пароль"
          className="w-full rounded-md border px-3 py-2"
          required
        />
        {error && <p className="text-sm text-red-600">{error}</p>}
        <button type="submit" className="w-full rounded-md bg-brand py-2 text-white">Войти</button>
        <button
          type="button"
          onClick={() => signIn('google')}
          className="w-full rounded-md border py-2"
        >
          Войти через Google
        </button>
        <button
          type="button"
          onClick={() => signIn('github')}
          className="w-full rounded-md border py-2"
        >
          Войти через GitHub
        </button>
        <p className="text-sm text-slate-600">
          Нет аккаунта? <Link href="/register" className="text-brand">Зарегистрироваться</Link>
        </p>
      </form>
    </div>
  );
}
