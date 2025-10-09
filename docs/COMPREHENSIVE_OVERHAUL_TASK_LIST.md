# LearnoSphere Comprehensive Overhaul - Task List

**Date**: 2025-10-01  
**Status**: 📋 PLANNING COMPLETE  
**Total Tasks**: 42 tasks across 6 phases  
**Estimated Timeline**: 3-4 weeks

---

## 📊 TASK OVERVIEW

| Phase | Tasks | Priority | Est. Time | Status |
|-------|-------|----------|-----------|--------|
| **Phase A: Research & Analysis** | 4 | 🔴 Critical | 8 hours | ✅ COMPLETE |
| **Phase B: Delete Bad Questions** | 3 | 🔴 Critical | 2 hours | ⏳ Pending |
| **Phase C: Redesign AI System** | 15 | 🔴 Critical | 40 hours | ⏳ Pending |
| **Phase D: Level Unlocking** | 6 | 🟠 High | 12 hours | ⏳ Pending |
| **Phase E: Performance Optimization** | 8 | 🔴 Critical | 16 hours | ⏳ Pending |
| **Phase F: UI/UX Fixes** | 6 | 🟠 High | 10 hours | ⏳ Pending |
| **TOTAL** | **42** | - | **88 hours** | **2% Complete** |

---

## ✅ PHASE A: RESEARCH & ANALYSIS (COMPLETE)

### A1: Audit Current Question Generation System ✅
**Status**: COMPLETE  
**Time**: 3 hours  
**Findings**:
- AI prompts are too generic
- No subject-specific context
- Validation only checks structure, not content
- Root cause identified

### A2: Research Subject-Specific Question Standards ✅
**Status**: COMPLETE  
**Time**: 3 hours  
**Deliverable**: Question standards for Math, Physics, Chemistry, Biology documented

### A3: Analyze Level Progression Systems ✅
**Status**: COMPLETE  
**Time**: 1 hour  
**Findings**: No level unlocking system exists

### A4: Investigate Performance Bottlenecks ✅
**Status**: COMPLETE  
**Time**: 1 hour  
**Findings**: API calls and UI rendering are bottlenecks

---

## 🔴 PHASE B: DELETE EXISTING GENERATED QUESTIONS

**Priority**: CRITICAL  
**Estimated Time**: 2 hours  
**Dependencies**: None  
**Must Complete Before**: Phase C

### B1: Clear Question Cache from SharedPreferences
**Time**: 30 minutes  
**Files**: `lib/core/services/game_session_service.dart`

**Actions**:
1. Create utility method to clear all cached questions
2. Clear keys matching patterns:
   - `ai_pool_*`
   - `cached_session_*`
   - `preloaded_*`
3. Log cleared items for verification
4. Test cache clearing

**Success Criteria**:
- All AI-generated questions removed
- Cache size reduced to 0
- No errors during clearing

### B2: Clear Preloaded Content
**Time**: 30 minutes  
**Files**: `lib/core/services/fallback_content_preloader.dart`, `lib/core/services/level_preloader_service.dart`

**Actions**:
1. Clear `_contentCache` map
2. Reset preload status flags
3. Clear preload timestamps
4. Force re-initialization on next app start

**Success Criteria**:
- All preloaded content cleared
- System ready for fresh content generation

### B3: Verify Clean State
**Time**: 1 hour  
**Actions**:
1. Run app and verify no cached questions appear
2. Check all subjects and skills
3. Verify fallback to local templates only
4. Document clean state

**Success Criteria**:
- No AI-generated questions visible
- Only hardcoded fallback templates appear
- App still functional

---

## 🔴 PHASE C: REDESIGN AI QUESTION GENERATION SYSTEM

**Priority**: CRITICAL  
**Estimated Time**: 40 hours  
**Dependencies**: Phase B complete  
**Impact**: Fixes root cause of bad questions

### C1: Create Subject-Specific Prompt Template System
**Time**: 4 hours  
**Files**: Create `lib/core/services/ai_prompt_templates.dart`

**Actions**:
1. Create `AIPromptTemplate` class
2. Define template structure:
   - Subject context
   - Skill-specific concepts
   - Example problems
   - Difficulty guidelines
   - Question format specifications
