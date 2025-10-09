# Phase 3: Feature Design & Specification
**LearnoSphere Enhancement - Detailed Feature Designs**

**Date**: 2025-10-01  
**Status**: ✅ PHASE 3 COMPLETE  
**Previous Phase**: Phase 2 - Research & Best Practices  
**Next Phase**: Phase 4 - Task List Creation

---

## 📋 EXECUTIVE SUMMARY

This phase provides detailed specifications for three major feature enhancements:
1. **Enhanced Reward System** - Complete currency design and spending mechanics
2. **AI Content Generation System** - Never-ending game with automatic chapter generation
3. **Candy Crush-Style Level Map** - Enhanced visual design with animations

---

## 1️⃣ ENHANCED REWARD SYSTEM DESIGN

### 1.1 Currency Types & Purposes

#### **Diamonds/Gems (Premium Currency)**

**Primary Purpose**: Premium features and convenience
**Earning Mechanics**:
- Daily login: 1 gem
- 3-day streak: 2 gems
- 7-day streak: 5 gems
- Level completion: 1-2 gems (based on difficulty)
- Every 5 levels: 10 gems (milestone)
- Perfect game (100% accuracy): 5 gems
- Achievements: 5-50 gems
- Special events: 10-100 gems

**Spending Mechanics**:
- Skip question: 2 gems
- Hint: 1 gem
- Streak freeze: 5 gems (protect streak for 1 day)
- Extra life: 3 gems
- Unlock premium content: 50-100 gems
- Customize avatar: 20-50 gems
- Remove ads (future): 500 gems

**Starting Balance**: 10 gems (new users)
**Display**: Top-right corner, diamond icon

#### **Coins (Soft Currency)**

**Primary Purpose**: In-game purchases and progression
**Earning Mechanics**:
- Question answered correctly: 2 coins
- Level completion: 10-20 coins (based on score)
- Daily challenge: 50 coins
- Skill mastery: 100 coins
- Level-up: 50 coins

**Spending Mechanics**:
- Buy hints: 5 coins
- Unlock bonus levels: 100 coins
- Practice mode (unlimited lives): 50 coins
- Review past questions: 20 coins
- Unlock cosmetics: 50-200 coins

**Starting Balance**: 100 coins (new users)
**Display**: Top-left corner, coin icon

#### **XP (Experience Points)**

**Primary Purpose**: Level progression and content unlocking
**Earning Mechanics**:
- Base XP per question: 10 XP
- Difficulty multiplier: 1x (easy), 2x (medium), 3x (hard)
- Accuracy bonus: +50% XP if 100% correct
- Speed bonus: +20 XP if under 30 seconds
- Streak bonus: +5 XP per day of streak
- First try bonus: +20 XP

**Calculation Formula**:
```dart
int calculateXP({
  required int baseXP,
  required int difficulty,
  required double accuracy,
  required int timeSeconds,
  required int streak,
  required bool firstTry,
}) {
  int xp = baseXP * difficulty;
  
  if (accuracy == 1.0) {
    xp = (xp * 1.5).round();
  }
  
  if (timeSeconds <= 30) {
    xp += 20;
  }
  
  xp += streak * 5;
  
  if (firstTry) {
    xp += 20;
  }
  
  return xp;
}
```

**Level-Up Requirements**:
- Level 1 → 2: 100 XP
- Level 2 → 3: 200 XP
- Level 3 → 4: 300 XP
- Formula: `XP_needed = level * 100`

**Purpose**: Unlock new subjects, skills, and features
**Display**: Profile screen, progress bars

### 1.2 Reward Collection Animations

#### **Coin Collection**
```dart
class CoinCollectionAnimation extends StatefulWidget {
  final int coins;
  final VoidCallback? onComplete;
  
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: IntTween(begin: 0, end: coins),
      duration: Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monetization_on, color: Colors.amber, size: 32),
            SizedBox(width: 8),
            Text(
              '+$value',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ],
        );
      },
      onEnd: onComplete,
    );
  }
}
```

#### **Gem Collection**
- Sparkle effect
- Scale-up animation
- Rainbow glow
- Chime sound

#### **XP Collection**
- Progress bar fill animation
- Level-up celebration if threshold reached
- Fanfare sound

### 1.3 Currency Display

**Top Bar Design**:
```
┌─────────────────────────────────────────┐
│  [Coin Icon] 1,234    [Gem Icon] 56    │
│  [XP Bar: ████████░░ Level 12]         │
└─────────────────────────────────────────┘
```

