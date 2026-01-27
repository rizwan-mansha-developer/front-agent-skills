---
title: Feature-Based Architecture with Clean Layers
impact: CRITICAL
impactDescription: maintainable codebase, clear separation of concerns, scalable architecture
tags: architecture, clean-architecture, features, separation-of-concerns, scalability
---

## Feature-Based Architecture with Clean Layers

**Impact: CRITICAL (maintainable codebase, clear separation of concerns, scalable architecture)**

Organize code by features rather than technical layers, following clean architecture principles with clear data flow: UI → UseCase → Repository → Adapter → API.

**Incorrect (technical layer organization):**

```
src/
├── components/          # All components mixed together
│   ├── UserCard.tsx
│   ├── ProductList.tsx
│   ├── OrderForm.tsx
│   └── PaymentModal.tsx
├── hooks/              # All hooks mixed together
│   ├── useUser.ts
│   ├── useProducts.ts
│   └── useOrders.ts
├── services/           # All services mixed together
│   ├── userService.ts
│   ├── productService.ts
│   └── orderService.ts
└── utils/              # All utilities mixed together
    ├── userUtils.ts
    └── orderUtils.ts
```

**Correct (feature-based organization):**

```
src/
├── app/                    # Next.js App Router
├── components/             # Shared UI components only
│   └── ui/
│       ├── Button.tsx
│       ├── Modal.tsx
│       └── Input.tsx
├── features/               # Feature modules
│   ├── auth/
│   │   ├── components/
│   │   │   ├── LoginForm.tsx
│   │   │   └── SignupForm.tsx
│   │   ├── hooks/
│   │   │   └── useAuth.ts
│   │   ├── services/
│   │   │   └── auth.service.ts
│   │   ├── types/
│   │   │   └── auth.types.ts
│   │   └── index.ts
│   ├── users/
│   │   ├── components/
│   │   │   ├── UserCard.tsx
│   │   │   ├── UserList.tsx
│   │   │   └── UserProfile.tsx
│   │   ├── hooks/
│   │   │   ├── useUser.ts
│   │   │   └── useUsers.ts
│   │   ├── services/
│   │   │   ├── user.repository.ts
│   │   │   ├── user.adapter.ts
│   │   │   └── user.use-cases.ts
│   │   ├── types/
│   │   │   └── user.types.ts
│   │   └── index.ts
│   └── orders/
│       ├── components/
│       ├── hooks/
│       ├── services/
│       ├── types/
│       └── index.ts
├── lib/                    # Shared utilities
│   ├── axios.ts
│   ├── utils.ts
│   └── constants.ts
└── types/                  # Global types
    └── api.types.ts
```

**Clean Architecture Implementation:**

