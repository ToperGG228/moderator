import { prisma } from '../../lib/prisma';
import { NextResponse } from 'next/server';

export async function GET() {
  const products = await prisma.product.findMany({ where: { isPublished: true }, select: { slug: true } });
  const urls = products
    .map((product) => `<url><loc>https://example.com/products/${product.slug}</loc></url>`)
    .join('');
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
  <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    <url><loc>https://example.com/</loc></url>
    <url><loc>https://example.com/catalog</loc></url>
    ${urls}
  </urlset>`;
  return new NextResponse(xml, { headers: { 'Content-Type': 'application/xml' } });
}
