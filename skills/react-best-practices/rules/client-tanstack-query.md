---
title: Use TanStack Query for Data Fetching and Caching
impact: MEDIUM-HIGH
impactDescription: automatic caching, background updates, optimistic updates, better UX
tags: tanstack-query, data-fetching, caching, suspense, performance
---

## Use TanStack Query for Data Fetching and Caching

**Impact: MEDIUM-HIGH (automatic caching, background updates, optimistic updates, better UX)**

Use TanStack Query (React Query) for all API data fetching with Suspense mode enabled. Always provide skeleton fallbacks and leverage server-side data prefetching for optimal performance.

**Incorrect (manual data fetching with useState/useEffect):**

```tsx
// Manual data fetching - no caching, no background updates
function UserProfile({ userId }: { userId: string }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchUser = async () => {
      try {
        setLoading(true)
        const response = await fetch(`/api/users/${userId}`)
        const userData = await response.json()
        setUser(userData)
      } catch (err) {
        setError(err.message)
      } finally {
        setLoading(false)
      }
    }

    fetchUser()
  }, [userId])

  if (loading) return <div>Loading...</div>
  if (error) return <div>Error: {error}</div>
  if (!user) return null

  return <div>{user.name}</div>
}
```

**Correct (TanStack Query with Suspense):**

```tsx
// Setup TanStack Query with Suspense
// app/providers.tsx
'use client'

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import { useState } from 'react'

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient({
    defaultOptions: {
      queries: {
        // Enable Suspense mode
        suspense: true,
        // Stale time - data considered fresh for 5 minutes
        staleTime: 5 * 60 * 1000,
        // Cache time - data kept in cache for 10 minutes
        cacheTime: 10 * 60 * 1000,
        // Retry failed requests
        retry: 3,
        // Refetch on window focus
        refetchOnWindowFocus: false,
      },
    },
  }))

  return (
    <QueryClientProvider client={queryClient}>
      {children}
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  )
}

// API service layer
// lib/api/users.ts
import { api } from '@/lib/axios'

export const usersApi = {
  getUser: async (userId: string): Promise<User> => {
    const response = await api.get(`/users/${userId}`)
    return response.data
  },

  getUsers: async (): Promise<User[]> => {
    const response = await api.get('/users')
    return response.data
  },

  updateUser: async (userId: string, data: Partial<User>): Promise<User> => {
    const response = await api.put(`/users/${userId}`, data)
    return response.data
  },

  deleteUser: async (userId: string): Promise<void> => {
    await api.delete(`/users/${userId}`)
  }
}

// Query hooks
// features/users/hooks/useUsers.ts
import { useSuspenseQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { usersApi } from '@/lib/api/users'

export function useUser(userId: string) {
  return useSuspenseQuery({
    queryKey: ['users', userId],
    queryFn: () => usersApi.getUser(userId),
    // Additional options
    staleTime: 5 * 60 * 1000, // 5 minutes
  })
}

export function useUsers() {
  return useSuspenseQuery({
    queryKey: ['users'],
    queryFn: usersApi.getUsers,
  })
}

export function useUpdateUser() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ userId, data }: { userId: string; data: Partial<User> }) =>
      usersApi.updateUser(userId, data),
    
    // Optimistic updates
    onMutate: async ({ userId, data }) => {
      // Cancel outgoing refetches
      await queryClient.cancelQueries({ queryKey: ['users', userId] })

      // Snapshot previous value
      const previousUser = queryClient.getQueryData(['users', userId])

      // Optimistically update
      queryClient.setQueryData(['users', userId], (old: User) => ({
        ...old,
        ...data
      }))

      return { previousUser }
    },

    // On error, rollback
    onError: (err, variables, context) => {
      if (context?.previousUser) {
        queryClient.setQueryData(['users', variables.userId], context.previousUser)
      }
    },

    // Always refetch after error or success
    onSettled: (data, error, variables) => {
      queryClient.invalidateQueries({ queryKey: ['users', variables.userId] })
      queryClient.invalidateQueries({ queryKey: ['users'] })
    },
  })
}

// Component with Suspense
// features/users/components/UserProfile.tsx
import { useUser } from '../hooks/useUsers'

function UserProfile({ userId }: { userId: string }) {
  const { data: user } = useUser(userId)

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <div className="flex items-center space-x-4">
        <img
          src={user.avatar}
          alt={user.name}
          className="w-16 h-16 rounded-full"
        />
        <div>
          <h2 className="text-xl font-semibold">{user.name}</h2>
          <p className="text-gray-600">{user.email}</p>
          <span className="inline-block px-2 py-1 text-xs bg-blue-100 text-blue-800 rounded">
            {user.role}
          </span>
        </div>
      </div>
    </div>
  )
}

// Skeleton component
// components/ui/UserProfileSkeleton.tsx
export function UserProfileSkeleton() {
  return (
    <div className="bg-white rounded-lg shadow p-6 animate-pulse">
      <div className="flex items-center space-x-4">
        <div className="w-16 h-16 bg-gray-200 rounded-full"></div>
        <div className="flex-1">
          <div className="h-6 bg-gray-200 rounded w-32 mb-2"></div>
          <div className="h-4 bg-gray-200 rounded w-48 mb-2"></div>
          <div className="h-6 bg-gray-200 rounded w-16"></div>
        </div>
      </div>
    </div>
  )
}

// Page with Suspense boundary
// app/users/[id]/page.tsx
import { Suspense } from 'react'
import { UserProfile } from '@/features/users/components/UserProfile'
import { UserProfileSkeleton } from '@/components/ui/UserProfileSkeleton'

export default function UserPage({ params }: { params: { id: string } }) {
  return (
    <div className="container mx-auto py-8">
      <Suspense fallback={<UserProfileSkeleton />}>
        <UserProfile userId={params.id} />
      </Suspense>
    </div>
  )
}
```

