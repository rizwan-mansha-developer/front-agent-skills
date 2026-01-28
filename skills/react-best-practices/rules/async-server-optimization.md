---
title: Leverage Next.js Server-Side Optimizations
impact: CRITICAL
impactDescription: faster initial loads, better SEO, reduced client-side work
tags: nextjs, server-side, optimization, performance, seo
---

## Leverage Next.js Server-Side Optimizations

**Impact: CRITICAL (faster initial loads, better SEO, reduced client-side work)**

Use Next.js 16+ server-side capabilities to optimize data fetching, reduce client-side work, and improve initial page load performance while maintaining interactivity where needed.

**Incorrect (everything client-side):**

```tsx
"use client";

// Everything runs on client - slower initial load
function UserDashboard({ userId }: { userId: string }) {
  const [user, setUser] = useState(null);
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Client-side data fetching - waterfall
    const fetchData = async () => {
      try {
        const userResponse = await fetch(`/api/users/${userId}`);
        const userData = await userResponse.json();
        setUser(userData);

        const statsResponse = await fetch(`/api/users/${userId}/stats`);
        const statsData = await statsResponse.json();
        setStats(statsData);
      } catch (error) {
        console.error("Error:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [userId]);

  if (loading) return <div>Loading...</div>;

  return (
    <div>
      <UserProfile user={user} />
      <UserStats stats={stats} />
    </div>
  );
}
```

**Correct (hybrid server/client approach):**

```tsx
// Server Component for initial data fetching
// app/users/[id]/page.tsx
import { Suspense } from "react";
import { UserProfile } from "@/features/users/components/UserProfile";
import { UserStats } from "@/features/users/components/UserStats";
import { InteractiveUserActions } from "@/features/users/components/InteractiveUserActions";
import {
  UserProfileSkeleton,
  UserStatsSkeleton,
} from "@/components/ui/skeletons";
import { usersApi } from "@/lib/api/users";

// Server Component - runs on server, no JavaScript sent to client
export default async function UserPage({ params }: { params: { id: string } }) {
  // Server-side data fetching - parallel requests
  const [user, stats] = await Promise.all([
    usersApi.getUser(params.id),
    usersApi.getUserStats(params.id),
  ]);

  return (
    <div className="container mx-auto space-y-8 py-8">
      {/* Server-rendered content */}
      <UserProfile user={user} />
      <UserStats stats={stats} />

      {/* Client-side interactive components */}
      <Suspense fallback={<div>Loading actions...</div>}>
        <InteractiveUserActions userId={params.id} />
      </Suspense>
    </div>
  );
}

// Server Component for static content
// features/users/components/UserProfile.tsx
interface UserProfileProps {
  user: User;
}

export function UserProfile({ user }: UserProfileProps) {
  return (
    <div className="rounded-lg border bg-white p-6 shadow-sm">
      <div className="flex items-start space-x-4">
        <img
          src={user.avatar}
          alt={user.name}
          className="h-16 w-16 rounded-full object-cover"
        />

        <div className="min-w-0 flex-1">
          <h1 className="text-2xl font-bold text-gray-900">{user.name}</h1>
          <p className="text-gray-600">{user.email}</p>
          <span className="mt-2 inline-flex items-center rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-800">
            {user.role}
          </span>
        </div>
      </div>
    </div>
  );
}

// Client Component only for interactive features
// features/users/components/InteractiveUserActions.tsx
("use client");

import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { usersApi } from "@/lib/api/users";

interface InteractiveUserActionsProps {
  userId: string;
}

export function InteractiveUserActions({
  userId,
}: InteractiveUserActionsProps) {
  const [isEditing, setIsEditing] = useState(false);
  const queryClient = useQueryClient();

  const updateUser = useMutation({
    mutationFn: (data: Partial<User>) => usersApi.updateUser(userId, data),
    onSuccess: () => {
      queryClient.invalidateQueries(["users", userId]);
      setIsEditing(false);
    },
  });

  return (
    <div className="rounded-lg border bg-white p-6 shadow-sm">
      <div className="mb-4 flex items-center justify-between">
        <h3 className="text-lg font-semibold">User Actions</h3>
        <button
          onClick={() => setIsEditing(!isEditing)}
          className="rounded bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
        >
          {isEditing ? "Cancel" : "Edit User"}
        </button>
      </div>

      {isEditing && (
        <UserEditForm
          userId={userId}
          onSave={data => updateUser.mutate(data)}
          isLoading={updateUser.isLoading}
        />
      )}
    </div>
  );
}
```

**Advanced server-side patterns:**

