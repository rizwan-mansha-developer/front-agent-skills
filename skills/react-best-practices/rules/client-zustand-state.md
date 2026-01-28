---
title: Use Zustand for Global State Management
impact: MEDIUM-HIGH
impactDescription: lightweight, TypeScript-first, minimal boilerplate, better performance
tags: zustand, state-management, global-state, typescript, performance
---

## Use Zustand for Global State Management

**Impact: MEDIUM-HIGH (lightweight, TypeScript-first, minimal boilerplate, better performance)**

Use Zustand for global state management instead of Redux or Context API. Zustand provides excellent TypeScript support, minimal boilerplate, and better performance with selective subscriptions.

**Incorrect (Context API with unnecessary re-renders):**

```tsx
// Context API - causes re-renders for all consumers
const AppContext = createContext<{
  user: User | null;
  theme: "light" | "dark";
  setUser: (user: User | null) => void;
  setTheme: (theme: "light" | "dark") => void;
}>({} as any);

function AppProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [theme, setTheme] = useState<"light" | "dark">("light");

  return (
    <AppContext.Provider value={{ user, theme, setUser, setTheme }}>
      {children}
    </AppContext.Provider>
  );
}

// Every component re-renders when any state changes
function Header() {
  const { user, theme } = useContext(AppContext);
  return <div>Welcome {user?.name}</div>;
}
```

**Correct (Zustand with selective subscriptions):**

```tsx
// stores/useAppStore.ts
import { create } from "zustand";
import { devtools, persist } from "zustand/middleware";
import { immer } from "zustand/middleware/immer";

interface User {
  id: string;
  name: string;
  email: string;
  role: string;
}

interface AppState {
  // State
  user: User | null;
  theme: "light" | "dark";
  isLoading: boolean;
  notifications: Notification[];

  // Actions
  setUser: (user: User | null) => void;
  setTheme: (theme: "light" | "dark") => void;
  setLoading: (loading: boolean) => void;
  addNotification: (notification: Omit<Notification, "id">) => void;
  removeNotification: (id: string) => void;
  clearNotifications: () => void;
}

export const useAppStore = create<AppState>()(
  devtools(
    persist(
      immer((set, get) => ({
        // Initial state
        user: null,
        theme: "light",
        isLoading: false,
        notifications: [],

        // Actions
        setUser: user => set({ user }),

        setTheme: theme => set({ theme }),

        setLoading: isLoading => set({ isLoading }),

        addNotification: notification =>
          set(state => {
            state.notifications.push({
              ...notification,
              id: crypto.randomUUID(),
              timestamp: Date.now(),
            });
          }),

        removeNotification: id =>
          set(state => {
            state.notifications = state.notifications.filter(n => n.id !== id);
          }),

        clearNotifications: () => set({ notifications: [] }),
      })),
      {
        name: "app-store",
        partialize: state => ({
          user: state.user,
          theme: state.theme,
        }),
      }
    ),
    { name: "app-store" }
  )
);

// Selectors for better performance
export const useUser = () => useAppStore(state => state.user);
export const useTheme = () => useAppStore(state => state.theme);
export const useNotifications = () => useAppStore(state => state.notifications);
export const useIsLoading = () => useAppStore(state => state.isLoading);

// Action selectors
export const useAppActions = () =>
  useAppStore(state => ({
    setUser: state.setUser,
    setTheme: state.setTheme,
    setLoading: state.setLoading,
    addNotification: state.addNotification,
    removeNotification: state.removeNotification,
    clearNotifications: state.clearNotifications,
  }));
```

**Feature-specific stores:**

