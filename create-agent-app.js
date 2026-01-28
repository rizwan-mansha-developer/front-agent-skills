#!/usr/bin/env node

const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const projectName = process.argv[2] || "my-app";

console.log(`🚀 Creating Next.js project with agent skills: ${projectName}`);

// Create Next.js app with TypeScript and Tailwind
console.log("📦 Installing Next.js with TypeScript and Tailwind...");
execSync(
  `npx create-next-app@latest ${projectName} --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"`,
  { stdio: "inherit" }
);

// Navigate to project directory
process.chdir(projectName);

// Install shadcn/ui
console.log("🎨 Setting up shadcn/ui...");
execSync("npx shadcn-ui@latest init -d", { stdio: "inherit" });

// Install essential shadcn components
console.log("🧩 Installing essential shadcn components...");
const components = [
  "button",
  "card",
  "input",
  "label",
  "form",
  "select",
  "textarea",
  "checkbox",
  "dialog",
  "sheet",
  "popover",
  "dropdown-menu",
  "table",
  "alert",
  "skeleton",
  "command",
];

components.forEach(component => {
  try {
    execSync(`npx shadcn-ui@latest add ${component} -y`, { stdio: "inherit" });
  } catch (error) {
    console.log(`⚠️  Could not install ${component}, continuing...`);
  }
});

// Install additional dependencies
console.log("📚 Installing additional dependencies...");
const dependencies = [
  "react-hook-form",
  "@hookform/resolvers",
  "zod",
  "@tanstack/react-table",
  "lucide-react",
  "next-themes",
];

execSync(`npm install ${dependencies.join(" ")}`, { stdio: "inherit" });

// Create project structure
console.log("📁 Setting up project structure...");

const directories = [
  "src/components/ui",
  "src/lib",
  "src/hooks",
  "src/types",
  "src/utils",
];

directories.forEach(dir => {
  fs.mkdirSync(dir, { recursive: true });
});

// Create theme provider
const themeProvider = `"use client"

import * as React from "react"
import { ThemeProvider as NextThemesProvider } from "next-themes"
import { type ThemeProviderProps } from "next-themes/dist/types"

export function ThemeProvider({ children, ...props }: ThemeProviderProps) {
  return <NextThemesProvider {...props}>{children}</NextThemesProvider>
}`;

fs.writeFileSync("src/components/theme-provider.tsx", themeProvider);

// Update layout.tsx
const layout = `import type { Metadata } from "next"
import { Inter } from "next/font/google"
import "./globals.css"
import { ThemeProvider } from "@/components/theme-provider"

const inter = Inter({ subsets: ["latin"] })

export const metadata: Metadata = {
  title: "${projectName}",
  description: "Built with Next.js, TypeScript, Tailwind CSS, and shadcn/ui",
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={inter.className}>
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
  )
}`;

fs.writeFileSync("src/app/layout.tsx", layout);

// Create sample page with shadcn components
const samplePage = `import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"

export default function Home() {
  return (
    <main className="container mx-auto p-8">
      <div className="max-w-2xl mx-auto space-y-8">
        <div className="text-center">
          <h1 className="text-4xl font-bold mb-4">Welcome to ${projectName}</h1>
          <p className="text-muted-foreground">
            Built with Next.js, TypeScript, Tailwind CSS, and shadcn/ui
          </p>
        </div>
        
        <Card>
          <CardHeader>
            <CardTitle>Get Started</CardTitle>
            <CardDescription>
              Your project is ready with shadcn/ui components and best practices
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input id="email" placeholder="Enter your email" />
            </div>
            <Button className="w-full">Get Started</Button>
          </CardContent>
        </Card>
      </div>
    </main>
  )
}`;

fs.writeFileSync("src/app/page.tsx", samplePage);

console.log("✅ Project setup complete!");
console.log(`
🎉 ${projectName} is ready!

📦 Installed:
  ✓ Next.js 14 with App Router
  ✓ TypeScript
  ✓ Tailwind CSS
  ✓ shadcn/ui components
  ✓ React Hook Form + Zod
  ✓ TanStack Table
  ✓ Lucide Icons
  ✓ Theme support

🚀 Next steps:
  cd ${projectName}
  npm run dev

📚 Resources:
  - shadcn/ui: https://ui.shadcn.com
  - Agent Skills: Follow the guidelines in your IDE
`);
