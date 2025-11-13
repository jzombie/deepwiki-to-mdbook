#!/bin/bash
set -e

echo "================================================================================"
echo "DeepWiki-to-mdBook Documentation Builder"
echo "================================================================================"

# Auto-detect Git repository if REPO not set
if [ -z "$REPO" ]; then
    # Try to get the GitHub remote URL from git
    if git rev-parse --git-dir > /dev/null 2>&1; then
        GIT_REMOTE=$(git config --get remote.origin.url 2>/dev/null || echo "")
        if [ -n "$GIT_REMOTE" ]; then
            # Extract owner/repo from various GitHub URL formats
            # Supports: https://github.com/owner/repo.git, git@github.com:owner/repo.git, etc.
            REPO=$(echo "$GIT_REMOTE" | sed -E 's#.*github\.com[:/]([^/]+/[^/\.]+)(\.git)?.*#\1#')
        fi
    fi
fi

# Configuration - all can be overridden via environment variables
REPO="${REPO:-}"
BOOK_TITLE="${BOOK_TITLE:-Documentation}"
BOOK_AUTHORS="${BOOK_AUTHORS:-}"
GIT_REPO_URL="${GIT_REPO_URL:-}"
MARKDOWN_ONLY="${MARKDOWN_ONLY:-false}"  # Set to "true" to skip mdBook build (debugging)
WORK_DIR="/workspace"
WIKI_DIR="$WORK_DIR/wiki"
RAW_DIR="$WORK_DIR/raw_markdown"
OUTPUT_DIR="/output"
BOOK_DIR="$WORK_DIR/book"

# Validate REPO is set
if [ -z "$REPO" ]; then
    echo "ERROR: REPO must be set or run from within a Git repository with a GitHub remote"
    echo "Usage: REPO=owner/repo $0"
    exit 1
fi

# Extract repo parts for defaults
REPO_OWNER=$(echo "$REPO" | cut -d'/' -f1)
REPO_NAME=$(echo "$REPO" | cut -d'/' -f2)

# Set defaults if not provided
: "${BOOK_AUTHORS:=$REPO_OWNER}"
: "${GIT_REPO_URL:=https://github.com/$REPO}"

DEEPWIKI_URL="https://deepwiki.com/$REPO"
DEEPWIKI_BADGE_URL="https://deepwiki.com/badge.svg"
REPO_BADGE_LABEL=$(printf '%s' "$REPO" | sed 's/-/--/g' | sed 's/\//%2F/g')
GITHUB_BADGE_URL="https://img.shields.io/badge/GitHub-${REPO_BADGE_LABEL}-181717?logo=github"

echo ""
echo "Configuration:"
echo "  Repository:    $REPO"
echo "  Book Title:    $BOOK_TITLE"
echo "  Authors:       $BOOK_AUTHORS"
echo "  Git Repo URL:  $GIT_REPO_URL"
echo "  Markdown Only: $MARKDOWN_ONLY"

# Step 1: Scrape wiki
echo ""
echo "Step 1: Scraping wiki from DeepWiki..."
rm -rf "$RAW_DIR"
python3 /usr/local/bin/deepwiki-scraper.py "$REPO" "$WIKI_DIR"

# If markdown-only mode, skip mdBook build
if [ "$MARKDOWN_ONLY" = "true" ]; then
    echo ""
    echo "Step 2: Copying markdown files to output (markdown-only mode)..."
    rm -rf "$OUTPUT_DIR/markdown"
    mkdir -p "$OUTPUT_DIR/markdown"
    cp -r "$WIKI_DIR"/. "$OUTPUT_DIR/markdown/"
    
    if [ -d "$RAW_DIR" ]; then
        echo ""
        echo "Step 3: Copying raw markdown snapshots..."
        rm -rf "$OUTPUT_DIR/raw_markdown"
        mkdir -p "$OUTPUT_DIR/raw_markdown"
        cp -r "$RAW_DIR"/. "$OUTPUT_DIR/raw_markdown/"
    fi
    
    echo ""
    echo "================================================================================"
    echo "✓ Markdown extraction complete!"
    echo "================================================================================"
    echo ""
    echo "Outputs:"
    echo "  - Markdown files:   /output/markdown/"
    [ -d "$RAW_DIR" ] && echo "  - Raw markdown:     /output/raw_markdown/"
    echo ""
    exit 0
