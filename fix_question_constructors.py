#!/usr/bin/env python3

def fix_question_constructors(file_path):
    """Fix missing closing parentheses for Question constructors."""
    
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    fixed_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        fixed_lines.append(line)
        
        # Check if this line starts a Question constructor
        if 'Question(' in line.strip():
            # Track bracket depth starting from this line
            bracket_depth = 0
            paren_depth = 0
            
            # Count brackets in the current line
            for char in line:
                if char == '(':
                    paren_depth += 1
                elif char == ')':
                    paren_depth -= 1
                elif char == '{':
                    bracket_depth += 1
                elif char == '}':
                    bracket_depth -= 1
            
            # Look ahead to find where this Question constructor should end
            j = i + 1
            while j < len(lines) and (paren_depth > 0 or bracket_depth > 0):
                next_line = lines[j]
                
                # Count brackets in the next line
                for char in next_line:
                    if char == '(':
                        paren_depth += 1
                    elif char == ')':
                        paren_depth -= 1
                    elif char == '{':
                        bracket_depth += 1
                    elif char == '}':
                        bracket_depth -= 1
                
                fixed_lines.append(next_line)
                j += 1
                
                # If we find another Question( or EducationalGame( or end of method, we need to close
                if ('Question(' in next_line.strip() or 
                    'EducationalGame(' in next_line.strip() or
                    next_line.strip().startswith('return ') or
                    next_line.strip() == '];' or
                    next_line.strip() == '}' or
                    'subject: SubjectType.' in next_line):
                    
                    # If we still have open parentheses, close them
                    if paren_depth > 0:
                        # Insert closing parentheses before this line
                        fixed_lines.pop()  # Remove the line we just added
                        
                        # Add the missing closing parentheses
                        indent = '            '  # Match typical indentation
                        fixed_lines.append(f'{indent}),\n')
                        
                        # Add back the line we removed
                        fixed_lines.append(next_line)
                        paren_depth = 0
                    break
            
            i = j
        else:
            i += 1
    
    # Write the fixed content back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(fixed_lines)
    
    print(f"Fixed Question constructors. File now has {len(fixed_lines)} lines.")

if __name__ == "__main__":
    fix_question_constructors("E:/sp/lib/core/services/predefined_games_service.dart")