```tsx
// Server-side data prefetching with TanStack Query
// app/users/layout.tsx
import {
  HydrationBoundary,
  QueryClient,
  dehydrate,
} from "@tanstack/react-query";
import { usersApi } from "@/lib/api/users";

export default async function UsersLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const queryClient = new QueryClient();

  // Prefetch common data on server
  await queryClient.prefetchQuery({
    queryKey: ["users"],
    queryFn: usersApi.getUsers,
    staleTime: 5 * 60 * 1000, // 5 minutes
  });

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <div className="min-h-screen bg-gray-50">
        <header className="bg-white shadow">
          <div className="container mx-auto px-4 py-6">
            <h1 className="text-3xl font-bold text-gray-900">
              User Management
            </h1>
          </div>
        </header>
        <main>{children}</main>
      </div>
    </HydrationBoundary>
  );
}

// Server-side search params handling
// app/users/page.tsx
interface UsersPageProps {
  searchParams: {
    search?: string;
    role?: string;
    page?: string;
  };
}

export default async function UsersPage({ searchParams }: UsersPageProps) {
  const { search, role, page = "1" } = searchParams;

  // Server-side filtering and pagination
  const users = await usersApi.getUsers({
    search,
    role,
    page: parseInt(page),
    limit: 20,
  });

  return (
    <div className="container mx-auto py-8">
      {/* Server-rendered search form */}
      <UserSearchForm defaultValues={{ search, role }} />

      {/* Server-rendered user list */}
      <UserList users={users.data} />

      {/* Server-rendered pagination */}
      <Pagination
        currentPage={parseInt(page)}
        totalPages={users.totalPages}
        baseUrl="/users"
        searchParams={searchParams}
      />
    </div>
  );
}

// Streaming with nested Suspense
// app/dashboard/page.tsx
import { Suspense } from "react";

export default function DashboardPage() {
  return (
    <div className="container mx-auto space-y-8 py-8">
      {/* Critical content loads first */}
      <DashboardHeader />

      {/* Non-critical content streams in */}
      <div className="grid grid-cols-1 gap-8 lg:grid-cols-2">
        <Suspense fallback={<ChartSkeleton />}>
          <RevenueChart />
        </Suspense>

        <Suspense fallback={<ChartSkeleton />}>
          <UserGrowthChart />
        </Suspense>
      </div>

      <Suspense fallback={<TableSkeleton />}>
        <RecentOrdersTable />
      </Suspense>
    </div>
  );
}

// Server Component with dynamic data
async function RevenueChart() {
  // This runs on the server
  const revenueData = await analyticsApi.getRevenueData();

  return (
    <div className="rounded-lg bg-white p-6 shadow">
      <h3 className="mb-4 text-lg font-semibold">Revenue Overview</h3>
      {/* Server-rendered chart */}
      <StaticChart data={revenueData} />
    </div>
  );
}

// Hybrid approach - server data, client interactivity
// components/charts/InteractiveChart.tsx
("use client");

interface InteractiveChartProps {
  initialData: ChartData[];
  apiEndpoint: string;
}

export function InteractiveChart({
  initialData,
  apiEndpoint,
}: InteractiveChartProps) {
  const [timeRange, setTimeRange] = useState("7d");

  const { data = initialData } = useSuspenseQuery({
    queryKey: ["chart-data", apiEndpoint, timeRange],
    queryFn: () =>
      fetch(`${apiEndpoint}?range=${timeRange}`).then(r => r.json()),
    staleTime: 2 * 60 * 1000, // 2 minutes
  });

  return (
    <div className="rounded-lg bg-white p-6 shadow">
      <div className="mb-4 flex items-center justify-between">
        <h3 className="text-lg font-semibold">Interactive Chart</h3>
        <select
          value={timeRange}
          onChange={e => setTimeRange(e.target.value)}
          className="rounded border px-3 py-1"
        >
          <option value="7d">Last 7 days</option>
          <option value="30d">Last 30 days</option>
          <option value="90d">Last 90 days</option>
        </select>
      </div>
      <Chart data={data} />
    </div>
  );
}

// Usage in server component
async function DashboardCharts() {
  const initialChartData = await analyticsApi.getChartData("7d");

  return (
    <Suspense fallback={<ChartSkeleton />}>
      <InteractiveChart
        initialData={initialChartData}
        apiEndpoint="/api/analytics/chart"
      />
    </Suspense>
  );
}
```

**Performance optimizations:**

```tsx
// Metadata generation for SEO
// app/users/[id]/page.tsx
export async function generateMetadata({ params }: { params: { id: string } }) {
  const user = await usersApi.getUser(params.id);

  return {
    title: `${user.name} - User Profile`,
    description: `View ${user.name}'s profile and activity`,
    openGraph: {
      title: `${user.name} - User Profile`,
      description: `View ${user.name}'s profile and activity`,
      images: [user.avatar],
    },
  };
}

// Static generation for performance
export async function generateStaticParams() {
  const users = await usersApi.getUsers({ limit: 100 });

  return users.data.map(user => ({
    id: user.id,
  }));
}

// Revalidation strategies
export const revalidate = 3600; // Revalidate every hour
export const dynamic = "force-static"; // Force static generation
```

This approach provides:

- **Faster initial loads** - server-rendered content appears immediately
- **Better SEO** - search engines can crawl server-rendered content
- **Reduced JavaScript bundle** - only interactive parts are client-side
- **Progressive enhancement** - works without JavaScript, enhanced with it
- **Optimal caching** - server and client-side caching strategies

Reference: [Next.js App Router](https://nextjs.org/docs/app)
