---
title: Avoid Direct DOM Manipulation - Use React Patterns
impact: HIGH
impactDescription: better React integration, SSR compatibility, predictable behavior, maintainability
tags: dom-manipulation, react-patterns, ssr, hooks, refs
---

## Avoid Direct DOM Manipulation - Use React Patterns

**Impact: HIGH (better React integration, SSR compatibility, predictable behavior, maintainability)**

Avoid direct window, document, and DOM manipulation. Use React patterns like hooks, refs, and state management instead. This ensures SSR compatibility, predictable behavior, and better integration with React's lifecycle.

**Incorrect (direct DOM manipulation, vanilla JS patterns):**

```tsx
// Direct DOM manipulation - breaks React patterns
function SearchComponent() {
  const handleSearch = () => {
    // Direct DOM access - bad
    const input = document.getElementById("search-input") as HTMLInputElement;
    const value = input.value;

    // Direct style manipulation - bad
    document.body.style.overflow = "hidden";

    // Direct event listeners - bad
    window.addEventListener("scroll", handleScroll);

    // Direct location manipulation - bad
    window.location.href = `/search?q=${value}`;

    // Direct localStorage access - bad
    localStorage.setItem("lastSearch", value);
  };

  const handleScroll = () => {
    // Direct DOM queries - bad
    const header = document.querySelector(".header");
    if (window.scrollY > 100) {
      header?.classList.add("scrolled");
    }
  };

  return (
    <div>
      <input id="search-input" type="text" />
      <button onClick={handleSearch}>Search</button>
    </div>
  );
}

// Direct window size access - bad
function ResponsiveComponent() {
  const [isMobile, setIsMobile] = useState(window.innerWidth < 768);

  useEffect(() => {
    const handleResize = () => {
      setIsMobile(window.innerWidth < 768);
    };

    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);
}
```

**Correct (React patterns and hooks):**

