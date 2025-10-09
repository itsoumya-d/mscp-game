#!/usr/bin/env python3

import re

def fix_educational_game_structure():
    """Fix EducationalGame constructors that have misplaced Question constructors"""
    
    with open('lib/core/services/predefined_games_service.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    
    lines = content.split('\n')
    fixed_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Look for EducationalGame( followed by Question( pattern
        if 'EducationalGame(' in line and i + 1 < len(lines) and 'Question(' in lines[i + 1]:
            # This is the problematic pattern
            # Keep the EducationalGame( line
            fixed_lines.append(line)
            
            # Skip the Question( line and find the actual EducationalGame parameters
            i += 1  # Skip the Question( line
            i += 1  # Move to the next line
            
            # Continue adding lines until we find the proper EducationalGame structure
            while i < len(lines):
                current_line = lines[i]
                
                # Look for typical EducationalGame parameters
                if any(param in current_line for param in ['id:', 'title:', 'description:', 'subject:', 'level:', 'xpReward:', 'difficulty:', 'learningObjectives:', 'estimatedTime:', 'questions:']):
                    fixed_lines.append(current_line)
                elif current_line.strip() == '));' or current_line.strip() == ');':
                    fixed_lines.append(current_line)
                    break
                elif current_line.strip() == '' or current_line.strip().startswith('//'):
                    fixed_lines.append(current_line)
                else:
                    # If we encounter something unexpected, add it and continue
                    fixed_lines.append(current_line)
                
                i += 1
        else:
            fixed_lines.append(line)
            i += 1
    
    # Write the fixed content back
    with open('lib/core/services/predefined_games_service.dart', 'w', encoding='utf-8') as f:
        f.write('\n'.join(fixed_lines))
    
    print("Fixed EducationalGame constructor structure")
    print(f"File now has {len(fixed_lines)} lines")

if __name__ == "__main__":
    fix_educational_game_structure()