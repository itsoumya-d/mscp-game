import re

# Read the file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# First, remove all incorrectly placed subject parameters
# Remove subject parameters that are in the middle of other fields
content = re.sub(r'\s*subject: SubjectType\.physicalEducation,\s*(?=\w+\s*<=)', '', content)

# Remove subject parameters that break string literals or expressions
content = re.sub(r'(\w+\s*:\s*[^,\n]*?)\s*subject: SubjectType\.physicalEducation,\s*([^,\n]*?)', r'\1\2', content)

# Remove any remaining orphaned subject parameters
content = re.sub(r'\s*subject: SubjectType\.physicalEducation,\s*(?=[a-zA-Z_])', '', content)

# Now find all Question constructors and add subject parameter correctly
# This pattern matches complete Question constructors
def fix_question_constructor(match):
    full_match = match.group(0)
    
    # Check if subject already exists in the correct place
    if 'subject: SubjectType.physicalEducation,' in full_match and full_match.rstrip().endswith('subject: SubjectType.physicalEducation,\n      ),'):
        return full_match
    
    # Remove any existing subject parameters first
    cleaned = re.sub(r'\s*subject: SubjectType\.physicalEducation,', '', full_match)
    
    # Find the last field before the closing ),
    # Look for the pattern: field_name: value, followed by ),
    pattern = r'(\s+hint: [^,]+,)\s*(\),)'
    
    if re.search(pattern, cleaned):
        # Add subject after hint field
        result = re.sub(pattern, r'\1\n        subject: SubjectType.physicalEducation,\2', cleaned)
        return result
    else:
        # Fallback: add before the closing ),
        result = re.sub(r'(\s+)(\),)', r'\1subject: SubjectType.physicalEducation,\n\1\2', cleaned)
        return result

# Match Question constructors
question_pattern = r'Question\([^}]*?\),'

content = re.sub(question_pattern, fix_question_constructor, content, flags=re.MULTILINE | re.DOTALL)

# Write back to file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Comprehensively fixed all Question constructor issues")