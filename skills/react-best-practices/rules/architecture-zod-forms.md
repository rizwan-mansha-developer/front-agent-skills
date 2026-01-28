---
title: Zod Validation with React Hook Form Integration
impact: HIGH
impactDescription: type-safe forms, runtime validation, better UX, reduced errors
tags: zod, react-hook-form, validation, forms, type-safety
---

## Zod Validation with React Hook Form Integration

**Impact: HIGH (type-safe forms, runtime validation, better UX, reduced errors)**

Use Zod schemas for type-safe validation combined with React Hook Form for performant form handling. This provides compile-time and runtime type safety with excellent developer experience.

**Incorrect (manual validation with useState):**

```tsx
// Manual form handling - no type safety, verbose validation
function UserForm({ onSubmit }: { onSubmit: (data: any) => void }) {
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    age: "",
  });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    // Manual validation - error-prone
    const newErrors: Record<string, string> = {};

    if (!formData.name.trim()) {
      newErrors.name = "Name is required";
    } else if (formData.name.length < 2) {
      newErrors.name = "Name must be at least 2 characters";
    }

    if (!formData.email.trim()) {
      newErrors.email = "Email is required";
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = "Email is invalid";
    }

    if (!formData.age) {
      newErrors.age = "Age is required";
    } else if (parseInt(formData.age) < 18) {
      newErrors.age = "Must be at least 18 years old";
    }

    setErrors(newErrors);

    if (Object.keys(newErrors).length === 0) {
      await onSubmit(formData);
    }

    setIsSubmitting(false);
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        value={formData.name}
        onChange={e => setFormData(prev => ({ ...prev, name: e.target.value }))}
        placeholder="Name"
      />
      {errors.name && <span className="error">{errors.name}</span>}

      <input
        value={formData.email}
        onChange={e =>
          setFormData(prev => ({ ...prev, email: e.target.value }))
        }
        placeholder="Email"
      />
      {errors.email && <span className="error">{errors.email}</span>}

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? "Submitting..." : "Submit"}
      </button>
    </form>
  );
}
```

**Correct (Zod + React Hook Form):**

