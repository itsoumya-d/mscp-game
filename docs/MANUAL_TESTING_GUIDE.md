# Manual Testing Guide - Phase 2 Features

**Purpose**: Step-by-step guide for manually testing all Phase 2 implementations  
**Estimated Time**: 30-45 minutes  
**Prerequisites**: App is running on Windows desktop

---

## Before You Start

### Setup
1. ✅ App is already running (launched via `flutter run -d windows`)
2. Have a notepad ready to record any issues
3. Take screenshots of any visual problems
4. Note any crashes or unexpected behavior

### What to Look For
- ✅ Features work as expected
- ✅ UI displays correctly (no overflow, no clipping)
- ✅ Animations play smoothly
- ✅ Text is readable
- ✅ Buttons respond to clicks
- ❌ Crashes or freezes
- ❌ Error messages
- ❌ Visual glitches

---

## Test 1: Onboarding Flow (10 minutes)

### Objective
Verify the 5-screen onboarding experience for first-time users

### Steps

#### 1.1 Clear App Data (Simulate First-Time User)
```bash
# On Windows, SharedPreferences is stored in:
# %APPDATA%\<app_name>\shared_preferences\

# Option 1: Delete the folder manually
# Navigate to: C:\Users\<YourUsername>\AppData\Roaming\sp\

# Option 2: Uninstall and reinstall the app

# Option 3: Add a debug button to clear preferences (recommended)
```

**For now**: Just note if onboarding appears on first launch

#### 1.2 Test Onboarding Screens
1. Launch the app (if not already running)
2. **Expected**: Onboarding screen appears automatically
3. Verify you see 5 screens in sequence:
   - **Screen 1**: Welcome to LearnoSphere
   - **Screen 2**: Learn at Your Own Pace
   - **Screen 3**: Track Your Progress
   - **Screen 4**: Earn Rewards
   - **Screen 5**: Ready to Start!

#### 1.3 Test Skip Functionality
1. On Screen 1, click "Skip" button
2. **Expected**: Onboarding ends, navigates to home screen
3. **Record**: Did skip work? ✅ / ❌

#### 1.4 Test Complete Functionality
1. Restart app and clear data again
2. Navigate through all 5 screens using "Next" button
3. On Screen 5, click "Done" button
4. **Expected**: Onboarding ends, navigates to home screen
5. **Record**: Did completion work? ✅ / ❌

#### 1.5 Test Persistence
1. Restart the app (without clearing data)
2. **Expected**: Onboarding does NOT appear again
3. **Record**: Did persistence work? ✅ / ❌

### Success Criteria
- [ ] Onboarding appears on first launch
- [ ] All 5 screens display correctly
- [ ] Skip button works
- [ ] Done button works
- [ ] Onboarding doesn't reappear after completion
- [ ] Animations are smooth
- [ ] Text is readable

### Issues to Report
- Screen number where issue occurred
- What you expected vs. what happened
- Screenshot if visual issue
- Steps to reproduce

---

## Test 2: Help System (5 minutes)

### Objective
Verify the help button and help screen functionality

### Steps

#### 2.1 Navigate to Game Session
1. From home screen, select a subject (e.g., Physics)
2. Select a chapter (e.g., Mechanics)
3. Click "Start Learning" or similar button
4. **Expected**: Game session screen appears

#### 2.2 Locate Help Button
1. Look for help button (?) in the app bar (top right)
2. **Record**: Is help button visible? ✅ / ❌

#### 2.3 Test Help Screen
1. Click the help button (?)
2. **Expected**: Help screen appears with title "How to Play"
3. Verify the following sections are present:
   - **Game Basics**: How the game works
   - **Question Types**: All 7 types explained
     - Multiple Choice
     - True/False
     - Numeric Input
     - Fill in the Blank
     - Drag & Drop
     - Clickable Answer
     - Short Answer
   - **Rewards & Progress**: XP, gems, streaks
   - **Tips & Tricks**: Helpful advice

#### 2.4 Test Content Readability
1. Scroll through all sections
2. **Record**: Is all text readable? ✅ / ❌
3. **Record**: Are icons visible? ✅ / ❌
4. **Record**: Is layout clean? ✅ / ❌

#### 2.5 Test Navigation
1. Click back button or close button
2. **Expected**: Returns to game session screen
3. **Record**: Did navigation work? ✅ / ❌

### Success Criteria
- [ ] Help button visible in app bar
- [ ] Help button opens help screen
- [ ] All sections display correctly
- [ ] Content is readable and helpful
- [ ] Icons display correctly
- [ ] Back navigation works