**Implementation**:
```dart
class CurrencyDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Coins
          _CurrencyItem(
            icon: Icons.monetization_on,
            color: Colors.amber,
            value: coins,
          ),
          
          // Gems
          _CurrencyItem(
            icon: Icons.diamond,
            color: Colors.blue,
            value: gems,
          ),
          
          // XP Progress
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Level $level', style: TextStyle(fontSize: 12)),
                  LinearProgressIndicator(
                    value: xpProgress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation(Colors.green),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 2️⃣ AI CONTENT GENERATION SYSTEM DESIGN

### 2.1 Automatic Chapter Generation

#### **Trigger Conditions**
1. **User Progress**: When user completes 80% of current chapters
2. **Time-Based**: Every 7 days, check if new content needed
3. **Manual**: Admin can trigger generation
4. **On-Demand**: When user reaches end of content

#### **Generation Process**
```dart
class AutomaticChapterGenerator {
  Future<void> generateNewChapter({
    required SubjectType subject,
    required String previousChapter,
  }) async {
    // 1. Analyze user progress
    final progress = await _analyzeProgress(subject);
    
    // 2. Determine next topic
    final nextTopic = await _determineNextTopic(
      subject: subject,
      previousChapter: previousChapter,
      userLevel: progress.level,
      weakAreas: progress.weakAreas,
    );
    
    // 3. Generate chapter structure
    final chapter = await _generateChapterStructure(
      subject: subject,
      topic: nextTopic,
      skillCount: 6, // 6 skills per chapter
      levelsPerSkill: 10, // 10 levels per skill
    );
    
    // 4. Generate questions for first 3 levels
    await _preGenerateQuestions(
      chapter: chapter,
      levelsToPreGenerate: 3,
    );
    
    // 5. Save to database
    await _saveChapter(chapter);
    
    // 6. Notify user
    await _notifyNewContent(chapter);
  }
}
```

#### **Chapter Structure**
```dart
class Chapter {
  final String id;
  final String name;
  final String description;
  final SubjectType subject;
  final int order;
  final List<Skill> skills;
  final DateTime createdAt;
  final bool isGenerated; // true if AI-generated
  
  // Example: "Advanced Algebra"
  // Skills: Quadratic Equations, Polynomials, Factoring, etc.
}
```

#### **Topic Progression**
**Math Example**:
1. Basic Arithmetic (pre-defined)
2. Fractions & Decimals (pre-defined)
3. Basic Algebra (pre-defined)
4. **Advanced Algebra** (AI-generated)
5. **Trigonometry Basics** (AI-generated)
6. **Calculus Introduction** (AI-generated)

### 2.2 Question Variety System

#### **Question Type Distribution**
```dart
Map<int, Map<QuestionType, int>> getQuestionDistribution(int level) {
  if (level <= 3) {
    // Beginner: Simple types
    return {
      QuestionType.multipleChoice: 3,
      QuestionType.trueFalse: 2,
      QuestionType.numericInput: 2,
    };
  } else if (level <= 7) {
    // Intermediate: Mixed types
    return {
      QuestionType.multipleChoice: 2,
      QuestionType.numericInput: 2,
      QuestionType.fillInTheBlank: 2,
      QuestionType.trueFalse: 1,
    };
  } else {
    // Advanced: All types
    return {
      QuestionType.multipleChoice: 2,
      QuestionType.dragDrop: 1,
      QuestionType.fillInTheBlank: 2,
      QuestionType.shortAnswer: 1,
      QuestionType.numericInput: 1,
    };
  }
}
```

#### **Diversity Enforcement**
```dart
class QuestionDiversityManager {
  List<Question> ensureDiversity(List<Question> questions) {
    // 1. Check type distribution
    final typeCount = <QuestionType, int>{};
    for (final q in questions) {
      typeCount[q.type] = (typeCount[q.type] ?? 0) + 1;
    }
    
    // 2. Ensure no type appears more than 3 times
    if (typeCount.values.any((count) => count > 3)) {
      return _rebalanceTypes(questions);
    }
    
    // 3. Ensure difficulty progression
    questions.sort((a, b) => a.difficulty.compareTo(b.difficulty));
    
    return questions;
  }
}
```

### 2.3 Difficulty Scaling Algorithm

#### **Adaptive Difficulty**
```dart
class AdaptiveDifficultyScaler {
  int calculateNextDifficulty({
    required int currentDifficulty,
    required double recentAccuracy,
    required int consecutiveCorrect,
    required int consecutiveIncorrect,
  }) {
    int newDifficulty = currentDifficulty;
    
    // Increase difficulty if performing well
    if (recentAccuracy >= 0.9 && consecutiveCorrect >= 3) {
      newDifficulty++;
    }
    
    // Decrease difficulty if struggling
    if (recentAccuracy < 0.5 || consecutiveIncorrect >= 3) {
      newDifficulty--;
    }
    
    // Gradual increase over time
    if (recentAccuracy >= 0.7) {
      newDifficulty += 0.1; // Slow increase
    }
    
    return newDifficulty.clamp(1, 10);
  }
}
```

### 2.4 Content Quality Validation

#### **Validation Checks**
```dart
class ContentQualityValidator {
  Future<bool> validateQuestion(Question question) async {
    // 1. Structure validation
    if (!_hasRequiredFields(question)) return false;
    
    // 2. Content validation
    if (!_hasValidContent(question)) return false;
    
    // 3. Options validation (for multiple choice)
    if (question.type == QuestionType.multipleChoice) {
      if (question.options.length != 4) return false;
      if (question.options.contains(question.correctAnswer) == false) {
        return false;
      }
    }
    
    // 4. Difficulty validation
    if (question.difficulty < 1 || question.difficulty > 10) return false;
    
    // 5. Explanation validation
    if (question.explanation.isEmpty) return false;
    
    return true;
  }
  
