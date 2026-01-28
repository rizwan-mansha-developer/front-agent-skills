---
name: shadcn-ui-guidelines
description: shadcn/ui component library best practices and patterns for Next.js applications. Use when building UI components, implementing design systems, or working with shadcn/ui components.
license: MIT
metadata:
  author: shadcn
  version: "1.0.0"
---

# shadcn/ui Guidelines

Comprehensive best practices for using shadcn/ui component library in Next.js applications. Covers component patterns, customization, accessibility, and performance optimization.

## When to Apply

Use these guidelines when:

- Setting up shadcn/ui in a new project
- Building custom components with shadcn/ui
- Implementing forms, data tables, or complex UI patterns
- Customizing themes and design tokens
- Optimizing shadcn/ui component performance

## Quick Setup

### Installation

```bash
npx shadcn-ui@latest init
```

### Essential Components

```bash
# Core UI components
npx shadcn-ui@latest add button card input label
npx shadcn-ui@latest add form select textarea checkbox
npx shadcn-ui@latest add dialog sheet popover dropdown-menu
npx shadcn-ui@latest add table data-table pagination
```

## Core Principles

### 1. Component Priority Hierarchy

**ALWAYS use this order when building UI:**

1. **shadcn/ui components first** - `<Button />`, `<Input />`, `<Card />`
2. **Custom wrappers second** - Extend shadcn components when needed
3. **Native HTML last** - Only when shadcn doesn't provide the component

```tsx
// ✅ PRIORITY 1: Use shadcn components
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

// ✅ PRIORITY 2: Custom wrappers of shadcn
import { SubmitButton } from "@/components/submit-button"; // wraps <Button />

// ❌ PRIORITY 3: Avoid native HTML when shadcn exists
// <button> <input> - use shadcn equivalents instead
```

### 2. Component Composition

- **Prefer composition over configuration**
- **Use compound components for complex UI**
- **Leverage Radix UI primitives**

### 3. Customization Strategy

- **Modify components in `/components/ui/`**
- **Use CSS variables for theming**
- **Extend with custom variants**

### 4. Performance Patterns

- **Tree-shake unused components**
- **Use dynamic imports for heavy components**
- **Optimize bundle size with selective imports**

## Best Practices by Category

### Component Selection Priority

#### ✅ ALWAYS: Use shadcn/ui First

```tsx
// Use shadcn components for all UI elements
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Dialog, DialogContent, DialogTrigger } from "@/components/ui/dialog";

function LoginForm() {
  return (
    <Card>
      <CardHeader>
        <h2>Login</h2>
      </CardHeader>
      <CardContent>
        <Input placeholder="Email" />
        <Input type="password" placeholder="Password" />
        <Button>Sign In</Button>
      </CardContent>
    </Card>
  );
}
```

#### ✅ WHEN NEEDED: Create Custom Wrappers

```tsx
// Extend shadcn components with custom logic
import { Button } from "@/components/ui/button";
import { Loader2 } from "lucide-react";

interface SubmitButtonProps extends React.ComponentProps<typeof Button> {
  isLoading?: boolean;
}

export function SubmitButton({
  isLoading,
  children,
  ...props
}: SubmitButtonProps) {
  return (
    <Button disabled={isLoading} {...props}>
      {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
      {children}
    </Button>
  );
}
```

#### ❌ AVOID: Native HTML When shadcn Exists

```tsx
// DON'T use native HTML
<button className="px-4 py-2 bg-blue-500">Click me</button>
<input className="border rounded px-3 py-2" />
<div className="border rounded p-4">Card content</div>

// DO use shadcn equivalents
<Button>Click me</Button>
<Input />
<Card><CardContent>Card content</CardContent></Card>
```

### Component Architecture

#### ✅ DO: Use Compound Components

```tsx
<Dialog>
  <DialogTrigger asChild>
    <Button variant="outline">Edit Profile</Button>
  </DialogTrigger>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Edit profile</DialogTitle>
    </DialogHeader>
    {/* Content */}
  </DialogContent>
</Dialog>
```

#### ❌ DON'T: Prop Drilling

```tsx
// Avoid complex prop interfaces
<Dialog
  trigger={<Button>Edit</Button>}
  title="Edit profile"
  content={<Form />}
  isOpen={isOpen}
  onClose={onClose}
/>
```

### Form Patterns

#### ✅ DO: Use React Hook Form + Zod

```tsx
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";

const formSchema = z.object({
  username: z.string().min(2).max(50),
});

export function ProfileForm() {
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)}>
        <FormField
          control={form.control}
          name="username"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Username</FormLabel>
              <FormControl>
                <Input placeholder="shadcn" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
      </form>
    </Form>
  );
}
```

### Data Tables

#### ✅ DO: Use TanStack Table

```tsx
import { DataTable } from "@/components/ui/data-table";
import { columns } from "./columns";

export function PaymentsTable() {
  return (
    <DataTable
      columns={columns}
      data={payments}
      searchKey="email"
      searchPlaceholder="Filter emails..."
    />
  );
}
```

### Theme Customization

#### ✅ DO: Use CSS Variables

```css
/* globals.css */
:root {
  --primary: 222.2 84% 4.9%;
  --primary-foreground: 210 40% 98%;
  --secondary: 210 40% 96%;
  --secondary-foreground: 222.2 84% 4.9%;
}

.dark {
  --primary: 210 40% 98%;
  --primary-foreground: 222.2 84% 4.9%;
}
```

#### ✅ DO: Extend Component Variants

