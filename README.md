# DeepWiki-to-mdBook Converter

[![Ask DeepWiki][deepwiki-badge]][deepwiki-page]

**Work in Progress**

Extracts documentation from [DeepWiki.com](https://deepwiki.com) and builds it into searchable HTML with [mdBook](https://rust-lang.github.io/mdBook/).

- [View this project on DeepWiki](https://deepwiki.com/jzombie/deepwiki-to-mdbook)
- [View example output](https://docs.deepwiki-to-mdbook.zenosmosis.com)

## Quick Start

```bash
# Build the Docker image
docker build -t deepwiki-to-mdbook .

# Generate documentation
docker run --rm \
  -e REPO="owner/repo" \
  -e BOOK_TITLE="My Documentation" \
  -v "$(pwd)/output:/output" \
  deepwiki-to-mdbook

# Serve locally
cd output && python3 -m http.server --directory book 8000
```

Open http://localhost:8000 in your browser.

## Configuration

**Core Settings:**
- `REPO` - GitHub repository (owner/repo) - auto-detected from git remote
- `BOOK_TITLE` - Documentation title (default: "Documentation")
- `BOOK_AUTHORS` - Author names (default: repo owner)
- `MARKDOWN_ONLY` - Set to "true" to skip HTML build

**Template Customization:**

Customize header/footer content by mounting your own HTML templates:

```bash
docker run --rm \
  -e REPO="owner/repo" \
  -v "$(pwd)/my-templates:/workspace/templates" \
  -v "$(pwd)/output:/output" \
  deepwiki-to-mdbook
```

Templates use `{{VARIABLE}}` syntax. Available variables: `REPO`, `BOOK_TITLE`, `BOOK_AUTHORS`, `GIT_REPO_URL`, `DEEPWIKI_URL`, `GENERATION_DATE`. See [templates/README.md](templates/README.md) for details.

## Output

- `output/book/` - Searchable HTML documentation with mermaid diagrams
- `output/markdown/` - Source markdown files
- `output/raw_markdown/` - Pre-enhanced markdown (for debugging)
- `output/book.toml` - mdBook configuration

## GitHub Action

Use in other repositories:

```yaml
- uses: jzombie/deepwiki-to-mdbook@main
  with:
    repo: owner/target-repo
    book_title: "Target Docs"
    output_dir: ./docs-output
```

## How It Works

1. Scrapes wiki pages from DeepWiki and converts to markdown
2. Extracts and intelligently places mermaid diagrams using fuzzy matching
3. Builds searchable HTML documentation with mdBook

Built with Python 3.12, mdBook, and mdbook-mermaid in a multi-stage Docker image.

## Development

Run tests: `./scripts/run-tests.sh`

**Project Structure:**
- `python/` - Python scripts and tests
- `scripts/` - Shell scripts
- `templates/` - HTML templates

[deepwiki-page]: https://deepwiki.com/jzombie/deepwiki-to-mdbook
[deepwiki-badge]: https://deepwiki.com/badge.svg
