#!/usr/bin/env python3

def fix_comprehensive_brackets(file_path):
    """Fix all bracket and parentheses issues comprehensively."""
    
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    fixed_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Fix specific patterns that are causing issues
        
        # Pattern 1: MapEntry calls missing closing parenthesis
        if 'MapEntry(' in line and not line.strip().endswith(');') and not line.strip().endswith('),'):
            # Look ahead to find where this should close
            j = i + 1
            paren_depth = line.count('(') - line.count(')')
            
            while j < len(lines) and paren_depth > 0:
                next_line = lines[j]
                paren_depth += next_line.count('(') - next_line.count(')')
                
                if (next_line.strip() == ');' or 
                    next_line.strip() == '}' or
                    next_line.strip().startswith('return ') or
                    'MapEntry(' in next_line):
                    # Add missing closing parenthesis
                    fixed_lines.append(line)
                    for k in range(i + 1, j):
                        fixed_lines.append(lines[k])
                    
                    # Add the missing closing parenthesis
                    indent = '      '  # Match indentation
                    fixed_lines.append(f'{indent}));\n')
                    i = j
                    break
                j += 1
            else:
                fixed_lines.append(line)
                i += 1
        
        # Pattern 2: Constructor calls ending with ),
        elif line.strip().endswith('),') and i + 1 < len(lines):
            next_line = lines[i + 1]
            if next_line.strip() == '}':
                # This constructor call is missing a closing parenthesis
                fixed_lines.append(line.rstrip().rstrip(',') + ');\n')
                i += 1
            else:
                fixed_lines.append(line)
                i += 1
        
        # Pattern 3: Lines ending with }); that should be });
        elif line.strip() == '});':
            # Check if previous context suggests this should be );
            if i > 0 and ('return ' in lines[i-1] or 'MapEntry(' in lines[i-1]):
                fixed_lines.append(line.replace('});', ');'))
            else:
                fixed_lines.append(line)
            i += 1
        
        # Pattern 4: Missing closing parenthesis before }
        elif line.strip() == '}' and i > 0:
            prev_line = lines[i - 1].strip()
            if (prev_line.endswith(',') and 
                ('UserProgress.fromJson(' in prev_line or 
                 'SubjectType.values.firstWhere(' in prev_line or
                 'MapEntry(' in prev_line)):
                # Insert missing closing parenthesis
                fixed_lines.append('      ));\n')
                fixed_lines.append(line)
            else:
                fixed_lines.append(line)
            i += 1
        
        # Pattern 5: Missing closing parenthesis before ];
        elif line.strip() == '];' and i > 0:
            # Check if we're in a context that needs closing parentheses
            context_lines = []
            for k in range(max(0, i - 10), i):
                context_lines.append(lines[k])
            
            context = ''.join(context_lines)
            open_parens = context.count('(') - context.count(')')
            
            if open_parens > 0:
                # Add missing closing parentheses
                indent = '    '
                for _ in range(open_parens):
                    fixed_lines.append(f'{indent})\n')
            
            fixed_lines.append(line)
            i += 1
        
        else:
            fixed_lines.append(line)
            i += 1
    
    # Write the fixed content back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(fixed_lines)
    
    print(f"Fixed comprehensive brackets. File now has {len(fixed_lines)} lines.")

if __name__ == "__main__":
    fix_comprehensive_brackets("E:/sp/lib/core/services/predefined_games_service.dart")