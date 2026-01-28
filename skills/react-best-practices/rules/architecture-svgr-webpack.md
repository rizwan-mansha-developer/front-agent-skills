---
title: Configure @svgr/webpack for Component-Based SVGs
impact: MEDIUM-HIGH
impactDescription: better performance, tree-shaking, type safety for SVG icons
tags: architecture, svg, webpack, icons, performance, tree-shaking
---

## Configure @svgr/webpack for Component-Based SVGs

**Impact: MEDIUM-HIGH (better performance, tree-shaking, type safety for SVG icons)**

Use `@svgr/webpack` to automatically convert SVG files into React components, enabling better performance, tree-shaking, and type safety compared to importing SVGs as static assets.

**Incorrect (SVG as static assets):**

```tsx
// Importing SVGs as URLs - no tree-shaking, larger bundles
import checkIcon from '@/assets/icons/check.svg'
import closeIcon from '@/assets/icons/close.svg'
import menuIcon from '@/assets/icons/menu.svg'

function Button({ icon, children }) {
  return (
    <button>
      {/* No type safety, manual sizing, no customization */}
      <img src={icon} alt="" width={16} height={16} />
      {children}
    </button>
  )
}

// Usage - not tree-shakeable, loads all icons
<Button icon={checkIcon}>Save</Button>
<Button icon={closeIcon}>Cancel</Button>
```

**Correct (@svgr/webpack configuration):**

```js
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  webpack(config) {
    // Configure SVGR
    config.module.rules.push({
      test: /\.svg$/i,
      issuer: /\.[jt]sx?$/,
      use: [
        {
          loader: "@svgr/webpack",
          options: {
            // Optimize SVGs
            svgo: true,
            svgoConfig: {
              plugins: [
                {
                  name: "preset-default",
                  params: {
                    overrides: {
                      removeViewBox: false, // Keep viewBox for scaling
                    },
                  },
                },
                "removeDimensions", // Remove width/height for responsive scaling
              ],
            },
            // Add TypeScript support
            typescript: true,
            // Make SVGs focusable for accessibility
            replaceAttrValues: {
              "#000": "currentColor", // Use currentColor for theming
            },
          },
        },
      ],
    });

    return config;
  },
};

module.exports = nextConfig;
```

**TypeScript configuration:**

```ts
// types/svg.d.ts
declare module "*.svg" {
  import { FC, SVGProps } from "react";
  const content: FC<SVGProps<SVGSVGElement>>;
  export default content;
}

// Or for more specific typing
declare module "*.svg" {
  import { ComponentType, SVGAttributes } from "react";

  interface SVGComponent extends ComponentType<SVGAttributes<SVGSVGElement>> {
    src: string; // Also available as URL if needed
  }

  const content: SVGComponent;
  export default content;
}
```

**Centralized icon system:**

```tsx
// assets/icons/index.ts - Barrel export for icons
export { default as CheckIcon } from "./check.svg";
export { default as CloseIcon } from "./close.svg";
export { default as MenuIcon } from "./menu.svg";
export { default as ArrowIcon } from "./arrow.svg";
export { default as UserIcon } from "./user.svg";

// components/ui/Icon.tsx - Wrapper component
import { SVGProps } from "react";
import * as Icons from "@/assets/icons";

type IconName = keyof typeof Icons;
type IconProps = SVGProps<SVGSVGElement> & {
  name: IconName;
  size?: number | string;
};

export function Icon({ name, size = 16, className, ...props }: IconProps) {
  const IconComponent = Icons[name];

  return (
    <IconComponent
      width={size}
      height={size}
      className={className}
      {...props}
    />
  );
}

// Usage - fully typed and tree-shakeable
import { Icon } from "@/components/ui/Icon";
import { CheckIcon } from "@/assets/icons";

function Button({ children, variant = "primary" }) {
  return (
    <button className={`btn btn-${variant}`}>
      {/* Method 1: Direct import */}
      <CheckIcon className="h-4 w-4 text-current" />

      {/* Method 2: Icon wrapper */}
      <Icon name="CheckIcon" size={16} className="text-green-500" />

      {children}
    </button>
  );
}
```

**Advanced configuration with custom templates:**

```js
// next.config.js - Advanced SVGR config
const nextConfig = {
  webpack(config) {
    config.module.rules.push({
      test: /\.svg$/i,
      issuer: /\.[jt]sx?$/,
      use: [
        {
          loader: "@svgr/webpack",
          options: {
            // Custom template for consistent component structure
            template: (variables, { tpl }) => {
              return tpl`
${variables.imports};
${variables.interfaces};

const ${variables.componentName} = (${variables.props}) => (
  ${variables.jsx}
);

${variables.componentName}.displayName = '${variables.componentName}';

${variables.exports};
`;
            },
            // Add custom props
            replaceAttrValues: {
              "#000": "currentColor",
              "#fff": "currentColor",
            },
            // Optimize for performance
            svgo: true,
            svgoConfig: {
              plugins: [
                {
                  name: "preset-default",
                  params: {
                    overrides: {
                      removeViewBox: false,
                      removeUselessStrokeAndFill: false,
                    },
                  },
                },
                "removeDimensions",
              ],
            },
            // TypeScript support
            typescript: true,
            // Add accessibility attributes
            titleProp: true,
            descProp: true,
          },
        },
      ],
    });

    return config;
  },
};
```

**Usage with accessibility:**

```tsx
// Accessible icon usage
function DeleteButton({ onDelete, itemName }) {
  return (
    <button
      onClick={onDelete}
      className="p-2 text-red-500 hover:bg-red-50"
      aria-label={`Delete ${itemName}`}
    >
      <TrashIcon
        className="h-4 w-4"
        title={`Delete ${itemName}`}
        desc="Click to permanently delete this item"
      />
    </button>
  );
}

// Themed icons
function ThemedIcon({ name, variant = "default" }) {
  const colorClasses = {
    default: "text-gray-600",
    primary: "text-blue-600",
    success: "text-green-600",
    danger: "text-red-600",
  };

  return <Icon name={name} className={`h-5 w-5 ${colorClasses[variant]}`} />;
}
```

This configuration provides:

- **Tree-shaking** - only used icons are bundled
- **Type safety** - TypeScript support for all SVG props
- **Performance** - optimized SVGs with SVGO
- **Theming** - currentColor support for CSS theming
- **Accessibility** - title and desc prop support
- **Consistency** - centralized icon management
- **Developer experience** - auto-completion and error checking

Reference: [SVGR Documentation](https://react-svgr.com/docs/webpack/)