```tsx
// stores/useUserStore.ts
interface UserStore {
  users: User[];
  selectedUser: User | null;
  filters: UserFilters;

  setUsers: (users: User[]) => void;
  selectUser: (user: User | null) => void;
  updateFilters: (filters: Partial<UserFilters>) => void;
  addUser: (user: User) => void;
  updateUser: (id: string, updates: Partial<User>) => void;
  removeUser: (id: string) => void;
}

export const useUserStore = create<UserStore>()(
  devtools(
    immer(set => ({
      users: [],
      selectedUser: null,
      filters: { search: "", role: "all", status: "all" },

      setUsers: users => set({ users }),

      selectUser: selectedUser => set({ selectedUser }),

      updateFilters: newFilters =>
        set(state => {
          Object.assign(state.filters, newFilters);
        }),

      addUser: user =>
        set(state => {
          state.users.push(user);
        }),

      updateUser: (id, updates) =>
        set(state => {
          const index = state.users.findIndex(u => u.id === id);
          if (index !== -1) {
            Object.assign(state.users[index], updates);
          }
        }),

      removeUser: id =>
        set(state => {
          state.users = state.users.filter(u => u.id !== id);
        }),
    })),
    { name: "user-store" }
  )
);

// Computed selectors
export const useFilteredUsers = () =>
  useUserStore(state => {
    const { users, filters } = state;
    return users.filter(user => {
      if (
        filters.search &&
        !user.name.toLowerCase().includes(filters.search.toLowerCase())
      ) {
        return false;
      }
      if (filters.role !== "all" && user.role !== filters.role) {
        return false;
      }
      if (filters.status !== "all" && user.status !== filters.status) {
        return false;
      }
      return true;
    });
  });
```

**Component usage with selective subscriptions:**

```tsx
// components/Header.tsx - Only re-renders when user changes
function Header() {
  const user = useUser();
  const { setUser } = useAppActions();

  const handleLogout = () => {
    setUser(null);
  };

  return (
    <header className="bg-white shadow">
      <div className="flex items-center justify-between px-4 py-2">
        <h1>Dashboard</h1>
        {user && (
          <div className="flex items-center gap-2">
            <span>Welcome, {user.name}</span>
            <button onClick={handleLogout}>Logout</button>
          </div>
        )}
      </div>
    </header>
  );
}

// components/ThemeToggle.tsx - Only re-renders when theme changes
function ThemeToggle() {
  const theme = useTheme();
  const { setTheme } = useAppActions();

  return (
    <button
      onClick={() => setTheme(theme === "light" ? "dark" : "light")}
      className="rounded p-2"
    >
      {theme === "light" ? "🌙" : "☀️"}
    </button>
  );
}

// components/UserList.tsx - Optimized with computed selector
function UserList() {
  const filteredUsers = useFilteredUsers();
  const { selectUser, removeUser } = useUserStore(state => ({
    selectUser: state.selectUser,
    removeUser: state.removeUser,
  }));

  return (
    <div className="space-y-2">
      {filteredUsers.map(user => (
        <div
          key={user.id}
          className="flex items-center justify-between rounded border p-3"
        >
          <div onClick={() => selectUser(user)} className="cursor-pointer">
            <h3>{user.name}</h3>
            <p className="text-sm text-gray-600">{user.email}</p>
          </div>
          <button
            onClick={() => removeUser(user.id)}
            className="text-red-600 hover:text-red-800"
          >
            Remove
          </button>
        </div>
      ))}
    </div>
  );
}
```

**Integration with TanStack Query:**

```tsx
// hooks/useUserData.ts
import { useQuery } from "@tanstack/react-query";
import { useUserStore } from "@/stores/useUserStore";

export function useUserData() {
  const setUsers = useUserStore(state => state.setUsers);

  return useQuery({
    queryKey: ["users"],
    queryFn: async () => {
      const response = await fetch("/api/users");
      const users = await response.json();
      setUsers(users); // Sync with Zustand
      return users;
    },
  });
}

// Sync mutations with store
export function useUpdateUserMutation() {
  const updateUser = useUserStore(state => state.updateUser);
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<User> }) =>
      api.put(`/users/${id}`, data),

    onMutate: ({ id, data }) => {
      // Optimistic update in Zustand
      updateUser(id, data);
    },

    onError: (error, variables) => {
      // Revert on error
      queryClient.invalidateQueries(["users"]);
    },

    onSuccess: updatedUser => {
      // Ensure consistency
      updateUser(updatedUser.id, updatedUser);
    },
  });
}
```

This pattern provides:

- **Selective subscriptions** - components only re-render when their specific data changes
- **TypeScript-first** - excellent type inference and safety
- **Minimal boilerplate** - less code than Redux
- **DevTools integration** - for debugging
- **Persistence** - automatic localStorage sync
- **Immer integration** - immutable updates with mutable syntax
