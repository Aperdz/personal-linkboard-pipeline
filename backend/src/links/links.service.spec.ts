import { generateShortCode } from './links.service';

describe('production short-code generator', () => {
  it('creates a seven-character alphanumeric code', () => {
    for (let i = 0; i < 100; i++) {
      expect(generateShortCode()).toMatch(/^[a-zA-Z0-9]{7}$/);
    }
  });
  it('does not return a fixed value', () => {
    const codes = new Set(Array.from({ length: 100 }, () => generateShortCode()));
    expect(codes.size).toBeGreaterThan(95);
  });
});
