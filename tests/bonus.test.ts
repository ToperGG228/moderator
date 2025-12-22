import { applyBonusSpend, calculateEarnedBonus } from '../lib/bonus';
import { describe, expect, it } from 'vitest';

describe('bonus program', () => {
  it('calculates earned bonus with floor', () => {
    expect(calculateEarnedBonus(999, 5)).toBe(49);
  });

  it('applies bonus spend respecting max percent', () => {
    const result = applyBonusSpend(1000, 500, 30);
    expect(result.spend).toBe(300);
    expect(result.remainingToPay).toBe(700);
  });
});
