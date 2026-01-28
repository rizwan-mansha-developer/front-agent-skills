---
title: Implement Error Boundaries and Global Error Handling
impact: HIGH
impactDescription: prevents app crashes, better UX, error tracking, graceful degradation
tags: error-boundaries, error-handling, toast, retry, resilience
---

## Implement Error Boundaries and Global Error Handling

**Impact: HIGH (prevents app crashes, better UX, error tracking, graceful degradation)**

Implement comprehensive error handling with React Error Boundaries, global error handlers, and retry mechanisms. Use toast notifications for user feedback and graceful degradation patterns.

**Incorrect (no error handling, app crashes):**

```tsx
// No error boundaries - one component crash brings down entire app
function UserProfile({ userId }: { userId: string }) {
  const { data: user } = useUser(userId); // Can throw error

  return (
    <div>
      <h1>{user.name}</h1> {/* Crashes if user is undefined */}
      <UserPosts userId={userId} /> {/* Can also crash */}
    </div>
  );
}

// No API error handling
async function fetchUser(id: string) {
  const response = await fetch(`/api/users/${id}`);
  return response.json(); // No error checking
}
```

**Correct (comprehensive error handling):**

```tsx
// components/ErrorBoundary.tsx
"use client";

import { Component, ReactNode } from "react";
import { AlertTriangle, RefreshCw } from "lucide-react";

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
  onError?: (error: Error, errorInfo: any) => void;
}

interface State {
  hasError: boolean;
  error?: Error;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: any) {
    console.error("Error Boundary caught an error:", error, errorInfo);

    // Send to error tracking service
    this.props.onError?.(error, errorInfo);

    // Report to analytics
    if (typeof window !== "undefined") {
      window.gtag?.("event", "exception", {
        description: error.message,
        fatal: false,
      });
    }
  }

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback;
      }

      return (
        <div className="flex flex-col items-center justify-center p-8 text-center">
          <AlertTriangle className="mb-4 h-12 w-12 text-red-500" />
          <h2 className="mb-2 text-xl font-semibold">Something went wrong</h2>
          <p className="mb-4 text-gray-600">
            We're sorry, but something unexpected happened.
          </p>
          <button
            onClick={() => this.setState({ hasError: false, error: undefined })}
            className="flex items-center gap-2 rounded-md bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
          >
            <RefreshCw className="h-4 w-4" />
            Try Again
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}

// Global error handler
// lib/error-handler.ts
import { toast } from "sonner";

export interface AppError extends Error {
  code?: string;
  statusCode?: number;
  context?: Record<string, any>;
}

export class ErrorHandler {
  static handle(error: AppError, context?: string) {
    console.error(`[${context || "App"}] Error:`, error);

    // Send to error tracking
    this.reportError(error, context);

    // Show user-friendly message
    this.showUserMessage(error);
  }

  private static reportError(error: AppError, context?: string) {
    // Send to Sentry, LogRocket, etc.
    if (typeof window !== "undefined" && window.Sentry) {
      window.Sentry.captureException(error, {
        tags: { context },
        extra: error.context,
      });
    }
  }

  private static showUserMessage(error: AppError) {
    let message = "Something went wrong. Please try again.";

    // Customize message based on error type
    if (error.statusCode === 404) {
      message = "The requested resource was not found.";
    } else if (error.statusCode === 403) {
      message = "You don't have permission to perform this action.";
    } else if (error.statusCode === 500) {
      message = "Server error. Please try again later.";
    } else if (error.code === "NETWORK_ERROR") {
      message = "Network error. Please check your connection.";
    }

    toast.error(message, {
      action: {
        label: "Retry",
        onClick: () => window.location.reload(),
      },
    });
  }
}

// API error handling with retry
// lib/api-client.ts
interface RetryConfig {
  maxRetries: number;
  baseDelay: number;
  maxDelay: number;
}

export class ApiClient {
  private defaultRetryConfig: RetryConfig = {
    maxRetries: 3,
    baseDelay: 1000,
    maxDelay: 10000,
  };

  async request<T>(
    url: string,
    options: RequestInit = {},
    retryConfig?: Partial<RetryConfig>
  ): Promise<T> {
    const config = { ...this.defaultRetryConfig, ...retryConfig };

    for (let attempt = 0; attempt <= config.maxRetries; attempt++) {
      try {
        const response = await fetch(url, {
          ...options,
          headers: {
            "Content-Type": "application/json",
            ...options.headers,
          },
        });

        if (!response.ok) {
          throw new AppError(
            `HTTP ${response.status}: ${response.statusText}`,
            {
              statusCode: response.status,
              context: { url, attempt },
            }
          );
        }

        return await response.json();
      } catch (error) {
        const isLastAttempt = attempt === config.maxRetries;
        const shouldRetry = this.shouldRetry(error as AppError, attempt);

        if (isLastAttempt || !shouldRetry) {
          ErrorHandler.handle(error as AppError, "API Request");
          throw error;
        }

        // Exponential backoff with jitter
        const delay = Math.min(
          config.baseDelay * Math.pow(2, attempt) + Math.random() * 1000,
          config.maxDelay
        );

        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }

    throw new Error("Max retries exceeded");
  }

  private shouldRetry(error: AppError, attempt: number): boolean {
    // Don't retry client errors (4xx)
    if (error.statusCode && error.statusCode >= 400 && error.statusCode < 500) {
      return false;
    }

    // Retry server errors (5xx) and network errors
    return error.statusCode >= 500 || error.code === "NETWORK_ERROR";
  }
}

export const apiClient = new ApiClient();

// React Query error handling
// lib/query-client.ts
import { QueryClient } from "@tanstack/react-query";
import { ErrorHandler } from "./error-handler";

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: (failureCount, error: any) => {
        // Don't retry 4xx errors
        if (error?.statusCode >= 400 && error?.statusCode < 500) {
          return false;
        }
        return failureCount < 3;
      },
      retryDelay: attemptIndex => Math.min(1000 * 2 ** attemptIndex, 30000),
      onError: (error: any) => {
        ErrorHandler.handle(error, "React Query");
      },
    },
    mutations: {
      onError: (error: any) => {
        ErrorHandler.handle(error, "Mutation");
      },
    },
  },
});

// Component with error boundary
// components/UserProfile.tsx
function UserProfileContent({ userId }: { userId: string }) {
  const { data: user, error, isLoading } = useUser(userId);

  if (isLoading) return <UserProfileSkeleton />;

  if (error) {
    return (
      <div className="rounded-md border border-red-200 bg-red-50 p-4">
        <p className="text-red-800">Failed to load user profile</p>
        <button
          onClick={() => queryClient.invalidateQueries(["users", userId])}
          className="mt-2 text-sm text-red-600 underline"
        >
          Try again
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center space-x-4">
        <img
          src={user.avatar}
          alt={user.name}
          className="h-16 w-16 rounded-full"
          onError={e => {
            e.currentTarget.src = "/default-avatar.png";
          }}
        />
        <div>
          <h1 className="text-2xl font-bold">{user.name}</h1>
          <p className="text-gray-600">{user.email}</p>
        </div>
      </div>

      <ErrorBoundary
        fallback={
          <div className="rounded-md border border-yellow-200 bg-yellow-50 p-4">
            <p className="text-yellow-800">Failed to load user posts</p>
          </div>
        }
      >
        <UserPosts userId={userId} />
      </ErrorBoundary>
    </div>
  );
}

export function UserProfile({ userId }: { userId: string }) {
  return (
    <ErrorBoundary>
      <UserProfileContent userId={userId} />
    </ErrorBoundary>
  );
}

// Global error boundary for app
// app/error.tsx
("use client");

import { useEffect } from "react";
import { ErrorHandler } from "@/lib/error-handler";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    ErrorHandler.handle(error, "App Error");
  }, [error]);

  return (
    <div className="flex min-h-screen flex-col items-center justify-center p-4">
      <div className="text-center">
        <h2 className="mb-4 text-2xl font-bold">Something went wrong!</h2>
        <p className="mb-6 text-gray-600">
          We apologize for the inconvenience. Please try again.
        </p>
        <button
          onClick={reset}
          className="rounded-md bg-blue-600 px-6 py-2 text-white hover:bg-blue-700"
        >
          Try again
        </button>
      </div>
    </div>
  );
}

// Toast provider setup
// app/providers.tsx
("use client");

import { Toaster } from "sonner";
import { QueryClientProvider } from "@tanstack/react-query";
import { queryClient } from "@/lib/query-client";

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <QueryClientProvider client={queryClient}>
      {children}
      <Toaster
        position="top-right"
        expand={false}
        richColors
        closeButton
        toastOptions={{
          duration: 5000,
          style: {
            background: "white",
            border: "1px solid #e5e7eb",
            color: "#374151",
          },
        }}
      />
    </QueryClientProvider>
  );
}
```

**Advanced error handling patterns:**

```tsx
// hooks/useErrorHandler.ts
export function useErrorHandler() {
  return useCallback((error: Error, context?: string) => {
    ErrorHandler.handle(error as AppError, context);
  }, []);
}

// Retry hook
export function useRetry<T>(fn: () => Promise<T>, maxRetries = 3) {
  const [retryCount, setRetryCount] = useState(0);
  const [isRetrying, setIsRetrying] = useState(false);

  const retry = useCallback(async () => {
    if (retryCount >= maxRetries) return;

    setIsRetrying(true);
    try {
      await fn();
      setRetryCount(0);
    } catch (error) {
      setRetryCount(prev => prev + 1);
      throw error;
    } finally {
      setIsRetrying(false);
    }
  }, [fn, retryCount, maxRetries]);

  return { retry, retryCount, isRetrying, canRetry: retryCount < maxRetries };
}
```

This pattern provides:

- **App crash prevention** - Error boundaries catch component errors
- **User-friendly feedback** - Toast notifications with actionable messages
- **Automatic retry** - Smart retry logic for transient failures
- **Error tracking** - Integration with monitoring services
- **Graceful degradation** - Fallback UI when components fail