### Issues to Report
- Location of help button (if not in app bar)
- Missing sections
- Unreadable text
- Layout issues
- Navigation problems

---

## Test 3: Question Type Tutorials (15 minutes)

### Objective
Verify tutorials appear for each of the 7 question types

### Steps

#### 3.1 Start a Game Session
1. Navigate to game session screen (if not already there)
2. Start answering questions

#### 3.2 Test Each Question Type
For EACH of the 7 question types, verify:

**Multiple Choice**
1. Encounter a multiple choice question
2. **Expected**: Tutorial dialog appears (first time only)
3. Dialog shows:
   - Title: "Multiple Choice"
   - Icon: ✓ checkmark
   - Instructions: "Select the correct answer from the options below"
4. Test "Skip" button → Dialog closes
5. **Record**: Tutorial appeared? ✅ / ❌

**True/False**
1. Encounter a true/false question
2. **Expected**: Tutorial dialog appears (first time only)
3. Dialog shows:
   - Title: "True or False"
   - Icon: ✓/✗
   - Instructions: "Decide if the statement is true or false"
4. Test "Got it!" button → Dialog closes, marked complete
5. **Record**: Tutorial appeared? ✅ / ❌

**Numeric Input**
1. Encounter a numeric input question
2. **Expected**: Tutorial dialog appears (first time only)
3. Dialog shows:
   - Title: "Numeric Input"
   - Icon: 123
   - Instructions: "Enter the numerical answer"
4. **Record**: Tutorial appeared? ✅ / ❌

**Fill in the Blank**
1. Encounter a fill-in-the-blank question
2. **Expected**: Tutorial dialog appears (first time only)
3. Dialog shows:
   - Title: "Fill in the Blank"
   - Icon: ___
   - Instructions: "Type the missing word or phrase"
4. **Record**: Tutorial appeared? ✅ / ❌

**Drag & Drop**
1. Encounter a drag & drop question
2. **Expected**: Tutorial dialog appears (first time only)
3. Dialog shows:
   - Title: "Drag & Drop"
   - Icon: ⇄
   - Instructions: "Match items by dragging"
4. **Record**: Tutorial appeared? ✅ / ❌

**Clickable Answer**
1. Encounter a clickable answer question
2. **Expected**: Tutorial dialog appears (first time only)
3. Dialog shows:
   - Title: "Clickable Answer"
   - Icon: 👆
   - Instructions: "Click on the correct part of the image"
4. **Record**: Tutorial appeared? ✅ / ❌

**Short Answer**
1. Encounter a short answer question
2. **Expected**: Tutorial dialog appears (first time only)
3. Dialog shows:
   - Title: "Short Answer"
   - Icon: ✍
   - Instructions: "Write a brief answer"
4. **Record**: Tutorial appeared? ✅ / ❌

#### 3.3 Test Persistence
1. Continue playing and encounter the same question types again
2. **Expected**: Tutorials do NOT reappear
3. **Record**: Tutorials stayed hidden? ✅ / ❌

### Success Criteria
- [ ] Tutorial appears for each question type (first time)
- [ ] Each tutorial has correct title and icon
- [ ] Instructions are clear and helpful
- [ ] Skip button works
- [ ] Got it! button works
- [ ] Tutorials don't reappear after completion/skip

### Issues to Report
- Question type where tutorial didn't appear
- Incorrect information in tutorial
- Button not working
- Tutorial reappearing after completion

---

## Test 4: Contextual Hint System (10 minutes)

### Objective
Verify hints appear after 3 wrong answers and work correctly

### Steps

#### 4.1 Trigger Hint Prompt
1. In a game session, intentionally answer 3 questions INCORRECTLY in a row
2. **Expected**: After 3rd wrong answer, hint prompt appears
3. Prompt shows:
   - Message: "Need some help?"
   - Gem cost: "5 gems"
   - Two buttons: "No Thanks" and "Use Hint"

#### 4.2 Test "No Thanks" Button
1. Click "No Thanks" button
2. **Expected**: Prompt closes, game continues
3. **Record**: Did button work? ✅ / ❌

#### 4.3 Test "Use Hint" Button (With Sufficient Gems)
1. Trigger hint prompt again (answer 3 questions wrong)
2. Verify you have at least 5 gems
3. Click "Use Hint" button
4. **Expected**:
   - 5 gems deducted from your balance
   - Hint display widget appears
   - Confetti animation plays
   - Actual hint text is shown
5. **Record**: Did hint display correctly? ✅ / ❌

