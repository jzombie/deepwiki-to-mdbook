#!/usr/bin/env python3
"""
Template processor for processing HTML templates with variable substitution.
Supports {{variable}} syntax and {{#if variable}}...{{/if}} conditionals.
"""
import sys
import os
import re


def process_template(template_content, variables):
    """
    Process a template string with variable substitution and conditionals.
    
    Args:
        template_content: The template string with {{}} placeholders
        variables: Dictionary of variable names to values
    
    Returns:
        Processed template string
    """
    result = template_content
    
    # Process conditionals: {{#if VAR}}...{{/if}}
    # Match the pattern and check if the variable exists and is non-empty
    conditional_pattern = r'\{\{#if\s+(\w+)\}\}(.*?)\{\{/if\}\}'
    
    def replace_conditional(match):
        var_name = match.group(1)
        content = match.group(2)
        # Include the content if variable exists and is non-empty
        if var_name in variables and variables[var_name]:
            return content
        return ''
    
    result = re.sub(conditional_pattern, replace_conditional, result, flags=re.DOTALL)
    
    # Process simple variable substitution: {{VAR}}
    variable_pattern = r'\{\{(\w+)\}\}'
    
    def replace_variable(match):
        var_name = match.group(1)
        return variables.get(var_name, '')
    
    result = re.sub(variable_pattern, replace_variable, result)
    
    # Remove HTML comments
    result = re.sub(r'<!--.*?-->', '', result, flags=re.DOTALL)
    
    return result


def main():
    if len(sys.argv) < 2:
        print("Usage: process-template.py <template_file> [VAR=value ...]", file=sys.stderr)
        sys.exit(1)
    
    template_file = sys.argv[1]
    
    # Check if template file exists
    if not os.path.isfile(template_file):
        print(f"Error: Template file '{template_file}' not found", file=sys.stderr)
        sys.exit(1)
    
    # Parse variables from command line arguments (VAR=value format)
    variables = {}
    for arg in sys.argv[2:]:
        if '=' in arg:
            key, value = arg.split('=', 1)
            variables[key] = value
    
    # Read template file
    with open(template_file, 'r', encoding='utf-8') as f:
        template_content = f.read()
    
    # Process and output
    result = process_template(template_content, variables)
    print(result, end='')


if __name__ == '__main__':
    main()
