import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'FRIOSUR · Web',
  description: 'Next.js + Supabase (@supabase/ssr)',
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="es">
      <body>{children}</body>
    </html>
  )
}
