import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

function rotaEhPublica(pathname: string) {
  return pathname === '/login' || pathname.startsWith('/auth/')
}

export async function updateSession(request: NextRequest) {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL
  const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY
  const pathname = request.nextUrl.pathname
  const rotaPublica = rotaEhPublica(pathname)

  if (!url || !publishableKey) {
    if (rotaPublica) {
      return NextResponse.next({ request })
    }

    const redirectUrl = request.nextUrl.clone()
    redirectUrl.pathname = '/login'
    redirectUrl.searchParams.set('erro', 'configuracao')
    return NextResponse.redirect(redirectUrl)
  }

  let supabaseResponse = NextResponse.next({ request })

  const supabase = createServerClient(url, publishableKey, {
    cookies: {
      getAll() {
        return request.cookies.getAll()
      },
      setAll(cookiesToSet, headers) {
        cookiesToSet.forEach(({ name, value }) =>
          request.cookies.set(name, value)
        )

        supabaseResponse = NextResponse.next({ request })

        cookiesToSet.forEach(({ name, value, options }) =>
          supabaseResponse.cookies.set(name, value, options)
        )

        Object.entries(headers).forEach(([key, value]) =>
          supabaseResponse.headers.set(key, value)
        )
      },
    },
  })

  // getUser() valida o JWT e retorna o usuario autenticado
  const { data: { user } } = await supabase.auth.getUser()

  if (!user && !rotaPublica) {
    const redirectUrl = request.nextUrl.clone()
    redirectUrl.pathname = '/login'
    redirectUrl.searchParams.set('next', pathname)
    return NextResponse.redirect(redirectUrl)
  }

  if (user && pathname === '/login') {
    const redirectUrl = request.nextUrl.clone()
    redirectUrl.pathname = '/'
    redirectUrl.search = ''
    return NextResponse.redirect(redirectUrl)
  }

  return supabaseResponse
}

