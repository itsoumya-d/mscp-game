import re

# Read the file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# First, let's restore the original file by removing the incorrectly added subject parameters
content = re.sub(r',\s*subject: SubjectType\.physicalEducation\),', '),', content)

# Now, let's add the subject parameter correctly
# Pattern to match Question constructors that end with a closing parenthesis and comma
pattern = r'(Question\(\s*\n(?:[^)]+\n)*[^)]+)(\),)'

def add_subject_parameter(match):
    question_content = match.group(1)
    closing = match.group(2)
    
    # Check if subject parameter already exists
    if 'subject:' in question_content:
        return match.group(0)  # Return unchanged if subject already exists
    
    # Add subject parameter before the closing parenthesis
    # Find the last parameter and add subject after it
    lines = question_content.split('\n')
    
    # Find the last line with content (not just whitespace)
    for i in range(len(lines) - 1, -1, -1):
        if lines[i].strip() and not lines[i].strip().startswith('//'):
            # Add comma if the line doesn't end with one
            if not lines[i].rstrip().endswith(','):
                lines[i] = lines[i].rstrip() + ','
            # Add the subject parameter
            indent = '        '  # Match the indentation of other parameters
            lines.insert(i + 1, f'{indent}subject: SubjectType.physicalEducation,')
            break
    
    return '\n'.join(lines) + closing

# Apply the replacement
new_content = re.sub(pattern, add_subject_parameter, content, flags=re.MULTILINE | re.DOTALL)

# Write back to file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Fixed Question constructors in predefined_games_service.dart (v2)")