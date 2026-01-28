---
title: Always Use Suspense with Skeleton Fallbacks
impact: HIGH
impactDescription: better perceived performance, consistent loading states, improved UX
tags: suspense, skeletons, loading-states, ux, performance
---

## Always Use Suspense with Skeleton Fallbacks

**Impact: HIGH (better perceived performance, consistent loading states, improved UX)**

Always wrap async components with Suspense boundaries and provide skeleton fallbacks that match the expected content structure. This creates better perceived performance and consistent loading experiences.

**Incorrect (generic loading spinners):**

```tsx
// Generic loading states - poor UX
function UserDashboard() {
  const [loading, setLoading] = useState(true);
  const [user, setUser] = useState(null);

  useEffect(() => {
    fetchUser().then(data => {
      setUser(data);
      setLoading(false);
    });
  }, []);

  if (loading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div>
      <UserProfile user={user} />
      <UserStats user={user} />
      <RecentActivity user={user} />
    </div>
  );
}
```

**Correct (Suspense with skeleton fallbacks):**

```tsx
// Skeleton components that match content structure
// components/ui/skeletons/UserProfileSkeleton.tsx
export function UserProfileSkeleton() {
  return (
    <div className="animate-pulse rounded-lg border bg-white p-6 shadow-sm">
      <div className="flex items-start space-x-4">
        {/* Avatar skeleton */}
        <div className="h-16 w-16 flex-shrink-0 rounded-full bg-gray-200"></div>

        <div className="min-w-0 flex-1">
          {/* Name skeleton */}
          <div className="mb-2 h-6 w-32 rounded bg-gray-200"></div>

          {/* Email skeleton */}
          <div className="mb-3 h-4 w-48 rounded bg-gray-200"></div>

          {/* Role badge skeleton */}
          <div className="h-6 w-20 rounded bg-gray-200"></div>
        </div>

        {/* Actions skeleton */}
        <div className="flex space-x-2">
          <div className="h-8 w-16 rounded bg-gray-200"></div>
          <div className="h-8 w-16 rounded bg-gray-200"></div>
        </div>
      </div>
    </div>
  );
}

// components/ui/skeletons/UserStatsSkeleton.tsx
export function UserStatsSkeleton() {
  return (
    <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
      {Array.from({ length: 3 }).map((_, i) => (
        <div
          key={i}
          className="animate-pulse rounded-lg border bg-white p-6 shadow-sm"
        >
          <div className="flex items-center justify-between">
            <div>
              <div className="mb-2 h-4 w-24 rounded bg-gray-200"></div>
              <div className="h-8 w-16 rounded bg-gray-200"></div>
            </div>
            <div className="h-12 w-12 rounded-lg bg-gray-200"></div>
          </div>
        </div>
      ))}
    </div>
  );
}

// components/ui/skeletons/RecentActivitySkeleton.tsx
export function RecentActivitySkeleton() {
  return (
    <div className="rounded-lg border bg-white shadow-sm">
      <div className="border-b p-6">
        <div className="h-6 w-32 animate-pulse rounded bg-gray-200"></div>
      </div>
      <div className="divide-y">
        {Array.from({ length: 5 }).map((_, i) => (
          <div
            key={i}
            className="flex animate-pulse items-center space-x-3 p-4"
          >
            <div className="h-8 w-8 flex-shrink-0 rounded-full bg-gray-200"></div>
            <div className="min-w-0 flex-1">
              <div className="mb-1 h-4 w-3/4 rounded bg-gray-200"></div>
              <div className="h-3 w-1/2 rounded bg-gray-200"></div>
            </div>
            <div className="h-3 w-16 rounded bg-gray-200"></div>
          </div>
        ))}
      </div>
    </div>
  );
}

// Actual components using TanStack Query with Suspense
// features/users/components/UserProfile.tsx
import { useSuspenseQuery } from "@tanstack/react-query";
import { usersApi } from "@/lib/api/users";

function UserProfile({ userId }: { userId: string }) {
  const { data: user } = useSuspenseQuery({
    queryKey: ["users", userId],
    queryFn: () => usersApi.getUser(userId),
  });

  return (
    <div className="rounded-lg border bg-white p-6 shadow-sm">
      <div className="flex items-start space-x-4">
        <img
          src={user.avatar}
          alt={user.name}
          className="h-16 w-16 rounded-full object-cover"
        />

        <div className="min-w-0 flex-1">
          <h2 className="truncate text-xl font-semibold text-gray-900">
            {user.name}
          </h2>
          <p className="truncate text-sm text-gray-600">{user.email}</p>
          <span className="mt-2 inline-flex items-center rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-800">
            {user.role}
          </span>
        </div>

        <div className="flex space-x-2">
          <button className="rounded bg-blue-600 px-3 py-1.5 text-sm text-white hover:bg-blue-700">
            Edit
          </button>
          <button className="rounded border border-gray-300 px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-50">
            View
          </button>
        </div>
      </div>
    </div>
  );
}

// features/users/components/UserStats.tsx
function UserStats({ userId }: { userId: string }) {
  const { data: stats } = useSuspenseQuery({
    queryKey: ["users", userId, "stats"],
    queryFn: () => usersApi.getUserStats(userId),
  });

  return (
    <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
      <div className="rounded-lg border bg-white p-6 shadow-sm">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-gray-600">Total Orders</p>
            <p className="text-2xl font-bold text-gray-900">
              {stats.totalOrders}
            </p>
          </div>
          <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-blue-100">
            <ShoppingBagIcon className="h-6 w-6 text-blue-600" />
          </div>
        </div>
      </div>

      <div className="rounded-lg border bg-white p-6 shadow-sm">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-gray-600">Revenue</p>
            <p className="text-2xl font-bold text-gray-900">
              ${stats.totalRevenue}
            </p>
          </div>
          <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-green-100">
            <CurrencyDollarIcon className="h-6 w-6 text-green-600" />
          </div>
        </div>
      </div>

      <div className="rounded-lg border bg-white p-6 shadow-sm">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-gray-600">Last Active</p>
            <p className="text-2xl font-bold text-gray-900">
              {stats.lastActive}
            </p>
          </div>
          <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-purple-100">
            <ClockIcon className="h-6 w-6 text-purple-600" />
          </div>
        </div>
      </div>
    </div>
  );
}

// Page with nested Suspense boundaries
// app/users/[id]/page.tsx
import { Suspense } from "react";
import { UserProfile } from "@/features/users/components/UserProfile";
import { UserStats } from "@/features/users/components/UserStats";
import { RecentActivity } from "@/features/users/components/RecentActivity";
import {
  UserProfileSkeleton,
  UserStatsSkeleton,
  RecentActivitySkeleton,
} from "@/components/ui/skeletons";

export default function UserPage({ params }: { params: { id: string } }) {
  return (
    <div className="container mx-auto space-y-8 py-8">
      {/* Each section has its own Suspense boundary */}
      <Suspense fallback={<UserProfileSkeleton />}>
        <UserProfile userId={params.id} />
      </Suspense>

      <Suspense fallback={<UserStatsSkeleton />}>
        <UserStats userId={params.id} />
      </Suspense>

      <Suspense fallback={<RecentActivitySkeleton />}>
        <RecentActivity userId={params.id} />
      </Suspense>
    </div>
  );
}
```