```tsx
// hooks/useLocalStorage.ts
import { useState, useEffect } from "react";

export function useLocalStorage<T>(
  key: string,
  initialValue: T
): [T, (value: T | ((val: T) => T)) => void] {
  // Get from local storage then parse stored json or return initialValue
  const [storedValue, setStoredValue] = useState<T>(() => {
    if (typeof window === "undefined") {
      return initialValue;
    }

    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch (error) {
      console.error(`Error reading localStorage key "${key}":`, error);
      return initialValue;
    }
  });

  // Return a wrapped version of useState's setter function that persists the new value to localStorage
  const setValue = (value: T | ((val: T) => T)) => {
    try {
      // Allow value to be a function so we have the same API as useState
      const valueToStore =
        value instanceof Function ? value(storedValue) : value;
      setStoredValue(valueToStore);

      // Save to local storage
      if (typeof window !== "undefined") {
        window.localStorage.setItem(key, JSON.stringify(valueToStore));
      }
    } catch (error) {
      console.error(`Error setting localStorage key "${key}":`, error);
    }
  };

  return [storedValue, setValue];
}

// hooks/useMediaQuery.ts
import { useState, useEffect } from "react";

export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(false);

  useEffect(() => {
    if (typeof window === "undefined") return;

    const media = window.matchMedia(query);

    // Set initial value
    setMatches(media.matches);

    // Create event listener
    const listener = (event: MediaQueryListEvent) => {
      setMatches(event.matches);
    };

    // Add listener
    media.addEventListener("change", listener);

    // Cleanup
    return () => media.removeEventListener("change", listener);
  }, [query]);

  return matches;
}

// hooks/useScrollPosition.ts
import { useState, useEffect } from "react";

interface ScrollPosition {
  x: number;
  y: number;
}

export function useScrollPosition(): ScrollPosition {
  const [scrollPosition, setScrollPosition] = useState<ScrollPosition>({
    x: 0,
    y: 0,
  });

  useEffect(() => {
    if (typeof window === "undefined") return;

    const updatePosition = () => {
      setScrollPosition({
        x: window.pageXOffset,
        y: window.pageYOffset,
      });
    };

    window.addEventListener("scroll", updatePosition, { passive: true });
    updatePosition(); // Set initial position

    return () => window.removeEventListener("scroll", updatePosition);
  }, []);

  return scrollPosition;
}

// hooks/useWindowSize.ts
import { useState, useEffect } from "react";

interface WindowSize {
  width: number;
  height: number;
}

export function useWindowSize(): WindowSize {
  const [windowSize, setWindowSize] = useState<WindowSize>({
    width: 0,
    height: 0,
  });

  useEffect(() => {
    if (typeof window === "undefined") return;

    const handleResize = () => {
      setWindowSize({
        width: window.innerWidth,
        height: window.innerHeight,
      });
    };

    // Set initial size
    handleResize();

    window.addEventListener("resize", handleResize, { passive: true });
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  return windowSize;
}

// hooks/useClickOutside.ts
import { useEffect, RefObject } from "react";

export function useClickOutside<T extends HTMLElement>(
  ref: RefObject<T>,
  handler: (event: MouseEvent | TouchEvent) => void
) {
  useEffect(() => {
    if (typeof window === "undefined") return;

    const listener = (event: MouseEvent | TouchEvent) => {
      // Do nothing if clicking ref's element or descendent elements
      if (!ref.current || ref.current.contains(event.target as Node)) {
        return;
      }
      handler(event);
    };

    document.addEventListener("mousedown", listener);
    document.addEventListener("touchstart", listener);

    return () => {
      document.removeEventListener("mousedown", listener);
      document.removeEventListener("touchstart", listener);
    };
  }, [ref, handler]);
}

// hooks/useBodyScrollLock.ts
import { useEffect } from "react";

export function useBodyScrollLock(isLocked: boolean) {
  useEffect(() => {
    if (typeof window === "undefined") return;

    const originalStyle = window.getComputedStyle(document.body).overflow;

    if (isLocked) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = originalStyle;
    }

    // Cleanup function to restore original overflow
    return () => {
      document.body.style.overflow = originalStyle;
    };
  }, [isLocked]);
}

// Correct component implementations
// components/SearchComponent.tsx
import { useState } from "react";
import { useRouter } from "next/navigation";
import { useLocalStorage } from "@/hooks/useLocalStorage";

function SearchComponent() {
  const [searchValue, setSearchValue] = useState("");
  const [lastSearch, setLastSearch] = useLocalStorage("lastSearch", "");
  const router = useRouter();

  const handleSearch = () => {
    // Use React state instead of DOM access
    if (!searchValue.trim()) return;

    // Save to localStorage using hook
    setLastSearch(searchValue);

    // Use Next.js router instead of window.location
    router.push(`/search?q=${encodeURIComponent(searchValue)}`);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter") {
      handleSearch();
    }
  };

  return (
    <div className="flex gap-2">
      <input
        type="text"
        value={searchValue}
        onChange={e => setSearchValue(e.target.value)}
        onKeyDown={handleKeyDown}
        placeholder={lastSearch ? `Last: ${lastSearch}` : "Search..."}
        className="rounded-md border px-3 py-2"
      />
      <button
        onClick={handleSearch}
        className="rounded-md bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
      >
        Search
      </button>
    </div>
  );
}

// components/ResponsiveComponent.tsx
import { useMediaQuery, useWindowSize } from "@/hooks";

function ResponsiveComponent() {
  const isMobile = useMediaQuery("(max-width: 768px)");
  const isTablet = useMediaQuery("(min-width: 769px) and (max-width: 1024px)");
  const { width, height } = useWindowSize();

  return (
    <div className="p-4">
      <h2>Responsive Information</h2>
      <p>
        Screen: {width} x {height}
      </p>
      <p>Device: {isMobile ? "Mobile" : isTablet ? "Tablet" : "Desktop"}</p>

      {/* Conditional rendering based on screen size */}
      {isMobile ? <MobileLayout /> : <DesktopLayout />}
    </div>
  );
}

// components/ScrollHeader.tsx
import { useScrollPosition } from "@/hooks/useScrollPosition";

function ScrollHeader() {
  const { y: scrollY } = useScrollPosition();
  const isScrolled = scrollY > 100;

  return (
    <header
      className={`fixed top-0 w-full transition-all duration-300 ${
        isScrolled ? "bg-white py-2 shadow-md" : "bg-transparent py-4"
      }`}
    >
      <div className="container mx-auto px-4">
        <h1 className="text-xl font-bold">My App</h1>
      </div>
    </header>
  );
}

// components/Modal.tsx
import { useRef, useEffect } from "react";
import { useClickOutside } from "@/hooks/useClickOutside";
import { useBodyScrollLock } from "@/hooks/useBodyScrollLock";

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  children: React.ReactNode;
}

function Modal({ isOpen, onClose, children }: ModalProps) {
  const modalRef = useRef<HTMLDivElement>(null);

  // Lock body scroll when modal is open
  useBodyScrollLock(isOpen);

  // Close modal when clicking outside
  useClickOutside(modalRef, onClose);

  // Handle escape key
  useEffect(() => {
    if (!isOpen) return;

    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        onClose();
      }
    };

    document.addEventListener("keydown", handleEscape);
    return () => document.removeEventListener("keydown", handleEscape);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black bg-opacity-50" />
      <div
        ref={modalRef}
        className="relative mx-4 w-full max-w-md rounded-lg bg-white p-6"
      >
        {children}
      </div>
    </div>
  );
}

// components/FocusManager.tsx
import { useRef, useEffect } from "react";

interface FocusManagerProps {
  children: React.ReactNode;
  autoFocus?: boolean;
  restoreFocus?: boolean;
}

function FocusManager({
  children,
  autoFocus = true,
  restoreFocus = true,
}: FocusManagerProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const previousActiveElement = useRef<HTMLElement | null>(null);

  useEffect(() => {
    if (restoreFocus) {
      previousActiveElement.current = document.activeElement as HTMLElement;
    }

    if (autoFocus && containerRef.current) {
      // Focus first focusable element
      const focusableElement = containerRef.current.querySelector(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
      ) as HTMLElement;

      focusableElement?.focus();
    }

    return () => {
      if (restoreFocus && previousActiveElement.current) {
        previousActiveElement.current.focus();
      }
    };
  }, [autoFocus, restoreFocus]);

  return <div ref={containerRef}>{children}</div>;
}

// utils/navigation.ts - Wrapper for navigation
import { useRouter } from "next/navigation";

export function useNavigation() {
  const router = useRouter();

  const navigateTo = (path: string, options?: { replace?: boolean }) => {
    if (options?.replace) {
      router.replace(path);
    } else {
      router.push(path);
    }
  };

  const goBack = () => {
    router.back();
  };

  const reload = () => {
    router.refresh();
  };

  return { navigateTo, goBack, reload };
}
```

**SSR-safe patterns:**

```tsx
// components/ClientOnly.tsx
import { useState, useEffect } from "react";

interface ClientOnlyProps {
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

export function ClientOnly({ children, fallback = null }: ClientOnlyProps) {
  const [hasMounted, setHasMounted] = useState(false);

  useEffect(() => {
    setHasMounted(true);
  }, []);

  if (!hasMounted) {
    return <>{fallback}</>;
  }

  return <>{children}</>;
}

// Usage for client-only features
function MyComponent() {
  return (
    <div>
      <h1>Server-rendered content</h1>

      <ClientOnly fallback={<div>Loading...</div>}>
        <WindowSizeDisplay />
      </ClientOnly>
    </div>
  );
}
```

This pattern provides:

- **SSR compatibility** - No window/document access during server rendering
- **React integration** - Proper lifecycle management with hooks
- **Predictable behavior** - State-driven instead of imperative DOM manipulation
- **Better testing** - Easier to mock and test React patterns
- **Maintainability** - Clear separation of concerns and reusable hooks
