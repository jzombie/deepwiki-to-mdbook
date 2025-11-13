# Template System

This directory contains HTML templates for customizing the header and footer content injected into generated markdown documentation.

## Available Templates

### `header.html`
Injected at the **beginning** of each markdown file before the content.

### `footer.html`
Injected at the **end** of each markdown file after the content.

## Template Syntax

Templates support a simple handlebar-like syntax:

### Variable Substitution
Use `{{VARIABLE_NAME}}` to insert variable values:

```html
<p>Repository: {{REPO}}</p>
<p>Title: {{BOOK_TITLE}}</p>
```

### Conditionals
Use `{{#if VARIABLE}}...{{/if}}` to conditionally include content:

```html
{{#if GIT_REPO_URL}}
<a href="{{GIT_REPO_URL}}">View on GitHub</a>
{{/if}}
```

## Available Variables

The following variables are automatically available in templates:

- `DEEPWIKI_URL` - URL to the DeepWiki documentation
- `DEEPWIKI_BADGE_URL` - URL to the DeepWiki badge image
- `GIT_REPO_URL` - URL to the Git repository (if configured)
- `GITHUB_BADGE_URL` - URL to the GitHub badge image
- `REPO` - Repository in `owner/repo` format
- `BOOK_TITLE` - The title of the documentation book
- `BOOK_AUTHORS` - The authors of the documentation
- `GENERATION_DATE` - Date and time when the documentation was generated (UTC format)

## Customization

### Using Custom Templates

You can provide your own templates by:

1. **In the Docker container**: Mount a custom template directory:
   ```bash
   docker run -v /path/to/templates:/custom-templates \
     -e TEMPLATE_DIR=/custom-templates \
     ...
   ```

2. **Override specific templates**: Mount individual files:
   ```bash
   docker run -v /path/to/my-header.html:/workspace/templates/header.html \
     ...
   ```

### Environment Variables

- `TEMPLATE_DIR` - Directory containing templates (default: `/workspace/templates`)
- `HEADER_TEMPLATE` - Path to header template (default: `$TEMPLATE_DIR/header.html`)
- `FOOTER_TEMPLATE` - Path to footer template (default: `$TEMPLATE_DIR/footer.html`)

## Example: Custom Header

```html
<!-- templates/header.html -->
<div class="custom-header" style="background: #f5f5f5; padding: 1rem; margin-bottom: 2rem;">
  <h3>{{BOOK_TITLE}}</h3>
  <p>Documentation generated from <a href="{{DEEPWIKI_URL}}">DeepWiki</a></p>
  {{#if GIT_REPO_URL}}
  <p><a href="{{GIT_REPO_URL}}">Source Code</a></p>
  {{/if}}
</div>
```

## Example: Custom Footer

```html
<!-- templates/footer.html -->
<div class="custom-footer" style="border-top: 1px solid #e0e0e0; margin-top: 3rem; padding-top: 1rem;">
  <p style="text-align: center; color: #666;">
    © {{BOOK_AUTHORS}} | Generated from {{REPO}}
  </p>
</div>
```

## Disabling Templates

To disable header or footer injection:

1. **Delete the template file** - If the file doesn't exist, it won't be injected
2. **Use empty files** - Create empty `header.html` or `footer.html` files
3. **Mount empty volumes**:
   ```bash
   docker run -v /dev/null:/workspace/templates/header.html \
     ...
   ```
