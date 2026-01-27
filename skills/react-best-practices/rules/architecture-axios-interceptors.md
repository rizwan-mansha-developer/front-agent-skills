---
title: Centralized Axios Interceptors Configuration
impact: HIGH
impactDescription: consistent error handling, auth token management, request/response logging
tags: architecture, axios, interceptors, error-handling, authentication
---

## Centralized Axios Interceptors Configuration

**Impact: HIGH (consistent error handling, auth token management, request/response logging)**

Configure Axios interceptors at the application level to handle authentication, error responses, loading states, and request/response transformations consistently across all API calls.

**Incorrect (scattered API configuration):**

```tsx
// Different configurations in each component/service
function UserService() {
  const fetchUser = async (id: string) => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.get(`/api/users/${id}`, {
        headers: { Authorization: `Bearer ${token}` }
      })
      return response.data
    } catch (error) {
      if (error.response?.status === 401) {
        // Handle auth error differently in each place
        window.location.href = '/login'
      }
      throw error
    }
  }
}

// Repeated auth logic everywhere
function ProductService() {
  const fetchProducts = async () => {
    const token = localStorage.getItem('token')
    const response = await axios.get('/api/products', {
      headers: { Authorization: `Bearer ${token}` }
    })
    return response.data
  }
}
```

**Correct (centralized interceptors):**

```tsx
// lib/axios.ts
import axios, { AxiosError, AxiosResponse } from 'axios'
import { toast } from '@/hooks/useToast'

// Create axios instance
export const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || '/api',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request interceptor - add auth token
api.interceptors.request.use(
  (config) => {
    // Add auth token
    const token = localStorage.getItem('access_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }

    // Add request ID for tracking
    config.headers['X-Request-ID'] = crypto.randomUUID()

    // Log request in development
    if (process.env.NODE_ENV === 'development') {
      console.log(`🚀 ${config.method?.toUpperCase()} ${config.url}`, config.data)
    }

    return config
  },
  (error) => {
    console.error('Request interceptor error:', error)
    return Promise.reject(error)
  }
)

// Response interceptor - handle errors globally
api.interceptors.response.use(
  (response: AxiosResponse) => {
    // Log successful responses in development
    if (process.env.NODE_ENV === 'development') {
      console.log(`✅ ${response.config.method?.toUpperCase()} ${response.config.url}`, response.data)
    }
    
    return response
  },
  async (error: AxiosError) => {
    const originalRequest = error.config

    // Handle different error types
    if (error.response) {
      const { status, data } = error.response

      switch (status) {
        case 401:
          // Unauthorized - try to refresh token
          if (!originalRequest._retry) {
            originalRequest._retry = true
            
            try {
              const refreshToken = localStorage.getItem('refresh_token')
              if (refreshToken) {
                const response = await axios.post('/api/auth/refresh', {
                  refresh_token: refreshToken
                })
                
                const { access_token } = response.data
                localStorage.setItem('access_token', access_token)
                
                // Retry original request with new token
                originalRequest.headers.Authorization = `Bearer ${access_token}`
                return api(originalRequest)
              }
            } catch (refreshError) {
              // Refresh failed, redirect to login
              localStorage.removeItem('access_token')
              localStorage.removeItem('refresh_token')
              window.location.href = '/login'
              return Promise.reject(refreshError)
            }
          }
          break

        case 403:
          toast.error('You do not have permission to perform this action')
          break

        case 404:
          toast.error('Resource not found')
          break

        case 422:
          // Validation errors
          const validationErrors = data?.errors || {}
          Object.values(validationErrors).forEach((message: any) => {
            toast.error(message)
          })
          break

        case 429:
          toast.error('Too many requests. Please try again later.')
          break

        case 500:
          toast.error('Internal server error. Please try again.')
          break

        default:
          toast.error(data?.message || 'An unexpected error occurred')
      }
    } else if (error.request) {
      // Network error
      toast.error('Network error. Please check your connection.')
    } else {
      // Request setup error
      toast.error('Request configuration error')
    }

    // Log error in development
    if (process.env.NODE_ENV === 'development') {
      console.error('API Error:', error)
    }

    return Promise.reject(error)
  }
)

export default api
```

**Advanced pattern with loading states:**

```tsx
// lib/axios-with-loading.ts
import { create } from 'zustand'

interface LoadingState {
  isLoading: boolean
  activeRequests: Set<string>
  setLoading: (requestId: string, loading: boolean) => void
}

export const useLoadingStore = create<LoadingState>((set, get) => ({
  isLoading: false,
  activeRequests: new Set(),
  setLoading: (requestId: string, loading: boolean) => {
    const { activeRequests } = get()
    
    if (loading) {
      activeRequests.add(requestId)
    } else {
      activeRequests.delete(requestId)
    }
    
    set({ 
      activeRequests: new Set(activeRequests),
      isLoading: activeRequests.size > 0 
    })
  }
}))

// Enhanced request interceptor with loading
api.interceptors.request.use((config) => {
  const requestId = config.headers['X-Request-ID'] as string
  useLoadingStore.getState().setLoading(requestId, true)
  
  // Add auth token
  const token = localStorage.getItem('access_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  
  return config
})

// Enhanced response interceptor with loading cleanup
api.interceptors.response.use(
  (response) => {
    const requestId = response.config.headers['X-Request-ID'] as string
    useLoadingStore.getState().setLoading(requestId, false)
    return response
  },
  (error) => {
    const requestId = error.config?.headers['X-Request-ID'] as string
    if (requestId) {
      useLoadingStore.getState().setLoading(requestId, false)
    }
    return Promise.reject(error)
  }
)
```

**Usage in services:**

```tsx
// services/user.service.ts
import api from '@/lib/axios'

export const userService = {
  async getUser(id: string) {
    const response = await api.get(`/users/${id}`)
    return response.data
  },

  async updateUser(id: string, data: UpdateUserData) {
    const response = await api.put(`/users/${id}`, data)
    return response.data
  },

  async deleteUser(id: string) {
    await api.delete(`/users/${id}`)
  }
}

// Usage in components - no auth/error handling needed
function UserProfile({ userId }: { userId: string }) {
  const { data: user, error, isLoading } = useSWR(
    `/users/${userId}`,
    () => userService.getUser(userId)
  )

  if (isLoading) return <div>Loading...</div>
  if (error) return <div>Error handled by interceptor</div>
  
  return <div>{user.name}</div>
}
```

This pattern provides:
- **Automatic authentication** - tokens added to all requests
- **Consistent error handling** - centralized error responses
- **Token refresh** - automatic token renewal
- **Loading states** - global loading management
- **Request logging** - development debugging
- **Type safety** - proper TypeScript interfaces

Reference: [Axios Interceptors](https://axios-http.com/docs/interceptors)