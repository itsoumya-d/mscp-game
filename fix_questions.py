import re

# Read the file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern to match Question constructors that don't have subject parameter
# This pattern looks for Question( followed by parameters but not containing subject:
pattern = r'(Question\(\s*\n\s*id:[^}]+?)(\s*\),)'

def add_subject_parameter(match):
    question_content = match.group(1)
    closing = match.group(2)
    
    # Check if subject parameter already exists
    if 'subject:' in question_content:
        return match.group(0)  # Return unchanged if subject already exists
    
    # Add subject parameter before the closing
    return question_content + ',\n        subject: SubjectType.physicalEducation' + closing

# Apply the replacement
new_content = re.sub(pattern, add_subject_parameter, content, flags=re.MULTILINE | re.DOTALL)

# Write back to file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Fixed Question constructors in predefined_games_service.dart")