3. Create template registry

**Deliverable**: Reusable prompt template system

### C2: Design Mathematics Prompt Templates
**Time**: 6 hours  
**Files**: `lib/core/services/ai_prompt_templates.dart`

**Skills to Cover**:
- Addition/Subtraction (10 levels)
- Multiplication/Division (10 levels)
- Fractions (10 levels)
- Decimals (10 levels)
- Algebra (10 levels)
- Geometry (10 levels)

**Template Structure for Each Skill**:
```dart
MathPromptTemplate(
  skillId: 'multiplication_division',
  skillName: 'Multiplication and Division',
  gradeLevel: '3-5',
  
  conceptsToTest: [
    'Single-digit multiplication (2×3, 4×5)',
    'Multiplication tables 1-10',
    'Simple division without remainders',
    'Division as inverse of multiplication',
    'Word problems with multiplication/division',
  ],
  
  questionFormats: [
    'Direct calculation: "What is 6 × 7?"',
    'Word problems: "Sarah has 4 boxes with 6 apples each..."',
    'Missing number: "8 × ? = 56"',
    'Application: "If 24 cookies are shared equally..."',
  ],
  
  difficultyScaling: {
    1-3: 'Numbers 1-10, no remainders, one-step problems',
    4-6: 'Numbers 1-12, simple remainders, two-step problems',
    7-10: 'Numbers 1-20, complex remainders, multi-step problems',
  },
  
  exampleQuestions: [
    // 5-10 example questions per difficulty level
  ],
)
```

**Success Criteria**:
- 6 comprehensive templates (one per math skill)
- 10 difficulty levels per template
- 5+ example questions per level
- Clear concept definitions

### C3: Design Physics Prompt Templates
**Time**: 6 hours  
**Files**: `lib/core/services/ai_prompt_templates.dart`

**Skills to Cover**:
- Mechanics (10 levels)
- Thermodynamics (10 levels)
- Electricity (10 levels)
- Optics (10 levels)
- Modern Physics (10 levels)

**Template Structure**:
- Fundamental concepts and laws
- Formula specifications
- Unit requirements
- Problem-solving approaches
- Real-world applications
- Example calculations

**Success Criteria**:
- 5 comprehensive templates
- Physics formulas included
- Unit conversions specified
- Example problems with solutions

### C4: Design Chemistry Prompt Templates
**Time**: 5 hours  
**Files**: `lib/core/services/ai_prompt_templates.dart`

**Skills to Cover**:
- Organic Chemistry (10 levels)
- Inorganic Chemistry (10 levels)
- Physical Chemistry (10 levels)
- Analytical Chemistry (10 levels)

**Template Structure**:
- Chemical concepts and reactions
- Nomenclature rules
- Molecular structures
- Stoichiometry requirements
- Lab safety considerations

**Success Criteria**:
- 4 comprehensive templates
- Chemical formulas included
- Reaction mechanisms specified
- Safety considerations noted

### C5: Design Biology Prompt Templates
**Time**: 5 hours  
**Files**: `lib/core/services/ai_prompt_templates.dart`

**Skills to Cover**:
- Cell Biology (10 levels)
- Genetics (10 levels)
- Ecology (10 levels)
- Human Anatomy (10 levels)

**Template Structure**:
- Biological concepts and processes
- Organism classifications
- System interactions
- Diagram requirements
- Real-world applications

**Success Criteria**:
- 4 comprehensive templates
- Biological processes detailed
- Diagram specifications included
- Medical applications noted

### C6: Update xAI Grok API Service with New Prompts
**Time**: 3 hours  
**Files**: `lib/core/services/xai_grok_api_service.dart`

**Actions**:
1. Import `AIPromptTemplate` system
2. Update `_buildEducationalPrompt()` method
3. Fetch appropriate template based on subject/skill
4. Inject template content into prompt
5. Add difficulty-specific instructions
6. Include example questions in prompt

