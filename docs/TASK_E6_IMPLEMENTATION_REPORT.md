# Task E6: Question Diversity Manager - Implementation Report
**Category E: AI Content Generation Enhancement**

**Date**: 2025-10-02  
**Status**: ✅ COMPLETE  
**Time Spent**: ~1 hour  
**Estimated Time**: 1 hour

---

## 📊 IMPLEMENTATION SUMMARY

Created a comprehensive `QuestionDiversityManager` service that ensures varied and engaging 7-question game sessions. The system enforces type distribution, prevents repetition, balances difficulty, and varies topics to provide optimal learning experiences.

---

## 📁 FILES CREATED

### 1. `lib/core/services/question_diversity_manager.dart` (400+ lines)

**Purpose**: Manage question diversity in 7-question game sessions

**Key Classes**:
- **QuestionDiversityManager**: Main service (singleton)
- **QuestionFingerprint**: Duplicate detection with hash
- **TopicRotationState**: Systematic topic coverage

---

## 🔍 KEY FEATURES IMPLEMENTED

### 1. **Type Distribution (Max 3 of Same Type)**

**Constraint**: Maximum 3 questions of the same type per game

**Major Types Required**:
- Multiple Choice (minimum 1)
- Numeric Input (minimum 1)
- Drag & Drop (minimum 1)

**Implementation**:
```dart
final typeCounts = <QuestionType, int>{};

for (final question in shuffled) {
  final count = typeCounts[question.type] ?? 0;
  
  if (count < _maxSameTypePerGame) { // Max 3
    balanced.add(question);
    typeCounts[question.type] = count + 1;
  }
}
```

**Randomization**:
- Shuffles questions before selection
- Avoids predictable patterns
- No fixed starting type

---

### 2. **Repetition Prevention**

**Tracking Window**: Last 20 questions per subject

**Prevention Window**: Last 10 questions (no duplicates)

**Question Fingerprinting**:
```dart
String _generateFingerprint(Question question) {
  final content = StringBuffer();
  content.write(question.questionText.toLowerCase().trim());
  content.write('|');
  content.write(question.correctAnswer.toLowerCase().trim());
  
  if (question.options != null) {
    final sortedOptions = List<String>.from(question.options!)..sort();
    content.write('|');
    content.write(sortedOptions.join(','));
  }

  final bytes = utf8.encode(content.toString());
  final digest = sha256.convert(bytes);
  return digest.toString();
}
```

**Hash Components**:
- Question text (normalized)
- Correct answer (normalized)
- Options (sorted for consistency)
- SHA-256 hash for uniqueness

**Storage**:
- Persistent in SharedPreferences
- Per-subject tracking
- Timestamp for each question

---

### 3. **Difficulty Distribution**

**Difficulty Mix by User Level**:

| User Level | Easy | Medium | Hard |
|------------|------|--------|------|
| **Beginner (1-3)** | 3 | 3 | 1 |
| **Intermediate (4-7)** | 2 | 3 | 2 |
| **Advanced (8-10)** | 2 | 2 | 3 |

**Categorization**:
```dart
if (q.difficulty <= userLevel - 2) {
  easy.add(q);
} else if (q.difficulty >= userLevel + 2) {
  hard.add(q);
} else {
  medium.add(q);
}
```

**Question Arrangement**:
1. **Start**: Easiest question (confidence boost)
2. **Middle**: Gradually increase difficulty
3. **End**: Medium difficulty (accomplished feeling)

---

### 4. **Topic Variation**

**Topic Extraction**:
```dart
String _extractTopic(Question question) {
  final text = question.questionText.toLowerCase();
  
  // Math topics
  if (text.contains('equation')) return 'equations';
  if (text.contains('inequality')) return 'inequalities';
  if (text.contains('function')) return 'functions';
  // ... more topics
  
  return 'general';
}
```

**Supported Topics**:
- **Math**: equations, inequalities, functions, fractions, decimals, percentages
- **Physics**: forces, energy, motion, velocity
- **Chemistry**: atoms, molecules, reactions, bonding
- **Biology**: cells, genetics, evolution

**Rotation Strategy**:
- Round-robin through available topics
- Avoid clustering (max 2 consecutive from same topic)
- Track rotation state per subject/skill
- Persistent storage

---

## 🎯 MAIN METHOD

### `diversifyQuestions()`

**Parameters**:
```dart
Future<List<Question>> diversifyQuestions({
  required List<Question> candidateQuestions,
  required SubjectType subject,
  required String skillId,
  required int userPerformanceLevel, // 1-10
})
```

