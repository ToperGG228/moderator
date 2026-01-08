export type BonusOperation = 'EARN' | 'SPEND';

export function calculateEarnedBonus(totalPaid: number, percent: number) {
  if (percent < 0 || percent > 100) throw new Error('percent out of range');
  return Math.floor((totalPaid * percent) / 100);
}

export function applyBonusSpend(total: number, availableBonus: number, maxPercent: number) {
  if (maxPercent < 0 || maxPercent > 100) throw new Error('maxPercent out of range');
  const maxSpend = Math.floor((total * maxPercent) / 100);
  const spend = Math.min(maxSpend, availableBonus, total);
  const remainingToPay = total - spend;
  return { spend, remainingToPay };
}