**New Prompt Structure**:
```
You are an expert educational content creator specializing in [SUBJECT].

SKILL: [Skill Name]
GRADE LEVEL: [Grade Range]
DIFFICULTY: Level [X] - [Description]

CONCEPTS TO TEST:
[Detailed list of specific concepts]

QUESTION FORMATS REQUIRED:
[Specific question types with examples]

EXAMPLE QUESTIONS FOR THIS LEVEL:
[5-10 example questions]

REQUIREMENTS:
1. Test actual [subject] knowledge, NOT meta-knowledge about the subject
2. Use specific numbers, formulas, and calculations
3. Provide concrete scenarios, not abstract concepts
4. Ensure all options are plausible but only one is correct
5. Match difficulty to Level [X] specifications above

Generate [count] questions following these exact specifications.
Return as JSON array: [{"question": "...", "options": [...], "correctAnswer": 0, ...}]
```

**Success Criteria**:
- Prompts include detailed subject context
- Example questions provided to AI
- Difficulty scaling clearly specified
- No generic prompts remain

### C7: Update Z.AI GLM API Service with New Prompts
**Time**: 2 hours  
**Files**: `lib/core/services/glm_api_service.dart`

**Actions**:
- Same as C6 but for Z.AI API
- Ensure consistency between providers

### C8: Add Content Quality Validation Layer
**Time**: 4 hours  
**Files**: Create `lib/core/utils/content_quality_validator.dart`

**Actions**:
1. Create `ContentQualityValidator` class
2. Implement quality checks:
   - Detect meta-questions (contains "important for", "relative to", "concept in")
   - Verify question contains subject-specific content
   - Check for concrete numbers/formulas (math/physics)
   - Verify options are meaningful (not just A, B, C, D)
   - Ensure question matches skill context
3. Assign quality scores (0-100)
4. Reject questions below threshold (score < 70)

**Quality Check Examples**:
```dart
// BAD - Meta-question
"Which of the following is relative to multiplication?"
→ Quality Score: 10 → REJECT

// GOOD - Actual knowledge test
"What is 7 × 8?"
→ Quality Score: 95 → ACCEPT

// BAD - Generic options
Options: ["A", "B", "C", "D"]
→ Quality Score: 5 → REJECT

// GOOD - Meaningful options
Options: ["56", "54", "63", "48"]
→ Quality Score: 90 → ACCEPT
```

**Success Criteria**:
- Meta-questions detected and rejected
- Generic options flagged
- Quality scores accurate
- Integration with existing validation

### C9: Integrate Quality Validation into Game Session Service
**Time**: 2 hours  
**Files**: `lib/core/services/game_session_service.dart`

**Actions**:
1. Import `ContentQualityValidator`
2. Add quality check after structure validation
3. Filter out low-quality questions
4. Track quality metrics in analytics
5. Regenerate if quality too low

**Validation Flow**:
```
Generate Questions
    ↓
Structure Validation (Phase 10)
    ↓
Content Quality Validation (NEW)
    ↓
Filter Low-Quality Questions
    ↓
Fill Gaps with Fallback
    ↓
Return Session
```

**Success Criteria**:
- Quality validation runs on all questions
- Low-quality questions filtered out
- Analytics track quality metrics
- No performance degradation

### C10: Create Pre-Question Educational Content System
**Time**: 3 hours  
**Files**: Create `lib/core/models/educational_content.dart`

**Actions**:
1. Create `EducationalContent` model:
   - Skill name
   - Brief explanation (2-3 sentences)
   - Key concepts list
   - Example problem with solution
   - Formulas/rules (if applicable)
   - Visual aids (optional)
2. Create content for all skills
3. Store in database/cache

**Example Content**:
```dart
EducationalContent(
  skillId: 'multiplication_division',
  skillName: 'Multiplication and Division',
  
  explanation: '''
Multiplication is repeated addition. For example, 4 × 3 means 
"add 4 three times" (4 + 4 + 4 = 12). Division is the opposite 
- it splits a number into equal groups.
''',
  
  keyConcepts: [
    'Multiplication tables (1-10)',
    'Division as inverse of multiplication',
    'Remainders in division',
  ],
  
  exampleProblem: '''
Problem: What is 6 × 7?
Solution: 6 × 7 = 42
Think: 6 added 7 times = 6+6+6+6+6+6+6 = 42
''',
  
  formulas: [
    'a × b = b × a (commutative property)',
    'a ÷ b = c means a = b × c',
  ],
)
```

