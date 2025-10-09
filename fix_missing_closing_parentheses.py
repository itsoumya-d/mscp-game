#!/usr/bin/env python3

import re

def fix_missing_closing_parentheses():
    """Fix missing closing parentheses by analyzing bracket depth"""
    
    with open('lib/core/services/predefined_games_service.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    
    lines = content.split('\n')
    fixed_lines = []
    
    # Track bracket depth
    paren_depth = 0
    brace_depth = 0
    bracket_depth = 0
    
    for i, line in enumerate(lines):
        original_line = line
        
        # Count brackets in this line
        for char in line:
            if char == '(':
                paren_depth += 1
            elif char == ')':
                paren_depth -= 1
            elif char == '{':
                brace_depth += 1
            elif char == '}':
                brace_depth -= 1
            elif char == '[':
                bracket_depth += 1
            elif char == ']':
                bracket_depth -= 1
        
        # Check if this line should have a closing parenthesis
        # Look for specific patterns that indicate missing closing parentheses
        if (line.strip() == '}' and paren_depth > 0 and 
            i > 0 and any(keyword in lines[i-10:i] for keyword in ['return', 'MapEntry', 'map('])):
            # Add missing closing parenthesis before the closing brace
            fixed_lines.append('      )')
            paren_depth -= 1
            fixed_lines.append(original_line)
        elif (line.strip() == '};' and paren_depth > 0 and 
              i > 0 and any(keyword in lines[i-10:i] for keyword in ['return', 'MapEntry', 'map('])):
            # Add missing closing parenthesis before the closing brace
            fixed_lines.append('      )')
            paren_depth -= 1
            fixed_lines.append(original_line)
        elif (line.strip() == ']).toList();' and paren_depth > 0):
            # Add missing closing parenthesis before the array closing
            fixed_lines.append('      )')
            paren_depth -= 1
            fixed_lines.append(original_line)
        elif (line.strip() == '];' and paren_depth > 0 and 
              i > 0 and any('Question(' in lines[j] for j in range(max(0, i-20), i))):
            # Add missing closing parenthesis before the array closing
            fixed_lines.append('      )')
            paren_depth -= 1
            fixed_lines.append(original_line)
        else:
            fixed_lines.append(original_line)
    
    # Write the fixed content back
    with open('lib/core/services/predefined_games_service.dart', 'w', encoding='utf-8') as f:
        f.write('\n'.join(fixed_lines))
    
    print("Fixed missing closing parentheses")
    print(f"File now has {len(fixed_lines)} lines")

if __name__ == "__main__":
    fix_missing_closing_parentheses()