---
title: Use proxy.ts for API Proxying in Next.js
impact: MEDIUM
impactDescription: better API organization, CORS handling, request transformation, security
tags: nextjs, proxy, api, middleware, cors, security
---

## Use proxy.ts for API Proxying in Next.js

**Impact: MEDIUM (better API organization, CORS handling, request transformation, security)**

Use `proxy.ts` instead of `middleware.ts` for API proxying, request transformation, and CORS handling. This provides better organization and more specific control over API routes.

**Incorrect (using middleware.ts for API proxying):**

```tsx
// middleware.ts - too broad, affects all routes
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  // This runs on ALL routes, including static files
  if (request.nextUrl.pathname.startsWith('/api/external')) {
    const url = request.nextUrl.clone()
    url.hostname = 'external-api.com'
    url.port = '443'
    url.protocol = 'https:'
    url.pathname = url.pathname.replace('/api/external', '')
    
    return NextResponse.rewrite(url)
  }
  
  return NextResponse.next()
}

export const config = {
  matcher: '/((?!_next/static|_next/image|favicon.ico).*)',
}
```

**Correct (using proxy.ts for specific API handling):**

```tsx
// lib/proxy.ts
import { NextRequest, NextResponse } from 'next/server'

interface ProxyConfig {
  target: string
  pathRewrite?: Record<string, string>
  changeOrigin?: boolean
  headers?: Record<string, string>
  timeout?: number
}

export class ApiProxy {
  private config: ProxyConfig

  constructor(config: ProxyConfig) {
    this.config = config
  }

  async handle(request: NextRequest): Promise<NextResponse> {
    try {
      const url = this.buildTargetUrl(request)
      const headers = this.buildHeaders(request)
      
      const controller = new AbortController()
      const timeoutId = setTimeout(() => controller.abort(), this.config.timeout || 30000)

      const response = await fetch(url, {
        method: request.method,
        headers,
        body: request.body,
        signal: controller.signal,
      })

      clearTimeout(timeoutId)

      const responseHeaders = new Headers()
      
      // Copy relevant headers
      response.headers.forEach((value, key) => {
        if (!this.isHopByHopHeader(key)) {
          responseHeaders.set(key, value)
        }
      })

      // Add CORS headers
      responseHeaders.set('Access-Control-Allow-Origin', '*')
      responseHeaders.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
      responseHeaders.set('Access-Control-Allow-Headers', 'Content-Type, Authorization')

      const body = await response.arrayBuffer()

      return new NextResponse(body, {
        status: response.status,
        statusText: response.statusText,
        headers: responseHeaders,
      })
    } catch (error) {
      console.error('Proxy error:', error)
      return NextResponse.json(
        { error: 'Proxy request failed' },
        { status: 502 }
      )
    }
  }

  private buildTargetUrl(request: NextRequest): string {
    const url = new URL(request.url)
    let pathname = url.pathname

    // Apply path rewrites
    if (this.config.pathRewrite) {
      Object.entries(this.config.pathRewrite).forEach(([from, to]) => {
        pathname = pathname.replace(new RegExp(from), to)
      })
    }

    return `${this.config.target}${pathname}${url.search}`
  }

  private buildHeaders(request: NextRequest): HeadersInit {
    const headers: Record<string, string> = {}

    // Copy request headers
    request.headers.forEach((value, key) => {
      if (!this.isHopByHopHeader(key)) {
        headers[key] = value
      }
    })

    // Override with config headers
    if (this.config.headers) {
      Object.assign(headers, this.config.headers)
    }

    // Set host header if changeOrigin is true
    if (this.config.changeOrigin) {
      const targetUrl = new URL(this.config.target)
      headers.host = targetUrl.host
    }

    return headers
  }

  private isHopByHopHeader(header: string): boolean {
    const hopByHopHeaders = [
      'connection',
      'keep-alive',
      'proxy-authenticate',
      'proxy-authorization',
      'te',
      'trailers',
      'transfer-encoding',
      'upgrade'
    ]
    return hopByHopHeaders.includes(header.toLowerCase())
  }
}

// Specific proxy configurations
export const externalApiProxy = new ApiProxy({
  target: 'https://external-api.com',
  pathRewrite: {
    '^/api/external': ''
  },
  changeOrigin: true,
  headers: {
    'X-API-Key': process.env.EXTERNAL_API_KEY!,
    'User-Agent': 'NextJS-Proxy/1.0'
  },
  timeout: 15000
})

export const authServiceProxy = new ApiProxy({
  target: 'https://auth.company.com',
  pathRewrite: {
    '^/api/auth': '/v1'
  },
  changeOrigin: true,
  headers: {
    'Authorization': `Bearer ${process.env.AUTH_SERVICE_TOKEN}`
  }
})

export const analyticsProxy = new ApiProxy({
  target: 'https://analytics.company.com',
  pathRewrite: {
    '^/api/analytics': '/api/v2'
  },
  changeOrigin: true
})
```

**API route implementations:**

