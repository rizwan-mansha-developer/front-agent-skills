---
title: Use pnpm for Package Management
impact: MEDIUM
impactDescription: faster installs, disk space efficiency, strict dependency resolution, better monorepo support
tags: pnpm, package-manager, performance, monorepo, dependencies
---

## Use pnpm for Package Management

**Impact: MEDIUM (faster installs, disk space efficiency, strict dependency resolution, better monorepo support)**

Use pnpm instead of npm or yarn for package management. pnpm provides faster installations, better disk space efficiency, and stricter dependency resolution that prevents phantom dependencies.

**Incorrect (using npm with potential issues):**

```bash
# npm - slower, uses more disk space, allows phantom dependencies
npm install
npm run dev
npm run build

# package.json - no pnpm configuration
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  }
}
```

**Correct (using pnpm with proper configuration):**

```bash
# Install pnpm globally
npm install -g pnpm

# Use pnpm commands
pnpm install
pnpm dev
pnpm build
pnpm start

# Add dependencies
pnpm add react react-dom
pnpm add -D typescript @types/react

# Remove dependencies
pnpm remove lodash

# Update dependencies
pnpm update
pnpm update react react-dom
```

**Project configuration:**

```json
// package.json - pnpm-optimized configuration
{
  "name": "my-nextjs-app",
  "version": "1.0.0",
  "packageManager": "pnpm@8.15.0",
  "engines": {
    "node": ">=18.0.0",
    "pnpm": ">=8.0.0"
  },
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "type-check": "tsc --noEmit",
    "clean": "rm -rf .next out dist",
    "install:clean": "pnpm clean && rm -rf node_modules pnpm-lock.yaml && pnpm install"
  },
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "typescript": "^5.0.0"
  }
}

// .npmrc - pnpm configuration
# Strict peer dependencies
strict-peer-dependencies=true

# Use hard links for better performance
link-workspace-packages=true

# Hoist patterns for better compatibility
hoist-pattern[]=*eslint*
hoist-pattern[]=*prettier*

# Registry configuration
registry=https://registry.npmjs.org/

# Store directory (optional)
store-dir=~/.pnpm-store

# Auto install peers
auto-install-peers=true

# Shamefully hoist for problematic packages
shamefully-hoist=false

# Enable side effects cache
side-effects-cache=true
```

**Monorepo configuration:**

```yaml
# pnpm-workspace.yaml
packages:
  - 'apps/*'
  - 'packages/*'
  - 'tools/*'
```

```json
// Root package.json for monorepo
{
  "name": "my-monorepo",
  "private": true,
  "packageManager": "pnpm@8.15.0",
  "scripts": {
    "dev": "pnpm --parallel --recursive dev",
    "build": "pnpm --recursive build",
    "lint": "pnpm --recursive lint",
    "type-check": "pnpm --recursive type-check",
    "clean": "pnpm --recursive clean",
    "test": "pnpm --recursive test"
  },
  "devDependencies": {
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "eslint": "^8.0.0",
    "prettier": "^3.0.0",
    "typescript": "^5.0.0"
  }
}

// apps/web/package.json
{
  "name": "@monorepo/web",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "@monorepo/ui": "workspace:*",
    "@monorepo/utils": "workspace:*"
  }
}

// packages/ui/package.json
{
  "name": "@monorepo/ui",
  "version": "1.0.0",
  "main": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "default": "./dist/index.js"
    }
  },
  "scripts": {
    "build": "tsup src/index.ts --format cjs,esm --dts",
    "dev": "tsup src/index.ts --format cjs,esm --dts --watch"
  },
  "peerDependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "tsup": "^7.0.0"
  }
}
```

**Docker configuration with pnpm:**

```dockerfile
# Dockerfile
FROM node:18-alpine AS base

# Install pnpm
RUN npm install -g pnpm

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build application
RUN pnpm build

# Production stage
FROM node:18-alpine AS production

RUN npm install -g pnpm

WORKDIR /app

# Copy built application
COPY --from=base /app/.next ./.next
COPY --from=base /app/public ./public
COPY --from=base /app/package.json ./package.json
COPY --from=base /app/pnpm-lock.yaml ./pnpm-lock.yaml

# Install production dependencies only
RUN pnpm install --prod --frozen-lockfile

EXPOSE 3000

CMD ["pnpm", "start"]
```

**CI/CD configuration:**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          
      - name: Setup pnpm
        uses: pnpm/action-setup@v2
        with:
          version: 8
          
      - name: Get pnpm store directory
        shell: bash
        run: |
          echo "STORE_PATH=$(pnpm store path --silent)" >> $GITHUB_ENV
          
      - name: Setup pnpm cache
        uses: actions/cache@v3
        with:
          path: ${{ env.STORE_PATH }}
          key: ${{ runner.os }}-pnpm-store-${{ hashFiles('**/pnpm-lock.yaml') }}
          restore-keys: |
            ${{ runner.os }}-pnpm-store-
            
      - name: Install dependencies
        run: pnpm install --frozen-lockfile
        
      - name: Type check
        run: pnpm type-check
        
      - name: Lint
        run: pnpm lint
        
      - name: Test
        run: pnpm test
        
      - name: Build
        run: pnpm build
```

**Development scripts:**

```json
// package.json - enhanced scripts
{
  "scripts": {
    "dev": "next dev",
    "dev:turbo": "next dev --turbo",
    "build": "next build",
    "build:analyze": "ANALYZE=true pnpm build",
    "start": "next start",
    "lint": "next lint",
    "lint:fix": "next lint --fix",
    "type-check": "tsc --noEmit",
    "clean": "rm -rf .next out dist",
    "deps:check": "pnpm audit",
    "deps:update": "pnpm update --interactive",
    "deps:outdated": "pnpm outdated",
    "install:clean": "pnpm clean && rm -rf node_modules pnpm-lock.yaml && pnpm install"
  }
}
```

**Performance comparison:**

```bash
# Installation speed comparison
npm install     # ~45s
yarn install    # ~35s  
pnpm install    # ~25s

# Disk space usage
npm             # ~200MB node_modules
yarn            # ~180MB node_modules
pnpm            # ~120MB node_modules (with hard links)

# Monorepo performance
npm workspaces  # Slower, more disk usage
yarn workspaces # Better, but still duplicates
pnpm workspaces # Fastest, minimal duplication
```

This pattern provides:
- **Faster installations** - up to 2x faster than npm
- **Disk space efficiency** - uses hard links to save space
- **Strict dependency resolution** - prevents phantom dependencies
- **Better monorepo support** - efficient workspace management
- **Improved security** - stricter peer dependency handling
- **Better caching** - more efficient cache strategy