```tsx
// features/users/types/user.types.ts
export interface User {
  id: string
  name: string
  email: string
  role: 'admin' | 'user'
}

export interface CreateUserData {
  name: string
  email: string
  password: string
}

export interface UpdateUserData {
  name?: string
  email?: string
}

// features/users/services/user.adapter.ts
import api from '@/lib/axios'
import { User, CreateUserData, UpdateUserData } from '../types/user.types'

export class UserAdapter {
  async fetchUser(id: string): Promise<User> {
    const response = await api.get(`/users/${id}`)
    return response.data
  }

  async fetchUsers(): Promise<User[]> {
    const response = await api.get('/users')
    return response.data
  }

  async createUser(data: CreateUserData): Promise<User> {
    const response = await api.post('/users', data)
    return response.data
  }

  async updateUser(id: string, data: UpdateUserData): Promise<User> {
    const response = await api.put(`/users/${id}`, data)
    return response.data
  }

  async deleteUser(id: string): Promise<void> {
    await api.delete(`/users/${id}`)
  }
}

// features/users/services/user.repository.ts
import { UserAdapter } from './user.adapter'
import { User, CreateUserData, UpdateUserData } from '../types/user.types'

export class UserRepository {
  private adapter: UserAdapter

  constructor() {
    this.adapter = new UserAdapter()
  }

  async getUser(id: string): Promise<User> {
    return this.adapter.fetchUser(id)
  }

  async getUsers(): Promise<User[]> {
    return this.adapter.fetchUsers()
  }

  async createUser(data: CreateUserData): Promise<User> {
    // Add repository-level logic (caching, validation, etc.)
    return this.adapter.createUser(data)
  }

  async updateUser(id: string, data: UpdateUserData): Promise<User> {
    return this.adapter.updateUser(id, data)
  }

  async deleteUser(id: string): Promise<void> {
    return this.adapter.deleteUser(id)
  }
}

// features/users/services/user.use-cases.ts
import { UserRepository } from './user.repository'
import { User, CreateUserData, UpdateUserData } from '../types/user.types'

export class UserUseCases {
  private repository: UserRepository

  constructor() {
    this.repository = new UserRepository()
  }

  async getUserById(id: string): Promise<User> {
    if (!id) {
      throw new Error('User ID is required')
    }
    return this.repository.getUser(id)
  }

  async getAllUsers(): Promise<User[]> {
    return this.repository.getUsers()
  }

  async createUser(data: CreateUserData): Promise<User> {
    // Business logic validation
    if (!data.email || !data.name) {
      throw new Error('Name and email are required')
    }

    if (data.password.length < 8) {
      throw new Error('Password must be at least 8 characters')
    }

    return this.repository.createUser(data)
  }

  async updateUser(id: string, data: UpdateUserData): Promise<User> {
    // Business logic
    if (data.email && !this.isValidEmail(data.email)) {
      throw new Error('Invalid email format')
    }

    return this.repository.updateUser(id, data)
  }

  async deleteUser(id: string): Promise<void> {
    // Business logic - check if user can be deleted
    const user = await this.repository.getUser(id)
    if (user.role === 'admin') {
      throw new Error('Cannot delete admin users')
    }

    return this.repository.deleteUser(id)
  }

  private isValidEmail(email: string): boolean {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
  }
}

// features/users/hooks/useUsers.ts
import useSWR from 'swr'
import { UserUseCases } from '../services/user.use-cases'
import { User } from '../types/user.types'

const userUseCases = new UserUseCases()

export function useUsers() {
  const { data, error, isLoading, mutate } = useSWR<User[]>(
    '/users',
    () => userUseCases.getAllUsers()
  )

  return {
    users: data,
    isLoading,
    error,
    refetch: mutate
  }
}

export function useUser(id: string) {
  const { data, error, isLoading } = useSWR<User>(
    id ? `/users/${id}` : null,
    () => userUseCases.getUserById(id)
  )

  return {
    user: data,
    isLoading,
    error
  }
}

// features/users/components/UserList.tsx
import { useUsers } from '../hooks/useUsers'
import { UserCard } from './UserCard'

export function UserList() {
  const { users, isLoading, error } = useUsers()

  if (isLoading) return <div>Loading users...</div>
  if (error) return <div>Error loading users</div>
  if (!users) return null

  return (
    <div className="grid gap-4">
      {users.map(user => (
        <UserCard key={user.id} user={user} />
      ))}
    </div>
  )
}

// features/users/index.ts - Feature barrel export
export { UserList } from './components/UserList'
export { UserCard } from './components/UserCard'
export { UserProfile } from './components/UserProfile'
export { useUser, useUsers } from './hooks/useUsers'
export type { User, CreateUserData, UpdateUserData } from './types/user.types'
```

**Usage in pages:**

```tsx
// app/users/page.tsx
import { UserList } from '@/features/users'

export default function UsersPage() {
  return (
    <div className="container mx-auto py-8">
      <h1 className="text-2xl font-bold mb-6">Users</h1>
      <UserList />
    </div>
  )
}

// app/users/[id]/page.tsx
import { UserProfile } from '@/features/users'

export default function UserPage({ params }: { params: { id: string } }) {
  return (
    <div className="container mx-auto py-8">
      <UserProfile userId={params.id} />
    </div>
  )
}
```

This architecture provides:
- **Clear separation of concerns** - each layer has a single responsibility
- **Feature isolation** - related code is co-located
- **Testability** - easy to mock dependencies at each layer
- **Scalability** - new features don't affect existing ones
- **Maintainability** - changes are localized to specific features
- **Type safety** - strong typing throughout all layers
- **Reusability** - shared components and utilities are separate

Reference: [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)