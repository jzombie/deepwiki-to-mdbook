#!/usr/bin/env python3
"""
Unit tests for the template processor.
Tests variable substitution, conditionals, and HTML comment removal.
"""
import unittest
import sys
import os

# Add tools directory to path
tools_dir = os.path.join(os.path.dirname(__file__), '..', 'tools')
sys.path.insert(0, tools_dir)

# Import the function we need to test
import importlib.util
spec = importlib.util.spec_from_file_location("process_template", os.path.join(tools_dir, "process-template.py"))
process_template_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(process_template_module)
process_template = process_template_module.process_template


class TestTemplateProcessor(unittest.TestCase):
    """Test cases for template processing functionality."""

    def test_simple_variable_substitution(self):
        """Test basic variable substitution."""
        template = "<p>{{TITLE}}</p>"
        variables = {"TITLE": "Hello World"}
        result = process_template(template, variables)
        self.assertEqual(result, "<p>Hello World</p>")

    def test_multiple_variables(self):
        """Test multiple variable substitutions."""
        template = "<h1>{{TITLE}}</h1><p>{{AUTHOR}}</p>"
        variables = {"TITLE": "My Book", "AUTHOR": "John Doe"}
        result = process_template(template, variables)
        self.assertEqual(result, "<h1>My Book</h1><p>John Doe</p>")

    def test_missing_variable(self):
        """Test that missing variables are replaced with empty string."""
        template = "<p>{{MISSING}}</p>"
        variables = {}
        result = process_template(template, variables)
        self.assertEqual(result, "<p></p>")

    def test_variable_with_empty_value(self):
        """Test variable with empty string value."""
        template = "<p>{{EMPTY}}</p>"
        variables = {"EMPTY": ""}
        result = process_template(template, variables)
        self.assertEqual(result, "<p></p>")

    def test_conditional_true(self):
        """Test conditional block when variable exists and is non-empty."""
        template = "{{#if URL}}<a href='{{URL}}'>Link</a>{{/if}}"
        variables = {"URL": "https://example.com"}
        result = process_template(template, variables)
        self.assertEqual(result, "<a href='https://example.com'>Link</a>")

    def test_conditional_false_missing(self):
        """Test conditional block when variable is missing."""
        template = "{{#if URL}}<a href='{{URL}}'>Link</a>{{/if}}"
        variables = {}
        result = process_template(template, variables)
        self.assertEqual(result, "")

    def test_conditional_false_empty(self):
        """Test conditional block when variable is empty string."""
        template = "{{#if URL}}<a href='{{URL}}'>Link</a>{{/if}}"
        variables = {"URL": ""}
        result = process_template(template, variables)
        self.assertEqual(result, "")

    def test_conditional_multiline(self):
        """Test conditional block with multiline content."""
        template = """{{#if SHOW}}
<div>
  <p>Content</p>
</div>
{{/if}}"""
        variables = {"SHOW": "yes"}
        result = process_template(template, variables)
        self.assertIn("<div>", result)
        self.assertIn("<p>Content</p>", result)

    def test_nested_variables_in_conditional(self):
        """Test variable substitution inside conditional blocks."""
        template = "{{#if NAME}}Hello {{NAME}}!{{/if}}"
        variables = {"NAME": "Alice"}
        result = process_template(template, variables)
        self.assertEqual(result, "Hello Alice!")

    def test_single_line_comment_removal(self):
        """Test removal of single-line HTML comments."""
        template = "<!-- Comment --><div>Content</div>"
        variables = {}
        result = process_template(template, variables)
        self.assertEqual(result, "<div>Content</div>")

    def test_multiline_comment_removal(self):
        """Test removal of multi-line HTML comments."""
        template = """<!-- This is a
        multi-line
        comment -->
<div>Content</div>"""
        variables = {}
        result = process_template(template, variables)
        self.assertNotIn("<!--", result)
        self.assertNotIn("comment", result)
        self.assertIn("<div>Content</div>", result)

    def test_multiple_comments_removal(self):
        """Test removal of multiple HTML comments."""
        template = """<!-- Comment 1 -->
<div>
  <!-- Comment 2 -->
  <p>Text</p>
  <!-- Comment 3 -->
</div>
<!-- Comment 4 -->"""
        variables = {}
        result = process_template(template, variables)
        self.assertNotIn("<!--", result)
        self.assertNotIn("Comment", result)
        self.assertIn("<div>", result)
        self.assertIn("<p>Text</p>", result)

    def test_comment_with_special_chars(self):
        """Test removal of comments containing special characters."""
        template = "<!-- Comment with <tags> and {{variables}} --><div>Content</div>"
        variables = {}
        result = process_template(template, variables)
        self.assertEqual(result, "<div>Content</div>")

    def test_complex_template(self):
        """Test a complex template with all features."""
        template = """<!-- Header template -->
<div class="header">
  <h1>{{TITLE}}</h1>
  <!-- Show link if available -->
  {{#if URL}}
  <a href="{{URL}}">Visit</a>
  {{/if}}
  <p>By {{AUTHOR}}</p>
</div>
<!-- End header -->"""
        variables = {
            "TITLE": "My Documentation",
            "URL": "https://example.com",
            "AUTHOR": "Test Author"
        }
        result = process_template(template, variables)
        
        # Check comments are removed
        self.assertNotIn("<!--", result)
        self.assertNotIn("Header template", result)
        
        # Check variables are substituted
        self.assertIn("My Documentation", result)
        self.assertIn("https://example.com", result)
        self.assertIn("Test Author", result)
        
        # Check structure remains
        self.assertIn("<div class=\"header\">", result)
        self.assertIn("<h1>", result)
        self.assertIn("<a href=", result)

    def test_conditional_not_shown_removes_variables(self):
        """Test that variables inside false conditionals are not processed."""
        template = "{{#if SHOW}}{{TITLE}}{{/if}}"
        variables = {"TITLE": "Should not appear"}
        result = process_template(template, variables)
        self.assertEqual(result, "")

    def test_whitespace_preservation(self):
        """Test that whitespace in content is preserved."""
        template = "<p>  {{TEXT}}  </p>"
        variables = {"TEXT": "Content"}
        result = process_template(template, variables)
        self.assertEqual(result, "<p>  Content  </p>")

    def test_special_html_characters(self):
        """Test that special HTML characters in variables are preserved."""
        template = "<p>{{TEXT}}</p>"
        variables = {"TEXT": "<script>alert('test')</script>"}
        result = process_template(template, variables)
        self.assertEqual(result, "<p><script>alert('test')</script></p>")

    def test_real_world_header_template(self):
        """Test with a real-world header template."""
        template = """<div class="project-badges">
<a href="{{DEEPWIKI_URL}}"><img src="{{DEEPWIKI_BADGE_URL}}" alt="DeepWiki" /></a>
{{#if GIT_REPO_URL}}
<a href="{{GIT_REPO_URL}}"><img src="{{GITHUB_BADGE_URL}}" alt="GitHub" /></a>
{{/if}}
</div>"""
        variables = {
            "DEEPWIKI_URL": "https://deepwiki.com/owner/repo",
            "DEEPWIKI_BADGE_URL": "https://deepwiki.com/badge.svg",
            "GIT_REPO_URL": "https://github.com/owner/repo",
            "GITHUB_BADGE_URL": "https://img.shields.io/badge/GitHub-repo"
        }
        result = process_template(template, variables)
        
        self.assertIn("https://deepwiki.com/owner/repo", result)
        self.assertIn("https://github.com/owner/repo", result)
        self.assertEqual(result.count("<a href="), 2)

    def test_real_world_footer_template(self):
        """Test with a real-world footer template."""
        template = """<hr>
<div class="doc-footer">
  <p>Documentation generated on {{GENERATION_DATE}}</p>
  {{#if GIT_REPO_URL}}
  <p>
    <a href="{{DEEPWIKI_URL}}">DeepWiki</a>
    •
    <a href="{{GIT_REPO_URL}}">{{REPO}}</a>
  </p>
  {{/if}}
</div>"""
        variables = {
            "GENERATION_DATE": "November 13, 2025 at 20:00 UTC",
            "GIT_REPO_URL": "https://github.com/owner/repo",
            "DEEPWIKI_URL": "https://deepwiki.com/owner/repo",
            "REPO": "owner/repo"
        }
        result = process_template(template, variables)
        
        self.assertIn("November 13, 2025 at 20:00 UTC", result)
        self.assertIn("owner/repo", result)
        self.assertIn("https://github.com/owner/repo", result)


