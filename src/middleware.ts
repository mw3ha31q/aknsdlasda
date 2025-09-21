import { defineMiddleware } from "astro/middleware";
import { verifyToken } from "./lib/auth";

const publicRoutes = ['/login'];

export const onRequest = defineMiddleware(async ({ url, cookies, redirect }, next) => {
  const pathname = url.pathname;
  
  // Allow public routes
  if (publicRoutes.includes(pathname)) {
    return next();
  }
  
  // Check for auth token
  const token = cookies.get('auth-token')?.value;
  
  if (!token || !verifyToken(token)) {
    return redirect('/login');
  }
  
  return next();
});