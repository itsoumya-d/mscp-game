import re

# Read the file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# First, restore the file by removing all incorrectly added subject parameters
content = re.sub(r',\s*subject: SubjectType\.physicalEducation,\),', '),', content)

# More precise pattern to match complete Question constructors
# This pattern looks for Question( followed by parameters ending with ),
pattern = r'(Question\(\s*\n(?:(?!\),)[^}])*?)(\s*\),)'

def add_subject_parameter(match):
    question_content = match.group(1)
    closing = match.group(2)
    
    # Check if subject parameter already exists
    if 'subject:' in question_content:
        return match.group(0)  # Return unchanged if subject already exists
    
    # Find the last parameter line that's not inside a string
    lines = question_content.split('\n')
    
    # Find the last line that contains a parameter (has a colon and ends with comma or is the last parameter)
    last_param_index = -1
    for i in range(len(lines) - 1, -1, -1):
        line = lines[i].strip()
        if ':' in line and (line.endswith(',') or i == len(lines) - 1):
            # Make sure this line is a parameter, not part of a string
            if any(param in line for param in ['id:', 'type:', 'questionText:', 'options:', 'correctAnswer:', 'explanation:', 'hint:']):
                last_param_index = i
                break
    
    if last_param_index >= 0:
        # Add comma if the last parameter line doesn't end with one
        if not lines[last_param_index].rstrip().endswith(','):
            lines[last_param_index] = lines[last_param_index].rstrip() + ','
        
        # Add the subject parameter with proper indentation
        indent = '        '  # Match the indentation of other parameters
        lines.insert(last_param_index + 1, f'{indent}subject: SubjectType.physicalEducation,')
    
    return '\n'.join(lines) + closing

# Apply the replacement
new_content = re.sub(pattern, add_subject_parameter, content, flags=re.MULTILINE | re.DOTALL)

# Write back to file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Fixed Question constructors in predefined_games_service.dart (v3)")