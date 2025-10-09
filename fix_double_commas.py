import re

# Read the file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix double commas
content = re.sub(r',,', ',', content)

# Fix missing commas after subject parameter
content = re.sub(r'(subject: SubjectType\.physicalEducation)\n', r'\1,\n', content)

# Write back to file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed double commas and missing commas after subject parameters")