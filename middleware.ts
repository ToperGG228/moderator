import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { getToken } from 'next-auth/jwt';
import { UserRole } from './lib/types';

export async function middleware(req: NextRequest) {
  const cookieName = process.env.NEXTAUTH_COOKIE_NAME || 'babushka.session';
  const secret = process.env.NEXTAUTH_SECRET;
  let token = await getToken({
    req,
    secret,
    cookieName
  });
  if (!token && cookieName && process.env.NODE_ENV === 'production') {
    token =
      (await getToken({ req, secret, cookieName: `__Secure-${cookieName}` })) ||
      (await getToken({ req, secret, cookieName: `__Host-${cookieName}` }));
  }
  const isAdminRoute = req.nextUrl.pathname.startsWith('/admin');
  if (isAdminRoute) {
    if (!token) {
      return NextResponse.redirect(new URL('/login', req.url));
    }
    if (token.role !== UserRole.ADMIN) {
      return NextResponse.redirect(new URL('/', req.url));
    }
  }
  return NextResponse.next();
}

export const config = {
  matcher: ['/admin/:path*']
};