```tsx
// Zod schema definition
// features/users/schemas/user.schema.ts
import { z } from "zod";

export const createUserSchema = z.object({
  name: z
    .string()
    .min(1, "Name is required")
    .min(2, "Name must be at least 2 characters")
    .max(50, "Name must be less than 50 characters"),

  email: z
    .string()
    .min(1, "Email is required")
    .email("Please enter a valid email address"),

  age: z
    .number({
      required_error: "Age is required",
      invalid_type_error: "Age must be a number",
    })
    .min(18, "Must be at least 18 years old")
    .max(120, "Age must be realistic"),

  role: z.enum(["admin", "user", "moderator"], {
    required_error: "Please select a role",
  }),

  preferences: z
    .object({
      newsletter: z.boolean().default(false),
      notifications: z.boolean().default(true),
      theme: z.enum(["light", "dark"]).default("light"),
    })
    .optional(),
});

export const updateUserSchema = createUserSchema.partial();

// Infer TypeScript types from Zod schema
export type CreateUserData = z.infer<typeof createUserSchema>;
export type UpdateUserData = z.infer<typeof updateUserSchema>;

// Form component with React Hook Form + Zod
// features/users/components/UserForm.tsx
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { createUserSchema, type CreateUserData } from "../schemas/user.schema";

interface UserFormProps {
  onSubmit: (data: CreateUserData) => Promise<void>;
  defaultValues?: Partial<CreateUserData>;
  isLoading?: boolean;
}

export function UserForm({
  onSubmit,
  defaultValues,
  isLoading = false,
}: UserFormProps) {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting, isDirty, isValid },
    reset,
    watch,
    setValue,
  } = useForm<CreateUserData>({
    resolver: zodResolver(createUserSchema),
    defaultValues: {
      preferences: {
        newsletter: false,
        notifications: true,
        theme: "light",
      },
      ...defaultValues,
    },
    mode: "onChange", // Validate on change for better UX
  });

  const handleFormSubmit = async (data: CreateUserData) => {
    try {
      await onSubmit(data);
      reset(); // Reset form after successful submission
    } catch (error) {
      // Error handling is done by the parent component
      console.error("Form submission error:", error);
    }
  };

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-6">
      {/* Name field */}
      <div>
        <label
          htmlFor="name"
          className="block text-sm font-medium text-gray-700"
        >
          Name *
        </label>
        <input
          {...register("name")}
          type="text"
          id="name"
          className={`mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 ${
            errors.name
              ? "border-red-300 focus:border-red-500 focus:ring-red-500"
              : ""
          }`}
          placeholder="Enter your name"
        />
        {errors.name && (
          <p className="mt-1 text-sm text-red-600">{errors.name.message}</p>
        )}
      </div>

      {/* Email field */}
      <div>
        <label
          htmlFor="email"
          className="block text-sm font-medium text-gray-700"
        >
          Email *
        </label>
        <input
          {...register("email")}
          type="email"
          id="email"
          className={`mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 ${
            errors.email
              ? "border-red-300 focus:border-red-500 focus:ring-red-500"
              : ""
          }`}
          placeholder="Enter your email"
        />
        {errors.email && (
          <p className="mt-1 text-sm text-red-600">{errors.email.message}</p>
        )}
      </div>

      {/* Age field */}
      <div>
        <label
          htmlFor="age"
          className="block text-sm font-medium text-gray-700"
        >
          Age *
        </label>
        <input
          {...register("age", { valueAsNumber: true })}
          type="number"
          id="age"
          min="18"
          max="120"
          className={`mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 ${
            errors.age
              ? "border-red-300 focus:border-red-500 focus:ring-red-500"
              : ""
          }`}
          placeholder="Enter your age"
        />
        {errors.age && (
          <p className="mt-1 text-sm text-red-600">{errors.age.message}</p>
        )}
      </div>

      {/* Role field */}
      <div>
        <label
          htmlFor="role"
          className="block text-sm font-medium text-gray-700"
        >
          Role *
        </label>
        <select
          {...register("role")}
          id="role"
          className={`mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 ${
            errors.role
              ? "border-red-300 focus:border-red-500 focus:ring-red-500"
              : ""
          }`}
        >
          <option value="">Select a role</option>
          <option value="user">User</option>
          <option value="moderator">Moderator</option>
          <option value="admin">Admin</option>
        </select>
        {errors.role && (
          <p className="mt-1 text-sm text-red-600">{errors.role.message}</p>
        )}
      </div>

      {/* Preferences */}
      <div className="space-y-3">
        <h3 className="text-sm font-medium text-gray-700">Preferences</h3>

        <div className="flex items-center">
          <input
            {...register("preferences.newsletter")}
            type="checkbox"
            id="newsletter"
            className="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
          />
          <label
            htmlFor="newsletter"
            className="ml-2 block text-sm text-gray-700"
          >
            Subscribe to newsletter
          </label>
        </div>

        <div className="flex items-center">
          <input
            {...register("preferences.notifications")}
            type="checkbox"
            id="notifications"
            className="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
          />
          <label
            htmlFor="notifications"
            className="ml-2 block text-sm text-gray-700"
          >
            Enable notifications
          </label>
        </div>

        <div>
          <label className="mb-1 block text-sm text-gray-700">Theme</label>
          <div className="flex space-x-4">
            <label className="flex items-center">
              <input
                {...register("preferences.theme")}
                type="radio"
                value="light"
                className="h-4 w-4 text-blue-600 focus:ring-blue-500"
              />
              <span className="ml-2 text-sm text-gray-700">Light</span>
            </label>
            <label className="flex items-center">
              <input
                {...register("preferences.theme")}
                type="radio"
                value="dark"
                className="h-4 w-4 text-blue-600 focus:ring-blue-500"
              />
              <span className="ml-2 text-sm text-gray-700">Dark</span>
            </label>
          </div>
        </div>
      </div>

      {/* Submit button */}
      <div className="flex justify-end space-x-3">
        <button
          type="button"
          onClick={() => reset()}
          className="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
          disabled={isSubmitting || isLoading}
        >
          Reset
        </button>
        <button
          type="submit"
          disabled={isSubmitting || isLoading || !isDirty || !isValid}
          className="rounded-md border border-transparent bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
        >
          {isSubmitting || isLoading ? "Submitting..." : "Submit"}
        </button>
      </div>
    </form>
  );
}
```

