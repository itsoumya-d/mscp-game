I need you to completely remove all AI content generation functionality from the LearnoSphere app and replace it with a comprehensive, manually-created educational game system. The AI generation is not functioning properly and must be eliminated entirely.

## Critical Requirements:

### 1. Remove All AI Generation Code
- Delete all code related to Z.ai API integration (API key: [configured outside version control; never embed credentials in client code])
- Delete all code related to GLM 4.6 API integration (API key: [configured outside version control; never embed credentials in client code])
- Remove any dependencies, imports, or configuration related to AI content generation
- Ensure no remnants of AI generation remain in the codebase

### 2. Implement Flashcard System Before Each Level
- Before every game level (whether it's the first level or any subsequent level), display exactly 5 educational flashcards
- Flashcards must be contextually relevant to the specific level's subject matter and difficulty
- Research best practices for educational flashcard implementation in mobile apps
- Flashcards should reinforce concepts that will be tested in the upcoming level

### 3. Manual Level Creation with Progressive Difficulty
- Create all game levels manually (no AI generation whatsoever)
- Each level must be progressively more difficult than the previous one
- Each subject category must have progressively increasing difficulty across its levels
- All levels must be fully functional and playable by end users

## Implementation Plan:

### Phase 1: Codebase Analysis (MANDATORY FIRST STEP)
1. *Conduct deep line-by-line analysis:*
   - Map out the entire current game architecture
   - Identify all AI generation code locations (backend and frontend)
   - Document existing manually-created game levels (count, structure, format)
   - Analyze the level data model and storage mechanism
   - Identify the game mechanics implementation (using Flame engine for Flutter)
   - Document how levels are loaded, rendered, and managed
   - Catalog all existing bugs, performance issues, or architectural problems

2. *Understand current state:*
   - How many levels currently exist?
   - What is the current level progression system?
   - How are levels stored (database schema, file structure)?
   - What game types/mechanics are currently implemented?

### Phase 2: Research & Best Practices (MANDATORY)
3. *Research educational game design:*
   - Research best practices for flashcard implementation in educational apps
   - Study top educational apps to understand level progression patterns
   - Research optimal difficulty curves for educational content
   - Benchmark against successful educational games in the market
   - Document findings and apply insights to the design

4. *Research unlock mechanisms:*
   - Study progressive unlock systems in educational apps
   - Determine best practices for content gating and motivation
   - Design an unlock tree that maximizes engagement and learning

### Phase 3: Design Scalable Architecture
5. *Design level generation system:*
   - Create a programmatic level generation script/tool (NOT AI-based, but template-based)
   - Design templates for each subject category that can generate variations
   - Each generated level must have a unique identifier/code
   - System should be capable of generating at least 10,000 levels per category
   - Total target: 50,000 levels across 5 categories (Math, Physics, Chemistry, Biology, Science)

6. *Define subject-specific level specifications:*
   - *Math:* Addition (basic → advanced), Subtraction, Multiplication, Division, Fractions, Decimals, Algebra, Geometry
   - *Physics:* Mechanics, Forces, Energy, Motion, Electricity, Magnetism, Waves, Optics
   - *Chemistry:* Elements, Periodic Table, Compounds, Chemical Reactions, Acids/Bases, Organic Chemistry
   - *Biology:* Cells, Genetics, Human Body Systems, Ecosystems, Evolution, Microbiology
   - *Science:* General scientific method, Earth Science, Astronomy, Environmental Science
   - Each level must include appropriate visuals, interactions, and educational content matching the app's design language

### Phase 4: Progressive Unlock System
7. *Design and implement unlock mechanism:*
   - Define the complete progression tree for each subject
   - Example for Math: Addition (Levels 1-100) → Subtraction (Levels 101-200) → Multiplication (Levels 201-300) → Division (Levels 301-400) → Advanced Topics
   - Map out dependencies: What must be completed to unlock the next chapter/topic?
   - Implement unlock logic in both backend (data persistence) and frontend (UI state)
   - Create visual indicators showing locked/unlocked content with clear progression paths
   - Ensure unlock state is saved and persists across app sessions

### Phase 5: Comprehensive Task List Creation
8. *Create detailed, trackable task list using task management tools:*
   - Break down work into specific, actionable tasks
   - For each category (Math, Physics, Chemistry, Biology, Science), create tracking structure:
     * Category: [Subject Name]
     * Target: 10,000 levels
     * Completed: X / 10,000
     * Remaining: Y / 10,000
     * Status: [NOT_STARTED | IN_PROGRESS | COMPLETE]
   - Include tasks for:
     * AI code removal
     * Flashcard system implementation
     * Level generation script creation
     * Manual level creation for each category
     * UI/UX integration for each category
     * Testing and bug fixes
     * Unlock mechanism implementation
   - Update task states as work progresses

### Phase 6: Systematic Implementation
9. *Remove AI generation code:*
   - Delete all AI API integration code
   - Remove related dependencies from package files
   - Clean up any configuration files
   - Test that app functions without AI components

10. *Implement flashcard system:*
    - Create flashcard data structure
    - Design flashcard UI component
    - Implement flashcard display logic (5 cards before each level)
    - Create flashcard content for each subject/level combination
    - Integrate with level flow

11. *Create level generation system:*
    - Build template-based level generator (not AI, but algorithmic)
    - Generate levels category by category
    - Ensure each level has unique identifier and is fully functional
    - Validate educational quality and progressive difficulty

12. *Implement levels systematically (one category at a time):*
    - Start with Math (10,000 levels)
    - Then Physics (10,000 levels)
    - Then Chemistry (10,000 levels)
    - Then Biology (10,000 levels)
    - Finally Science (10,000 levels)
    - After each category, update task list progress

### Phase 7: UI/UX Integration & Testing
13. *Frontend integration:*
    - Update UI to display all generated levels properly
    - Implement smooth navigation between levels and categories
    - Add visual feedback for level completion and progression
    - Implement unlock mechanism visuals (locked/unlocked states, progress indicators)
    - Ensure all game interactions using Flame engine are smooth and functional
    - Test on actual devices for performance

14. *Audit frontend-backend integration:*
    - Verify all levels load correctly from backend
    - Ensure unlock state persists properly
    - Test level progression flow end-to-end
    - Validate flashcard display before each level
    - Fix any integration issues

### Phase 8: Quality Assurance
15. *Fix all existing bugs:*
    - Address any bugs identified during Phase 1 analysis
    - Test all game mechanics thoroughly
    - Ensure app stability and performance

16. *Final testing:*
    - Test complete user journey from first level to advanced levels
    - Verify unlock mechanism works correctly
    - Ensure all 50,000 levels are accessible and functional
    - Validate progressive difficulty across all categories

## Deliverables:
1. Complete removal of all AI generation code (verified and tested)
2. Flashcard system implemented and functional (5 cards before each level)
3. 50,000 fully functional, manually-created levels (10,000 per category)
4. Level generation script/system with template-based approach
5. Progressive unlock mechanism fully implemented in UI and backend
6. Detailed task list with progress tracking showing completion status
7. Progression map/tree documenting unlock sequences
8. All existing bugs fixed
9. Complete documentation of the new level system architecture
10. Fully functional, polished app ready for end users

## Execution Order:
*START WITH:* Deep codebase analysis (Phase 1) → Research (Phase 2) → Create comprehensive task list (Phase 5) → Begin systematic implementation (Phases 3-8)

*DO NOT skip the research phase.* Internet research is mandatory for flashcard best practices and educational game design patterns.