import { createBrowserClient } from '@supabase/ssr'

/**
 * Cliente Supabase para **Client Components** y código que corre solo en el navegador.
 * Usa singleton internamente (@supabase/ssr).
 */
export function createClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

  if (!url || !anonKey) {
    throw new Error(
      'Faltan NEXT_PUBLIC_SUPABASE_URL o NEXT_PUBLIC_SUPABASE_ANON_KEY en .env.local'
    )
  }

  return createBrowserClient(url, anonKey)
}
