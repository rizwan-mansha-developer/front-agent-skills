---
title: Use React Hook Form with Zod for Form Validation
impact: HIGH
impactDescription: type-safe forms, real-time validation, better UX, server actions integration
tags: react-hook-form, zod, validation, forms, server-actions, real-time
---

## Use React Hook Form with Zod for Form Validation

**Impact: HIGH (type-safe forms, real-time validation, better UX, server actions integration)**

Use React Hook Form with Zod for type-safe form handling with real-time validation. Integrate with Next.js server actions for seamless form submission with optimistic updates.

**Incorrect (manual form handling with useState):**

```tsx
// Manual form state - no validation, poor UX
function UserForm() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    // Manual validation
    const newErrors: Record<string, string> = {};
    if (!name) newErrors.name = "Name is required";
    if (!email) newErrors.email = "Email is required";

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      setLoading(false);
      return;
    }

    try {
      await fetch("/api/users", {
        method: "POST",
        body: JSON.stringify({ name, email }),
      });
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        value={name}
        onChange={e => setName(e.target.value)}
        placeholder="Name"
      />
      {errors.name && <span>{errors.name}</span>}
    </form>
  );
}
```

**Correct (React Hook Form with Zod and real-time validation):**

```tsx
// lib/validations/user.ts
import { z } from "zod";

export const userSchema = z.object({
  name: z
    .string()
    .min(2, "Name must be at least 2 characters")
    .max(50, "Name must be less than 50 characters"),
  email: z
    .string()
    .email("Please enter a valid email address")
    .min(1, "Email is required"),
  age: z
    .number()
    .min(18, "Must be at least 18 years old")
    .max(120, "Age must be realistic"),
  role: z.enum(["admin", "user", "moderator"], {
    errorMap: () => ({ message: "Please select a valid role" }),
  }),
  bio: z.string().max(500, "Bio must be less than 500 characters").optional(),
  website: z
    .string()
    .url("Please enter a valid URL")
    .optional()
    .or(z.literal("")),
});

export type UserFormData = z.infer<typeof userSchema>;

// Server action
// app/actions/user.ts
("use server");

import { userSchema } from "@/lib/validations/user";
import { revalidatePath } from "next/cache";

export async function createUser(formData: FormData) {
  const rawData = {
    name: formData.get("name"),
    email: formData.get("email"),
    age: Number(formData.get("age")),
    role: formData.get("role"),
    bio: formData.get("bio"),
    website: formData.get("website"),
  };

  // Server-side validation
  const result = userSchema.safeParse(rawData);

  if (!result.success) {
    return {
      success: false,
      errors: result.error.flatten().fieldErrors,
    };
  }

  try {
    // Save to database
    const user = await db.user.create({
      data: result.data,
    });

    revalidatePath("/users");

    return {
      success: true,
      data: user,
    };
  } catch (error) {
    return {
      success: false,
      errors: { _form: ["Failed to create user"] },
    };
  }
}

// components/UserForm.tsx
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { userSchema, type UserFormData } from "@/lib/validations/user";
import { createUser } from "@/app/actions/user";
import { useFormState } from "react-dom";
import { useEffect } from "react";
import { toast } from "sonner";

export function UserForm() {
  const [state, formAction] = useFormState(createUser, null);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting, isValid, touchedFields },
    watch,
    setError,
    reset,
  } = useForm<UserFormData>({
    resolver: zodResolver(userSchema),
    mode: "onChange", // Real-time validation
    defaultValues: {
      name: "",
      email: "",
      age: 18,
      role: "user",
      bio: "",
      website: "",
    },
  });

  // Watch for real-time validation feedback
  const watchedFields = watch();

  // Handle server errors
  useEffect(() => {
    if (state?.success === false && state.errors) {
      Object.entries(state.errors).forEach(([field, messages]) => {
        if (field === "_form") {
          toast.error(messages[0]);
        } else {
          setError(field as keyof UserFormData, {
            message: messages[0],
          });
        }
      });
    } else if (state?.success) {
      toast.success("User created successfully!");
      reset();
    }
  }, [state, setError, reset]);

  return (
    <form action={formAction} className="space-y-6">
      <div className="space-y-2">
        <label htmlFor="name" className="block text-sm font-medium">
          Name *
        </label>
        <input
          {...register("name")}
          type="text"
          className={`w-full rounded-md border px-3 py-2 ${
            errors.name
              ? "border-red-500"
              : touchedFields.name && !errors.name
                ? "border-green-500"
                : "border-gray-300"
          }`}
          placeholder="Enter your name"
        />
        {errors.name && (
          <p className="text-sm text-red-600">{errors.name.message}</p>
        )}
        {touchedFields.name && !errors.name && (
          <p className="text-sm text-green-600">✓ Looks good!</p>
        )}
      </div>

      <div className="space-y-2">
        <label htmlFor="email" className="block text-sm font-medium">
          Email *
        </label>
        <input
          {...register("email")}
          type="email"
          className={`w-full rounded-md border px-3 py-2 ${
            errors.email
              ? "border-red-500"
              : touchedFields.email && !errors.email
                ? "border-green-500"
                : "border-gray-300"
          }`}
          placeholder="Enter your email"
        />
        {errors.email && (
          <p className="text-sm text-red-600">{errors.email.message}</p>
        )}
      </div>

      <div className="space-y-2">
        <label htmlFor="age" className="block text-sm font-medium">
          Age *
        </label>
        <input
          {...register("age", { valueAsNumber: true })}
          type="number"
          min="18"
          max="120"
          className={`w-full rounded-md border px-3 py-2 ${
            errors.age ? "border-red-500" : "border-gray-300"
          }`}
        />
        {errors.age && (
          <p className="text-sm text-red-600">{errors.age.message}</p>
        )}
      </div>

      <div className="space-y-2">
        <label htmlFor="role" className="block text-sm font-medium">
          Role *
        </label>
        <select
          {...register("role")}
          className="w-full rounded-md border border-gray-300 px-3 py-2"
        >
          <option value="user">User</option>
          <option value="admin">Admin</option>
          <option value="moderator">Moderator</option>
        </select>
        {errors.role && (
          <p className="text-sm text-red-600">{errors.role.message}</p>
        )}
      </div>

      <div className="space-y-2">
        <label htmlFor="bio" className="block text-sm font-medium">
          Bio
        </label>
        <textarea
          {...register("bio")}
          rows={3}
          className="w-full rounded-md border border-gray-300 px-3 py-2"
          placeholder="Tell us about yourself..."
        />
        <div className="flex justify-between text-sm text-gray-500">
          <span>{errors.bio?.message}</span>
          <span>{watchedFields.bio?.length || 0}/500</span>
        </div>
      </div>

      <div className="space-y-2">
        <label htmlFor="website" className="block text-sm font-medium">
          Website
        </label>
        <input
          {...register("website")}
          type="url"
          className="w-full rounded-md border border-gray-300 px-3 py-2"
          placeholder="https://example.com"
        />
        {errors.website && (
          <p className="text-sm text-red-600">{errors.website.message}</p>
        )}
      </div>

      <button
        type="submit"
        disabled={isSubmitting || !isValid}
        className="w-full rounded-md bg-blue-600 px-4 py-2 text-white hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
      >
        {isSubmitting ? "Creating..." : "Create User"}
      </button>
    </form>
  );
}
```

