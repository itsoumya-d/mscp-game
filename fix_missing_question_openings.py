import re

# Read the file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Split into lines for processing
lines = content.split('\n')
fixed_lines = []
i = 0

while i < len(lines):
    line = lines[i]
    
    # Check if this line starts with 'id:' and should be part of a Question constructor
    if re.match(r'\s*id:\s*[\'"]', line.strip()):
        # Look back to see if there's already a Question( opening
        found_question_opening = False
        
        # Check the previous few lines for Question(
        for j in range(max(0, i-5), i):
            if 'Question(' in lines[j]:
                found_question_opening = True
                break
        
        if not found_question_opening:
            # This id: line needs a Question( opening
            indent = len(line) - len(line.lstrip())
            question_line = ' ' * (indent - 2) + 'Question('
            fixed_lines.append(question_line)
    
    fixed_lines.append(line)
    i += 1

# Join the lines back together
content = '\n'.join(fixed_lines)

# Clean up any double Question( openings that might have been created
content = re.sub(r'Question\(\s*Question\(', 'Question(', content)

# Write back to file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Added missing Question( openings")