**Process Flow**:
```
1. Filter recent duplicates (last 10 questions)
   ↓
2. Balance question types (max 3 of same type)
   ↓
3. Balance difficulty (based on user level)
   ↓
4. Vary topics (rotate through concepts)
   ↓
5. Arrange questions (easy → medium → hard → medium)
   ↓
6. Take exactly 7 questions
   ↓
7. Track questions (add to recent history)
   ↓
8. Log diversity stats (debug mode)
   ↓
Return diversified questions
```

---

## 💡 USAGE EXAMPLES

### Example 1: Basic Usage in GameSessionService

```dart
final diversityManager = QuestionDiversityManager.instance;
await diversityManager.initialize();

// Get candidate questions (e.g., 20-30 questions)
final candidates = await aiGenerator.generateQuestions(
  subject: SubjectType.math,
  skillId: 'algebra',
  count: 30,
);

// Get user performance level
final difficultyService = ProgressiveDifficultyEnhancedService();
final stats = difficultyService.getRecentPerformanceStats(
  subject: SubjectType.math,
  skillId: 'algebra',
);
final userLevel = (stats.averageDifficulty).round();

// Diversify questions
final gameQuestions = await diversityManager.diversifyQuestions(
  candidateQuestions: candidates,
  subject: SubjectType.math,
  skillId: 'algebra',
  userPerformanceLevel: userLevel,
);

// gameQuestions now contains 7 diverse, balanced questions
```

### Example 2: Debug Logging Output

```
[DiversityManager] ✅ Service initialized
[DiversityManager] 🎯 Diversifying 30 questions for Math/algebra
[DiversityManager] 🗑️ Filtered 3 duplicate questions
[DiversityManager] 📊 Difficulty mix: 2E, 3M, 2H
[DiversityManager] 📊 Type distribution:
   multipleChoice: 3
   numericInput: 2
   dragDrop: 1
   trueFalse: 1
[DiversityManager] 📊 Difficulty distribution:
   Easy: 2, Medium: 3, Hard: 2
```

### Example 3: Clear Recent Questions

```dart
// Clear recent questions for a subject (e.g., after completing all levels)
await QuestionDiversityManager.instance.clearRecentQuestions(
  SubjectType.math,
);
```

---

## 📈 DIVERSITY ALGORITHM DETAILS

### Step 1: Filter Recent Duplicates

```dart
// Get last 10 question fingerprints
final recentWindow = recentFingerprints.take(10).toList();
final recentHashes = recentWindow.map((f) => f.hash).toSet();

// Filter out duplicates
final filtered = questions.where((q) {
  final hash = _generateFingerprint(q);
  return !recentHashes.contains(hash);
}).toList();
```

### Step 2: Balance Question Types

```dart
// Shuffle to avoid patterns
final shuffled = List<Question>.from(questions)..shuffle();

// Enforce max 3 of same type
for (final question in shuffled) {
  final count = typeCounts[question.type] ?? 0;
  if (count < 3) {
    balanced.add(question);
    typeCounts[question.type] = count + 1;
  }
}

// Ensure minimum 1 of each major type
final majorTypes = [multipleChoice, numericInput, dragDrop];
for (final type in majorTypes) {
  if (!balanced.any((q) => q.type == type)) {
    // Add one question of this type
  }
}
```

### Step 3: Balance Difficulty

```dart
// Categorize by difficulty relative to user level
for (final q in questions) {
  if (q.difficulty <= userLevel - 2) {
    easy.add(q);
  } else if (q.difficulty >= userLevel + 2) {
    hard.add(q);
  } else {
    medium.add(q);
  }
}

// Select based on user level
if (userLevel <= 3) {
  // Beginner: 3 easy, 3 medium, 1 hard
} else if (userLevel <= 7) {
  // Intermediate: 2 easy, 3 medium, 2 hard
} else {
  // Advanced: 2 easy, 2 medium, 3 hard
}
```

### Step 4: Vary Topics

```dart
// Extract topics from questions
final topicGroups = <String, List<Question>>{};
for (final q in questions) {
  final topic = _extractTopic(q);
  topicGroups.putIfAbsent(topic, () => []).add(q);
}

// Avoid clustering same topics
final usedTopics = <String>{};
for (final q in questions) {
  final topic = _extractTopic(q);
  
  // Only add if not recently used (last 2 questions)
  if (usedTopics.length < 2 || !usedTopics.contains(topic)) {
    varied.add(q);
    usedTopics.add(topic);
    
    if (usedTopics.length > 2) {
      usedTopics.remove(usedTopics.first); // Keep only last 2
    }
  }
}
```

