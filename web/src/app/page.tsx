import { createClient } from '@/utils/supabase/server'

export default async function Home() {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  return (
    <main style={{ padding: '2rem', maxWidth: 640 }}>
      <h1 style={{ fontSize: '1.5rem' }}>Next.js + Supabase</h1>
      <p style={{ color: '#525252' }}>
        Cliente servidor configurado con <code>@supabase/ssr</code>. Sesión:{' '}
        {user ? (
          <strong>autenticado ({user.email})</strong>
        ) : (
          <span>sin usuario (anon)</span>
        )}
      </p>
      <p style={{ fontSize: '14px', color: '#737373' }}>
        Sustituye los valores en <code>web/.env.local</code> y ejecuta{' '}
        <code>npm run dev</code> desde la carpeta <code>web</code>.
      </p>
    </main>
  )
}
