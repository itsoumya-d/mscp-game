import re

# Read the file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Find patterns where we have parameters without Question( opening
# Look for lines that start with id: that should be inside Question constructors
lines = content.split('\n')
fixed_lines = []
i = 0

while i < len(lines):
    line = lines[i]
    
    # Check if this line looks like it should be the start of a Question constructor
    if (re.match(r'\s*id:\s*[\'"]', line.strip()) and 
        i > 0 and 
        ('return [' in lines[i-1] or '// Multiple Choice' in lines[i-1] or lines[i-1].strip() == '')):
        
        # This looks like a Question constructor that's missing the opening
        # Add the Question( opening
        indent = len(line) - len(line.lstrip())
        question_line = ' ' * (indent - 2) + 'Question('
        fixed_lines.append(question_line)
        fixed_lines.append(line)
        
        # Continue processing the rest of the constructor
        i += 1
        while i < len(lines):
            current_line = lines[i]
            
            # Check if we've reached the end of this constructor
            if (current_line.strip().startswith('subject: SubjectType.') and 
                i + 1 < len(lines) and 
                (lines[i + 1].strip().startswith('id:') or 
                 lines[i + 1].strip() == ']' or
                 lines[i + 1].strip().startswith('//') or
                 lines[i + 1].strip() == '' or
                 'return [' in lines[i + 1] or
                 '_generate' in lines[i + 1])):
                
                # Add the current line and close the constructor
                fixed_lines.append(current_line)
                fixed_lines.append(' ' * (indent - 2) + '),')
                break
            else:
                fixed_lines.append(current_line)
            
            i += 1
    else:
        fixed_lines.append(line)
    
    i += 1

# Join the lines back together
content = '\n'.join(fixed_lines)

# Clean up any double Question( openings
content = re.sub(r'Question\(\s*Question\(', 'Question(', content)

# Fix any remaining issues with empty constructors
content = re.sub(r'Question\(\s*\),', '', content)

# Write back to file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Restored proper Question constructor structure")