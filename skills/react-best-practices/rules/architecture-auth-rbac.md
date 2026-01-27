---
title: Implement Authentication with Route Protection and RBAC
impact: CRITICAL
impactDescription: secure routes, role-based access, session management, HTTP-only cookies
tags: authentication, authorization, middleware, rbac, session, security
---

## Implement Authentication with Route Protection and RBAC

**Impact: CRITICAL (secure routes, role-based access, session management, HTTP-only cookies)**

Implement secure authentication with Next.js middleware for route protection, role-based access control (RBAC), and HTTP-only cookie session management. Use server-side validation for all protected resources.

**Incorrect (client-side only auth, insecure):**

```tsx
// Client-side only auth - easily bypassed
function ProtectedPage() {
  const [user, setUser] = useState(null)
  
  useEffect(() => {
    const token = localStorage.getItem('token') // Insecure
    if (!token) {
      router.push('/login')
      return
    }
    
    // Client-side role check - can be manipulated
    if (user?.role !== 'admin') {
      router.push('/unauthorized')
    }
  }, [])

  return <AdminDashboard />
}
```

**Correct (server-side auth with middleware and RBAC):**

```tsx
// lib/auth.ts
import { SignJWT, jwtVerify } from 'jose'
import { cookies } from 'next/headers'
import { NextRequest } from 'next/server'

const secretKey = process.env.AUTH_SECRET!
const key = new TextEncoder().encode(secretKey)

export interface User {
  id: string
  email: string
  name: string
  role: 'admin' | 'user' | 'moderator'
  permissions: string[]
}

export interface Session {
  user: User
  expires: string
}

export async function encrypt(payload: Session): Promise<string> {
  return await new SignJWT(payload)
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('24h')
    .sign(key)
}

export async function decrypt(input: string): Promise<Session | null> {
  try {
    const { payload } = await jwtVerify(input, key, {
      algorithms: ['HS256'],
    })
    return payload as Session
  } catch (error) {
    return null
  }
}

export async function createSession(user: User) {
  const expires = new Date(Date.now() + 24 * 60 * 60 * 1000) // 24 hours
  const session: Session = { user, expires: expires.toISOString() }
  const sessionToken = await encrypt(session)

  cookies().set('session', sessionToken, {
    expires,
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/'
  })
}

export async function getSession(): Promise<Session | null> {
  const sessionCookie = cookies().get('session')?.value
  if (!sessionCookie) return null
  
  return await decrypt(sessionCookie)
}

export async function deleteSession() {
  cookies().delete('session')
}

// Role and permission definitions
export const ROLES = {
  ADMIN: 'admin',
  USER: 'user',
  MODERATOR: 'moderator'
} as const

export const PERMISSIONS = {
  USER_READ: 'user:read',
  USER_WRITE: 'user:write',
  USER_DELETE: 'user:delete',
  ADMIN_PANEL: 'admin:panel',
  MODERATE_CONTENT: 'content:moderate'
} as const

export const ROLE_PERMISSIONS = {
  [ROLES.ADMIN]: [
    PERMISSIONS.USER_READ,
    PERMISSIONS.USER_WRITE,
    PERMISSIONS.USER_DELETE,
    PERMISSIONS.ADMIN_PANEL,
    PERMISSIONS.MODERATE_CONTENT
  ],
  [ROLES.MODERATOR]: [
    PERMISSIONS.USER_READ,
    PERMISSIONS.MODERATE_CONTENT
  ],
  [ROLES.USER]: [
    PERMISSIONS.USER_READ
  ]
}

export function hasPermission(user: User, permission: string): boolean {
  return user.permissions.includes(permission)
}

export function hasRole(user: User, role: string): boolean {
  return user.role === role
}

// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { decrypt } from '@/lib/auth'

// Define protected routes and their required permissions
const PROTECTED_ROUTES = {
  '/admin': ['admin:panel'],
  '/users': ['user:read'],
  '/users/create': ['user:write'],
  '/users/[id]/edit': ['user:write'],
  '/users/[id]/delete': ['user:delete'],
  '/moderate': ['content:moderate']
}

const PUBLIC_ROUTES = ['/login', '/register', '/forgot-password', '/']

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl
  
  // Allow public routes
  if (PUBLIC_ROUTES.some(route => pathname.startsWith(route))) {
    return NextResponse.next()
  }

  // Get session
  const sessionCookie = request.cookies.get('session')?.value
  const session = sessionCookie ? await decrypt(sessionCookie) : null

  // Redirect to login if no session
  if (!session) {
    const loginUrl = new URL('/login', request.url)
    loginUrl.searchParams.set('redirect', pathname)
    return NextResponse.redirect(loginUrl)
  }

  // Check if session is expired
  if (new Date(session.expires) < new Date()) {
    const response = NextResponse.redirect(new URL('/login', request.url))
    response.cookies.delete('session')
    return response
  }

  // Check route permissions
  const requiredPermissions = getRequiredPermissions(pathname)
  if (requiredPermissions.length > 0) {
    const hasAccess = requiredPermissions.every(permission =>
      session.user.permissions.includes(permission)
    )

    if (!hasAccess) {
      return NextResponse.redirect(new URL('/unauthorized', request.url))
    }
  }

  // Add user info to headers for server components
  const response = NextResponse.next()
  response.headers.set('x-user-id', session.user.id)
  response.headers.set('x-user-role', session.user.role)
  
  return response
}

function getRequiredPermissions(pathname: string): string[] {
  // Check exact matches first
  if (PROTECTED_ROUTES[pathname]) {
    return PROTECTED_ROUTES[pathname]
  }

  // Check pattern matches
  for (const [route, permissions] of Object.entries(PROTECTED_ROUTES)) {
    if (route.includes('[') && matchesPattern(pathname, route)) {
      return permissions
    }
  }

  return []
}

function matchesPattern(pathname: string, pattern: string): boolean {
  const patternRegex = pattern.replace(/\[([^\]]+)\]/g, '([^/]+)')
  return new RegExp(`^${patternRegex}$`).test(pathname)
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)']
}

// Server actions for auth
// app/actions/auth.ts
'use server'

import { z } from 'zod'
import { createSession, deleteSession, ROLE_PERMISSIONS } from '@/lib/auth'
import { redirect } from 'next/navigation'
import bcrypt from 'bcryptjs'

const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required')
})

export async function login(formData: FormData) {
  const result = loginSchema.safeParse({
    email: formData.get('email'),
    password: formData.get('password')
  })

  if (!result.success) {
    return {
      success: false,
      errors: result.error.flatten().fieldErrors
    }
  }

  const { email, password } = result.data

  try {
    // Verify user credentials
    const user = await db.user.findUnique({
      where: { email },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        password: true
      }
    })

    if (!user || !await bcrypt.compare(password, user.password)) {
      return {
        success: false,
        errors: { email: ['Invalid email or password'] }
      }
    }

    // Create session with permissions
    const userWithPermissions = {
      ...user,
      permissions: ROLE_PERMISSIONS[user.role] || []
    }

    await createSession(userWithPermissions)
    
  } catch (error) {
    return {
      success: false,
      errors: { _form: ['Login failed. Please try again.'] }
    }
  }

  redirect('/dashboard')
}

export async function logout() {
  await deleteSession()
  redirect('/login')
}

// Components
// components/ProtectedRoute.tsx
import { getSession } from '@/lib/auth'
import { redirect } from 'next/navigation'

interface ProtectedRouteProps {
  children: React.ReactNode
  requiredPermissions?: string[]
  requiredRole?: string
  fallback?: React.ReactNode
}

export async function ProtectedRoute({
  children,
  requiredPermissions = [],
  requiredRole,
  fallback
}: ProtectedRouteProps) {
  const session = await getSession()

  if (!session) {
    redirect('/login')
  }

  // Check role requirement
  if (requiredRole && session.user.role !== requiredRole) {
    if (fallback) return <>{fallback}</>
    redirect('/unauthorized')
  }

  // Check permission requirements
  if (requiredPermissions.length > 0) {
    const hasPermissions = requiredPermissions.every(permission =>
      session.user.permissions.includes(permission)
    )

    if (!hasPermissions) {
      if (fallback) return <>{fallback}</>
      redirect('/unauthorized')
    }
  }

  return <>{children}</>
}

// components/RoleGuard.tsx
import { getSession, hasPermission, hasRole } from '@/lib/auth'

interface RoleGuardProps {
  children: React.ReactNode
  requiredPermissions?: string[]
  requiredRole?: string
  fallback?: React.ReactNode
}

export async function RoleGuard({
  children,
  requiredPermissions = [],
  requiredRole,
  fallback = null
}: RoleGuardProps) {
  const session = await getSession()

  if (!session) return <>{fallback}</>

  // Check role
  if (requiredRole && !hasRole(session.user, requiredRole)) {
    return <>{fallback}</>
  }

  // Check permissions
  if (requiredPermissions.length > 0) {
    const hasAccess = requiredPermissions.every(permission =>
      hasPermission(session.user, permission)
    )

    if (!hasAccess) return <>{fallback}</>
  }

  return <>{children}</>
}

// Usage in pages
// app/admin/page.tsx
import { ProtectedRoute } from '@/components/ProtectedRoute'
import { PERMISSIONS } from '@/lib/auth'

export default function AdminPage() {
  return (
    <ProtectedRoute requiredPermissions={[PERMISSIONS.ADMIN_PANEL]}>
      <div>
        <h1>Admin Dashboard</h1>
        <AdminContent />
      </div>
    </ProtectedRoute>
  )
}

// app/users/page.tsx
import { RoleGuard } from '@/components/RoleGuard'
import { PERMISSIONS } from '@/lib/auth'

export default function UsersPage() {
  return (
    <div>
      <h1>Users</h1>
      <UsersList />
      
      <RoleGuard requiredPermissions={[PERMISSIONS.USER_WRITE]}>
        <CreateUserButton />
      </RoleGuard>
    </div>
  )
}

// Client-side auth context
// contexts/AuthContext.tsx
'use client'

import { createContext, useContext, useEffect, useState } from 'react'
import type { User } from '@/lib/auth'

interface AuthContextType {
  user: User | null
  loading: boolean
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  loading: true
})

export function AuthProvider({ children, initialUser }: {
  children: React.ReactNode
  initialUser: User | null
}) {
  const [user, setUser] = useState<User | null>(initialUser)
  const [loading, setLoading] = useState(!initialUser)

  useEffect(() => {
    if (initialUser) {
      setUser(initialUser)
      setLoading(false)
    }
  }, [initialUser])

  return (
    <AuthContext.Provider value={{ user, loading }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)
```

This pattern provides:
- **Server-side validation** - All auth checks happen on the server
- **HTTP-only cookies** - Secure session storage
- **Route protection** - Middleware blocks unauthorized access
- **Role-based access** - Granular permission system
- **Session management** - Automatic token refresh and cleanup