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
        content.startswith('http')):        # URLs only (not embedded in text)
        return [line]
    
    wrapped_lines = []
    remaining = content
    
    while len(remaining) > max_length - leading_whitespace:
        # Find the best break point
        break_point = max_length - leading_whitespace
        
        # Avoid breaking inside markdown links [text](url)
        # Find if we're inside a markdown link
        link_start = remaining.rfind('[', 0, break_point)
        link_end = remaining.find(')', link_start) if link_start >= 0 else -1
        
        if link_start >= 0 and link_end > break_point:
            # We're trying to break inside a markdown link
            # Break before the link starts
            if link_start > 0:
                break_point = link_start
                # Find word boundary before the link
                while break_point > 0 and remaining[break_point - 1] != ' ':
                    break_point -= 1
                if break_point == 0:
                    # Can't break before link, break after it instead
                    break_point = link_end + 1
            else:
                # Link starts at beginning, break after it
                break_point = link_end + 1
        else:
            # Look for word boundary
            while break_point > 0 and remaining[break_point] != ' ':
                break_point -= 1
        
        if break_point == 0:  # No good break point found
            break_point = max_length - leading_whitespace
        
        # Add the wrapped line
        wrapped_lines.append(indent + remaining[:break_point].rstrip())
        
        # Continue with remaining text, adding continuation indent
        remaining = remaining[break_point:].lstrip()
        
        # For list items, indent to align with the text after the bullet
        if content.startswith('- ') or content.startswith('* '):
            if leading_whitespace == 0 and len(wrapped_lines) == 1:
                indent = '  '  # Standard 2-space indent for list continuation
        elif not (content.startswith('*') or content.startswith('-')):
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
    
    # Search all directories including root
    for root, dirs, files in os.walk('.'):
        # Skip .git directory but not .github
        if '/.git/' in root or root == './.git':
            continue
            
        for file in files:
            if file.endswith('.md'):
                full_path = os.path.join(root, file)
                md_files.append(full_path)
    
    # Process each file
    for md_file in md_files:
        try:
            process_markdown_file(md_file)
        except Exception as e:
            print(f"Error processing {md_file}: {e}")

if __name__ == "__main__":
    main()