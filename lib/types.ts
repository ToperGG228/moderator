import { Category, Product, ProductVariant } from '@prisma/client';

export type ProductWithRelations = Product & {
  category?: Category | null;
  variants: ProductVariant[];
};

export enum OrderStatus {
  NEW = 'NEW',
  CONFIRMED = 'CONFIRMED',
  COOKING = 'COOKING',
  READY = 'READY',
  DELIVERING = 'DELIVERING',
  DONE = 'DONE',
  CANCELED = 'CANCELED'
}

export enum UserRole {
  ADMIN = 'ADMIN',
  CUSTOMER = 'CUSTOMER'
}