class TestTemplateEdgeCases(unittest.TestCase):
    """Test edge cases and error conditions."""

    def test_empty_template(self):
        """Test processing an empty template."""
        template = ""
        variables = {"VAR": "value"}
        result = process_template(template, variables)
        self.assertEqual(result, "")

    def test_template_with_only_comments(self):
        """Test template that only contains comments."""
        template = "<!-- Comment 1 --><!-- Comment 2 -->"
        variables = {}
        result = process_template(template, variables)
        self.assertEqual(result, "")

    def test_no_variables_dictionary(self):
        """Test with empty variables dictionary."""
        template = "<p>{{VAR}}</p>"
        variables = {}
        result = process_template(template, variables)
        self.assertEqual(result, "<p></p>")

    def test_unclosed_conditional(self):
        """Test behavior with unclosed conditional (should not match)."""
        template = "{{#if VAR}}<p>Text</p>"
        variables = {"VAR": "value"}
        result = process_template(template, variables)
        # Should not process the unclosed conditional
        self.assertIn("{{#if VAR}}", result)

    def test_malformed_comment(self):
        """Test with malformed HTML comment."""
        template = "<!- Not a comment --><div>Content</div>"
        variables = {}
        result = process_template(template, variables)
        # Malformed comment should remain
        self.assertIn("<!-", result)
        self.assertIn("<div>Content</div>", result)

    def test_variable_name_with_underscore(self):
        """Test variable names with underscores."""
        template = "{{MY_VAR}}"
        variables = {"MY_VAR": "test"}
        result = process_template(template, variables)
        self.assertEqual(result, "test")

    def test_variable_name_with_numbers(self):
        """Test variable names with numbers."""
        template = "{{VAR123}}"
        variables = {"VAR123": "test"}
        result = process_template(template, variables)
        self.assertEqual(result, "test")


if __name__ == '__main__':
    # Run tests with verbose output
    unittest.main(verbosity=2)