**Advanced skeleton patterns:**

```tsx
// Reusable skeleton building blocks
// components/ui/skeletons/SkeletonBase.tsx
interface SkeletonProps {
  className?: string;
  children?: React.ReactNode;
}

export function Skeleton({ className = "", children }: SkeletonProps) {
  return (
    <div className={`animate-pulse rounded bg-gray-200 ${className}`}>
      {children}
    </div>
  );
}

// Skeleton composition utilities
export function SkeletonText({
  lines = 1,
  className = "",
}: {
  lines?: number;
  className?: string;
}) {
  return (
    <div className={`space-y-2 ${className}`}>
      {Array.from({ length: lines }).map((_, i) => (
        <Skeleton
          key={i}
          className={`h-4 ${i === lines - 1 ? "w-3/4" : "w-full"}`}
        />
      ))}
    </div>
  );
}

export function SkeletonCard({ children, className = "" }: SkeletonProps) {
  return (
    <div className={`rounded-lg border bg-white p-6 shadow-sm ${className}`}>
      {children}
    </div>
  );
}

// Usage with composition
function ProductCardSkeleton() {
  return (
    <SkeletonCard>
      <Skeleton className="mb-4 h-48 w-full" /> {/* Image */}
      <SkeletonText lines={2} className="mb-2" /> {/* Title & description */}
      <div className="flex items-center justify-between">
        <Skeleton className="h-6 w-20" /> {/* Price */}
        <Skeleton className="h-8 w-24" /> {/* Button */}
      </div>
    </SkeletonCard>
  );
}

// Error boundaries with skeleton fallbacks
function SuspenseWithErrorBoundary({
  children,
  fallback,
  errorFallback,
}: {
  children: React.ReactNode;
  fallback: React.ReactNode;
  errorFallback?: React.ReactNode;
}) {
  return (
    <ErrorBoundary fallback={errorFallback || fallback}>
      <Suspense fallback={fallback}>{children}</Suspense>
    </ErrorBoundary>
  );
}
```

This pattern provides:

- **Better perceived performance** - users see content structure immediately
- **Consistent loading states** - predictable UX across the app
- **Granular loading** - different sections load independently
- **Accessibility** - screen readers understand loading states
- **Reduced layout shift** - skeleton matches final content dimensions

Reference: [React Suspense](https://react.dev/reference/react/Suspense)