**Success Criteria**:
- Content created for all 25+ skills
- Clear, concise explanations
- Example problems included
- Age-appropriate language

### C11: Create Pre-Question Educational Screen
**Time**: 3 hours  
**Files**: Create `lib/screens/educational_content_screen.dart`

**Actions**:
1. Create new screen between Level Preview and Game Session
2. Display educational content
3. Show skill explanation
4. Display example problem
5. Add "Start Game" button
6. Add "Skip" option (for returning users)
7. Track views in analytics

**UI Design**:
```
┌─────────────────────────────────────┐
│  📚 Before You Start...             │
├─────────────────────────────────────┤
│                                     │
│  Multiplication and Division        │
│                                     │
│  [Explanation text]                 │
│                                     │
│  Key Concepts:                      │
│  • Multiplication tables            │
│  • Division as inverse              │
│  • Remainders                       │
│                                     │
│  Example Problem:                   │
│  [Problem with solution]            │
│                                     │
│  ┌─────────────┐  ┌──────────────┐ │
│  │ Start Game  │  │ Skip (Know   │ │
│  │             │  │ This Already)│ │
│  └─────────────┘  └──────────────┘ │
└─────────────────────────────────────┘
```

**Success Criteria**:
- Screen displays before game starts
- Content is readable and helpful
- Skip option available
- Smooth navigation flow

### C12: Update Navigation Flow
**Time**: 1 hour  
**Files**: `lib/core/controllers/game_controller.dart`, navigation routes

**Actions**:
1. Insert Educational Content Screen into flow
2. Update navigation:
   - Old: Level Preview → Game Session
   - New: Level Preview → Educational Content → Game Session
3. Handle skip logic
4. Preserve back navigation

**Success Criteria**:
- Educational screen appears before game
- Skip works correctly
- Back button navigates properly
- No breaking changes

### C13: Test New Question Generation (Math)
**Time**: 2 hours  
**Actions**:
1. Generate 50 questions for each math skill
2. Manually review quality
3. Verify no meta-questions
4. Check difficulty scaling
5. Document any issues

**Success Criteria**:
- 0 meta-questions
- All questions test actual math knowledge
- Difficulty scales appropriately
- Quality score >80 average

### C14: Test New Question Generation (Physics/Chemistry/Biology)
**Time**: 2 hours  
**Actions**:
- Same as C13 for science subjects

### C15: Deploy New Question Generation System
**Time**: 1 hour  
**Actions**:
1. Enable new prompt system
2. Disable old generic prompts
3. Monitor generation quality
4. Track analytics
5. Prepare rollback plan

**Success Criteria**:
- New system generates high-quality questions
- No errors in production
- Quality metrics improve
- User feedback positive

---

## 🟠 PHASE D: IMPLEMENT LEVEL UNLOCKING SYSTEM

**Priority**: HIGH  
**Estimated Time**: 12 hours  
**Dependencies**: None (can run parallel to Phase C)

### D1: Define Skill Dependency Trees
**Time**: 2 hours  
**Files**: Create `lib/core/config/skill_dependencies.dart`

**Actions**:
1. Create dependency configuration for each subject
2. Define prerequisite relationships
3. Specify unlock criteria
4. Document progression paths

**Example Structure**:
```dart
final mathSkillDependencies = {
  'addition_subtraction': SkillDependency(
    skillId: 'addition_subtraction',
    prerequisites: [], // First skill, no prerequisites
    unlockCriteria: UnlockCriteria.none,
  ),
  
  'multiplication_division': SkillDependency(
    skillId: 'multiplication_division',
    prerequisites: ['addition_subtraction'],
    unlockCriteria: UnlockCriteria(
      requireAllLevelsComplete: true,
      OR: true,
      requireMinAccuracy: 0.70, // 70%
    ),
  ),
  
  'fractions': SkillDependency(
    skillId: 'fractions',
    prerequisites: ['multiplication_division'],
    unlockCriteria: UnlockCriteria(
      requireAllLevelsComplete: true,
      OR: true,
      requireMinAccuracy: 0.70,
    ),
  ),
  
  // ... more skills
};
```