```tsx
// app/api/external/[...path]/route.ts
import { externalApiProxy } from '@/lib/proxy'
import { NextRequest } from 'next/server'

export async function GET(request: NextRequest) {
  return externalApiProxy.handle(request)
}

export async function POST(request: NextRequest) {
  return externalApiProxy.handle(request)
}

export async function PUT(request: NextRequest) {
  return externalApiProxy.handle(request)
}

export async function DELETE(request: NextRequest) {
  return externalApiProxy.handle(request)
}

export async function OPTIONS(request: NextRequest) {
  return new Response(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  })
}

// app/api/auth/[...path]/route.ts
import { authServiceProxy } from '@/lib/proxy'
import { NextRequest } from 'next/server'

export async function GET(request: NextRequest) {
  return authServiceProxy.handle(request)
}

export async function POST(request: NextRequest) {
  return authServiceProxy.handle(request)
}

// app/api/analytics/[...path]/route.ts
import { analyticsProxy } from '@/lib/proxy'
import { NextRequest } from 'next/server'

export async function GET(request: NextRequest) {
  return analyticsProxy.handle(request)
}

export async function POST(request: NextRequest) {
  return analyticsProxy.handle(request)
}
```

**Advanced proxy with caching and rate limiting:**

```tsx
// lib/advanced-proxy.ts
import { NextRequest, NextResponse } from 'next/server'
import { LRUCache } from 'lru-cache'

interface CacheConfig {
  ttl: number
  max: number
}

interface RateLimitConfig {
  windowMs: number
  maxRequests: number
}

export class AdvancedApiProxy extends ApiProxy {
  private cache?: LRUCache<string, { data: ArrayBuffer; headers: Headers; status: number }>
  private rateLimitMap = new Map<string, { count: number; resetTime: number }>()

  constructor(
    config: ProxyConfig,
    private cacheConfig?: CacheConfig,
    private rateLimitConfig?: RateLimitConfig
  ) {
    super(config)
    
    if (cacheConfig) {
      this.cache = new LRUCache({
        max: cacheConfig.max,
        ttl: cacheConfig.ttl
      })
    }
  }

  async handle(request: NextRequest): Promise<NextResponse> {
    // Rate limiting
    if (this.rateLimitConfig && !this.checkRateLimit(request)) {
      return NextResponse.json(
        { error: 'Rate limit exceeded' },
        { status: 429 }
      )
    }

    // Cache check for GET requests
    if (request.method === 'GET' && this.cache) {
      const cacheKey = this.getCacheKey(request)
      const cached = this.cache.get(cacheKey)
      
      if (cached) {
        return new NextResponse(cached.data, {
          status: cached.status,
          headers: cached.headers
        })
      }
    }

    const response = await super.handle(request)

    // Cache successful GET responses
    if (
      request.method === 'GET' && 
      this.cache && 
      response.status === 200
    ) {
      const cacheKey = this.getCacheKey(request)
      const data = await response.arrayBuffer()
      
      this.cache.set(cacheKey, {
        data,
        headers: response.headers,
        status: response.status
      })

      return new NextResponse(data, {
        status: response.status,
        headers: response.headers
      })
    }

    return response
  }

  private checkRateLimit(request: NextRequest): boolean {
    if (!this.rateLimitConfig) return true

    const clientId = this.getClientId(request)
    const now = Date.now()
    const windowStart = now - this.rateLimitConfig.windowMs
    
    const clientData = this.rateLimitMap.get(clientId)
    
    if (!clientData || clientData.resetTime < windowStart) {
      this.rateLimitMap.set(clientId, {
        count: 1,
        resetTime: now + this.rateLimitConfig.windowMs
      })
      return true
    }

    if (clientData.count >= this.rateLimitConfig.maxRequests) {
      return false
    }

    clientData.count++
    return true
  }

  private getClientId(request: NextRequest): string {
    return request.headers.get('x-forwarded-for') || 
           request.headers.get('x-real-ip') || 
           'unknown'
  }

  private getCacheKey(request: NextRequest): string {
    const url = new URL(request.url)
    return `${request.method}:${url.pathname}${url.search}`
  }
}

// Usage with caching and rate limiting
export const cachedExternalProxy = new AdvancedApiProxy(
  {
    target: 'https://external-api.com',
    pathRewrite: { '^/api/external': '' },
    changeOrigin: true
  },
  { ttl: 5 * 60 * 1000, max: 100 }, // 5 minute cache, max 100 items
  { windowMs: 60 * 1000, maxRequests: 100 } // 100 requests per minute
)
```

**Environment-specific proxy configuration:**

```tsx
// lib/proxy-config.ts
const isDevelopment = process.env.NODE_ENV === 'development'

export const proxyConfigs = {
  external: {
    target: isDevelopment 
      ? 'http://localhost:3001' 
      : 'https://external-api.com',
    pathRewrite: { '^/api/external': '' },
    changeOrigin: true,
    headers: {
      'X-API-Key': process.env.EXTERNAL_API_KEY!
    }
  },
  
  auth: {
    target: isDevelopment 
      ? 'http://localhost:3002' 
      : 'https://auth.company.com',
    pathRewrite: { '^/api/auth': '/v1' },
    changeOrigin: true
  }
}
```

This pattern provides:
- **Specific API handling** - only affects designated routes
- **Better organization** - separate proxy logic from middleware
- **CORS handling** - proper cross-origin request support
- **Request transformation** - modify headers and paths
- **Caching and rate limiting** - performance and security features
- **Environment flexibility** - different configs per environment