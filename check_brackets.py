import re

# Read the file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Count brackets and parentheses
open_parens = content.count('(')
close_parens = content.count(')')
open_brackets = content.count('[')
close_brackets = content.count(']')
open_braces = content.count('{')
close_braces = content.count('}')

print(f"Open parentheses: {open_parens}")
print(f"Close parentheses: {close_parens}")
print(f"Difference: {open_parens - close_parens}")
print()
print(f"Open brackets: {open_brackets}")
print(f"Close brackets: {close_brackets}")
print(f"Difference: {open_brackets - close_brackets}")
print()
print(f"Open braces: {open_braces}")
print(f"Close braces: {close_braces}")
print(f"Difference: {open_braces - close_braces}")

# Find unclosed Question constructors
lines = content.split('\n')
in_question = False
question_start_line = 0
open_count = 0

for i, line in enumerate(lines, 1):
    if 'Question(' in line and not in_question:
        in_question = True
        question_start_line = i
        open_count = line.count('(') - line.count(')')
    elif in_question:
        open_count += line.count('(') - line.count(')')
        if open_count == 0 and '),' in line:
            in_question = False
        elif i > question_start_line + 50:  # If we've gone too far, something's wrong
            print(f"Potentially unclosed Question constructor starting at line {question_start_line}")
            in_question = False

if in_question:
    print(f"Unclosed Question constructor starting at line {question_start_line}")