**Success Criteria**:
- Dependencies defined for all subjects
- Clear progression paths
- Unlock criteria specified
- No circular dependencies

### D2: Create Level Progression Service
**Time**: 3 hours  
**Files**: Create `lib/core/services/level_progression_service.dart`

**Actions**:
1. Create service to manage skill unlocking
2. Implement methods:
   - `isSkillUnlocked(subject, skillId)`
   - `getUnlockRequirements(subject, skillId)`
   - `checkAndUnlockSkills(subject)`
   - `getProgressionPath(subject)`
3. Integrate with user progress tracking
4. Cache unlock states

**Success Criteria**:
- Service correctly determines unlock status
- Performance is fast (<10ms)
- Integrates with existing progress system

### D3: Update UI to Show Locked/Unlocked Skills
**Time**: 3 hours  
**Files**: `lib/features/subjects/subject_screen.dart`

**Actions**:
1. Add lock icon to locked skills
2. Show unlock requirements on tap
3. Disable navigation to locked skills
4. Add visual indicators (grayed out, etc.)
5. Show progress toward unlocking

**UI Design**:
```
Unlocked Skill:
┌──────────────────┐
│ ✅ Addition      │
│ Level 10/10      │
│ 85% Accuracy     │
└──────────────────┘

Locked Skill:
┌──────────────────┐
│ 🔒 Multiplication│
│ Complete Addition│
│ OR 70% Accuracy  │
└──────────────────┘
```

**Success Criteria**:
- Locked skills clearly indicated
- Unlock requirements visible
- Smooth user experience
- No confusion about progression

### D4: Implement Unlock Notifications
**Time**: 2 hours  
**Files**: Create `lib/widgets/skill_unlock_dialog.dart`

**Actions**:
1. Create celebration dialog for skill unlocks
2. Show when new skill becomes available
3. Animate unlock transition
4. Track unlock events in analytics

**Success Criteria**:
- Users notified when skills unlock
- Celebration feels rewarding
- Analytics track unlocks

### D5: Test Level Unlocking System
**Time**: 1 hour  
**Actions**:
1. Test all progression paths
2. Verify unlock criteria work
3. Test edge cases
4. Verify UI updates correctly

**Success Criteria**:
- All skills unlock correctly
- No bugs in progression logic
- UI updates in real-time

### D6: Document Progression System
**Time**: 1 hour  
**Deliverable**: User-facing documentation explaining progression

---

## 🔴 PHASE E: OPTIMIZE PERFORMANCE (<2 SECONDS)

**Priority**: CRITICAL  
**Estimated Time**: 16 hours  
**Dependencies**: Phase C complete (new questions available)

### E1: Implement Cache-First Strategy
**Time**: 3 hours  
**Files**: `lib/core/services/game_session_service.dart`

**Actions**:
1. Reorder session source priority:
   - OLD: Cache → Preloader → API → Fallback
   - NEW: Cache → Preloader → Fallback → API (only if needed)
2. Remove unnecessary API calls
3. Add timeout to API calls (2 seconds max)
4. Prefer cached content over fresh generation

**Success Criteria**:
- Cached content used first
- API calls only when necessary
- Timeout prevents long waits

### E2: Implement Aggressive Preloading
**Time**: 4 hours  
**Files**: `lib/core/services/fallback_content_preloader.dart`

**Actions**:
1. Preload next 3 skills when user enters subject
2. Preload in background during idle time
3. Use new high-quality question generation
4. Cache in memory AND storage
5. Preload on app startup

**Preloading Strategy**:
```
User opens app
    ↓
Preload popular subjects (Math, Physics)
    ↓
User selects Math
    ↓
Preload all Math skills (background)
    ↓
User selects Addition
    ↓
Preload Addition levels 1-10 (immediate)
Preload Multiplication levels 1-3 (background)
```

**Success Criteria**:
- Content available before user needs it
- Background preloading doesn't block UI
- Memory usage reasonable (<50MB)

