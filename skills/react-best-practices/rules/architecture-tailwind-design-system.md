---
title: Use Tailwind CSS v4+ with Component Composition Patterns
impact: MEDIUM-HIGH
impactDescription: better maintainability, design system consistency, performance optimization
tags: tailwindcss, styling, design-system, composition, global-css, v4
---

## Use Tailwind CSS v4+ with Component Composition Patterns

**Impact: MEDIUM-HIGH (better maintainability, design system consistency, performance optimization)**

Use Tailwind CSS v4+ with global.css for design tokens and component composition patterns. Leverage CSS custom properties, component variants, and proper abstraction layers for maintainable styling.

**Incorrect (inline styles everywhere, no design system):**

```tsx
// Inline styles scattered throughout components
function Button({ children, type = 'primary' }) {
  return (
    <button
      className={`
        px-4 py-2 rounded-md font-medium transition-colors
        ${type === 'primary' 
          ? 'bg-blue-600 text-white hover:bg-blue-700' 
          : 'bg-gray-200 text-gray-900 hover:bg-gray-300'
        }
      `}
    >
      {children}
    </button>
  )
}

// Repeated styles, no consistency
function Card({ children }) {
  return (
    <div className="bg-white rounded-lg shadow-md border border-gray-200 p-6">
      {children}
    </div>
  )
}
```

**Correct (Tailwind v4+ with design system and composition):**

```css
/* app/global.css - Tailwind v4+ with design tokens */
@import "tailwindcss";

/* Design tokens using CSS custom properties */
@layer base {
  :root {
    /* Colors */
    --color-primary-50: #eff6ff;
    --color-primary-100: #dbeafe;
    --color-primary-500: #3b82f6;
    --color-primary-600: #2563eb;
    --color-primary-700: #1d4ed8;
    --color-primary-900: #1e3a8a;
    
    --color-gray-50: #f9fafb;
    --color-gray-100: #f3f4f6;
    --color-gray-500: #6b7280;
    --color-gray-900: #111827;
    
    --color-success-500: #10b981;
    --color-error-500: #ef4444;
    --color-warning-500: #f59e0b;
    
    /* Typography */
    --font-sans: 'Inter', system-ui, sans-serif;
    --font-mono: 'JetBrains Mono', monospace;
    
    /* Spacing */
    --spacing-xs: 0.25rem;
    --spacing-sm: 0.5rem;
    --spacing-md: 1rem;
    --spacing-lg: 1.5rem;
    --spacing-xl: 2rem;
    --spacing-2xl: 3rem;
    
    /* Border radius */
    --radius-sm: 0.25rem;
    --radius-md: 0.375rem;
    --radius-lg: 0.5rem;
    --radius-xl: 0.75rem;
    
    /* Shadows */
    --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
    --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
    --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);
    
    /* Transitions */
    --transition-fast: 150ms ease;
    --transition-normal: 200ms ease;
    --transition-slow: 300ms ease;
  }
  
  /* Dark mode tokens */
  @media (prefers-color-scheme: dark) {
    :root {
      --color-gray-50: #1f2937;
      --color-gray-100: #374151;
      --color-gray-500: #9ca3af;
      --color-gray-900: #f9fafb;
    }
  }
  
  /* Base styles */
  body {
    font-family: var(--font-sans);
    color: rgb(var(--color-gray-900));
    background-color: rgb(var(--color-gray-50));
  }
  
  /* Focus styles */
  *:focus-visible {
    outline: 2px solid rgb(var(--color-primary-500));
    outline-offset: 2px;
  }
}

/* Component base classes */
@layer components {
  /* Button variants */
  .btn {
    @apply inline-flex items-center justify-center gap-2 px-4 py-2 text-sm font-medium rounded-md transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed;
  }
  
  .btn-primary {
    @apply btn bg-primary-600 text-white hover:bg-primary-700 focus:ring-primary-500;
  }
  
  .btn-secondary {
    @apply btn bg-gray-200 text-gray-900 hover:bg-gray-300 focus:ring-gray-500;
  }
  
  .btn-outline {
    @apply btn border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 focus:ring-primary-500;
  }
  
  .btn-ghost {
    @apply btn text-gray-700 hover:bg-gray-100 focus:ring-primary-500;
  }
  
  .btn-sm {
    @apply px-3 py-1.5 text-xs;
  }
  
  .btn-lg {
    @apply px-6 py-3 text-base;
  }
  
  /* Card variants */
  .card {
    @apply bg-white rounded-lg shadow-sm border border-gray-200;
  }
  
  .card-elevated {
    @apply card shadow-md;
  }
  
  .card-interactive {
    @apply card hover:shadow-md transition-shadow cursor-pointer;
  }
  
  /* Form elements */
  .form-input {
    @apply block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-primary-500 focus:border-primary-500;
  }
  
  .form-input-error {
    @apply form-input border-red-300 focus:ring-red-500 focus:border-red-500;
  }
  
  .form-label {
    @apply block text-sm font-medium text-gray-700 mb-1;
  }
  
  .form-error {
    @apply text-sm text-red-600 mt-1;
  }
  
  /* Layout utilities */
  .container-responsive {
    @apply mx-auto px-4 sm:px-6 lg:px-8;
  }
  
  .stack {
    @apply flex flex-col gap-4;
  }
  
  .stack-sm {
    @apply flex flex-col gap-2;
  }
  
  .stack-lg {
    @apply flex flex-col gap-6;
  }
  
  .cluster {
    @apply flex flex-wrap gap-2;
  }
  
  .sidebar-layout {
    @apply grid grid-cols-1 lg:grid-cols-[250px_1fr] gap-6;
  }
}

/* Utility classes */
@layer utilities {
  .text-balance {
    text-wrap: balance;
  }
  
  .scrollbar-hide {
    -ms-overflow-style: none;
    scrollbar-width: none;
  }
  
  .scrollbar-hide::-webkit-scrollbar {
    display: none;
  }
}
```

