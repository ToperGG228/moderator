'use client';

import Link from 'next/link';
import { useSession, signOut } from 'next-auth/react';
import { ShoppingCart, User, Shield } from 'lucide-react';

export function SiteHeader() {
  const { data: session } = useSession();
  const isAdmin = session?.user?.role === 'ADMIN';

  return (
    <header className="sticky top-0 z-30 border-b border-orange-100 bg-white/80 backdrop-blur">
      <div className="container-section flex items-center justify-between py-4">
        <Link href="/" className="font-semibold text-lg tracking-tight text-brand">
          Бабушкины вкусности
        </Link>
        <nav className="flex items-center gap-4 text-sm font-medium text-slate-700">
          <Link href="/catalog" className="hover:text-brand">
            Каталог
          </Link>
          <Link href="/about" className="hover:text-brand">
            О нас
          </Link>
          <Link href="/contact" className="hover:text-brand">
            Контакты
          </Link>
          {isAdmin && (
            <Link href="/admin" className="flex items-center gap-1 text-brand">
              <Shield className="h-4 w-4" /> Админка
            </Link>
          )}
          <Link href="/cart" className="flex items-center gap-1">
            <ShoppingCart className="h-4 w-4" /> Корзина
          </Link>
          {session ? (
            <button
              type="button"
              onClick={() => signOut({ callbackUrl: '/' })}
              className="flex items-center gap-2 rounded-full bg-brand text-white px-3 py-1 text-xs"
            >
              <User className="h-4 w-4" /> Выйти
            </button>
          ) : (
            <Link
              href="/login"
              className="flex items-center gap-2 rounded-full border border-brand px-3 py-1 text-xs text-brand"
            >
              <User className="h-4 w-4" /> Войти
            </Link>
          )}
        </nav>
      </div>
    </header>
  );
}
