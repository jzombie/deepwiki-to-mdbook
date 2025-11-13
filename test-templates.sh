#!/bin/bash
# Test script to verify the template system works correctly

set -e

echo "=========================================="
echo "Template System Test"
echo "=========================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_PROCESSOR="$SCRIPT_DIR/tools/process-template.py"
HEADER_TEMPLATE="$SCRIPT_DIR/templates/header.html"
FOOTER_TEMPLATE="$SCRIPT_DIR/templates/footer.html"

# Test 1: Variable substitution
echo "Test 1: Variable substitution with all variables"
echo "------------------------------------------------"
output=$(python3 "$TEMPLATE_PROCESSOR" "$HEADER_TEMPLATE" \
    "DEEPWIKI_URL=https://deepwiki.com/test/repo" \
    "DEEPWIKI_BADGE_URL=https://deepwiki.com/badge.svg" \
    "GIT_REPO_URL=https://github.com/test/repo" \
    "GITHUB_BADGE_URL=https://img.shields.io/badge/test" \
    "REPO=test/repo" \
    "BOOK_TITLE=Test Book" \
    "BOOK_AUTHORS=Test Author")

if echo "$output" | grep -q "deepwiki.com/test/repo"; then
    echo "✓ DEEPWIKI_URL substituted correctly"
else
    echo "✗ DEEPWIKI_URL not found"
    exit 1
fi

if echo "$output" | grep -q "github.com/test/repo"; then
    echo "✓ GIT_REPO_URL substituted correctly"
else
    echo "✗ GIT_REPO_URL not found"
    exit 1
fi

echo ""

# Test 2: Conditional inclusion
echo "Test 2: Conditional with GIT_REPO_URL present"
echo "------------------------------------------------"
output_with_git=$(python3 "$TEMPLATE_PROCESSOR" "$HEADER_TEMPLATE" \
    "DEEPWIKI_URL=https://deepwiki.com/test/repo" \
    "DEEPWIKI_BADGE_URL=https://deepwiki.com/badge.svg" \
    "GIT_REPO_URL=https://github.com/test/repo" \
    "GITHUB_BADGE_URL=https://img.shields.io/badge/test" \
    "REPO=test/repo")

if echo "$output_with_git" | grep -q "github.com/test/repo"; then
    echo "✓ GitHub badge included when GIT_REPO_URL is set"
else
    echo "✗ GitHub badge not found when expected"
    exit 1
fi

echo ""

# Test 3: Conditional exclusion
echo "Test 3: Conditional with GIT_REPO_URL absent"
echo "------------------------------------------------"
output_without_git=$(python3 "$TEMPLATE_PROCESSOR" "$HEADER_TEMPLATE" \
    "DEEPWIKI_URL=https://deepwiki.com/test/repo" \
    "DEEPWIKI_BADGE_URL=https://deepwiki.com/badge.svg" \
    "REPO=test/repo")

if echo "$output_without_git" | grep -q "github.com"; then
    echo "✗ GitHub badge incorrectly included"
    exit 1
else
    echo "✓ GitHub badge excluded when GIT_REPO_URL is not set"
fi

if echo "$output_without_git" | grep -q "deepwiki.com/test/repo"; then
    echo "✓ DeepWiki badge still included"
else
    echo "✗ DeepWiki badge not found"
    exit 1
fi

echo ""

# Test 4: Footer template
echo "Test 4: Footer template processing"
echo "------------------------------------------------"
footer_output=$(python3 "$TEMPLATE_PROCESSOR" "$FOOTER_TEMPLATE" \
    "REPO=test/repo" \
    "BOOK_TITLE=Test Book")

echo "✓ Footer template processed ($(echo "$footer_output" | wc -c) bytes)"

echo ""
echo "=========================================="
echo "All tests passed! ✓"
echo "=========================================="
