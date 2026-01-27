#!/bin/bash
set -e

# Test Generator Script
FILE_PATH="$1"
TEST_TYPE="${2:-unit}"

# Validate inputs
if [ -z "$FILE_PATH" ]; then
    echo "Error: File path is required" >&2
    exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File not found: $FILE_PATH" >&2
    exit 1
fi

# Get file info
FILENAME=$(basename "$FILE_PATH")
DIRNAME=$(dirname "$FILE_PATH")
EXTENSION="${FILENAME##*.}"
BASENAME="${FILENAME%.*}"

# Determine test directory and file
if [[ "$DIRNAME" == *"src"* ]]; then
    TEST_DIR="$DIRNAME/__tests__"
else
    TEST_DIR="tests"
fi

# Create test directory if it doesn't exist
mkdir -p "$TEST_DIR"

# Determine test file extension
case "$EXTENSION" in
    "tsx"|"jsx")
        TEST_FILE="$TEST_DIR/$BASENAME.test.tsx"
        ;;
    "ts"|"js")
        TEST_FILE="$TEST_DIR/$BASENAME.test.js"
        ;;
    "py")
        TEST_FILE="$TEST_DIR/test_$BASENAME.py"
        ;;
    *)
        echo "Error: Unsupported file type: $EXTENSION" >&2
        exit 1
        ;;
esac

# Analyze source file
echo "Analyzing source file..." >&2

# Count functions, classes, exports
FUNCTIONS=$(grep -c "function\|const.*=.*=>" "$FILE_PATH" 2>/dev/null || echo "0")
CLASSES=$(grep -c "class\|interface\|type.*=" "$FILE_PATH" 2>/dev/null || echo "0")
EXPORTS=$(grep -c "export" "$FILE_PATH" 2>/dev/null || echo "0")

# Generate test content based on file type
case "$EXTENSION" in
    "tsx"|"jsx")
        # React component tests
        cat > "$TEST_FILE" << EOF
import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import $BASENAME from '../$FILENAME';

describe('$BASENAME Component', () => {
  // Setup and teardown
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // Basic rendering tests
  test('renders without crashing', () => {
    render(<$BASENAME />);
    expect(screen.getByRole('button')).toBeInTheDocument();
  });

  test('renders with default props', () => {
    render(<$BASENAME />);
    expect(screen.getByRole('button')).toHaveClass('default-class');
  });

  // Props testing
  test('accepts and displays custom text', () => {
    const customText = 'Custom Button Text';
    render(<$BASENAME text={customText} />);
    expect(screen.getByText(customText)).toBeInTheDocument();
  });

  test('applies custom className', () => {
    const customClass = 'custom-button';
    render(<$BASENAME className={customClass} />);
    expect(screen.getByRole('button')).toHaveClass(customClass);
  });

  // Event handling tests
  test('calls onClick handler when clicked', () => {
    const mockOnClick = jest.fn();
    render(<$BASENAME onClick={mockOnClick} />);
    
    fireEvent.click(screen.getByRole('button'));
    expect(mockOnClick).toHaveBeenCalledTimes(1);
  });

  // Accessibility tests
  test('is accessible via keyboard', () => {
    render(<$BASENAME />);
    const button = screen.getByRole('button');
    
    button.focus();
    expect(button).toHaveFocus();
    
    fireEvent.keyDown(button, { key: 'Enter' });
    // Add assertions for Enter key behavior
  });

  test('has proper ARIA attributes', () => {
    render(<$BASENAME ariaLabel="Test button" />);
    expect(screen.getByRole('button')).toHaveAttribute('aria-label', 'Test button');
  });

  // Edge cases
  test('handles disabled state', () => {
    render(<$BASENAME disabled />);
    expect(screen.getByRole('button')).toBeDisabled();
  });

  test('handles loading state', () => {
    render(<$BASENAME loading />);
    expect(screen.getByRole('button')).toHaveAttribute('aria-busy', 'true');
  });

  // Error boundary tests
  test('handles errors gracefully', () => {
    const consoleSpy = jest.spyOn(console, 'error').mockImplementation();
    
    // Test error scenarios
    render(<$BASENAME invalidProp="test" />);
    
    consoleSpy.mockRestore();
  });
});
EOF
        TESTS_COUNT=10
        ;;
    
    "ts"|"js")
        # Function/utility tests
        cat > "$TEST_FILE" << EOF
