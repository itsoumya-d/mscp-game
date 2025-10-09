import re

# Read the file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the specific issue where subject parameter is inserted in the middle of options
# This pattern looks for subject parameter that's incorrectly placed in the middle of options
pattern = r'(options: [^:]+?)\s*subject: SubjectType\.physicalEducation,\s*([^:]+?:)'
replacement = r'\1\2'

content = re.sub(pattern, replacement, content, flags=re.MULTILINE | re.DOTALL)

# Now add subject parameter correctly at the end of each Question constructor
# Find all Question constructors and add subject parameter before the closing parenthesis
question_pattern = r'(Question\([^}]*?hint: [^,]+,)\s*(\),)'

def add_subject_correctly(match):
    question_part = match.group(1)
    closing = match.group(2)
    
    # Check if subject already exists
    if 'subject:' in question_part:
        return match.group(0)
    
    # Add subject parameter
    return question_part + '\n        subject: SubjectType.physicalEducation,' + closing

content = re.sub(question_pattern, add_subject_correctly, content, flags=re.MULTILINE | re.DOTALL)

# Write back to file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed structural issues in Question constructors")