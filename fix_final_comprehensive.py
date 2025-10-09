import re

# Read the file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the specific formatting issue where type and options are on the same line
content = re.sub(r'type: QuestionType\.multipleChoice,options:', 'type: QuestionType.multipleChoice,\n        options:', content)

# Fix any other similar formatting issues
content = re.sub(r'type: QuestionType\.([^,]+),([a-zA-Z]+):', r'type: QuestionType.\1,\n        \2:', content)

# Remove any existing subject parameters to start fresh
content = re.sub(r'\s*subject: SubjectType\.physicalEducation,', '', content)

# Now fix all Question constructors systematically
def fix_question_constructor(match):
    full_match = match.group(0)
    
    # Check if this is already properly closed
    if full_match.strip().endswith('),'):
        # Add subject parameter before the closing
        if 'subject: SubjectType.physicalEducation,' not in full_match:
            # Find the last field before closing
            pattern = r'(\s+hint: [^,\n]+,)\s*(\),)'
            if re.search(pattern, full_match):
                result = re.sub(pattern, r'\1\n        subject: SubjectType.physicalEducation,\2', full_match)
                return result
            else:
                # Fallback: add before closing
                result = re.sub(r'(\s+)(\),)', r'\1subject: SubjectType.physicalEducation,\n\1\2', full_match)
                return result
        return full_match
    else:
        # This constructor is not properly closed, fix it
        lines = full_match.split('\n')
        fixed_lines = []
        
        for line in lines:
            # Fix any malformed lines
            if 'type: QuestionType.' in line and 'options:' in line:
                parts = line.split('options:')
                fixed_lines.append(parts[0].rstrip(',') + ',')
                if len(parts) > 1 and parts[1].strip():
                    fixed_lines.append('        options:' + parts[1])
                else:
                    fixed_lines.append('        options: ')
            else:
                fixed_lines.append(line)
        
        result = '\n'.join(fixed_lines)
        
        # Ensure it ends properly
        if not result.strip().endswith('),'):
            # Add missing closing
            if not result.strip().endswith(','):
                result = result.rstrip() + ','
            result += '\n        subject: SubjectType.physicalEducation,\n      ),'
        else:
            # Add subject parameter
            if 'subject: SubjectType.physicalEducation,' not in result:
                result = re.sub(r'(\s+)(\),)', r'\1subject: SubjectType.physicalEducation,\n\1\2', result)
        
        return result

# Match Question constructors - be more flexible with the pattern
question_pattern = r'Question\([^}]*?(?:\),|$)'

content = re.sub(question_pattern, fix_question_constructor, content, flags=re.MULTILINE | re.DOTALL)

# Fix any remaining unclosed constructors at the end
if not content.strip().endswith('}'):
    # Find the last incomplete Question constructor
    lines = content.split('\n')
    for i in range(len(lines) - 1, -1, -1):
        if 'Question(' in lines[i]:
            # This might be an unclosed constructor
            # Add proper closing
            if not any('),' in lines[j] for j in range(i, len(lines))):
                # Add the missing closing
                lines.append('        subject: SubjectType.physicalEducation,')
                lines.append('      )),')
                break
    content = '\n'.join(lines)

# Write back to file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Applied final comprehensive fix to all Question constructors")