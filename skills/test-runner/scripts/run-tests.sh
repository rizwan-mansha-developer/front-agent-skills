#!/bin/bash
set -e

# Test Runner Script
TEST_PATTERN="${1:-*}"
OPTIONS="$2"

echo "Starting test execution..." >&2

# Detect test framework
FRAMEWORK=""
if [ -f "package.json" ]; then
    if grep -q "jest" package.json; then
        FRAMEWORK="jest"
    elif grep -q "mocha" package.json; then
        FRAMEWORK="mocha"
    elif grep -q "vitest" package.json; then
        FRAMEWORK="vitest"
    fi
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    if command -v pytest &> /dev/null; then
        FRAMEWORK="pytest"
    elif command -v python -m unittest &> /dev/null; then
        FRAMEWORK="unittest"
    fi
fi

if [ -z "$FRAMEWORK" ]; then
    echo "Error: No supported test framework detected" >&2
    exit 1
fi

echo "Detected framework: $FRAMEWORK" >&2

# Create temp files for output
TEMP_DIR=$(mktemp -d)
RESULTS_FILE="$TEMP_DIR/results.json"
COVERAGE_FILE="$TEMP_DIR/coverage.json"

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Run tests based on framework
case "$FRAMEWORK" in
    "jest")
        echo "Running Jest tests..." >&2
        
        # Build Jest command
        JEST_CMD="npx jest"
        
        if [[ "$TEST_PATTERN" != "*" ]]; then
            JEST_CMD="$JEST_CMD $TEST_PATTERN"
        fi
        
        if [[ "$OPTIONS" == *"--coverage"* ]]; then
            JEST_CMD="$JEST_CMD --coverage --coverageReporters=json"
        fi
        
        if [[ "$OPTIONS" == *"--watch"* ]]; then
            JEST_CMD="$JEST_CMD --watch"
        fi
        
        if [[ "$OPTIONS" == *"--verbose"* ]]; then
            JEST_CMD="$JEST_CMD --verbose"
        fi
        
        # Add JSON reporter
        JEST_CMD="$JEST_CMD --json --outputFile=$RESULTS_FILE"
        
        # Execute Jest
        if eval "$JEST_CMD" 2>&1; then
            TEST_STATUS="success"
        else
            TEST_STATUS="failed"
        fi
        ;;
        
    "pytest")
        echo "Running pytest..." >&2
        
        PYTEST_CMD="python -m pytest"
        
        if [[ "$TEST_PATTERN" != "*" ]]; then
            PYTEST_CMD="$PYTEST_CMD $TEST_PATTERN"
        fi
        
        if [[ "$OPTIONS" == *"--coverage"* ]]; then
            PYTEST_CMD="$PYTEST_CMD --cov=. --cov-report=json:$COVERAGE_FILE"
        fi
        
        if [[ "$OPTIONS" == *"--verbose"* ]]; then
            PYTEST_CMD="$PYTEST_CMD -v"
        fi
        
        # Add JSON report
        PYTEST_CMD="$PYTEST_CMD --json-report --json-report-file=$RESULTS_FILE"
        
        if eval "$PYTEST_CMD" 2>&1; then
            TEST_STATUS="success"
        else
            TEST_STATUS="failed"
        fi
        ;;
        
    "mocha")
        echo "Running Mocha tests..." >&2
        
        MOCHA_CMD="npx mocha"
        
        if [[ "$TEST_PATTERN" != "*" ]]; then
            MOCHA_CMD="$MOCHA_CMD $TEST_PATTERN"
        fi
        
        if [[ "$OPTIONS" == *"--coverage"* ]]; then
            MOCHA_CMD="npx nyc $MOCHA_CMD"
        fi
        
        MOCHA_CMD="$MOCHA_CMD --reporter json > $RESULTS_FILE"
        
        if eval "$MOCHA_CMD" 2>&1; then
            TEST_STATUS="success"
        else
            TEST_STATUS="failed"
        fi
        ;;
        
    "vitest")
        echo "Running Vitest..." >&2
        
        VITEST_CMD="npx vitest run"
        
        if [[ "$OPTIONS" == *"--coverage"* ]]; then
            VITEST_CMD="$VITEST_CMD --coverage"
        fi
        
        VITEST_CMD="$VITEST_CMD --reporter=json --outputFile=$RESULTS_FILE"
        
        if eval "$VITEST_CMD" 2>&1; then
            TEST_STATUS="success"
        else
            TEST_STATUS="failed"
        fi
        ;;
esac

