import re

# Read the file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

print("Starting comprehensive cleanup and fix...")

# Phase 1: Clean up malformed bracket sequences
print("Phase 1: Cleaning up malformed brackets...")

# Remove sequences like "),\n);" and "),\n),"
content = re.sub(r'\),\s*\);', '),', content)
content = re.sub(r'\),\s*\),', '),', content)

# Remove duplicate subject parameters
content = re.sub(r'subject: SubjectType\.\w+,\s*subject: SubjectType\.\w+,', lambda m: m.group(0).split(',')[0] + ',', content)

# Remove orphaned subject parameters that are outside constructors
content = re.sub(r'\),\s*subject: SubjectType\.\w+,\s*\),', '),', content)

# Phase 2: Fix Question constructor structure
print("Phase 2: Fixing Question constructor structure...")

lines = content.split('\n')
fixed_lines = []
i = 0

while i < len(lines):
    line = lines[i]
    
    # Look for Question constructor patterns
    if 'Question(' in line:
        # This is a proper Question constructor start
        fixed_lines.append(line)
        i += 1
        
        # Collect constructor content until we find the end
        constructor_content = []
        paren_count = 1
        
        while i < len(lines) and paren_count > 0:
            current_line = lines[i]
            
            # Count parentheses to track nesting
            paren_count += current_line.count('(') - current_line.count(')')
            
            if paren_count > 0:
                constructor_content.append(current_line)
                i += 1
            else:
                # We've reached the end, but don't include the closing line yet
                break
        
        # Process the constructor content
        has_subject = any('subject:' in line for line in constructor_content)
        
        # Add all the constructor content
        fixed_lines.extend(constructor_content)
        
        # Add subject parameter if missing
        if not has_subject and constructor_content:
            # Determine subject type based on context
            subject_type = 'SubjectType.physicalEducation'  # default
            
            # Look for method context in recent lines
            for j in range(max(0, len(fixed_lines) - 200), len(fixed_lines)):
                if j < len(fixed_lines):
                    context_line = fixed_lines[j]
                    if any(pe_method in context_line for pe_method in ['_generateLifetimeFitness', '_generateAdvancedFitness', '_generateInjuryPrevention', '_generateExerciseScience', '_generateNutritionWellness']):
                        subject_type = 'SubjectType.physicalEducation'
                        break
                    elif any(eng_method in context_line for eng_method in ['_generateGrammar', '_generateVocabulary', '_generateReading', '_generateWriting', '_generateLiterature']):
                        subject_type = 'SubjectType.english'
                        break
                    elif any(math_method in context_line for math_method in ['_generateAlgebra', '_generateGeometry', '_generateCalculus', '_generateStatistics', '_generateTrigonometry']):
                        subject_type = 'SubjectType.math'
                        break
                    elif any(sci_method in context_line for sci_method in ['_generateBiology', '_generateChemistry', '_generatePhysics', '_generateEarth', '_generateEnvironmental']):
                        subject_type = 'SubjectType.science'
                        break
                    elif any(ss_method in context_line for ss_method in ['_generateWorldHistory', '_generateUSHistory', '_generateCivics', '_generateGeography', '_generateEconomics']):
                        subject_type = 'SubjectType.socialStudies'
                        break
                    elif any(art_method in context_line for art_method in ['_generateDrawing', '_generatePainting', '_generateSculpture', '_generateArtHistory', '_generateDigitalArt']):
                        subject_type = 'SubjectType.art'
                        break
            
            # Add subject parameter with proper indentation
            if constructor_content:
                last_line = constructor_content[-1]
                indent = len(last_line) - len(last_line.lstrip())
                subject_line = ' ' * indent + f'subject: {subject_type},'
                fixed_lines.append(subject_line)
        
        # Add proper closing
        if constructor_content:
            last_line = constructor_content[-1] if constructor_content else '        '
            indent = len(last_line) - len(last_line.lstrip())
            close_line = ' ' * (indent - 2) + '),'
            fixed_lines.append(close_line)
    
    elif re.match(r'\s*id:\s*[\'"]', line.strip()):
        # This looks like a Question constructor that's missing the opening
        # Check if there's already a Question( in recent lines
        has_recent_question = False
        for j in range(max(0, len(fixed_lines) - 10), len(fixed_lines)):
            if j < len(fixed_lines) and 'Question(' in fixed_lines[j]:
                has_recent_question = True
                break
        
        if not has_recent_question:
            # Add Question( opening
            indent = len(line) - len(line.lstrip())
            question_line = ' ' * (indent - 2) + 'Question('
            fixed_lines.append(question_line)
        
        fixed_lines.append(line)
        i += 1
    
    else:
        fixed_lines.append(line)
        i += 1

# Phase 3: Final cleanup
print("Phase 3: Final cleanup...")

content = '\n'.join(fixed_lines)

# Remove any remaining double Question( patterns
content = re.sub(r'Question\(\s*Question\(', 'Question(', content)

# Clean up any remaining malformed patterns
content = re.sub(r'\),\s*\),', '),', content)

# Write back to file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Comprehensive cleanup and fix completed!")
print(f"File now has {len(content.splitlines())} lines")