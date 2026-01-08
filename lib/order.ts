import { applyBonusSpend, calculateEarnedBonus } from './bonus';
import { OrderStatus } from './types';

export type CartLine = { price: number; quantity: number };

export function calculateCartTotal(lines: CartLine[]) {
  return lines.reduce((sum, line) => sum + line.price * line.quantity, 0);
}

export function simulateOrderFlow(lines: CartLine[], availableBonus: number, earnPercent: number, maxSpendPercent: number) {
  const total = calculateCartTotal(lines);
  const { spend, remainingToPay } = applyBonusSpend(total, availableBonus, maxSpendPercent);
  const earned = calculateEarnedBonus(remainingToPay, earnPercent);
  const statusSteps: OrderStatus[] = [
    OrderStatus.NEW,
    OrderStatus.CONFIRMED,
    OrderStatus.COOKING,
    OrderStatus.READY,
    OrderStatus.DELIVERING,
    OrderStatus.DONE
  ];
  return {
    total,
    spend,
    remainingToPay,
    earned,
    statusSteps
  };
}
