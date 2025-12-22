# Бабушкины вкусности и рукоделие

Интернет-магазин домашних деликатесов и вязаных изделий. Стек: Next.js 14 (App Router), TypeScript, TailwindCSS/shadcn базовые токены, Prisma + PostgreSQL, NextAuth (credentials + Google + GitHub), MinIO/S3 для прод-хранилища изображений.

## Скрипты
- `npm run dev` — локальная разработка.
- `npm run build` — сборка.
- `npm run start` — запуск собранного приложения.
- `npm run db:migrate` — применение миграций.
- `npm run db:seed` — сидинг с админом и демо-данными.
- `npm test` — unit и e2e smoke тесты.

## Быстрый старт (dev)
```bash
npm install
cp .env.example .env
npx prisma migrate dev
npm run db:seed
npm run dev
```
Приложение будет на http://localhost:3000.