### E3: Optimize UI Rendering
**Time**: 3 hours  
**Files**: Multiple screen files

**Actions**:
1. Add skeleton screens during loading
2. Lazy load images and animations
3. Reduce provider rebuilds
4. Optimize widget trees
5. Use `const` constructors where possible

**Success Criteria**:
- UI feels instant
- No janky animations
- Smooth transitions

### E4: Implement Loading Progress Indicators
**Time**: 2 hours  
**Files**: Update all navigation screens

**Actions**:
1. Show progress during preloading
2. Display "Preparing questions..." message
3. Add percentage indicators
4. Provide instant feedback on taps

**Success Criteria**:
- Users always know what's happening
- No "frozen" feeling
- Professional loading experience

### E5: Add Performance Monitoring
**Time**: 2 hours  
**Files**: `lib/core/services/performance_monitor.dart`

**Actions**:
1. Track load times for each operation
2. Log slow operations (>500ms)
3. Send metrics to analytics
4. Create performance dashboard

**Metrics to Track**:
- Cache hit rate
- API call frequency
- Average load time
- 95th percentile load time
- Preload success rate

**Success Criteria**:
- All operations monitored
- Slow operations identified
- Data-driven optimization

### E6: Benchmark and Optimize
**Time**: 2 hours  
**Actions**:
1. Run performance tests
2. Measure load times across all subjects
3. Identify remaining bottlenecks
4. Optimize critical paths
5. Verify <2 second target met

**Success Criteria**:
- 95% of loads complete in <2 seconds
- Average load time <1 second
- No regressions

---

## 🟠 PHASE F: FIX UI/UX ISSUES

**Priority**: HIGH  
**Estimated Time**: 10 hours  
**Dependencies**: Phase C complete (quality questions available)

### F1: Audit Levels 4-7 Across All Question Types
**Time**: 2 hours  
**Actions**:
1. Test all 7 question types at levels 4-7
2. Document specific bugs
3. Identify rendering issues
4. Test answer submission

**Success Criteria**:
- All bugs documented
- Reproduction steps clear

### F2: Fix Multiple Choice Rendering Issues
**Time**: 1 hour  
**Files**: `lib/widgets/question_types/multiple_choice_widget.dart`

### F3: Fix True/False Rendering Issues
**Time**: 1 hour  
**Files**: `lib/widgets/question_types/true_false_widget.dart`

### F4: Fix Numeric Input Issues
**Time**: 1 hour  
**Files**: `lib/widgets/question_types/numeric_input_widget.dart`

### F5: Fix Drag-Drop Issues
**Time**: 2 hours  
**Files**: `lib/widgets/question_types/drag_drop_widget.dart`

### F6: Test All Question Types End-to-End
**Time**: 3 hours  
**Actions**:
1. Play through complete games for each type
2. Verify scoring works
3. Test all difficulty levels
4. Confirm no crashes

**Success Criteria**:
- All question types playable
- No crashes or errors
- Scoring accurate
- User experience smooth

---

## 📊 IMPLEMENTATION PRIORITY

### Week 1 (Critical Path)
1. **Phase B**: Delete bad questions (2 hours)
2. **Phase C1-C6**: Create prompt templates (26 hours)
3. **Phase E1-E2**: Performance optimization basics (7 hours)

### Week 2 (Core Features)
4. **Phase C7-C12**: Complete AI system redesign (14 hours)
5. **Phase D1-D3**: Level unlocking basics (8 hours)
6. **Phase E3-E4**: UI optimization (5 hours)

### Week 3 (Testing & Polish)
7. **Phase C13-C15**: Test and deploy (5 hours)
8. **Phase D4-D6**: Complete unlocking system (4 hours)
9. **Phase E5-E6**: Performance monitoring (4 hours)
10. **Phase F**: Fix UI/UX issues (10 hours)

### Week 4 (Buffer & Documentation)
11. Final testing and bug fixes
12. Documentation updates
13. User acceptance testing

---

**Total Estimated Time**: 88 hours (11 working days)  
**Recommended Team Size**: 2-3 developers  
**Timeline**: 3-4 weeks with testing

---

**Next Step**: Begin Phase B - Delete existing bad questions

