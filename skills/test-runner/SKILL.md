---
name: test-runner
description: Execute and manage test suites with detailed reporting. Run specific tests, generate coverage reports, and analyze test results.
---

# Test Runner

Execute test suites with comprehensive reporting, coverage analysis, and result management. Supports multiple test frameworks and provides detailed insights into test performance and coverage.

## How It Works

1. Detects test framework (Jest, Mocha, pytest, etc.)
2. Runs specified tests or entire test suite
3. Generates coverage reports and performance metrics
4. Analyzes test results and identifies failures
5. Provides actionable insights and recommendations

## Usage

```bash
bash /mnt/skills/user/test-runner/scripts/run-tests.sh [test_pattern] [options]
```

**Arguments:**

- `test_pattern` - Test file pattern or specific test (defaults to all tests)
- `options` - Additional options: --coverage, --watch, --verbose

**Examples:**

Run all tests with coverage:

```bash
bash /mnt/skills/user/test-runner/scripts/run-tests.sh "*" --coverage
```

Run specific test file:

```bash
bash /mnt/skills/user/test-runner/scripts/run-tests.sh "Button.test.tsx"
```

Run tests in watch mode:

```bash
bash /mnt/skills/user/test-runner/scripts/run-tests.sh "*" --watch
```

Run tests with verbose output:

```bash
bash /mnt/skills/user/test-runner/scripts/run-tests.sh "api/*.test.js" --verbose
```

## Output

```json
{
  "status": "success",
  "total_tests": 45,
  "passed": 42,
  "failed": 3,
  "skipped": 0,
  "coverage": {
    "lines": 85.2,
    "functions": 90.1,
    "branches": 78.5,
    "statements": 86.7
  },
  "execution_time": "12.34s",
  "failed_tests": [
    {
      "test": "Button should handle click",
      "file": "Button.test.tsx",
      "error": "Expected function to be called"
    }
  ]
}
```

## Present Results to User

**Test Results Summary**

✅ **{passed}** passed | ❌ **{failed}** failed | ⏭️ **{skipped}** skipped
⏱️ Execution time: **{execution_time}**

**Coverage Report:**

- Lines: {coverage.lines}%
- Functions: {coverage.functions}%
- Branches: {coverage.branches}%
- Statements: {coverage.statements}%

**Failed Tests:**
{failed_tests_list}

**Recommendations:**

- Increase test coverage for uncovered lines
- Fix failing tests before deployment
- Consider adding edge case tests

## Troubleshooting

**No tests found**: Check test file patterns and directory structure
**Test framework not detected**: Ensure package.json has testing dependencies
**Coverage tool missing**: Install coverage tools (nyc, jest --coverage)
**Permission errors**: Check file permissions and directory access
**Memory issues**: Increase Node.js memory limit with --max-old-space-size