# Parse results based on framework
if [ -f "$RESULTS_FILE" ]; then
    case "$FRAMEWORK" in
        "jest")
            if command -v jq &> /dev/null; then
                TOTAL_TESTS=$(jq '.numTotalTests // 0' "$RESULTS_FILE")
                PASSED_TESTS=$(jq '.numPassedTests // 0' "$RESULTS_FILE")
                FAILED_TESTS=$(jq '.numFailedTests // 0' "$RESULTS_FILE")
                SKIPPED_TESTS=$(jq '.numPendingTests // 0' "$RESULTS_FILE")
                EXECUTION_TIME=$(jq -r '.testResults[0].perfStats.end - .testResults[0].perfStats.start // 0' "$RESULTS_FILE")
            else
                # Fallback parsing without jq
                TOTAL_TESTS=0
                PASSED_TESTS=0
                FAILED_TESTS=0
                SKIPPED_TESTS=0
                EXECUTION_TIME="0"
            fi
            ;;
        "pytest")
            if command -v jq &> /dev/null && [ -f "$RESULTS_FILE" ]; then
                TOTAL_TESTS=$(jq '.summary.total // 0' "$RESULTS_FILE")
                PASSED_TESTS=$(jq '.summary.passed // 0' "$RESULTS_FILE")
                FAILED_TESTS=$(jq '.summary.failed // 0' "$RESULTS_FILE")
                SKIPPED_TESTS=$(jq '.summary.skipped // 0' "$RESULTS_FILE")
                EXECUTION_TIME=$(jq -r '.duration // 0' "$RESULTS_FILE")
            else
                TOTAL_TESTS=0
                PASSED_TESTS=0
                FAILED_TESTS=0
                SKIPPED_TESTS=0
                EXECUTION_TIME="0"
            fi
            ;;
        *)
            TOTAL_TESTS=0
            PASSED_TESTS=0
            FAILED_TESTS=0
            SKIPPED_TESTS=0
            EXECUTION_TIME="0"
            ;;
    esac
else
    # Default values if no results file
    TOTAL_TESTS=0
    PASSED_TESTS=0
    FAILED_TESTS=0
    SKIPPED_TESTS=0
    EXECUTION_TIME="0"
fi

# Parse coverage if available
COVERAGE_LINES="0"
COVERAGE_FUNCTIONS="0"
COVERAGE_BRANCHES="0"
COVERAGE_STATEMENTS="0"

if [[ "$OPTIONS" == *"--coverage"* ]]; then
    case "$FRAMEWORK" in
        "jest")
            if [ -f "coverage/coverage-final.json" ] && command -v jq &> /dev/null; then
                COVERAGE_LINES=$(jq '[.[] | .l.pct] | add / length' coverage/coverage-final.json 2>/dev/null || echo "0")
                COVERAGE_FUNCTIONS=$(jq '[.[] | .f.pct] | add / length' coverage/coverage-final.json 2>/dev/null || echo "0")
                COVERAGE_BRANCHES=$(jq '[.[] | .b.pct] | add / length' coverage/coverage-final.json 2>/dev/null || echo "0")
                COVERAGE_STATEMENTS=$(jq '[.[] | .s.pct] | add / length' coverage/coverage-final.json 2>/dev/null || echo "0")
            fi
            ;;
        "pytest")
            if [ -f "$COVERAGE_FILE" ] && command -v jq &> /dev/null; then
                COVERAGE_LINES=$(jq '.totals.percent_covered // 0' "$COVERAGE_FILE")
                COVERAGE_FUNCTIONS="$COVERAGE_LINES"
                COVERAGE_BRANCHES="$COVERAGE_LINES"
                COVERAGE_STATEMENTS="$COVERAGE_LINES"
            fi
            ;;
    esac
fi

# Format execution time
if [[ "$EXECUTION_TIME" =~ ^[0-9]+$ ]]; then
    EXECUTION_TIME="${EXECUTION_TIME}ms"
elif [[ "$EXECUTION_TIME" =~ ^[0-9.]+$ ]]; then
    EXECUTION_TIME="${EXECUTION_TIME}s"
fi

echo "Test execution completed" >&2

# Output JSON result
cat << EOF
{
  "status": "$TEST_STATUS",
  "framework": "$FRAMEWORK",
  "total_tests": $TOTAL_TESTS,
  "passed": $PASSED_TESTS,
  "failed": $FAILED_TESTS,
  "skipped": $SKIPPED_TESTS,
  "coverage": {
    "lines": $COVERAGE_LINES,
    "functions": $COVERAGE_FUNCTIONS,
    "branches": $COVERAGE_BRANCHES,
    "statements": $COVERAGE_STATEMENTS
  },
  "execution_time": "$EXECUTION_TIME",
  "test_pattern": "$TEST_PATTERN",
  "options": "$OPTIONS",
  "failed_tests": []
}
EOF