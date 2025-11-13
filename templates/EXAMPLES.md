# Custom Template Examples

This directory contains example templates showing different customization options.

## Minimal Header (Badges Only)

**File: `minimal-header.html`**

The default template - shows DeepWiki and GitHub badges:

```html
<div class="project-badges" style="display:flex;align-items:center;gap:0.6rem;padding:0.75rem 0 0.5rem;flex-wrap:wrap;margin-bottom:1.5rem;border-bottom:1px solid #e0e0e0;">
<a href="{{DEEPWIKI_URL}}" target="_blank" rel="noopener noreferrer" style="display:inline-flex;text-decoration:none;"><img src="{{DEEPWIKI_BADGE_URL}}" alt="DeepWiki" style="height:24px;" /></a>
{{#if GIT_REPO_URL}}
<a href="{{GIT_REPO_URL}}" target="_blank" rel="noopener noreferrer" style="display:inline-flex;text-decoration:none;"><img src="{{GITHUB_BADGE_URL}}" alt="GitHub" style="height:24px;" /></a>
{{/if}}
</div>

```

## Full Header with Title

**File: `full-header.html`**

Includes project title and description:

```html
<div class="doc-header" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 2rem; margin-bottom: 2rem; border-radius: 8px;">
  <h1 style="margin: 0 0 0.5rem 0; color: white;">{{BOOK_TITLE}}</h1>
  <p style="margin: 0; opacity: 0.9;">Documentation for {{REPO}}</p>
  <div style="margin-top: 1rem; display: flex; gap: 0.5rem;">
    <a href="{{DEEPWIKI_URL}}" target="_blank" style="background: rgba(255,255,255,0.2); padding: 0.5rem 1rem; border-radius: 4px; color: white; text-decoration: none;">📚 DeepWiki</a>
    {{#if GIT_REPO_URL}}
    <a href="{{GIT_REPO_URL}}" target="_blank" style="background: rgba(255,255,255,0.2); padding: 0.5rem 1rem; border-radius: 4px; color: white; text-decoration: none;">💻 GitHub</a>
    {{/if}}
  </div>
</div>

```

## Simple Footer

**File: `simple-footer.html`**

```html
<hr style="margin-top: 3rem; border: none; border-top: 1px solid #e0e0e0;">

<div class="doc-footer" style="text-align: center; padding: 2rem 0; color: #666;">
  <p>Documentation built from <a href="{{DEEPWIKI_URL}}">DeepWiki</a></p>
  <p style="font-size: 0.875rem;">{{BOOK_AUTHORS}} • {{REPO}}</p>
  <p style="font-size: 0.75rem; margin-top: 0.5rem; color: #999;">Generated on {{GENERATION_DATE}}</p>
</div>

```

## Footer with Navigation

**File: `nav-footer.html`**

```html
<hr style="margin-top: 3rem; border: none; border-top: 2px solid #e0e0e0;">

<div class="doc-footer" style="padding: 2rem 0;">
  <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem;">
    <div>
      <p style="margin: 0; font-weight: bold;">{{BOOK_TITLE}}</p>
      <p style="margin: 0.25rem 0 0 0; font-size: 0.875rem; color: #666;">by {{BOOK_AUTHORS}}</p>
      <p style="margin: 0.25rem 0 0 0; font-size: 0.75rem; color: #999;">Generated {{GENERATION_DATE}}</p>
    </div>
    <div style="display: flex; gap: 1rem;">
      <a href="{{DEEPWIKI_URL}}" target="_blank" style="color: #667eea; text-decoration: none;">DeepWiki</a>
      {{#if GIT_REPO_URL}}
      <a href="{{GIT_REPO_URL}}" target="_blank" style="color: #667eea; text-decoration: none;">GitHub</a>
      <a href="{{GIT_REPO_URL}}/issues" target="_blank" style="color: #667eea; text-decoration: none;">Issues</a>
      {{/if}}
    </div>
  </div>
</div>

```

## Usage

To use any of these examples:

1. Copy the desired template content to a file
2. Mount it when running Docker:

```bash
# Using a custom header only
docker run --rm \
  -e REPO="owner/repo" \
  -v "$(pwd)/my-custom-header.html:/workspace/templates/header.html" \
  -v "$(pwd)/output:/output" \
  deepwiki-to-mdbook

# Using both custom header and footer
docker run --rm \
  -e REPO="owner/repo" \
  -v "$(pwd)/my-templates:/workspace/templates" \
  -v "$(pwd)/output:/output" \
  deepwiki-to-mdbook
```

## Tips

- Keep styling inline for maximum compatibility with mdBook
- Test with different mdBook themes (rust, navy, coal, light, ayu)
- Use subtle colors and borders to avoid overwhelming the content
- Remember that templates are injected into markdown, which is then converted to HTML
- Use `{{#if VARIABLE}}` to make content conditional based on configuration
