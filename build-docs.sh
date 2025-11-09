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
    main_pages=$(ls "$WIKI_DIR"/*.md 2>/dev/null | awk -F/ '{print $NF}' | sort -t- -k1 -n | while read fname; do echo "$WIKI_DIR/$fname"; done)
    
    # Find the first main page (usually overview/introduction)
    first_page=$(echo "$main_pages" | head -1 | xargs basename)
    if [ -n "$first_page" ]; then
        title=$(head -1 "$WIKI_DIR/$first_page" | sed 's/^# //')
        echo "[${title:-Introduction}]($first_page)"
        echo ""
    fi
    
    # Process all main pages (files in root, not in section-* directories)
    echo "$main_pages" | while read -r file; do
        [ -f "$file" ] || continue
        filename=$(basename "$file")
        
        # Skip the first page (already added as introduction)
        [ "$filename" = "$first_page" ] && continue
        
        # Extract title from first line of markdown file
        title=$(head -1 "$file" | sed 's/^# //')
        
        # Check if this page has subsections
        section_num=$(echo "$filename" | grep -oE '^[0-9]+' || true)
        section_dir="$WIKI_DIR/section-$section_num"
        
        if [ -n "$section_num" ] && [ -d "$section_dir" ]; then
            # Main section with subsections
            echo "# $title"
            echo ""
            echo "- [$title]($filename)"
            
            # Add subsections (sorted numerically by prefix)
            ls "$section_dir"/*.md 2>/dev/null | awk -F/ '{print $NF}' | sort -t- -k1 -n | while read subname; do
                subfile="$section_dir/$subname"
                [ -f "$subfile" ] || continue
                subfilename=$(basename "$subfile")
                subtitle=$(head -1 "$subfile" | sed 's/^# //')
                echo "  - [$subtitle](section-$section_num/$subfilename)"
            done
            echo ""
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

# Create badges HTML snippet
BADGES_HTML="<div class=\"project-badges\" style=\"display:flex;align-items:center;gap:0.6rem;padding:0.75rem 0 0.5rem;flex-wrap:wrap;margin-bottom:1.5rem;border-bottom:1px solid #e0e0e0;\">
<a href=\"$DEEPWIKI_URL\" target=\"_blank\" rel=\"noopener noreferrer\" style=\"display:inline-flex;text-decoration:none;\"><img src=\"$DEEPWIKI_BADGE_URL\" alt=\"DeepWiki\" style=\"height:24px;\" /></a>"

if [ -n "$GIT_REPO_URL" ]; then
    BADGES_HTML="$BADGES_HTML
<a href=\"$GIT_REPO_URL\" target=\"_blank\" rel=\"noopener noreferrer\" style=\"display:inline-flex;text-decoration:none;\"><img src=\"$GITHUB_BADGE_URL\" alt=\"GitHub\" style=\"height:24px;\" /></a>"
fi

BADGES_HTML="$BADGES_HTML
</div>

"

# Copy files and inject badges
cp -r "$WIKI_DIR"/* src/

# Inject badges at the top of each markdown file
echo "Injecting badges into markdown files..."
file_count=0
for mdfile in src/*.md src/*/*.md; do
    [ -f "$mdfile" ] || continue
    # Create temp file with badges + original content
    {
        printf '%s\n' "$BADGES_HTML"
        cat "$mdfile"
    } > "$mdfile.tmp"
    mv "$mdfile.tmp" "$mdfile"
    file_count=$((file_count + 1))
done
echo "Injected badges into $file_count files"

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