fi

# Step 2: Initialize mdbook structure
echo ""
echo "Step 2: Initializing mdBook structure..."
mkdir -p "$BOOK_DIR"
cd "$BOOK_DIR"

# Create book.toml
cat > book.toml <<EOF
[book]
title = "$BOOK_TITLE"
authors = ["$BOOK_AUTHORS"]
language = "en"
multilingual = false
src = "src"

[output.html]
default-theme = "rust"
git-repository-url = "$GIT_REPO_URL"

[preprocessor.mermaid]
command = "mdbook-mermaid"

[output.html.fold]
enable = true
level = 1
EOF

# Create src directory
mkdir -p src

# Step 3: Generate SUMMARY.md dynamically from scraped files
echo ""
echo "Step 3: Generating SUMMARY.md from scraped content..."

# Generate SUMMARY.md by discovering the actual file structure
{
    echo "# Summary"
    echo ""
    
    # Get all main pages sorted numerically by their numeric prefix
    # Extract the leading number, sort numerically, then get the full path back
    main_pages_list=$(ls "$WIKI_DIR"/*.md 2>/dev/null || true)
    overview_file=""
    if [ -n "$main_pages_list" ]; then
        overview_file=$(printf '%s\n' "$main_pages_list" | awk -F/ '{print $NF}' | grep -Ev '^[0-9]' | head -1)
        if [ -n "$overview_file" ] && [ -f "$WIKI_DIR/$overview_file" ]; then
            title=$(head -1 "$WIKI_DIR/$overview_file" | sed 's/^# //')
            echo "[${title:-Overview}]($overview_file)"
            echo ""
            main_pages_list=$(printf '%s\n' "$main_pages_list" | grep -v "$overview_file")
        fi
    fi
    
    main_pages=$(
        printf '%s\n' "$main_pages_list" \
        | awk -F/ '{print $NF}' \
        | grep -E '^[0-9]' \
        | sort -t- -k1 -n \
        | while read fname; do
            [ -n "$fname" ] && echo "$WIKI_DIR/$fname"
        done
    )
    
    # Process all main pages (files in root, not in section-* directories)
    echo "$main_pages" | while read -r file; do
        [ -f "$file" ] || continue
        filename=$(basename "$file")
        
        # Extract title from first line of markdown file
        title=$(head -1 "$file" | sed 's/^# //')
        
        # Check if this page has subsections
        section_num=$(echo "$filename" | grep -oE '^[0-9]+' || true)
        section_dir="$WIKI_DIR/section-$section_num"
        
        if [ -n "$section_num" ] && [ -d "$section_dir" ]; then
            # Main section with subsections
            echo "- [$title]($filename)"
            
            # Add subsections (sorted numerically by prefix)
            ls "$section_dir"/*.md 2>/dev/null | awk -F/ '{print $NF}' | sort -t- -k1 -n | while read subname; do
                subfile="$section_dir/$subname"
                [ -f "$subfile" ] || continue
                subfilename=$(basename "$subfile")
                subtitle=$(head -1 "$subfile" | sed 's/^# //')
                echo "  - [$subtitle](section-$section_num/$subfilename)"
            done
        else
            # Standalone page without subsections
            echo "- [$title]($filename)"
        fi
    done
} > src/SUMMARY.md

echo "Generated SUMMARY.md with $(grep -c '\[' src/SUMMARY.md) entries"

# Step 4: Copy markdown files to book src
echo ""
echo "Step 4: Copying and processing markdown files to book..."

# Process header and footer templates
TEMPLATE_DIR="${TEMPLATE_DIR:-/workspace/templates}"
HEADER_TEMPLATE="${HEADER_TEMPLATE:-$TEMPLATE_DIR/header.html}"
FOOTER_TEMPLATE="${FOOTER_TEMPLATE:-$TEMPLATE_DIR/footer.html}"

# Capture generation date/time
GENERATION_DATE="${GENERATION_DATE:-$(date -u '+%B %d, %Y at %H:%M UTC')}"

# Process header template if it exists
if [ -f "$HEADER_TEMPLATE" ]; then
    echo "Processing header template from $HEADER_TEMPLATE..."
    HEADER_HTML=$(python3 /usr/local/bin/process-template.py "$HEADER_TEMPLATE" \
        "DEEPWIKI_URL=$DEEPWIKI_URL" \
        "DEEPWIKI_BADGE_URL=$DEEPWIKI_BADGE_URL" \
        "GIT_REPO_URL=$GIT_REPO_URL" \
        "GITHUB_BADGE_URL=$GITHUB_BADGE_URL" \
        "REPO=$REPO" \
        "BOOK_TITLE=$BOOK_TITLE" \
        "BOOK_AUTHORS=$BOOK_AUTHORS" \
        "GENERATION_DATE=$GENERATION_DATE")
else
    echo "Warning: Header template not found at $HEADER_TEMPLATE, skipping..."
    HEADER_HTML=""
fi

# Process footer template if it exists
if [ -f "$FOOTER_TEMPLATE" ]; then
    echo "Processing footer template from $FOOTER_TEMPLATE..."
    FOOTER_HTML=$(python3 /usr/local/bin/process-template.py "$FOOTER_TEMPLATE" \
        "DEEPWIKI_URL=$DEEPWIKI_URL" \
        "DEEPWIKI_BADGE_URL=$DEEPWIKI_BADGE_URL" \
        "GIT_REPO_URL=$GIT_REPO_URL" \
        "GITHUB_BADGE_URL=$GITHUB_BADGE_URL" \
        "REPO=$REPO" \
        "BOOK_TITLE=$BOOK_TITLE" \
        "BOOK_AUTHORS=$BOOK_AUTHORS" \
        "GENERATION_DATE=$GENERATION_DATE")
else
    echo "Warning: Footer template not found at $FOOTER_TEMPLATE, skipping..."
    FOOTER_HTML=""
fi

# Copy files and inject header/footer
cp -r "$WIKI_DIR"/* src/

# Inject header and footer into markdown files
if [ -n "$HEADER_HTML" ] || [ -n "$FOOTER_HTML" ]; then
    echo "Injecting header/footer into markdown files..."
    file_count=0
    for mdfile in src/*.md src/*/*.md; do
        [ -f "$mdfile" ] || continue
        # Create temp file with header + original content + footer
        {
            [ -n "$HEADER_HTML" ] && printf '%s\n' "$HEADER_HTML"
            cat "$mdfile"
            [ -n "$FOOTER_HTML" ] && printf '%s\n' "$FOOTER_HTML"
        } > "$mdfile.tmp"
        mv "$mdfile.tmp" "$mdfile"
        file_count=$((file_count + 1))
    done
    echo "Processed $file_count files with templates"
else
    echo "No templates to inject, copying files as-is"
fi

# Step 5: Install mermaid support
echo ""
echo "Step 5: Installing mdbook-mermaid assets..."
mdbook-mermaid install "$BOOK_DIR"

# Step 6: Build the book
echo ""
echo "Step 6: Building mdBook..."
mdbook build

# Step 7: Copy outputs
echo ""
echo "Step 7: Copying outputs to /output..."
mkdir -p "$OUTPUT_DIR"

# Copy the built book
cp -r book "$OUTPUT_DIR/"

# Copy the markdown source files
rm -rf "$OUTPUT_DIR/markdown"
mkdir -p "$OUTPUT_DIR/markdown"
cp -r "$WIKI_DIR"/. "$OUTPUT_DIR/markdown/"

# Copy pre-enhancement markdown snapshots
if [ -d "$RAW_DIR" ]; then
    rm -rf "$OUTPUT_DIR/raw_markdown"
    mkdir -p "$OUTPUT_DIR/raw_markdown"
    cp -r "$RAW_DIR"/. "$OUTPUT_DIR/raw_markdown/"
fi

# Copy book configuration for reference
cp book.toml "$OUTPUT_DIR/"

echo ""
echo "================================================================================"
echo "✓ Documentation build complete!"
echo "================================================================================"
echo ""
echo "Outputs:"
echo "  - HTML book:        /output/book/"
echo "  - Markdown files:   /output/markdown/"
[ -d "$RAW_DIR" ] && echo "  - Raw markdown:      /output/raw_markdown/"
echo "  - Book config:      /output/book.toml"
echo ""
echo "To serve the book locally:"
echo "  cd output && python3 -m http.server --directory book 8000"
echo ""