**Advanced patterns with TanStack Query integration:**

```tsx
// Form with mutation integration
// features/users/components/CreateUserForm.tsx
import { useCreateUser } from "../hooks/useUsers";
import { UserForm } from "./UserForm";
import { toast } from "@/hooks/useToast";

export function CreateUserForm() {
  const createUser = useCreateUser();

  const handleSubmit = async (data: CreateUserData) => {
    try {
      await createUser.mutateAsync(data);
      toast.success("User created successfully!");
    } catch (error) {
      toast.error("Failed to create user. Please try again.");
      throw error; // Re-throw to prevent form reset
    }
  };

  return (
    <div className="mx-auto max-w-md">
      <h2 className="mb-6 text-2xl font-bold">Create New User</h2>
      <UserForm onSubmit={handleSubmit} isLoading={createUser.isPending} />
    </div>
  );
}

// Edit form with prefilled data
export function EditUserForm({ userId }: { userId: string }) {
  const { data: user } = useUser(userId);
  const updateUser = useUpdateUser();

  const handleSubmit = async (data: UpdateUserData) => {
    try {
      await updateUser.mutateAsync({ userId, data });
      toast.success("User updated successfully!");
    } catch (error) {
      toast.error("Failed to update user. Please try again.");
      throw error;
    }
  };

  return (
    <div className="mx-auto max-w-md">
      <h2 className="mb-6 text-2xl font-bold">Edit User</h2>
      <UserForm
        onSubmit={handleSubmit}
        defaultValues={user}
        isLoading={updateUser.isPending}
      />
    </div>
  );
}

// Custom hook for form with server validation
export function useUserForm(userId?: string) {
  const form = useForm<CreateUserData>({
    resolver: zodResolver(createUserSchema),
    mode: "onChange",
  });

  // Server-side validation
  const validateEmail = async (email: string) => {
    try {
      await usersApi.validateEmail(email, userId);
      return true;
    } catch (error) {
      form.setError("email", {
        type: "server",
        message: "Email is already taken",
      });
      return false;
    }
  };

  return {
    ...form,
    validateEmail,
  };
}

// Reusable form field components
// components/ui/FormField.tsx
interface FormFieldProps {
  label: string;
  name: string;
  error?: string;
  required?: boolean;
  children: React.ReactNode;
}

export function FormField({
  label,
  name,
  error,
  required,
  children,
}: FormFieldProps) {
  return (
    <div>
      <label htmlFor={name} className="block text-sm font-medium text-gray-700">
        {label} {required && <span className="text-red-500">*</span>}
      </label>
      <div className="mt-1">{children}</div>
      {error && <p className="mt-1 text-sm text-red-600">{error}</p>}
    </div>
  );
}

// Usage with FormField
<FormField label="Name" name="name" error={errors.name?.message} required>
  <input
    {...register("name")}
    type="text"
    id="name"
    className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
  />
</FormField>;
```

This pattern provides:

- **Type safety** - compile-time and runtime validation
- **Better UX** - real-time validation feedback
- **Reduced errors** - schema-driven validation
- **Performance** - React Hook Form's uncontrolled components
- **Reusability** - shared schemas across forms
- **Server integration** - works seamlessly with TanStack Query

Reference: [Zod](https://zod.dev/) | [React Hook Form](https://react-hook-form.com/)