  bool _hasValidContent(Question question) {
    // Check for placeholder text
    if (question.questionText.contains('[INSERT]')) return false;
    if (question.questionText.contains('TODO')) return false;
    
    // Check for minimum length
    if (question.questionText.length < 10) return false;
    
    // Check for proper formatting
    if (!question.questionText.endsWith('?') && 
        !question.questionText.contains('Calculate')) {
      return false;
    }
    
    return true;
  }
}
```

### 2.5 Content Caching & Preloading

#### **Preloading Strategy**
```dart
class ContentPreloadingService {
  Future<void> preloadContent() async {
    // 1. Preload next 3 levels for current skill
    await _preloadLevels(
      skill: currentSkill,
      startLevel: currentLevel + 1,
      count: 3,
    );
    
    // 2. Preload first level of next skill
    await _preloadLevels(
      skill: nextSkill,
      startLevel: 1,
      count: 1,
    );
    
    // 3. Cache in SQLite
    await _cacheToDatabase();
  }
  
  Future<List<Question>> getQuestions({
    required SubjectType subject,
    required String skillId,
    required int level,
  }) async {
    // 1. Check cache first
    final cached = await _getCachedQuestions(subject, skillId, level);
    if (cached != null) return cached;
    
    // 2. Generate if not cached
    final questions = await _generateQuestions(subject, skillId, level);
    
    // 3. Cache for future use
    await _cacheQuestions(questions);
    
    return questions;
  }
}
```

---

## 3️⃣ CANDY CRUSH-STYLE LEVEL MAP DESIGN

### 3.1 Visual Layout Specification

#### **Screen Layout**
```
┌─────────────────────────────────────────┐
│  ← Back    Skill Name    [Coins] [Gems] │ ← Header
├─────────────────────────────────────────┤
│                                         │
│         ⭐⭐⭐                           │ ← Level 10
│          (10)                           │
│           │                             │
│           │ (curved path)               │
│           │                             │
│      ⭐⭐☆                              │ ← Level 9
│       (9)                               │
│           │                             │
│           │                             │
│           │                             │
│         ⭐☆☆                           │ ← Level 8
│          (8)                            │
│           │                             │
│          ...                            │
│           │                             │
│         ⭐⭐⭐⭐⭐                      │ ← Level 1
│          (1)                            │
│                                         │
└─────────────────────────────────────────┘
```

#### **Node Design**
```dart
class LevelNode extends StatelessWidget {
  final LevelNodeData data;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _getGradient(data.state),
        border: Border.all(
          color: _getBorderColor(data.state),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: _getGlowColor(data.state),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Level number
          Center(
            child: Text(
              '${data.level}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          // Stars
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Icon(
                  i < data.stars ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                ),
              }),
            ),
          ),
          
          // Lock icon (if locked)
          if (data.state == LevelNodeState.locked)
            Center(
              child: Icon(Icons.lock, color: Colors.white, size: 32),
            ),
        ],
      ),
    );
  }
}
```

### 3.2 Animation Specifications

#### **Path Reveal Animation**
- Duration: 500ms per segment
- Curve: Curves.easeInOut
- Effect: Path draws from previous node to new node

#### **Node Unlock Animation**
- Lock fade-out: 300ms
- Scale-up: 400ms (0.8 → 1.2 → 1.0)
- Color transition: 300ms (gray → colored)
- Particle burst: 500ms (20 particles)
- Glow pulse: Continuous (1s cycle)

#### **Node Tap Animation**
- Unlocked: Scale down (0.95) → Scale up (1.05) → Normal (1.0)
- Locked: Shake (±5px horizontal, 400ms)

### 3.3 Interaction Design

#### **Tap Behaviors**
```dart
void handleNodeTap(LevelNodeData node) {
  switch (node.state) {
    case LevelNodeState.locked:
      _playShakeAnimation();
      _showLockedTooltip();
      SoundManagerService.instance.playIncorrectAnswer();
      break;
      
    case LevelNodeState.unlocked:
    case LevelNodeState.current:
      _playTapAnimation();
      _navigateToLevelPreview(node);
      SoundManagerService.instance.playButtonClick();
      break;
      
    case LevelNodeState.completed:
      _playTapAnimation();
      _showCompletionStats(node);
      SoundManagerService.instance.playButtonClick();
      break;
  }
}
```

---

**End of Phase 3 Report**

**Next Steps**: Proceed to Phase 4 - Task List Creation

