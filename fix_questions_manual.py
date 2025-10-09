import re

# Read the file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# First, restore the file by removing all incorrectly added subject parameters
content = re.sub(r',\s*subject: SubjectType\.physicalEducation,\),', '),', content)

# Find all Question constructors and their exact boundaries
question_pattern = r'Question\('
matches = []

# Find all Question( occurrences
for match in re.finditer(question_pattern, content):
    start_pos = match.start()
    
    # Find the matching closing parenthesis
    paren_count = 0
    in_string = False
    string_char = None
    i = start_pos + len('Question(')
    
    while i < len(content):
        char = content[i]
        
        if not in_string:
            if char in ['"', "'"]:
                in_string = True
                string_char = char
            elif char == '(':
                paren_count += 1
            elif char == ')':
                if paren_count == 0:
                    # Found the closing parenthesis
                    # Check if this is followed by a comma (indicating it's part of a list)
                    j = i + 1
                    while j < len(content) and content[j] in [' ', '\n', '\t']:
                        j += 1
                    if j < len(content) and content[j] == ',':
                        end_pos = j + 1
                    else:
                        end_pos = i + 1
                    
                    matches.append((start_pos, end_pos))
                    break
                else:
                    paren_count -= 1
        else:
            if char == string_char and (i == 0 or content[i-1] != '\\'):
                in_string = False
                string_char = None
        
        i += 1

# Process matches in reverse order to avoid position shifts
for start_pos, end_pos in reversed(matches):
    question_constructor = content[start_pos:end_pos]
    
    # Check if subject parameter already exists
    if 'subject:' in question_constructor:
        continue
    
    # Find the position to insert the subject parameter
    # Look for the last parameter before the closing parenthesis
    lines = question_constructor.split('\n')
    
    # Find the line with the closing parenthesis
    closing_line_index = -1
    for i, line in enumerate(lines):
        if ')' in line and not line.strip().startswith('//'):
            closing_line_index = i
            break
    
    if closing_line_index > 0:
        # Insert subject parameter before the closing line
        indent = '        '  # Standard indentation
        subject_line = f'{indent}subject: SubjectType.physicalEducation,'
        lines.insert(closing_line_index, subject_line)
        
        # Reconstruct the constructor
        new_constructor = '\n'.join(lines)
        
        # Replace in the content
        content = content[:start_pos] + new_constructor + content[end_pos:]

# Write back to file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print(f"Fixed {len(matches)} Question constructors in predefined_games_service.dart")