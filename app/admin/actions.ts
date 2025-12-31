'use server';

import { Prisma } from '@prisma/client';
import { revalidatePath } from 'next/cache';
import { prisma } from '../../lib/prisma';
import { OrderStatus, UserRole } from '../../lib/types';

export type ActionState = { ok: boolean; message: string; field?: 'slug' | 'name' | 'form' };

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

export async function createProduct(prevState: ActionState, formData: FormData): Promise<ActionState> {
  const name = String(formData.get('name') || '').trim();
  const slug = String(formData.get('slug') || '').trim();
  const description = String(formData.get('description') || '').trim();
  const price = Number.parseInt(String(formData.get('price') || '0'), 10);
  const imageUrl = String(formData.get('imageUrl') || '').trim();
  const categoryId = String(formData.get('categoryId') || '').trim() || null;

  if (!name || !slug || !description || !price) {
    return { ok: false, message: 'Заполни обязательные поля', field: 'form' };
  }

  const duplicate = await prisma.product.findFirst({
    where: {
      OR: [
        { slug },
        {
          AND: [
            { name },
            { categoryId }
          ]
        }
      ]
    }
  });

  if (duplicate?.slug === slug) {
    return { ok: false, message: 'Такой slug уже существует', field: 'slug' };
  }

  if (duplicate) {
    return { ok: false, message: 'Товар с таким названием уже есть в этой категории', field: 'name' };
  }

  try {
    await prisma.product.create({
      data: {
        name,
        slug,
        description,
        price,
        imageUrl: imageUrl || null,
        categoryId
      }
    });
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      return { ok: false, message: 'Такой slug уже существует', field: 'slug' };
    }
    return { ok: false, message: 'Не удалось сохранить товар', field: 'form' };
  }

  revalidatePath('/admin');
  return { ok: true, message: 'Товар добавлен' };
}
