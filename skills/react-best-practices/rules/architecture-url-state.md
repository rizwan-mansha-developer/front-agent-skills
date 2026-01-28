---
title: Use URL State for Tabs, Filters, and Navigation
impact: MEDIUM-HIGH
impactDescription: shareable URLs, browser back/forward, SEO-friendly, better UX
tags: url-state, query-params, navigation, tabs, filters, nextjs
---

## Use URL State for Tabs, Filters, and Navigation

**Impact: MEDIUM-HIGH (shareable URLs, browser back/forward, SEO-friendly, better UX)**

Store UI state like active tabs, filters, and pagination in URL query parameters. Use dynamic routes for record viewing/editing. This enables shareable URLs, proper browser navigation, and better SEO.

**Incorrect (local state for navigation):**

```tsx
// Local state - not shareable, no browser navigation
function UserDashboard() {
  const [activeTab, setActiveTab] = useState("overview");
  const [filters, setFilters] = useState({ role: "all", status: "active" });
  const [selectedUser, setSelectedUser] = useState<string | null>(null);

  return (
    <div>
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="users">Users</TabsTrigger>
          <TabsTrigger value="settings">Settings</TabsTrigger>
        </TabsList>
      </Tabs>

      {selectedUser && <UserModal userId={selectedUser} />}
    </div>
  );
}
```

**Correct (URL state with query parameters):**

```tsx
// hooks/useUrlState.ts
import { useRouter, useSearchParams } from "next/navigation";
import { useCallback } from "react";

export function useUrlState() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const updateUrl = useCallback(
    (updates: Record<string, string | null>) => {
      const params = new URLSearchParams(searchParams.toString());

      Object.entries(updates).forEach(([key, value]) => {
        if (value === null || value === "" || value === "all") {
          params.delete(key);
        } else {
          params.set(key, value);
        }
      });

      const queryString = params.toString();
      const url = queryString ? `?${queryString}` : "";

      router.push(url, { scroll: false });
    },
    [router, searchParams]
  );

  const getParam = useCallback(
    (key: string, defaultValue = "") => {
      return searchParams.get(key) ?? defaultValue;
    },
    [searchParams]
  );

  return { updateUrl, getParam, searchParams };
}

// components/UserDashboard.tsx
function UserDashboard() {
  const { updateUrl, getParam } = useUrlState();

  const activeTab = getParam("tab", "overview");
  const roleFilter = getParam("role", "all");
  const statusFilter = getParam("status", "all");
  const search = getParam("search");
  const page = parseInt(getParam("page", "1"));

  const handleTabChange = (tab: string) => {
    updateUrl({ tab: tab === "overview" ? null : tab });
  };

  const handleFilterChange = (filters: Record<string, string>) => {
    updateUrl({ ...filters, page: null }); // Reset page when filtering
  };

  return (
    <div className="space-y-6">
      <Tabs value={activeTab} onValueChange={handleTabChange}>
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="users">Users</TabsTrigger>
          <TabsTrigger value="analytics">Analytics</TabsTrigger>
          <TabsTrigger value="settings">Settings</TabsTrigger>
        </TabsList>

        <TabsContent value="overview">
          <DashboardOverview />
        </TabsContent>

        <TabsContent value="users">
          <UserFilters
            role={roleFilter}
            status={statusFilter}
            search={search}
            onFilterChange={handleFilterChange}
          />
          <UserList
            filters={{ role: roleFilter, status: statusFilter, search }}
            page={page}
            onPageChange={page => updateUrl({ page: page.toString() })}
          />
        </TabsContent>

        <TabsContent value="analytics">
          <AnalyticsDashboard />
        </TabsContent>

        <TabsContent value="settings">
          <SettingsPanel />
        </TabsContent>
      </Tabs>
    </div>
  );
}

// components/UserFilters.tsx
interface UserFiltersProps {
  role: string;
  status: string;
  search: string;
  onFilterChange: (filters: Record<string, string>) => void;
}

function UserFilters({
  role,
  status,
  search,
  onFilterChange,
}: UserFiltersProps) {
  return (
    <div className="flex gap-4 rounded-lg bg-gray-50 p-4">
      <input
        type="text"
        placeholder="Search users..."
        value={search}
        onChange={e => onFilterChange({ search: e.target.value })}
        className="rounded-md border px-3 py-2"
      />

      <select
        value={role}
        onChange={e => onFilterChange({ role: e.target.value })}
        className="rounded-md border px-3 py-2"
      >
        <option value="all">All Roles</option>
        <option value="admin">Admin</option>
        <option value="user">User</option>
        <option value="moderator">Moderator</option>
      </select>

      <select
        value={status}
        onChange={e => onFilterChange({ status: e.target.value })}
        className="rounded-md border px-3 py-2"
      >
        <option value="all">All Status</option>
        <option value="active">Active</option>
        <option value="inactive">Inactive</option>
        <option value="pending">Pending</option>
      </select>
    </div>
  );
}
```

**Dynamic routes for record operations:**