### Step 5: Arrange Questions

```dart
// Sort by difficulty
final sorted = questions..sort((a, b) => a.difficulty.compareTo(b.difficulty));

// Arrange: easy → medium → hard → medium
final arranged = <Question>[];

// Start with easiest (confidence boost)
arranged.add(sorted.first);

// Gradually increase difficulty
final middle = sorted.sublist(1, sorted.length - 1);
arranged.addAll(middle);

// End with medium difficulty (accomplished feeling)
final mediumIndex = sorted.length ~/ 2;
arranged.add(sorted[mediumIndex]);
```

---

## 📊 DATA STRUCTURES

### QuestionFingerprint

```dart
class QuestionFingerprint {
  final String hash;          // SHA-256 hash
  final String questionId;    // Original question ID
  final DateTime timestamp;   // When shown to user
}
```

**Storage**: SharedPreferences (JSON)
**Key**: `recent_questions_v1`
**Structure**: `Map<SubjectType, List<QuestionFingerprint>>`

### TopicRotationState

```dart
class TopicRotationState {
  final List<String> topics;  // Available topics
  int lastUsedIndex;          // Round-robin index
}
```

**Storage**: SharedPreferences (JSON)
**Key**: `topic_rotation_v1`
**Structure**: `Map<String, TopicRotationState>` (key: `${subject}_${skillId}`)

---

## ✅ SUCCESS CRITERIA MET

- ✅ Type distribution enforced (max 3 of same type)
- ✅ Minimum 1 of each major type (multiple choice, numeric, drag-drop)
- ✅ Randomized order (no predictable patterns)
- ✅ Repetition prevention (no duplicates in 10-question window)
- ✅ Last 20 questions tracked per subject
- ✅ Question fingerprinting (SHA-256 hash)
- ✅ Topic variation within skill
- ✅ Difficulty balanced appropriately
- ✅ User level-based mix (beginner/intermediate/advanced)
- ✅ Easy start, medium end (confidence boost)
- ✅ Topic rotation (round-robin)
- ✅ Avoid topic clustering (max 2 consecutive)
- ✅ Persistent storage (SharedPreferences)
- ✅ Debug logging included
- ✅ No IDE errors or warnings

---

## 📊 IMPACT

### Before Implementation
- Random question selection
- No type distribution control
- Possible duplicate questions
- No difficulty balancing
- No topic variation

### After Implementation
- Controlled type distribution (max 3 of same type)
- Duplicate prevention (10-question window)
- Balanced difficulty (user level-based)
- Topic variation (round-robin rotation)
- Optimal question flow (easy → hard → medium)

---

## 🔄 INTEGRATION POINTS

### With GameSessionService
```dart
// In GameSessionService.generateGameSession()
final candidates = await _generateCandidateQuestions(subject, skillId, 30);

final diversified = await QuestionDiversityManager.instance.diversifyQuestions(
  candidateQuestions: candidates,
  subject: subject,
  skillId: skillId,
  userPerformanceLevel: userLevel,
);

return GameSession(questions: diversified, ...);
```

### With ProgressiveDifficultyEnhancedService
```dart
// Get user performance level
final stats = difficultyService.getRecentPerformanceStats(
  subject: subject,
  skillId: skillId,
);
final userLevel = (stats.averageDifficulty).round();

// Use in diversification
final diversified = await diversityManager.diversifyQuestions(
  userPerformanceLevel: userLevel,
  ...
);
```

---

## 🚀 **Category E Progress: 6/8 Tasks Complete (75%)**

- ✅ **E1**: Subject-Specific Prompt Templates (3h)
- ✅ **E2**: Content Quality Validator (2h)
- ✅ **E3**: Automatic Chapter Generation (3h)
- ✅ **E4**: Difficulty Scaling Algorithm (2h)
- ✅ **E5**: Content Caching Strategy (2h)
- ✅ **E6**: Question Diversity Manager (1h)
- ⏳ **E7**: AI Generation Fallback Chain (0.5h) ← **NEXT**
- ⏳ **E8**: Content Quality Metrics (0.5h)

**Time Spent**: 13 hours / 14 hours total  
**Progress**: 92.9% complete

---

**End of Task E6 Implementation Report**

**Status**: ✅ COMPLETE  
**Ready for**: Task E7 - AI Generation Fallback Chain Verification