**Component composition patterns:**

```tsx
// components/ui/Button.tsx
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const buttonVariants = cva('btn', {
  variants: {
    variant: {
      primary: 'btn-primary',
      secondary: 'btn-secondary',
      outline: 'btn-outline',
      ghost: 'btn-ghost',
      destructive: 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500'
    },
    size: {
      sm: 'btn-sm',
      md: '',
      lg: 'btn-lg'
    }
  },
  defaultVariants: {
    variant: 'primary',
    size: 'md'
  }
})

interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  loading?: boolean
}

export function Button({
  className,
  variant,
  size,
  loading,
  disabled,
  children,
  ...props
}: ButtonProps) {
  return (
    <button
      className={cn(buttonVariants({ variant, size }), className)}
      disabled={disabled || loading}
      {...props}
    >
      {loading && (
        <svg className="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
          <path className="opacity-75" fill="currentColor" d="m4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
        </svg>
      )}
      {children}
    </button>
  )
}

// components/ui/Card.tsx
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const cardVariants = cva('card', {
  variants: {
    variant: {
      default: '',
      elevated: 'card-elevated',
      interactive: 'card-interactive'
    },
    padding: {
      none: 'p-0',
      sm: 'p-4',
      md: 'p-6',
      lg: 'p-8'
    }
  },
  defaultVariants: {
    variant: 'default',
    padding: 'md'
  }
})

interface CardProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof cardVariants> {}

export function Card({ className, variant, padding, ...props }: CardProps) {
  return (
    <div
      className={cn(cardVariants({ variant, padding }), className)}
      {...props}
    />
  )
}

export function CardHeader({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn('flex flex-col space-y-1.5 p-6', className)}
      {...props}
    />
  )
}

export function CardTitle({ className, ...props }: React.HTMLAttributes<HTMLHeadingElement>) {
  return (
    <h3
      className={cn('text-lg font-semibold leading-none tracking-tight', className)}
      {...props}
    />
  )
}

export function CardContent({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div className={cn('p-6 pt-0', className)} {...props} />
  )
}

// components/ui/Input.tsx
import { forwardRef } from 'react'
import { cn } from '@/lib/utils'

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  error?: boolean
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ className, error, type, ...props }, ref) => {
    return (
      <input
        type={type}
        className={cn(
          'form-input',
          error && 'form-input-error',
          className
        )}
        ref={ref}
        {...props}
      />
    )
  }
)

Input.displayName = 'Input'

// Layout components
// components/layout/Container.tsx
interface ContainerProps extends React.HTMLAttributes<HTMLDivElement> {
  size?: 'sm' | 'md' | 'lg' | 'xl' | 'full'
}

export function Container({ className, size = 'lg', ...props }: ContainerProps) {
  return (
    <div
      className={cn(
        'container-responsive',
        {
          'max-w-2xl': size === 'sm',
          'max-w-4xl': size === 'md',
          'max-w-6xl': size === 'lg',
          'max-w-7xl': size === 'xl',
          'max-w-none': size === 'full'
        },
        className
      )}
      {...props}
    />
  )
}

// components/layout/Stack.tsx
interface StackProps extends React.HTMLAttributes<HTMLDivElement> {
  gap?: 'sm' | 'md' | 'lg'
  align?: 'start' | 'center' | 'end'
}

export function Stack({ className, gap = 'md', align, ...props }: StackProps) {
  return (
    <div
      className={cn(
        'flex flex-col',
        {
          'gap-2': gap === 'sm',
          'gap-4': gap === 'md',
          'gap-6': gap === 'lg',
          'items-start': align === 'start',
          'items-center': align === 'center',
          'items-end': align === 'end'
        },
        className
      )}
      {...props}
    />
  )
}

// Usage examples
// app/dashboard/page.tsx
import { Container, Stack } from '@/components/layout'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'

export default function DashboardPage() {
  return (
    <Container>
      <Stack gap="lg">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-bold text-balance">Dashboard</h1>
          <Button variant="primary">
            New Project
          </Button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <Card variant="interactive">
            <CardHeader>
              <CardTitle>Total Users</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">1,234</div>
              <p className="text-sm text-gray-600">+12% from last month</p>
            </CardContent>
          </Card>

          <Card variant="interactive">
            <CardHeader>
              <CardTitle>Revenue</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">$45,231</div>
              <p className="text-sm text-gray-600">+8% from last month</p>
            </CardContent>
          </Card>
        </div>
      </Stack>
    </Container>
  )
}
```

**Tailwind configuration for v4+:**

```js
// tailwind.config.js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: 'rgb(var(--color-primary-50) / <alpha-value>)',
          100: 'rgb(var(--color-primary-100) / <alpha-value>)',
          500: 'rgb(var(--color-primary-500) / <alpha-value>)',
          600: 'rgb(var(--color-primary-600) / <alpha-value>)',
          700: 'rgb(var(--color-primary-700) / <alpha-value>)',
          900: 'rgb(var(--color-primary-900) / <alpha-value>)',
        }
      },
      fontFamily: {
        sans: ['var(--font-sans)'],
        mono: ['var(--font-mono)']
      },
      spacing: {
        xs: 'var(--spacing-xs)',
        sm: 'var(--spacing-sm)',
        md: 'var(--spacing-md)',
        lg: 'var(--spacing-lg)',
        xl: 'var(--spacing-xl)',
        '2xl': 'var(--spacing-2xl)'
      }
    }
  },
  plugins: []
}
```

This pattern provides:
- **Design system consistency** - Centralized design tokens
- **Component composition** - Reusable, composable UI components
- **Performance optimization** - Efficient CSS with custom properties
- **Maintainability** - Clear separation of concerns
- **Accessibility** - Built-in focus states and semantic HTML