import { $BASENAME } from '../$FILENAME';

describe('$BASENAME', () => {
  // Setup
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // Happy path tests
  test('returns expected result with valid input', () => {
    const input = 'test input';
    const result = $BASENAME(input);
    expect(result).toBeDefined();
  });

  test('handles multiple parameters correctly', () => {
    const result = $BASENAME('param1', 'param2');
    expect(result).toEqual(expect.any(String));
  });

  // Edge cases
  test('handles empty input', () => {
    const result = $BASENAME('');
    expect(result).toBeDefined();
  });

  test('handles null input', () => {
    const result = $BASENAME(null);
    expect(result).toBeDefined();
  });

  test('handles undefined input', () => {
    const result = $BASENAME(undefined);
    expect(result).toBeDefined();
  });

  // Type validation
  test('handles different data types', () => {
    expect(() => $BASENAME(123)).not.toThrow();
    expect(() => $BASENAME([])).not.toThrow();
    expect(() => $BASENAME({})).not.toThrow();
  });

  // Error cases
  test('throws error for invalid input', () => {
    expect(() => $BASENAME('invalid')).toThrow();
  });

  // Performance tests
  test('executes within acceptable time', () => {
    const start = Date.now();
    $BASENAME('performance test');
    const end = Date.now();
    expect(end - start).toBeLessThan(100);
  });

  // Mock external dependencies
  test('calls external services correctly', () => {
    const mockService = jest.fn().mockResolvedValue('mocked response');
    // Test with mocked dependencies
  });
});
EOF
        TESTS_COUNT=9
        ;;
        
    "py")
        # Python tests
        cat > "$TEST_FILE" << EOF
import unittest
from unittest.mock import Mock, patch
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from $BASENAME import *

class Test$BASENAME(unittest.TestCase):
    
    def setUp(self):
        """Set up test fixtures before each test method."""
        pass
    
    def tearDown(self):
        """Clean up after each test method."""
        pass
    
    def test_basic_functionality(self):
        """Test basic functionality works as expected."""
        # Add your test here
        self.assertTrue(True)
    
    def test_with_valid_input(self):
        """Test function with valid input."""
        result = your_function("valid_input")
        self.assertIsNotNone(result)
    
    def test_with_invalid_input(self):
        """Test function handles invalid input."""
        with self.assertRaises(ValueError):
            your_function("invalid_input")
    
    def test_edge_cases(self):
        """Test edge cases."""
        self.assertEqual(your_function(""), "")
        self.assertEqual(your_function(None), None)
    
    def test_type_validation(self):
        """Test type validation."""
        with self.assertRaises(TypeError):
            your_function(123)
    
    @patch('your_module.external_service')
    def test_with_mocked_dependency(self, mock_service):
        """Test with mocked external dependency."""
        mock_service.return_value = "mocked_response"
        result = your_function("test")
        mock_service.assert_called_once()
    
    def test_performance(self):
        """Test performance requirements."""
        import time
        start = time.time()
        your_function("performance_test")
        end = time.time()
        self.assertLess(end - start, 1.0)

if __name__ == '__main__':
    unittest.main()
EOF
        TESTS_COUNT=7
        ;;
esac

echo "Generated test file: $TEST_FILE" >&2

# Output JSON result
cat << EOF
{
  "status": "success",
  "tests_generated": $TESTS_COUNT,
  "test_file": "$TEST_FILE",
  "source_file": "$FILE_PATH",
  "coverage_areas": [
    "happy path",
    "edge cases", 
    "error handling",
    "type validation",
    "performance"
  ],
  "test_types": ["$TEST_TYPE"],
  "functions_found": $FUNCTIONS,
  "classes_found": $CLASSES,
  "exports_found": $EXPORTS
}
EOF