**Advanced patterns with optimistic updates:**

```tsx
// hooks/useOptimisticForm.ts
import { useOptimistic, useTransition } from "react";
import { useForm } from "react-hook-form";

export function useOptimisticForm<T extends Record<string, any>>(
  initialData: T[],
  action: (formData: FormData) => Promise<any>
) {
  const [isPending, startTransition] = useTransition();
  const [optimisticData, addOptimistic] = useOptimistic(
    initialData,
    (state, newItem: T) => [...state, newItem]
  );

  const submitWithOptimistic = (data: T) => {
    startTransition(async () => {
      addOptimistic(data);
      const formData = new FormData();
      Object.entries(data).forEach(([key, value]) => {
        formData.append(key, String(value));
      });
      await action(formData);
    });
  };

  return {
    optimisticData,
    isPending,
    submitWithOptimistic,
  };
}

// components/OptimisticUserForm.tsx
export function OptimisticUserForm({ users }: { users: User[] }) {
  const { optimisticData, isPending, submitWithOptimistic } = useOptimisticForm(
    users,
    createUser
  );

  const form = useForm<UserFormData>({
    resolver: zodResolver(userSchema),
    mode: "onChange",
  });

  const onSubmit = (data: UserFormData) => {
    submitWithOptimistic({
      ...data,
      id: crypto.randomUUID(),
      createdAt: new Date().toISOString(),
    });
    form.reset();
  };

  return (
    <div>
      <form onSubmit={form.handleSubmit(onSubmit)}>{/* Form fields */}</form>

      <div className="mt-8">
        <h3>Users ({optimisticData.length})</h3>
        {optimisticData.map((user, index) => (
          <div
            key={user.id}
            className={`rounded border p-3 ${
              index >= users.length ? "opacity-50" : ""
            }`}
          >
            <p>
              {user.name} - {user.email}
            </p>
            {index >= users.length && (
              <span className="text-sm text-gray-500">Creating...</span>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
```

**Reusable form components:**

```tsx
// components/form/FormField.tsx
interface FormFieldProps {
  label: string;
  error?: string;
  required?: boolean;
  children: React.ReactNode;
  hint?: string;
}

export function FormField({
  label,
  error,
  required,
  children,
  hint,
}: FormFieldProps) {
  return (
    <div className="space-y-2">
      <label className="block text-sm font-medium">
        {label} {required && <span className="text-red-500">*</span>}
      </label>
      {children}
      {hint && <p className="text-sm text-gray-500">{hint}</p>}
      {error && <p className="text-sm text-red-600">{error}</p>}
    </div>
  );
}

// Usage
<FormField
  label="Email"
  required
  error={errors.email?.message}
  hint="We'll never share your email"
>
  <input {...register("email")} type="email" />
</FormField>;
```

This pattern provides:

- **Type-safe validation** - Zod ensures runtime and compile-time safety
- **Real-time feedback** - immediate validation as users type
- **Server integration** - seamless server actions with error handling
- **Optimistic updates** - better UX with immediate feedback
- **Reusable components** - consistent form styling and behavior
