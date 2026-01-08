import type { Metadata } from 'next';
import './globals.css';
import { ReactNode } from 'react';
import { Providers } from '../components/providers';
import { SiteHeader } from '../components/site-header';
import { SiteFooter } from '../components/site-footer';
import { Toaster } from 'sonner';

export const metadata: Metadata = {
  title: 'Бабушкины вкусности и рукоделие',
  description: 'Каталог домашних деликатесов и вязаных изделий',
  metadataBase: new URL('https://example.com'),
  openGraph: {
    title: 'Бабушкины вкусности и рукоделие',
    description: 'Домашняя кухня и уютные вязаные вещи',
    url: 'https://example.com',
    siteName: 'Бабушкины вкусности',
    locale: 'ru_RU',
    type: 'website'
  },
  alternates: {
    canonical: 'https://example.com'
  },
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="ru">
      <body className="min-h-screen">
        <Providers>
          <div className="flex min-h-screen flex-col">
            <SiteHeader />
            <main className="flex-1 bg-gradient-to-b from-orange-50 via-white to-white">
              {children}
            </main>
            <SiteFooter />
          </div>
          <Toaster position="top-left" richColors closeButton duration={2800} />
        </Providers>
      </body>
    </html>
  );
}