```tsx
// components/ui/button.tsx
const buttonVariants = cva(
  "inline-flex items-center justify-center rounded-md text-sm font-medium",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/90",
        destructive:
          "bg-destructive text-destructive-foreground hover:bg-destructive/90",
        // Add custom variants
        gradient: "bg-gradient-to-r from-purple-500 to-pink-500 text-white",
      },
    },
  }
);
```

### Accessibility

#### ✅ DO: Leverage Built-in A11y

```tsx
// shadcn/ui components include ARIA attributes
<AlertDialog>
  <AlertDialogTrigger asChild>
    <Button variant="destructive">Delete Account</Button>
  </AlertDialogTrigger>
  <AlertDialogContent>
    <AlertDialogHeader>
      <AlertDialogTitle>Are you absolutely sure?</AlertDialogTitle>
      <AlertDialogDescription>
        This action cannot be undone.
      </AlertDialogDescription>
    </AlertDialogHeader>
    <AlertDialogFooter>
      <AlertDialogCancel>Cancel</AlertDialogCancel>
      <AlertDialogAction>Continue</AlertDialogAction>
    </AlertDialogFooter>
  </AlertDialogContent>
</AlertDialog>
```

### Performance Optimization

#### ✅ DO: Dynamic Imports for Heavy Components

```tsx
import dynamic from "next/dynamic";

const DataTable = dynamic(() => import("@/components/ui/data-table"), {
  loading: () => <TableSkeleton />,
  ssr: false,
});
```

#### ✅ DO: Selective Component Imports

```tsx
// Import only what you need
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

// Don't import entire library
// import * from "@/components/ui"
```

## Common Patterns

### Loading States

```tsx
import { Skeleton } from "@/components/ui/skeleton";

function CardSkeleton() {
  return (
    <div className="flex flex-col space-y-3">
      <Skeleton className="h-[125px] w-[250px] rounded-xl" />
      <div className="space-y-2">
        <Skeleton className="h-4 w-[250px]" />
        <Skeleton className="h-4 w-[200px]" />
      </div>
    </div>
  );
}
```

### Error Handling

```tsx
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { AlertCircle } from "lucide-react";

function ErrorAlert({ error }: { error: string }) {
  return (
    <Alert variant="destructive">
      <AlertCircle className="h-4 w-4" />
      <AlertTitle>Error</AlertTitle>
      <AlertDescription>{error}</AlertDescription>
    </Alert>
  );
}
```

### Command Palette

```tsx
import { Command } from "@/components/ui/command";

function CommandPalette() {
  return (
    <Command className="rounded-lg border shadow-md">
      <CommandInput placeholder="Type a command or search..." />
      <CommandList>
        <CommandEmpty>No results found.</CommandEmpty>
        <CommandGroup heading="Suggestions">
          <CommandItem>Calendar</CommandItem>
          <CommandItem>Search Emoji</CommandItem>
          <CommandItem>Calculator</CommandItem>
        </CommandGroup>
      </CommandList>
    </Command>
  );
}
```

## Integration with Next.js

### App Router Setup

```tsx
// app/layout.tsx
import { ThemeProvider } from "@/components/theme-provider";

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          {children}
        </ThemeProvider>
      </body>
    </html>
  );
}
```

### Server Components

```tsx
// app/dashboard/page.tsx
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default function Dashboard() {
  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Total Revenue</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">$45,231.89</div>
        </CardContent>
      </Card>
    </div>
  );
}
```

## Common Anti-Patterns

### ❌ DON'T: Use Native HTML When shadcn Exists

```tsx
// Bad - using native elements
<button onClick={handleClick}>Submit</button>
<input type="text" placeholder="Search" />
<select><option>Choose</option></select>
<textarea placeholder="Message" />

// Good - use shadcn components
<Button onClick={handleClick}>Submit</Button>
<Input placeholder="Search" />
<Select><SelectTrigger><SelectValue placeholder="Choose" /></SelectTrigger></Select>
<Textarea placeholder="Message" />
```

### ❌ DON'T: Override Core Styles Directly

```tsx
// Avoid inline styles that break theming
<Button style={{ backgroundColor: '#ff0000' }}>
  Bad Button
</Button>

// Use variants instead
<Button variant="destructive">
  Good Button
</Button>
```

### ❌ DON'T: Ignore TypeScript Types

```tsx
// Use proper types
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "default" | "destructive" | "outline";
}
```

### ❌ DON'T: Mix UI Libraries

```tsx
// Don't mix shadcn/ui with other component libraries
// Choose one and stick with it for consistency
```

### ❌ DON'T: Skip Component Wrappers for Business Logic

```tsx
// Bad - business logic in every usage
<Button
  onClick={() => {
    setLoading(true)
    submitForm().finally(() => setLoading(false))
  }}
  disabled={loading}
>
  {loading ? 'Submitting...' : 'Submit'}
</Button>

// Good - create reusable wrapper
<SubmitButton onSubmit={submitForm}>
  Submit
</SubmitButton>
```

## Troubleshooting

### Common Issues

1. **Styling conflicts**: Ensure Tailwind CSS is properly configured
2. **Dark mode not working**: Check ThemeProvider setup
3. **Components not found**: Verify installation with `npx shadcn-ui@latest add`
4. **TypeScript errors**: Update component types after customization

### Debug Commands

```bash
# Check installed components
npx shadcn-ui@latest list

# Update components
npx shadcn-ui@latest update

# Add missing dependencies
npm install @radix-ui/react-dialog class-variance-authority
```

## Resources

- [shadcn/ui Documentation](https://ui.shadcn.com)
- [Radix UI Primitives](https://radix-ui.com)
- [Tailwind CSS](https://tailwindcss.com)
- [React Hook Form](https://react-hook-form.com)
- [Zod Validation](https://zod.dev)
