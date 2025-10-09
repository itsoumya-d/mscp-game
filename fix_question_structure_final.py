import re

# Read the file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# First, let's fix the misplaced subject parameters that are outside constructors
content = re.sub(r'\),\s*subject: SubjectType\.\w+,\s*\),', '),', content)

# Split into lines for processing
lines = content.split('\n')
fixed_lines = []
i = 0

while i < len(lines):
    line = lines[i]
    
    # Check if this line contains a Question( opening
    if 'Question(' in line:
        # Start processing this Question constructor
        fixed_lines.append(line)
        i += 1
        
        # Collect all parameters for this constructor
        constructor_params = []
        brace_count = 1  # We started with Question(
        
        while i < len(lines) and brace_count > 0:
            current_line = lines[i]
            
            # Count braces to know when constructor ends
            brace_count += current_line.count('(') - current_line.count(')')
            
            # If we're still inside the constructor
            if brace_count > 0:
                constructor_params.append(current_line)
                i += 1
            else:
                # We've reached the end of the constructor
                break
        
        # Now process the collected parameters
        processed_params = []
        has_subject = False
        
        for param_line in constructor_params:
            if 'subject:' in param_line:
                has_subject = True
            processed_params.append(param_line)
        
        # Add subject parameter if missing
        if not has_subject and processed_params:
            # Determine subject type based on context
            subject_type = 'SubjectType.physicalEducation'  # default
            
            # Look back in fixed_lines for method context
            for j in range(max(0, len(fixed_lines) - 100), len(fixed_lines)):
                if j < len(fixed_lines):
                    context_line = fixed_lines[j]
                    if '_generateLifetimeFitness' in context_line or '_generateAdvancedFitness' in context_line or '_generateInjuryPrevention' in context_line or '_generateExerciseScience' in context_line or '_generateNutritionWellness' in context_line:
                        subject_type = 'SubjectType.physicalEducation'
                        break
                    elif '_generateGrammar' in context_line or '_generateVocabulary' in context_line or '_generateReading' in context_line or '_generateWriting' in context_line or '_generateLiterature' in context_line:
                        subject_type = 'SubjectType.english'
                        break
                    elif '_generateAlgebra' in context_line or '_generateGeometry' in context_line or '_generateCalculus' in context_line or '_generateStatistics' in context_line or '_generateTrigonometry' in context_line:
                        subject_type = 'SubjectType.math'
                        break
                    elif '_generateBiology' in context_line or '_generateChemistry' in context_line or '_generatePhysics' in context_line or '_generateEarth' in context_line or '_generateEnvironmental' in context_line:
                        subject_type = 'SubjectType.science'
                        break
                    elif '_generateWorldHistory' in context_line or '_generateUSHistory' in context_line or '_generateCivics' in context_line or '_generateGeography' in context_line or '_generateEconomics' in context_line:
                        subject_type = 'SubjectType.socialStudies'
                        break
                    elif '_generateDrawing' in context_line or '_generatePainting' in context_line or '_generateSculpture' in context_line or '_generateArtHistory' in context_line or '_generateDigitalArt' in context_line:
                        subject_type = 'SubjectType.art'
                        break
            
            # Add subject parameter with proper indentation
            if processed_params:
                last_param = processed_params[-1]
                indent = len(last_param) - len(last_param.lstrip())
                subject_param = ' ' * indent + f'subject: {subject_type},'
                processed_params.append(subject_param)
        
        # Add all processed parameters
        fixed_lines.extend(processed_params)
        
        # Add closing parenthesis
        if processed_params:
            last_param = processed_params[-1]
            indent = len(last_param) - len(last_param.lstrip())
            close_paren = ' ' * (indent - 2) + '),'
            fixed_lines.append(close_paren)
        
    else:
        fixed_lines.append(line)
        i += 1

# Join the lines back together
content = '\n'.join(fixed_lines)

# Clean up any remaining issues
content = re.sub(r'Question\(\s*Question\(', 'Question(', content)
content = re.sub(r'\),\s*\),', '),', content)
content = re.sub(r'subject: SubjectType\.\w+,\s*subject: SubjectType\.\w+,', lambda m: m.group(0).split('subject:')[1], content)

# Write back to file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed Question constructor structure with proper parameter placement")