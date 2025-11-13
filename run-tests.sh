#!/bin/bash
# Run all tests for the project

set -e

echo "=========================================="
echo "Running Template Processor Tests"
echo "=========================================="
echo ""

python3 tests/test_template_processor.py

echo ""
echo "=========================================="
echo "Running Mermaid Normalization Tests"
echo "=========================================="
echo ""

python3 -m pytest tests/test_mermaid_normalization.py -v

echo ""
echo "=========================================="
echo "Running Numbering Tests"
echo "=========================================="
echo ""

python3 -m pytest tests/test_numbering.py -v

echo ""
echo "=========================================="
echo "✓ All tests passed!"
echo "=========================================="
