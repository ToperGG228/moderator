import { hash } from 'bcryptjs';
import { prisma } from '../lib/prisma';
import { OrderStatus } from '../lib/types';

async function main() {
  const adminEmail = process.env.SEED_ADMIN_EMAIL || 'admin@example.com';
  const adminPassword = process.env.SEED_ADMIN_PASSWORD || 'password123';

  const passwordHash = await hash(adminPassword, 10);
  await prisma.user.upsert({
    where: { email: adminEmail },
    update: { passwordHash, role: 'ADMIN' },
    create: {
      email: adminEmail,
      passwordHash,
      role: 'ADMIN',
      name: 'Admin'
    }
  });

  const categories = await prisma.category.createMany({
    data: [
      { name: 'Пельмени и вареники', slug: 'dumplings' },
      { name: 'Колбаски', slug: 'sausages' },
      { name: 'Выпечка', slug: 'bakery' },
      { name: 'Вязаные изделия', slug: 'knit' }
    ],
    skipDuplicates: true
  });

  const products = await prisma.product.createMany({
    data: [
      {
        name: 'Пельмени домашние',
        slug: 'pelmeni',
        description: 'Свежие пельмени из говядины и свинины',
        price: 650,
        categoryId: (await prisma.category.findUnique({ where: { slug: 'dumplings' } }))?.id,
        isFeatured: true,
        imageUrl: '/uploads/pelmeni.jpg'
      },
      {
        name: 'Вареники с картошкой',
        slug: 'vareniki-kartoshka',
        description: 'Нежное тесто и ароматная картошка',
        price: 450,
        categoryId: (await prisma.category.findUnique({ where: { slug: 'dumplings' } }))?.id,
        isFeatured: true,
        imageUrl: '/uploads/vareniki.jpg'
      },
      {
        name: 'Домашние колбаски',
        slug: 'kolbaski',
        description: 'Запекайте или жарьте — всегда вкусно',
        price: 700,
        categoryId: (await prisma.category.findUnique({ where: { slug: 'sausages' } }))?.id,
        isFeatured: true,
        imageUrl: '/uploads/kolbaski.jpg'
      },
      {
        name: 'Вязаные носки',
        slug: 'noski',
        description: 'Теплые шерстяные носки ручной работы',
        price: 350,
        categoryId: (await prisma.category.findUnique({ where: { slug: 'knit' } }))?.id,
        imageUrl: '/uploads/noski.jpg'
      }
    ],
    skipDuplicates: true
  });

  await prisma.productVariant.createMany({
    data: [
      { name: '1 кг', price: 650, attributes: { weight: '1kg' }, productId: (await prisma.product.findUnique({ where: { slug: 'pelmeni' } }))!.id },
      { name: '0.5 кг', price: 380, attributes: { weight: '0.5kg' }, productId: (await prisma.product.findUnique({ where: { slug: 'vareniki-kartoshka' } }))!.id },
      { name: 'С перчиком', price: 720, attributes: { spice: 'mild' }, productId: (await prisma.product.findUnique({ where: { slug: 'kolbaski' } }))!.id },
      { name: 'Размер 38-40', price: 350, attributes: { size: '38-40' }, productId: (await prisma.product.findUnique({ where: { slug: 'noski' } }))!.id }
    ],
    skipDuplicates: true
  });

  console.log('Seed complete', { categories, products });
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