**Advanced patterns with prefetching:**

```tsx
// Server-side prefetching in layout or page
// app/users/layout.tsx
import { HydrationBoundary, QueryClient, dehydrate } from '@tanstack/react-query'
import { usersApi } from '@/lib/api/users'

export default async function UsersLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const queryClient = new QueryClient()

  // Prefetch users list on server
  await queryClient.prefetchQuery({
    queryKey: ['users'],
    queryFn: usersApi.getUsers,
  })

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <div className="min-h-screen bg-gray-50">
        <nav className="bg-white shadow">
          <div className="container mx-auto px-4 py-4">
            <h1 className="text-2xl font-bold">Users Management</h1>
          </div>
        </nav>
        <main className="container mx-auto px-4 py-8">
          {children}
        </main>
      </div>
    </HydrationBoundary>
  )
}

// Infinite queries for pagination
export function useInfiniteUsers() {
  return useInfiniteQuery({
    queryKey: ['users', 'infinite'],
    queryFn: ({ pageParam = 1 }) => 
      usersApi.getUsers({ page: pageParam, limit: 20 }),
    getNextPageParam: (lastPage, pages) => 
      lastPage.hasMore ? pages.length + 1 : undefined,
    suspense: true,
  })
}

// Background sync with mutations
export function useUserActions() {
  const queryClient = useQueryClient()

  const updateUser = useMutation({
    mutationFn: usersApi.updateUser,
    onSuccess: (updatedUser) => {
      // Update individual user cache
      queryClient.setQueryData(['users', updatedUser.id], updatedUser)
      
      // Update users list cache
      queryClient.setQueryData(['users'], (old: User[]) =>
        old?.map(user => user.id === updatedUser.id ? updatedUser : user)
      )
    },
  })

  const deleteUser = useMutation({
    mutationFn: usersApi.deleteUser,
    onSuccess: (_, deletedUserId) => {
      // Remove from cache
      queryClient.removeQueries(['users', deletedUserId])
      
      // Update users list
      queryClient.setQueryData(['users'], (old: User[]) =>
        old?.filter(user => user.id !== deletedUserId)
      )
    },
  })

  return { updateUser, deleteUser }
}
```

This pattern provides:
- **Automatic caching** - no duplicate requests
- **Background updates** - data stays fresh
- **Optimistic updates** - immediate UI feedback
- **Suspense integration** - clean loading states
- **Server-side prefetching** - faster initial loads
- **Error boundaries** - graceful error handling

Reference: [TanStack Query Suspense](https://tanstack.com/query/latest/docs/react/guides/suspense)