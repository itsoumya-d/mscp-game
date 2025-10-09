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
    
    # Check if this line contains a Question( opening
    if 'Question(' in line:
        # Start processing this Question constructor
        fixed_lines.append(line)
        i += 1
        
        # Process the constructor parameters
        constructor_lines = []
        while i < len(lines):
            current_line = lines[i]
            
            # Check if we've reached the end of this constructor
            if (current_line.strip().startswith('//') or 
                current_line.strip() == '' or
                current_line.strip() == ']' or
                'Question(' in current_line or
                '_generate' in current_line or
                'return [' in current_line or
                current_line.strip().startswith('}')):
                
                # We've reached the end, need to close the constructor
                # First, add subject parameter if not present
                has_subject = any('subject:' in cl for cl in constructor_lines)
                
                if not has_subject:
                    # Determine the subject type based on the method name
                    subject_type = 'SubjectType.physicalEducation'  # default
                    
                    # Look for method context to determine subject
                    for j in range(max(0, len(fixed_lines) - 50), len(fixed_lines)):
                        if j < len(fixed_lines):
                            method_line = fixed_lines[j]
                            if '_generateLifetimeFitness' in method_line:
                                subject_type = 'SubjectType.physicalEducation'
                            elif '_generateAdvancedFitness' in method_line:
                                subject_type = 'SubjectType.physicalEducation'
                            elif '_generateInjuryPrevention' in method_line:
                                subject_type = 'SubjectType.physicalEducation'
                            elif '_generateExerciseScience' in method_line:
                                subject_type = 'SubjectType.physicalEducation'
                            elif '_generateNutritionWellness' in method_line:
                                subject_type = 'SubjectType.physicalEducation'
                            elif '_generateGrammar' in method_line:
                                subject_type = 'SubjectType.english'
                            elif '_generateVocabulary' in method_line:
                                subject_type = 'SubjectType.english'
                            elif '_generateReading' in method_line:
                                subject_type = 'SubjectType.english'
                            elif '_generateWriting' in method_line:
                                subject_type = 'SubjectType.english'
                            elif '_generateLiterature' in method_line:
                                subject_type = 'SubjectType.english'
                            elif '_generateAlgebra' in method_line:
                                subject_type = 'SubjectType.math'
                            elif '_generateGeometry' in method_line:
                                subject_type = 'SubjectType.math'
                            elif '_generateCalculus' in method_line:
                                subject_type = 'SubjectType.math'
                            elif '_generateStatistics' in method_line:
                                subject_type = 'SubjectType.math'
                            elif '_generateTrigonometry' in method_line:
                                subject_type = 'SubjectType.math'
                            elif '_generateBiology' in method_line:
                                subject_type = 'SubjectType.science'
                            elif '_generateChemistry' in method_line:
                                subject_type = 'SubjectType.science'
                            elif '_generatePhysics' in method_line:
                                subject_type = 'SubjectType.science'
                            elif '_generateEarth' in method_line:
                                subject_type = 'SubjectType.science'
                            elif '_generateEnvironmental' in method_line:
                                subject_type = 'SubjectType.science'
                            elif '_generateWorldHistory' in method_line:
                                subject_type = 'SubjectType.socialStudies'
                            elif '_generateUSHistory' in method_line:
                                subject_type = 'SubjectType.socialStudies'
                            elif '_generateCivics' in method_line:
                                subject_type = 'SubjectType.socialStudies'
                            elif '_generateGeography' in method_line:
                                subject_type = 'SubjectType.socialStudies'
                            elif '_generateEconomics' in method_line:
                                subject_type = 'SubjectType.socialStudies'
                            elif '_generateDrawing' in method_line:
                                subject_type = 'SubjectType.art'
                            elif '_generatePainting' in method_line:
                                subject_type = 'SubjectType.art'
                            elif '_generateSculpture' in method_line:
                                subject_type = 'SubjectType.art'
                            elif '_generateArtHistory' in method_line:
                                subject_type = 'SubjectType.art'
                            elif '_generateDigitalArt' in method_line:
                                subject_type = 'SubjectType.art'
                    
                    # Add subject parameter
                    if constructor_lines:
                        # Find the right indentation
                        last_param_line = constructor_lines[-1] if constructor_lines else '        '
                        indent = len(last_param_line) - len(last_param_line.lstrip())
                        subject_line = ' ' * indent + f'subject: {subject_type},'
                        constructor_lines.append(subject_line)
                
                # Add all constructor lines
                fixed_lines.extend(constructor_lines)
                
                # Add closing parenthesis
                if constructor_lines:
                    last_line = constructor_lines[-1] if constructor_lines else '      '
                    indent = len(last_line) - len(last_line.lstrip())
                    close_line = ' ' * (indent - 2) + '),'
                    fixed_lines.append(close_line)
                
                # Don't increment i here, we want to process the current line
                break
            else:
                constructor_lines.append(current_line)
                i += 1
    else:
        fixed_lines.append(line)
        i += 1

# Join the lines back together
content = '\n'.join(fixed_lines)

# Clean up any issues
content = re.sub(r'Question\(\s*Question\(', 'Question(', content)
content = re.sub(r'\),\s*\),', '),', content)
content = re.sub(r'subject: SubjectType\.\w+,\s*subject: SubjectType\.\w+,', lambda m: m.group(0).split(',')[0] + ',', content)

# Write back to file
with open(r'E:\sp\lib\core\services\predefined_games_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed Question constructor closures and added missing subject parameters")