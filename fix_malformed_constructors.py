import re

# Read the file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix empty Question constructors like "Question(,"
content = re.sub(r'Question\(\s*,\s*subject: SubjectType\.physicalEducation,\s*\),', '', content)

# Fix malformed constructors where parameters are outside the constructor
# Pattern: Question(...), followed by parameters that should be inside
pattern = r'Question\(\s*,\s*subject: SubjectType\.physicalEducation,\s*\),\s*([^}]*?)(?=Question\(|List<GameQuestion>|\s*\]\s*;\s*\})'

def fix_malformed_pattern(match):
    parameters = match.group(1).strip()
    if parameters and 'id:' in parameters:
        # This looks like parameters that should be inside the constructor
        # Extract the parameters and create a proper constructor
        lines = parameters.split('\n')
        param_lines = []
        for line in lines:
            line = line.strip()
            if line and not line.startswith('//') and ':' in line:
                param_lines.append('        ' + line)
        
        if param_lines:
            constructor = 'Question(\n' + '\n'.join(param_lines) + '\n        subject: SubjectType.physicalEducation,\n      ),'
            return constructor
    
    return match.group(0)

content = re.sub(pattern, fix_malformed_pattern, content, flags=re.MULTILINE | re.DOTALL)

# Remove any remaining empty Question constructors
content = re.sub(r'Question\(\s*,?\s*subject: SubjectType\.physicalEducation,\s*\),?\s*', '', content)

# Fix any double commas that might have been introduced
content = re.sub(r',,+', ',', content)

# Fix any trailing commas before closing brackets in lists
content = re.sub(r',\s*\]\s*;', '\n    ];\n', content)

# Write back to file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed malformed Question constructors")