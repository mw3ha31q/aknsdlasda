export async function POST({ cookies, redirect }) {
  cookies.delete('auth-token', { path: '/' });
  return redirect('/login');
}