```tsx
// app/users/page.tsx - List view with URL state
export default function UsersPage() {
  return (
    <div>
      <h1>Users Management</h1>
      <UserDashboard />
    </div>
  );
}

// app/users/[id]/page.tsx - View/Edit record
interface UserPageProps {
  params: { id: string };
  searchParams: { mode?: "view" | "edit" };
}

export default function UserPage({ params, searchParams }: UserPageProps) {
  const mode = searchParams.mode ?? "view";

  return (
    <div>
      <UserBreadcrumb userId={params.id} mode={mode} />

      {mode === "edit" ? (
        <UserEditForm userId={params.id} />
      ) : (
        <UserProfile userId={params.id} />
      )}
    </div>
  );
}

// app/users/new/page.tsx - Create new record
export default function NewUserPage() {
  return (
    <div>
      <UserBreadcrumb mode="create" />
      <UserCreateForm />
    </div>
  );
}

// components/UserBreadcrumb.tsx
interface UserBreadcrumbProps {
  userId?: string;
  mode: "view" | "edit" | "create";
}

function UserBreadcrumb({ userId, mode }: UserBreadcrumbProps) {
  const { data: user } = useUser(userId);

  return (
    <nav className="mb-6 flex items-center space-x-2 text-sm text-gray-600">
      <Link href="/users" className="hover:text-blue-600">
        Users
      </Link>
      <span>/</span>

      {mode === "create" ? (
        <span className="text-gray-900">New User</span>
      ) : (
        <>
          <Link
            href={`/users/${userId}`}
            className={
              mode === "view" ? "text-gray-900" : "hover:text-blue-600"
            }
          >
            {user?.name ?? "Loading..."}
          </Link>

          {mode === "edit" && (
            <>
              <span>/</span>
              <span className="text-gray-900">Edit</span>
            </>
          )}
        </>
      )}
    </nav>
  );
}

// components/UserList.tsx - Navigate to records
function UserList({ filters, page, onPageChange }: UserListProps) {
  const { data: users } = useUsers({ ...filters, page });

  return (
    <div className="space-y-4">
      {users?.data.map(user => (
        <div key={user.id} className="rounded-lg border p-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="font-semibold">{user.name}</h3>
              <p className="text-gray-600">{user.email}</p>
            </div>

            <div className="flex gap-2">
              <Link
                href={`/users/${user.id}`}
                className="rounded border border-blue-600 px-3 py-1 text-blue-600 hover:bg-blue-50"
              >
                View
              </Link>
              <Link
                href={`/users/${user.id}?mode=edit`}
                className="rounded bg-blue-600 px-3 py-1 text-white hover:bg-blue-700"
              >
                Edit
              </Link>
            </div>
          </div>
        </div>
      ))}

      <Pagination
        currentPage={page}
        totalPages={users?.totalPages ?? 1}
        onPageChange={onPageChange}
      />
    </div>
  );
}
```

**Advanced URL state patterns:**

```tsx
// hooks/useAdvancedUrlState.ts
export function useAdvancedUrlState<T extends Record<string, any>>(
  defaultState: T,
  options: {
    serialize?: (value: any) => string;
    deserialize?: (value: string) => any;
    debounceMs?: number;
  } = {}
) {
  const { updateUrl, getParam } = useUrlState();
  const {
    serialize = JSON.stringify,
    deserialize = JSON.parse,
    debounceMs = 300,
  } = options;

  const [debouncedUpdate] = useDebouncedCallback(updateUrl, debounceMs);

  const state = useMemo(() => {
    const result = { ...defaultState };

    Object.keys(defaultState).forEach(key => {
      const urlValue = getParam(key);
      if (urlValue) {
        try {
          result[key] = deserialize(urlValue);
        } catch {
          result[key] = urlValue;
        }
      }
    });

    return result;
  }, [getParam, defaultState, deserialize]);

  const setState = useCallback(
    (updates: Partial<T>) => {
      const urlUpdates: Record<string, string | null> = {};

      Object.entries(updates).forEach(([key, value]) => {
        if (value === defaultState[key]) {
          urlUpdates[key] = null;
        } else {
          urlUpdates[key] =
            typeof value === "string" ? value : serialize(value);
        }
      });

      debouncedUpdate(urlUpdates);
    },
    [defaultState, serialize, debouncedUpdate]
  );

  return [state, setState] as const;
}

// Usage with complex state
function AdvancedFilters() {
  const [filters, setFilters] = useAdvancedUrlState({
    search: "",
    roles: [] as string[],
    dateRange: { start: null, end: null } as {
      start: Date | null;
      end: Date | null;
    },
    sortBy: "name",
    sortOrder: "asc" as "asc" | "desc",
  });

  return (
    <div className="space-y-4">
      <input
        value={filters.search}
        onChange={e => setFilters({ search: e.target.value })}
        placeholder="Search..."
      />

      <MultiSelect
        value={filters.roles}
        onChange={roles => setFilters({ roles })}
        options={["admin", "user", "moderator"]}
      />

      <DateRangePicker
        value={filters.dateRange}
        onChange={dateRange => setFilters({ dateRange })}
      />
    </div>
  );
}
```

This pattern provides:

- **Shareable URLs** - users can bookmark and share filtered views
- **Browser navigation** - back/forward buttons work correctly
- **SEO benefits** - search engines can index different states
- **Better UX** - state persists across page refreshes
- **Deep linking** - direct access to specific views
