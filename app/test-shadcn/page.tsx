import { Button } from "@/components/ui/button";

export default function TestPage() {
  return (
    <div className="container mx-auto py-8">
      <h1 className="mb-4 text-2xl font-bold">Shadcn/UI Test Page</h1>
      <div className="flex flex-col gap-4">
        <Button>Default Button</Button>
        <Button variant="destructive">Destructive Button</Button>
        <Button variant="outline">Outline Button</Button>
        <Button variant="secondary">Secondary Button</Button>
        <Button variant="ghost">Ghost Button</Button>
        <Button variant="link">Link Button</Button>
      </div>
    </div>
  );
}
