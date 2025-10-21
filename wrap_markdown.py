import re
import os
import sys

def wrap_line(line, max_length=80):
    """
    Wrap a line at max_length, breaking at word boundaries.
    Preserves markdown formatting and indentation.
    """
    if len(line) <= max_length:
        return [line]
    
    # Preserve leading whitespace
    leading_whitespace = len(line) - len(line.lstrip())
    indent = line[:leading_whitespace]
    content = line[leading_whitespace:]
    
    # Don't wrap certain lines
    if (content.startswith('#') or          # Headers
        content.startswith('```') or        # Code blocks
        content.startswith('http') or       # URLs
        content.startswith('- ') and '(http' in content or  # Bullet with URL
        content.strip().startswith('*') and '(http' in content):  # List item with URL
        return [line]
    
    wrapped_lines = []
    remaining = content
    
    while len(remaining) > max_length - leading_whitespace:
        # Find the best break point
        break_point = max_length - leading_whitespace
        
        # Look for word boundary
        while break_point > 0 and remaining[break_point] != ' ':
            break_point -= 1
        
        if break_point == 0:  # No good break point found
            break_point = max_length - leading_whitespace
        
        # Add the wrapped line
        wrapped_lines.append(indent + remaining[:break_point].rstrip())
        
        # Continue with remaining text, adding continuation indent for non-list items
        remaining = remaining[break_point:].lstrip()
        if not (content.startswith('*') or content.startswith('-')):
            # Add continuation indent for regular paragraphs
            if leading_whitespace == 0:
                indent = '  '
            else:
                indent = line[:leading_whitespace] + '  '
        leading_whitespace = len(indent)
    
    # Add the final piece
    if remaining:
        wrapped_lines.append(indent + remaining)
    
    return wrapped_lines

def process_markdown_file(file_path):
    """Process a markdown file and wrap long lines."""
    print(f"Processing {file_path}...")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    wrapped_lines = []
    in_code_block = False
    
    for line in lines:
        line = line.rstrip('\n\r')
        
        # Track code blocks - don't wrap content inside them
        if line.strip().startswith('```'):
            in_code_block = not in_code_block
            wrapped_lines.append(line)
            continue
        
        if in_code_block:
            wrapped_lines.append(line)
            continue
        
        # Wrap the line if it's too long
        if len(line) > 80:
            wrapped_lines.extend(wrap_line(line))
        else:
            wrapped_lines.append(line)
    
    # Write back to file
    with open(file_path, 'w', encoding='utf-8') as f:
        for line in wrapped_lines:
            f.write(line + '\n')
    
    print(f"Completed {file_path}")

def main():
    # Find all markdown files
    md_files = []
    
    # Root level markdown files
    for file in os.listdir('.'):
        if file.endswith('.md'):
            md_files.append(file)
    
    # Search subdirectories
    for root, dirs, files in os.walk('.'):
        for file in files:
            if file.endswith('.md'):
                full_path = os.path.join(root, file)
                if full_path not in md_files and not full_path.startswith('./'):
                    md_files.append(full_path)
    
    # Process each file
    for md_file in md_files:
        try:
            process_markdown_file(md_file)
        except Exception as e:
            print(f"Error processing {md_file}: {e}")

if __name__ == "__main__":
    main()