#### 4.4 Test Hint Display
1. Verify hint text is readable
2. Verify confetti animation played
3. Click close button
4. **Expected**: Hint display closes
5. **Record**: Did close button work? ✅ / ❌

#### 4.5 Test "Use Hint" Button (Without Sufficient Gems)
1. If possible, reduce gems to less than 5
2. Trigger hint prompt again
3. Click "Use Hint" button
4. **Expected**: Error message or button disabled
5. **Record**: Did it handle insufficient gems? ✅ / ❌

### Success Criteria
- [ ] Hint prompt appears after 3 wrong answers
- [ ] Gem cost displayed correctly (5 gems)
- [ ] "No Thanks" button works
- [ ] "Use Hint" button deducts gems
- [ ] Hint text displays correctly
- [ ] Confetti animation plays
- [ ] Close button works
- [ ] Handles insufficient gems gracefully

### Issues to Report
- Hint prompt not appearing
- Incorrect gem cost
- Buttons not working
- Gems not deducted
- Hint text not displaying
- Animation not playing
- Error handling issues

---

## Test 5: UI/UX Verification (5 minutes)

### Objective
Verify all Phase 2 features have good UI/UX

### Steps

#### 5.1 Visual Consistency
1. Check that all Phase 2 screens match the app's theme
2. **Record**: Do colors match? ✅ / ❌
3. **Record**: Do fonts match? ✅ / ❌
4. **Record**: Do button styles match? ✅ / ❌

#### 5.2 Responsiveness
1. Resize the window (if on desktop)
2. **Record**: Does UI adapt? ✅ / ❌
3. **Record**: Any overflow errors? ✅ / ❌

#### 5.3 Animations
1. Observe all animations (onboarding transitions, confetti, etc.)
2. **Record**: Are animations smooth? ✅ / ❌
3. **Record**: Any lag or stuttering? ✅ / ❌

#### 5.4 Text Readability
1. Check all text in Phase 2 features
2. **Record**: Is all text readable? ✅ / ❌
3. **Record**: Any text cutoff? ✅ / ❌

### Success Criteria
- [ ] Visual consistency across all screens
- [ ] UI adapts to different window sizes
- [ ] No overflow errors
- [ ] Animations are smooth
- [ ] All text is readable

---

## Reporting Issues

### Issue Template

For each issue found, record:

```
**Issue #**: [Number]
**Feature**: [Onboarding / Help / Tutorial / Hint]
**Severity**: [Critical / High / Medium / Low]
**Description**: [What went wrong]
**Expected**: [What should happen]
**Actual**: [What actually happened]
**Steps to Reproduce**:
1. [Step 1]
2. [Step 2]
3. [Step 3]
**Screenshot**: [Attach if visual issue]
**Device**: Windows Desktop
**Flutter Version**: [Check with `flutter --version`]
```

### Severity Levels

- **Critical**: App crashes, feature completely broken
- **High**: Feature doesn't work as intended, major UX issue
- **Medium**: Feature works but has minor issues
- **Low**: Cosmetic issue, typo, minor improvement

---

## After Testing

### Summary Checklist

- [ ] All onboarding tests passed
- [ ] Help system tests passed
- [ ] All 7 question type tutorials tested
- [ ] Hint system tests passed
- [ ] UI/UX verification passed
- [ ] All issues documented
- [ ] Screenshots captured for visual issues

### Next Steps

1. **If all tests pass**: Proceed to Phase 3 implementation
2. **If issues found**: Fix issues and retest
3. **If critical issues**: Stop and address immediately

### Report Submission

Submit your testing results with:
1. Completed checklist
2. List of all issues found
3. Screenshots of visual issues
4. Recommendations for improvements

---

## Quick Reference

### Files to Reference
- `lib/features/onboarding/app_onboarding_screen.dart`
- `lib/features/help/how_to_play_screen.dart`
- `lib/features/tutorials/question_type_tutorial_widget.dart`
- `lib/shared/widgets/contextual_hint_widget.dart`
- `lib/core/services/tutorial_service.dart`

### Common Issues and Solutions

**Issue**: Onboarding doesn't appear
**Solution**: Clear SharedPreferences or app data

**Issue**: Tutorial appears every time
**Solution**: Check TutorialService persistence

**Issue**: Hint prompt doesn't appear
**Solution**: Verify 3 wrong answers in a row

**Issue**: Confetti doesn't play
**Solution**: Check confetti package integration

---

**Happy Testing!** 🧪✅

If you encounter any issues, document them thoroughly and we'll address them before proceeding to Phase 3.


