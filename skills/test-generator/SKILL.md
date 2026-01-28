---
name: test-generator
description: Generate comprehensive test cases for any feature, function, or component. Supports unit, integration, and edge case testing.
---

# Test Generator

Automatically generates comprehensive test cases for functions, components, APIs, and features. Creates test files with proper setup, mocking, and coverage for all scenarios.

## How It Works

1. Analyzes source code to identify testable units
2. Generates test cases for happy path, edge cases, and error scenarios
3. Creates proper test file structure with imports and setup
4. Includes mocking for dependencies and external services
5. Outputs test files ready to run

## Usage

```bash
bash /mnt/skills/user/test-generator/scripts/generate-tests.sh [file_path] [test_type]
```

**Arguments:**

- `file_path` - Path to source file to generate tests for
- `test_type` - Type of tests: unit, integration, e2e (defaults to unit)

**Examples:**

Generate unit tests for a React component:

```bash
bash /mnt/skills/user/test-generator/scripts/generate-tests.sh src/components/Button.tsx unit
```

Generate integration tests for an API:

```bash
bash /mnt/skills/user/test-generator/scripts/generate-tests.sh src/api/users.js integration
```

Generate all test types:

```bash
bash /mnt/skills/user/test-generator/scripts/generate-tests.sh src/utils/helpers.js all
```

## Output

```json
{
  "status": "success",
  "tests_generated": 15,
  "test_file": "src/components/__tests__/Button.test.tsx",
  "coverage_areas": [
    "props validation",
    "click handlers",
    "accessibility",
    "error states",
    "edge cases"
  ],
  "test_types": ["unit", "integration"]
}
```

## Present Results to User

**Test Generation Complete!**

✅ Generated **{tests_generated}** test cases for `{source_file}`
📁 Test file: `{test_file}`
🎯 Coverage: {coverage_areas}

**Test Categories:**

- Unit tests: {unit_count}
- Integration tests: {integration_count}
- Edge cases: {edge_count}

Run tests with: `npm test {test_file}`

## Troubleshooting

**File not found**: Ensure the source file path is correct and file exists
**Permission denied**: Check write permissions in the target directory
**Unsupported file type**: Currently supports .js, .ts, .jsx, .tsx, .py files
**Missing dependencies**: Install required testing libraries (Jest, React Testing Library, etc.)
