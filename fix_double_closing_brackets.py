#!/usr/bin/env python3

import re

def fix_double_closing_brackets():
    """Fix double closing brackets like )); that should be single )"""
    
    with open('lib/core/services/predefined_games_service.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    
    lines = content.split('\n')
    fixed_lines = []
    
    for i, line in enumerate(lines):
        # Fix double closing brackets
        if line.strip() == '));' and i > 0 and lines[i-1].strip() == '));':
            # Skip this line if the previous line was also ));
            continue
        elif line.strip() == '));':
            # Replace with single closing bracket
            fixed_lines.append(line.replace('));', ');'))
        else:
            fixed_lines.append(line)
    
    # Write the fixed content back
    with open('lib/core/services/predefined_games_service.dart', 'w', encoding='utf-8') as f:
        f.write('\n'.join(fixed_lines))
    
    print("Fixed double closing brackets")
    print(f"File now has {len(fixed_lines)} lines")

if __name__ == "__main__":
    fix_double_closing_brackets()