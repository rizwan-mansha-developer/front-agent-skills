# Agent Skills CLI

Create Next.js projects optimized for AI coding agents with all necessary packages pre-installed.

## Installation

```bash
# Install globally
npm install -g agent-skills

# Or use directly with npx
npx agent-skills my-app
```

## Usage

```bash
# Create new project
npx agent-skills my-app
cd my-app
npm run dev
```

## What's Included

### Core Stack
- **Next.js 16** with App Router
- **TypeScript** for type safety
- **Tailwind CSS** for styling
- **ESLint** for code quality

### UI Components
- **shadcn/ui** component library
- **Lucide React** icons
- **next-themes** for dark mode

### Form Handling
- **React Hook Form** for forms
- **Zod** for validation
- **@hookform/resolvers** for integration

### Data Tables
- **@tanstack/react-table** for data tables

### Pre-installed Components
- Button, Card, Input, Label
- Form, Select, Textarea, Checkbox
- Dialog, Sheet, Popover, Dropdown Menu
- Table, Alert, Skeleton, Command

## Project Structure

```
my-app/
├── src/
│   ├── app/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   └── globals.css
│   ├── components/
│   │   ├── ui/           # shadcn/ui components
│   │   └── theme-provider.tsx
│   ├── lib/
│   ├── hooks/
│   ├── types/
│   └── utils/
└── components.json       # shadcn/ui config
```

## Agent Skills Integration

The project is pre-configured to work with:
- **React Best Practices** skill
- **shadcn/ui Guidelines** skill
- **Web Design Guidelines** skill
- **Test Generator** skill
- **Test Runner** skill

## Quick Commands

```bash
# Add more shadcn components
npx shadcn-ui@latest add badge
npx shadcn-ui@latest add calendar

# Generate tests (with agent)
"Generate tests for my components"

# Review code (with agent)
"Review my React code for performance"
```