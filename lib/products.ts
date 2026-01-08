import { prisma } from './prisma';

export async function getFeaturedProducts() {
  return prisma.product.findMany({
    where: { isPublished: true, isFeatured: true },
    take: 6,
    include: { category: true, variants: true }
  });
}

export async function getLatestProducts() {
  return prisma.product.findMany({
    where: { isPublished: true },
    orderBy: { createdAt: 'desc' },
    take: 8,
    include: { category: true, variants: true }
  });
}
