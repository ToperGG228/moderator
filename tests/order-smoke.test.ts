import { describe, expect, it } from 'vitest';
import { simulateOrderFlow } from '../lib/order';

describe('order smoke flow', () => {
  it('walks through order statuses and bonus application', () => {
    const { total, spend, remainingToPay, earned, statusSteps } = simulateOrderFlow(
      [
        { price: 650, quantity: 1 },
        { price: 380, quantity: 2 }
      ],
      500,
      5,
      30
    );

    expect(total).toBe(1410);
    expect(spend).toBe(423);
    expect(remainingToPay).toBe(987);
    expect(earned).toBe(49);
    expect(statusSteps[0]).toBe('NEW');
    expect(statusSteps.at(-1)).toBe('DONE');
  });
});
