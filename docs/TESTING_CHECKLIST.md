# LearnoSphere Testing Checklist
**Date**: 2025-10-02  
**Version**: 1.0  
**Purpose**: Comprehensive testing checklist for all features before app store submission

---

## Phase 1: Critical Bug Fixes Testing ✅

### Test 1.1: RangeError Fix
**Status**: ⏳ Pending  
**File**: `lib/features/lessons/widgets/question_widget.dart:470-515`

**Test Cases**:
- [ ] Question with 4 options displays correctly
- [ ] Question with 6 options displays correctly
- [ ] Question with 8+ options displays only first 6
- [ ] No RangeError in console logs
- [ ] All options are clickable

**How to Test**:
1. Navigate to any subject → any skill → Level 1
2. Play through questions
3. Check console for errors
4. Verify all options display correctly

**Expected Result**: No crashes, max 6 options displayed

---

### Test 1.2: UI Overflow Fix
**Status**: ⏳ Pending  
**File**: `lib/features/lessons/widgets/question_widget.dart:130-182`

**Test Cases**:
- [ ] No "RenderFlex overflowed" warnings in console
- [ ] All content visible on small screens (iPhone SE, 4.7")
- [ ] Hint section displays correctly
- [ ] Scrolling works smoothly when content exceeds screen height
- [ ] Submit button always visible

**How to Test**:
1. Resize window to small size (375x667 for iPhone SE)
2. Play a level with hints
3. Show hint and verify it's visible
4. Check console for overflow warnings

**Expected Result**: No overflow, all content scrollable

---

### Test 1.3: Skill-Specific Content Fix
**Status**: ⏳ Pending  
**File**: `lib/core/services/predefined_games_manager.dart:187-834`

**Test Cases - Math**:
- [ ] Addition skill shows ONLY addition/subtraction questions
- [ ] Multiplication skill shows ONLY multiplication/division questions
- [ ] Fractions skill shows ONLY fraction questions
- [ ] Variables skill shows ONLY algebra questions
- [ ] Geometry skill shows ONLY geometry questions
- [ ] Measurement skill shows ONLY measurement questions

**How to Test**:
1. Home → Math → Addition & Subtraction → Level 1
2. Play all 7 questions
3. Verify each question is about addition or subtraction
4. Repeat for other skills

**Expected Result**: Each skill shows only relevant questions

---

## Phase 2: Subject-Specific Content Testing

### Test 2.1: Physics Content
**Status**: ⏳ Pending

**Test Cases**:
- [ ] Newtonian Motion skill shows physics questions (forces, F=ma)
- [ ] Work & Energy skill shows energy questions (kinetic, potential)
- [ ] Optics skill shows light/reflection questions
- [ ] No math questions in physics levels
- [ ] skillId='newton', 'energy', 'optics' passed correctly

**How to Test**:
1. Home → Physics → Newtonian Motion → Level 1
2. Verify questions about forces, acceleration, Newton's laws
3. Repeat for other physics skills

**Expected Result**: Physics-specific questions only

---

### Test 2.2: Chemistry Content
**Status**: ⏳ Pending

**Test Cases**:
- [ ] Periodic Table skill shows element/symbol questions
- [ ] Chemical Bonding skill shows ionic/covalent bond questions
- [ ] Stoichiometry skill shows mole/Avogadro's number questions
- [ ] No math or physics questions
- [ ] skillId='periodic', 'bonding', 'stoich' passed correctly

**How to Test**:
1. Home → Chemistry → Periodic Table Basics → Level 1
2. Verify questions about elements, symbols, periodic table
3. Repeat for other chemistry skills

**Expected Result**: Chemistry-specific questions only

---

### Test 2.3: Biology Content
**Status**: ⏳ Pending

**Test Cases**:
- [ ] Cell Parts skill shows organelle questions (mitochondria, nucleus)
- [ ] Genetics skill shows DNA/chromosome questions
- [ ] Food Chain skill shows producer/consumer/decomposer questions
- [ ] No math, physics, or chemistry questions
- [ ] skillId='cell_parts', 'genetics', 'food_chain' passed correctly

**How to Test**:
1. Home → Biology → Cell Parts → Level 1
2. Verify questions about cell organelles
3. Repeat for other biology skills

**Expected Result**: Biology-specific questions only

---

### Test 2.4: Geography Content
**Status**: ⏳ Pending

**Test Cases**:
- [ ] Landforms skill shows mountain/valley/river questions
- [ ] Climate skill shows weather/climate zone questions
- [ ] Ecosystems skill shows biome/habitat questions
- [ ] skillId='landforms', 'climate', 'ecosystems' passed correctly

**How to Test**:
1. Home → Geography → Landforms → Level 1
2. Verify questions about geographical features
3. Repeat for other geography skills

**Expected Result**: Geography-specific questions only

---

### Test 2.5: History Content
**Status**: ⏳ Pending

**Test Cases**:
- [ ] Mesopotamia skill shows Sumerian/Babylonian questions
- [ ] Egypt skill shows pyramid/pharaoh questions
- [ ] Greece skill shows Athens/Sparta questions
- [ ] skillId='mesopotamia', 'egypt', 'greece' passed correctly

**How to Test**:
1. Home → History → Mesopotamia → Level 1
2. Verify questions about ancient Mesopotamia
3. Repeat for other history skills

**Expected Result**: History-specific questions only

---

## Phase 3: Level Progression Testing

### Test 3.1: Level Unlocking
**Status**: ⏳ Pending

**Test Cases**:
- [ ] Complete Level 1 with 100% accuracy → Level 2 unlocks
- [ ] Complete Level 1 with 50% accuracy → Level 2 stays locked
- [ ] Complete Level 1 three times with 80% accuracy → Level 2 unlocks
- [ ] XP requirements match level_progression_service.dart
- [ ] Level unlocking persists after app restart

**How to Test**:
1. Start fresh (clear app data)
2. Play Level 1, get all questions correct
3. Check if Level 2 is unlocked
4. Restart app, verify Level 2 still unlocked

**Expected Result**: Levels unlock based on performance

---

### Test 3.2: XP System
**Status**: ⏳ Pending

**Test Cases**:
- [ ] XP awarded for correct answers
- [ ] XP deducted for using hints
- [ ] XP requirements: Level 2=100, Level 3=250, Level 4=450, etc.
- [ ] XP progress bar updates correctly
- [ ] Total XP persists after app restart

**How to Test**:
1. Complete a level, note XP earned
2. Check XP progress bar
3. Restart app, verify XP persists

**Expected Result**: XP system works correctly

---

## Phase 4: UI/UX Testing

### Test 4.1: Responsive Design
**Status**: ⏳ Pending

**Test Cases**:
- [ ] Small phone (iPhone SE, 4.7") - all content visible
- [ ] Medium phone (iPhone 13, 6.1") - optimal layout
- [ ] Large phone (iPhone 13 Pro Max, 6.7") - no wasted space
- [ ] Small tablet (iPad Mini, 7.9") - tablet-optimized layout
- [ ] Large tablet (iPad Pro, 12.9") - multi-column layout

**How to Test**:
1. Resize window to different sizes
2. Check all screens: home, subject, level, game, results
3. Verify no overflow, no wasted space

**Expected Result**: App looks good on all screen sizes

---

### Test 4.2: Landscape Orientation
**Status**: ⏳ Pending

**Test Cases**:
- [ ] Home screen works in landscape
- [ ] Subject screen works in landscape
- [ ] Level selection works in landscape
- [ ] Game session works in landscape
- [ ] Results screen works in landscape

**How to Test**:
1. Rotate device/window to landscape
2. Navigate through all screens
3. Verify layout adjusts appropriately

**Expected Result**: All screens work in landscape

---

## Phase 5: Question Type Testing

### Test 5.1: Multiple Choice
**Status**: ⏳ Pending

**Test Cases**:
- [ ] 4 options display correctly
- [ ] 6 options display correctly
- [ ] Selected option highlights
- [ ] Correct answer shows green
- [ ] Incorrect answer shows red
- [ ] Explanation displays after submission

**How to Test**:
1. Play a level with multiple choice questions
2. Select an option
3. Submit answer
4. Verify feedback

**Expected Result**: Multiple choice works correctly

---

### Test 5.2: True/False
**Status**: ⏳ Pending

**Test Cases**:
- [ ] True/False buttons display
- [ ] Selected button highlights
- [ ] Correct answer feedback
- [ ] Incorrect answer feedback

**How to Test**:
1. Play a level with true/false questions
2. Select True or False
3. Submit answer
4. Verify feedback

**Expected Result**: True/False works correctly

---

### Test 5.3: Numeric Input
**Status**: ⏳ Pending

**Test Cases**:
- [ ] Keyboard appears for input
- [ ] Can type numbers
- [ ] Submit button enables when input provided
- [ ] Correct answer accepted
- [ ] Incorrect answer rejected

**How to Test**:
1. Play a level with numeric input questions
2. Type a number
3. Submit answer
4. Verify feedback

**Expected Result**: Numeric input works correctly

---

### Test 5.4: Fill in the Blank
**Status**: ⏳ Pending

**Test Cases**:
- [ ] Text field displays
- [ ] Can type text
- [ ] Submit button enables when input provided
- [ ] Correct answer accepted (case-insensitive)
- [ ] Incorrect answer rejected

**How to Test**:
1. Play a level with fill-in-the-blank questions
2. Type an answer
3. Submit answer
4. Verify feedback

**Expected Result**: Fill in the blank works correctly

---

### Test 5.5: Drag & Drop
**Status**: ⏳ Pending

**Test Cases**:
- [ ] Left and right items display
- [ ] Can drag items
- [ ] Items snap to drop zones
- [ ] Correct matches accepted
- [ ] Incorrect matches rejected
- [ ] Can undo matches

**How to Test**:
1. Play a level with drag & drop questions
2. Drag items to match
3. Submit answer
4. Verify feedback

**Expected Result**: Drag & drop works correctly

---

### Test 5.6: Clickable Answer
**Status**: ⏳ Pending

**Test Cases**:
- [ ] Multiple options can be selected
- [ ] Selected options highlight
- [ ] Can deselect options
- [ ] Correct combination accepted
- [ ] Incorrect combination rejected

**How to Test**:
1. Play a level with clickable answer questions
2. Click multiple options
3. Submit answer
4. Verify feedback

**Expected Result**: Clickable answer works correctly

---

### Test 5.7: Short Answer
**Status**: ⏳ Pending

**Test Cases**:
- [ ] Text area displays
- [ ] Can type multi-line text
- [ ] Submit button enables when input provided
- [ ] Answer validated correctly

**How to Test**:
1. Play a level with short answer questions
2. Type a short answer
3. Submit answer
4. Verify feedback

**Expected Result**: Short answer works correctly

---

## Phase 6: Performance Testing

### Test 6.1: App Startup
**Status**: ⏳ Pending

**Test Cases**:
- [ ] App starts in < 3 seconds
- [ ] Splash screen displays
- [ ] No crashes on startup
- [ ] Firebase initializes correctly

**How to Test**:
1. Close app completely
2. Launch app
3. Time from launch to home screen
4. Check console for errors

**Expected Result**: Fast, smooth startup

---

### Test 6.2: Memory Usage
**Status**: ⏳ Pending

**Test Cases**:
- [ ] Memory usage < 200MB during gameplay
- [ ] No memory leaks
- [ ] App doesn't crash after extended use

**How to Test**:
1. Play 10+ levels continuously
2. Monitor memory usage
3. Check for crashes

**Expected Result**: Stable memory usage

---

### Test 6.3: Question Loading
**Status**: ⏳ Pending

**Test Cases**:
- [ ] Questions load in < 1 second
- [ ] No lag between questions
- [ ] Smooth transitions

**How to Test**:
1. Play a level
2. Time question loading
3. Check for lag

**Expected Result**: Fast question loading

---

## Phase 7: Accessibility Testing

### Test 7.1: Screen Reader
**Status**: ⏳ Pending

**Test Cases**:
- [ ] All buttons have labels
- [ ] Questions are read aloud
- [ ] Navigation works with screen reader
- [ ] Feedback is announced

**How to Test**:
1. Enable TalkBack (Android) or VoiceOver (iOS)
2. Navigate through app
3. Verify all elements are accessible

**Expected Result**: Fully accessible with screen reader

---

### Test 7.2: Font Scaling
**Status**: ⏳ Pending

**Test Cases**:
- [ ] App works at 100% font size
- [ ] App works at 150% font size
- [ ] App works at 200% font size
- [ ] No text cutoff

**How to Test**:
1. Change system font size
2. Navigate through app
3. Verify all text is readable

**Expected Result**: Works at all font sizes

---

## Test Summary

**Total Tests**: 50+  
**Passed**: 0  
**Failed**: 0  
**Pending**: 50+

**Critical Tests** (must pass before release):
- [ ] No crashes
- [ ] Skill-specific content works
- [ ] Level progression works
- [ ] All question types work
- [ ] Responsive design works

**Nice-to-Have Tests** (can be fixed post-release):
- [ ] Accessibility
- [ ] Performance optimization
- [ ] Landscape orientation

---

## Testing Notes

**Date**: 2025-10-02  
**Tester**: AI Development Team  
**Device**: Windows Desktop  
**OS Version**: Windows 11  
**App Version**: 1.0.0

**Issues Found**:
1. [List issues here as they're discovered]

**Fixes Applied**:
1. ✅ RangeError in question_widget.dart
2. ✅ RenderFlex overflow in question_widget.dart
3. ✅ Skill-specific content in predefined_games_manager.dart

---

**Next Steps**:
1. Run app and complete Phase 1 testing
2. Document any issues found
3. Fix issues and re-test
4. Move to Phase 2 testing
5. Continue until all tests pass

