# Template System

Customize the header and footer content injected into each markdown file.

## Files

- `header.html` - Injected at the beginning of each file
- `footer.html` - Injected at the end of each file

## Syntax

**Variables:** `{{VARIABLE_NAME}}`
```html
<p>{{BOOK_TITLE}} by {{BOOK_AUTHORS}}</p>
```

**Conditionals:** `{{#if VARIABLE}}...{{/if}}`
```html
{{#if GIT_REPO_URL}}
<a href="{{GIT_REPO_URL}}">GitHub</a>
{{/if}}
```

**Comments:** HTML comments are automatically removed from output
```html
<!-- This comment won't appear in the generated documentation -->
<div>This content will appear</div>
```

## Available Variables

- `REPO` - Repository in `owner/repo` format
- `BOOK_TITLE` - Documentation title
- `BOOK_AUTHORS` - Authors
- `GENERATION_DATE` - When docs were generated (UTC)
- `DEEPWIKI_URL` - DeepWiki documentation URL
- `DEEPWIKI_BADGE_URL` - DeepWiki badge image URL
- `GIT_REPO_URL` - Git repository URL (if configured)
- `GITHUB_BADGE_URL` - GitHub badge image URL

## Usage

Mount your custom templates:

```bash
# Custom template directory
docker run -v "$(pwd)/my-templates:/workspace/templates" ...

# Or override individual files
docker run -v "$(pwd)/my-header.html:/workspace/templates/header.html" ...
```

**Environment Variables:**
- `TEMPLATE_DIR` - Template directory (default: `/workspace/templates`)
- `HEADER_TEMPLATE` - Header path (default: `$TEMPLATE_DIR/header.html`)
- `FOOTER_TEMPLATE` - Footer path (default: `$TEMPLATE_DIR/footer.html`)

## Examples

**Custom Header:**
```html
<div style="background: #f5f5f5; padding: 1rem;">
  <h3>{{BOOK_TITLE}}</h3>
  {{#if GIT_REPO_URL}}
  <a href="{{GIT_REPO_URL}}">Source</a>
  {{/if}}
</div>
```

**Custom Footer:**
```html
<hr>
<p style="text-align: center; color: #666;">
  Generated {{GENERATION_DATE}}
</p>
```
