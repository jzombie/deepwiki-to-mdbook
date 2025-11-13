#!/bin/bash
# Run all tests for the project

set -e

echo "=========================================="
echo "Running Template Processor Tests"
echo "=========================================="
echo ""

python3 python/tests/test_template_processor.py

PYTEST_AVAILABLE=false
if command -v pytest &> /dev/null; then
    PYTEST_AVAILABLE=true
    echo ""
    echo "=========================================="
    echo "Running Mermaid Normalization Tests"
    echo "=========================================="
    echo ""
    
    python3 -m pytest python/tests/test_mermaid_normalization.py -v
    
    echo ""
    echo "=========================================="
    echo "Running Numbering Tests"
    echo "=========================================="
    echo ""
    
    python3 -m pytest python/tests/test_numbering.py -v
fi

echo ""
echo "=========================================="
if [ "$PYTEST_AVAILABLE" = true ]; then
    echo "✓ All tests passed!"
else
    echo "⚠ Template tests passed (mermaid/numbering tests skipped)"
    echo ""
    echo "Note: pytest not found, install with: pip install pytest"
fi
echo "=========================================="
