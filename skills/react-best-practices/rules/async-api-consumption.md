---
title: Optimize API Consumption and Data Fetching Patterns
impact: CRITICAL
impactDescription: prevents waterfalls, improves UX, reduces server load
tags: api, data-fetching, performance, optimization, frontend
---

## Optimize API Consumption and Data Fetching Patterns

**Impact: CRITICAL (prevents waterfalls, improves UX, reduces server load)**

Optimize how your frontend consumes third-party APIs (NestJS backend) by implementing efficient data fetching patterns, proper caching, and avoiding request waterfalls.

**Incorrect (sequential API calls creating waterfalls):**

```tsx
// Waterfall pattern - each call waits for the previous
async function UserDashboard({ userId }: { userId: string }) {
  const [user, setUser] = useState(null)
  const [orders, setOrders] = useState([])
  const [preferences, setPreferences] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchData = async () => {
      try {
        // Sequential calls - creates waterfall
        const userResponse = await fetch(`/api/users/${userId}`)
        const userData = await userResponse.json()
        setUser(userData)

        const ordersResponse = await fetch(`/api/users/${userId}/orders`)
        const ordersData = await ordersResponse.json()
        setOrders(ordersData)

        const prefsResponse = await fetch(`/api/users/${userId}/preferences`)
        const prefsData = await prefsResponse.json()
        setPreferences(prefsData)
      } catch (error) {
        console.error('Error fetching data:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [userId])

  if (loading) return <div>Loading...</div>

  return (
    <div>
      <UserProfile user={user} />
      <OrdersList orders={orders} />
      <UserPreferences preferences={preferences} />
    </div>
  )
}
```

**Correct (parallel API calls with TanStack Query):**

```tsx
// Parallel data fetching with TanStack Query
import { useSuspenseQuery } from '@tanstack/react-query'
import { Suspense } from 'react'

// API service layer
const apiService = {
  getUser: (userId: string) => 
    fetch(`/api/users/${userId}`).then(res => res.json()),
  
  getUserOrders: (userId: string) => 
    fetch(`/api/users/${userId}/orders`).then(res => res.json()),
  
  getUserPreferences: (userId: string) => 
    fetch(`/api/users/${userId}/preferences`).then(res => res.json())
}

// Individual data fetching hooks
function useUser(userId: string) {
  return useSuspenseQuery({
    queryKey: ['users', userId],
    queryFn: () => apiService.getUser(userId)
  })
}

function useUserOrders(userId: string) {
  return useSuspenseQuery({
    queryKey: ['users', userId, 'orders'],
    queryFn: () => apiService.getUserOrders(userId)
  })
}

function useUserPreferences(userId: string) {
  return useSuspenseQuery({
    queryKey: ['users', userId, 'preferences'],
    queryFn: () => apiService.getUserPreferences(userId)
  })
}

// Component with parallel data fetching
function UserDashboard({ userId }: { userId: string }) {
  return (
    <div className="space-y-6">
      <Suspense fallback={<UserProfileSkeleton />}>
        <UserProfileSection userId={userId} />
      </Suspense>
      
      <Suspense fallback={<OrdersListSkeleton />}>
        <OrdersSection userId={userId} />
      </Suspense>
      
      <Suspense fallback={<PreferencesSkeleton />}>
        <PreferencesSection userId={userId} />
      </Suspense>
    </div>
  )
}

// Individual sections that fetch their own data
function UserProfileSection({ userId }: { userId: string }) {
  const { data: user } = useUser(userId)
  
  return <UserProfile user={user} />
}

function OrdersSection({ userId }: { userId: string }) {
  const { data: orders } = useUserOrders(userId)
  
  return <OrdersList orders={orders} />
}

function PreferencesSection({ userId }: { userId: string }) {
  const { data: preferences } = useUserPreferences(userId)
  
  return <UserPreferences preferences={preferences} />
}
```

**Advanced pattern with dependent data fetching:**

```tsx
// When some data depends on other data
function ProductRecommendations({ userId }: { userId: string }) {
  // First fetch user preferences
  const { data: preferences } = useUserPreferences(userId)
  
  // Then fetch recommendations based on preferences
  const { data: recommendations, isLoading } = useSWR(
    preferences ? `/recommendations/${userId}?category=${preferences.category}` : null,
    () => apiService.getRecommendations(userId, preferences.category)
  )
  
  if (!preferences) return <PreferencesSkeleton />
  if (isLoading) return <RecommendationsSkeleton />
  
  return <RecommendationsList recommendations={recommendations} />
}

// Optimistic updates for better UX
function useOptimisticUserUpdate() {
  const { mutate } = useSWRConfig()
  
  const updateUser = async (userId: string, updates: Partial<User>) => {
    const key = `/users/${userId}`
    
    // Optimistically update the cache
    mutate(key, (currentUser: User) => ({ ...currentUser, ...updates }), false)
    
    try {
      // Make the actual API call
      const updatedUser = await apiService.updateUser(userId, updates)
      
      // Update cache with server response
      mutate(key, updatedUser, false)
      
      return updatedUser
    } catch (error) {
      // Revert optimistic update on error
      mutate(key)
      throw error
    }
  }
  
  return { updateUser }
}

// Usage with optimistic updates
function UserProfileEdit({ user }: { user: User }) {
  const { updateUser } = useOptimisticUserUpdate()
  const [isUpdating, setIsUpdating] = useState(false)
  
  const handleSave = async (formData: Partial<User>) => {
    setIsUpdating(true)
    try {
      await updateUser(user.id, formData)
      toast.success('Profile updated successfully')
    } catch (error) {
      toast.error('Failed to update profile')
    } finally {
      setIsUpdating(false)
    }
  }
  
  return (
    <form onSubmit={handleSave}>
      {/* Form fields */}
      <button type="submit" disabled={isUpdating}>
        {isUpdating ? 'Saving...' : 'Save Changes'}
      </button>
    </form>
  )
}
```

**Batch API calls for efficiency:**

```tsx
// Batch multiple operations
const batchApiService = {
  batchUserOperations: async (operations: BatchOperation[]) => {
    const response = await fetch('/api/batch', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ operations })
    })
    return response.json()
  }
}

// Usage for bulk operations
function BulkUserActions({ selectedUsers }: { selectedUsers: string[] }) {
  const [isProcessing, setIsProcessing] = useState(false)
  
  const handleBulkUpdate = async (updates: Partial<User>) => {
    setIsProcessing(true)
    
    try {
      const operations = selectedUsers.map(userId => ({
        type: 'UPDATE_USER',
        userId,
        data: updates
      }))
      
      await batchApiService.batchUserOperations(operations)
      
      // Invalidate affected cache entries
      selectedUsers.forEach(userId => {
        mutate(`/users/${userId}`)
      })
      
      toast.success(`Updated ${selectedUsers.length} users`)
    } catch (error) {
      toast.error('Bulk update failed')
    } finally {
      setIsProcessing(false)
    }
  }
  
  return (
    <button onClick={() => handleBulkUpdate({ status: 'active' })}>
      {isProcessing ? 'Processing...' : `Update ${selectedUsers.length} Users`}
    </button>
  )
}
```

This pattern provides:
- **Parallel data fetching** - eliminates waterfalls
- **Proper error boundaries** - isolated error handling
- **Optimistic updates** - better perceived performance
- **Efficient caching** - reduces unnecessary API calls
- **Batch operations** - reduces server load
- **Progressive loading** - better UX with Suspense

Reference: [SWR Data Fetching](https://swr.vercel.app/)