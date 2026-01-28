This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.

# Agent Skills

A collection of skills for AI coding agents. Skills are packaged instructions and scripts that extend agent capabilities.

Skills follow the [Agent Skills](https://agentskills.io/) format.

## Quick Start

```bash
# Clone the repository
# git clone https://github.com/rizwan-mansha-developer/front-agent-skills.git
cd agent-skills

# Install dependencies
pnpm install

# Build the skills
pnpm build
```

## Available Skills

### react-best-practices

React and Next.js performance optimization guidelines from Vercel Engineering. Contains 40+ rules across 8 categories, prioritized by impact.

**Use when:**

- Writing new React components or Next.js pages
- Implementing data fetching (client or server-side)
- Reviewing code for performance issues
- Optimizing bundle size or load times

**Categories covered:**

- Eliminating waterfalls (Critical)
- Bundle size optimization (Critical)
- Server-side performance (High)
- Client-side data fetching (Medium-High)
- Re-render optimization (Medium)
- Rendering performance (Medium)
- JavaScript micro-optimizations (Low-Medium)

### web-design-guidelines

Review UI code for compliance with web interface best practices. Audits your code for 100+ rules covering accessibility, performance, and UX.

**Use when:**

- "Review my UI"
- "Check accessibility"
- "Audit design"
- "Review UX"
- "Check my site against best practices"

**Categories covered:**

- Accessibility (aria-labels, semantic HTML, keyboard handlers)
- Focus States (visible focus, focus-visible patterns)
- Forms (autocomplete, validation, error handling)
- Animation (prefers-reduced-motion, compositor-friendly transforms)
- Typography (curly quotes, ellipsis, tabular-nums)
- Images (dimensions, lazy loading, alt text)
- Performance (virtualization, layout thrashing, preconnect)
- Navigation & State (URL reflects state, deep-linking)
- Dark Mode & Theming (color-scheme, theme-color meta)
- Touch & Interaction (touch-action, tap-highlight)
- Locale & i18n (Intl.DateTimeFormat, Intl.NumberFormat)

### test-generator

Generate comprehensive test cases for any feature, function, or component. Creates unit, integration, and edge case tests automatically.

**Use when:**

- "Generate tests for this function"
- "Create test cases"
- "Write tests for my component"
- "Test this feature"
- "Generate unit tests"

**Features:**

- Supports React/TypeScript/JavaScript/Python
- Creates proper test file structure
- Includes mocking and setup
- Covers happy path, edge cases, and errors
- Generates accessibility and performance tests

### test-runner

Execute and manage test suites with detailed reporting. Run tests, generate coverage reports, and analyze results.

**Use when:**

- "Run my tests"
- "Check test coverage"
- "Execute test suite"
- "Run tests with coverage"
- "Test my code"

**Features:**

- Auto-detects test frameworks (Jest, pytest, Mocha, Vitest)
- Generates coverage reports
- Provides detailed test results
- Supports watch mode and filtering
- Performance metrics and insights

### shadcn-ui-guidelines

shadcn/ui component library best practices and patterns for Next.js applications. Comprehensive guide for building modern UI components.

**Use when:**

- Setting up shadcn/ui in a new project
- Building custom components with shadcn/ui
- Implementing forms, data tables, or complex UI patterns
- Customizing themes and design tokens
- "Help me with shadcn components"
- "Build a form with shadcn"
- "Create a data table"

**Features:**

- Component composition patterns
- Form handling with React Hook Form + Zod
- Data table implementations
- Theme customization strategies
- Performance optimization
- Accessibility best practices
- Next.js App Router integration

## Installation

```bash
# Clone the repository
git clone https://github.com/rizwan-mansha-developer/front-agent-skills.git
cd agent-skills

# Install dependencies
pnpm install

# Build the skills
pnpm build
```

## Development

```bash
# Validate all rules
pnpm validate

# Extract test cases
pnpm extract-tests

# Development mode (build + validate)
pnpm dev
```

## Usage

Skills are automatically available once installed. The agent will use them when relevant tasks are detected.

**Examples:**

```
Review this React component for performance issues
```

```
Help me optimize this Next.js page
```

```
Generate tests for this function
```

```
Run my tests with coverage
```

## Skill Structure

Each skill contains:

- `SKILL.md` - Instructions for the agent
- `scripts/` - Helper scripts for automation (optional)
- `references/` - Supporting documentation (optional)

## License

MIT
