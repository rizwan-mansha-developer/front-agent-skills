---
title: Strict TypeScript Patterns and No-Any Policy
impact: HIGH
impactDescription: type safety, better IDE support, fewer runtime errors, maintainable code
tags: typescript, type-safety, generics, strict-mode, code-quality
---

## Strict TypeScript Patterns and No-Any Policy

**Impact: HIGH (type safety, better IDE support, fewer runtime errors, maintainable code)**

Enforce strict TypeScript usage with explicit return types, proper generics, and zero tolerance for `any` type. Use union types, interfaces, and proper type guards for robust type safety.

**Incorrect (loose typing with any):**

```tsx
// Using 'any' - loses all type safety
function processData(data: any): any {
  return data.map((item: any) => {
    return {
      id: item.id,
      name: item.name,
      value: item.value
    }
  })
}

// No return type specified
function fetchUser(id: string) {
  return fetch(`/api/users/${id}`).then(res => res.json())
}

// Loose object typing
interface User {
  [key: string]: any
}

// No error handling types
function handleApiCall(callback: Function) {
  callback()
}
```

**Correct (strict TypeScript patterns):**

```tsx
// Proper generic types with constraints
interface ApiResponse<T> {
  data: T
  status: 'success' | 'error'
  message?: string
}

interface User {
  readonly id: string
  name: string
  email: string
  role: 'admin' | 'user' | 'moderator'
  createdAt: Date
  updatedAt: Date
}

interface CreateUserData {
  name: string
  email: string
  role?: User['role'] // Use keyof for type safety
}

// Explicit return types and proper generics
function processData<T extends { id: string; name: string }>(
  data: T[]
): Array<Pick<T, 'id' | 'name'> & { processed: boolean }> {
  return data.map((item) => ({
    id: item.id,
    name: item.name,
    processed: true
  }))
}

// Proper async function typing
async function fetchUser(id: string): Promise<ApiResponse<User>> {
  try {
    const response = await fetch(`/api/users/${id}`)
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }
    
    const data = await response.json()
    return {
      data,
      status: 'success'
    }
  } catch (error) {
    return {
      data: {} as User, // Explicit type assertion when necessary
      status: 'error',
      message: error instanceof Error ? error.message : 'Unknown error'
    }
  }
}

// Type guards for runtime type checking
function isUser(obj: unknown): obj is User {
  return (
    typeof obj === 'object' &&
    obj !== null &&
    typeof (obj as User).id === 'string' &&
    typeof (obj as User).name === 'string' &&
    typeof (obj as User).email === 'string' &&
    ['admin', 'user', 'moderator'].includes((obj as User).role)
  )
}

// Proper callback typing
type ApiCallback<T> = (
  error: Error | null,
  data: T | null
) => void

function handleApiCall<T>(
  apiCall: () => Promise<T>,
  callback: ApiCallback<T>
): void {
  apiCall()
    .then(data => callback(null, data))
    .catch(error => callback(error, null))
}
```

**Advanced TypeScript patterns:**

```tsx
// Utility types for better type safety
type RequiredFields<T, K extends keyof T> = T & Required<Pick<T, K>>
type OptionalFields<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>

// Example usage
type UserWithRequiredEmail = RequiredFields<User, 'email'>
type PartialUser = OptionalFields<User, 'name' | 'role'>

// Discriminated unions for better error handling
type ApiResult<T> = 
  | { success: true; data: T }
  | { success: false; error: string; code: number }

async function safeApiCall<T>(
  apiCall: () => Promise<T>
): Promise<ApiResult<T>> {
  try {
    const data = await apiCall()
    return { success: true, data }
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      code: error instanceof Error && 'status' in error ? 
        (error as any).status : 500
    }
  }
}

// Usage with type narrowing
const result = await safeApiCall(() => fetchUser('123'))

if (result.success) {
  // TypeScript knows result.data is available
  console.log(result.data.name)
} else {
  // TypeScript knows result.error and result.code are available
  console.error(`Error ${result.code}: ${result.error}`)
}

// Generic hook with proper typing
function useApi<T>(
  apiCall: () => Promise<T>,
  dependencies: React.DependencyList = []
): {
  data: T | null
  loading: boolean
  error: string | null
  refetch: () => Promise<void>
} {
  const [data, setData] = useState<T | null>(null)
  const [loading, setLoading] = useState<boolean>(true)
  const [error, setError] = useState<string | null>(null)

  const fetchData = useCallback(async (): Promise<void> => {
    try {
      setLoading(true)
      setError(null)
      const result = await apiCall()
      setData(result)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error')
      setData(null)
    } finally {
      setLoading(false)
    }
  }, dependencies)

  useEffect(() => {
    fetchData()
  }, [fetchData])

  return { data, loading, error, refetch: fetchData }
}

// Strict component props with proper defaults
interface ButtonProps {
  readonly variant: 'primary' | 'secondary' | 'danger'
  readonly size: 'sm' | 'md' | 'lg'
  readonly disabled?: boolean
  readonly loading?: boolean
  readonly onClick: (event: React.MouseEvent<HTMLButtonElement>) => void
  readonly children: React.ReactNode
  readonly className?: string
  readonly 'data-testid'?: string
}

// Use const assertion for better type inference
const BUTTON_VARIANTS = {
  primary: 'bg-blue-600 hover:bg-blue-700 text-white',
  secondary: 'bg-gray-200 hover:bg-gray-300 text-gray-900',
  danger: 'bg-red-600 hover:bg-red-700 text-white'
} as const

const BUTTON_SIZES = {
  sm: 'px-3 py-1.5 text-sm',
  md: 'px-4 py-2 text-base',
  lg: 'px-6 py-3 text-lg'
} as const

function Button({
  variant,
  size,
  disabled = false,
  loading = false,
  onClick,
  children,
  className = '',
  'data-testid': testId
}: ButtonProps): JSX.Element {
  const baseClasses = 'font-medium rounded-md focus:outline-none focus:ring-2'
  const variantClasses = BUTTON_VARIANTS[variant]
  const sizeClasses = BUTTON_SIZES[size]
  
  return (
    <button
      type="button"
      disabled={disabled || loading}
      onClick={onClick}
      className={`${baseClasses} ${variantClasses} ${sizeClasses} ${className}`}
      data-testid={testId}
    >
      {loading ? 'Loading...' : children}
    </button>
  )
}
```

**TSConfig strict configuration:**

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "noImplicitReturns": true,
    "noImplicitThis": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "exactOptionalPropertyTypes": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true
  },
  "include": ["**/*.ts", "**/*.tsx"],
  "exclude": ["node_modules"]
}
```

This approach provides:
- **Zero runtime type errors** - catch issues at compile time
- **Better IDE support** - autocomplete, refactoring, navigation
- **Self-documenting code** - types serve as documentation
- **Easier refactoring** - TypeScript catches breaking changes
- **Better testing** - type-safe mocks and test data
- **Team consistency** - enforced coding standards

Reference: [TypeScript Handbook](https://www.typescriptlang.org/docs/)