'use server';

import { prisma } from '../../lib/prisma';
import { OrderStatus, UserRole } from '../../lib/types';

export async function updateProductFlags(formData: FormData) {
  const productId = String(formData.get('productId') || '');
  const isPublished = formData.get('isPublished') === 'on';
  const isFeatured = formData.get('isFeatured') === 'on';
  if (!productId) return;
  await prisma.product.update({
    where: { id: productId },
    data: { isPublished, isFeatured }
  });
}

export async function updateOrderStatus(formData: FormData) {
  const orderId = String(formData.get('orderId') || '');
  const status = String(formData.get('status') || '') as OrderStatus;
  if (!orderId || !Object.values(OrderStatus).includes(status)) return;
  await prisma.order.update({
    where: { id: orderId },
    data: { status }
  });
}

export async function updateUserRole(formData: FormData) {
  const userId = String(formData.get('userId') || '');
  const role = String(formData.get('role') || '') as UserRole;
  if (!userId || !Object.values(UserRole).includes(role)) return;
  await prisma.user.update({
    where: { id: userId },
    data: { role }
  });
}

export async function createCategory(formData: FormData) {
  const name = String(formData.get('name') || '').trim();
  const slug = String(formData.get('slug') || '').trim();
  const imageUrl = String(formData.get('imageUrl') || '').trim();
  if (!name || !slug) return;
  await prisma.category.create({
    data: {
      name,
      slug,
      imageUrl: imageUrl || null
    }
  });
}

export async function createProduct(formData: FormData) {
  const name = String(formData.get('name') || '').trim();
  const slug = String(formData.get('slug') || '').trim();
  const description = String(formData.get('description') || '').trim();
  const price = Number(formData.get('price') || 0);
  const imageUrl = String(formData.get('imageUrl') || '').trim();
  const categoryId = String(formData.get('categoryId') || '').trim();
  if (!name || !slug || !description || !price) return;
  await prisma.product.create({
    data: {
      name,
      slug,
      description,
      price,
      imageUrl: imageUrl || null,
      categoryId: categoryId || null
    }
  });
}
