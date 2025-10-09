import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/subject.dart';
import '../models/user.dart';
import '../models/question_pool.dart';
import '../models/question.dart';

import 'package:riverpod/riverpod.dart';
// AI service removed for AI cleanup
import 'daily_content_service.dart';
import 'question_pool_service.dart';
import 'unified_lesson_service.dart';
import '../../features/streak/streak_notification_service.dart';
import '../../features/syllabus/dynamic_syllabus_service.dart';
// import 'enhanced_daily_content_service.dart'; // Missing file - commented out
// import 'comprehensive_lesson_generator.dart'; // Missing file - commented out
import 'lesson_validation_service.dart';
// import 'automatic_chapter_generator.dart'; // Removed to avoid circular dependency

// Riverpod 3 Notifier-based controller for global progress/state
final progressProvider = NotifierProvider<ProgressController, ProgressState>(
  ProgressController.new,
);

class ProgressController extends Notifier<ProgressState> {
  // Update the user's display name and persist it
  Future<void> updateUserName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(user: state.user.copyWith(name: trimmed));
    await _save();
  }
  static const _prefsKey = 'progress_state_v1';
  static const _defaultUserName = 'Alex';

  late SharedPreferences _prefs;
  late QuestionPoolService _questionPoolService;
  late UnifiedLessonService _comprehensiveGenerator;
  late LessonValidationService _validationService;
  // late AutomaticChapterGenerator _chapterGenerator; // Commented out to avoid circular dependency

  static const _comprehensiveProgressKey = 'comprehensive_progress_v1';

  @override
  ProgressState build() {
    // Build is called once per provider lifecycle
    _init();
    return const ProgressState.initial();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();

    // Initialize question pool service
    _questionPoolService = QuestionPoolService();
    await _questionPoolService.initialize();

    // Initialize comprehensive lesson services
    _comprehensiveGenerator = UnifiedLessonService.instance;
    _validationService = LessonValidationService();

    // Initialize automatic chapter generator
    // Commented out to avoid circular dependency and AI removal
    /*
    _chapterGenerator = AutomaticChapterGenerator(
      progressController: this,
      aiGenerator: AIContentGenerator(),
    );
    */

    // Initialize AI question service for procedural generation - REMOVED FOR AI CLEANUP
    // try { await AIQuestionService.getInstance().loadKeyFromPrefs(); } catch (_) {}
    final raw = _prefs.getString(_prefsKey);
    if (raw == null) {
      // Seed initial state with starting currency
      final initial = ProgressState(
        user: User(
          id: const Uuid().v4(),
          name: _defaultUserName,
          email: '$_defaultUserName@learnosphere.app',
          totalXP: 0,
          currentStreak: 0,
          level: 1,
          lastActiveDate: null,
          coins: 100, // Starting coins for new users
          gems: 10,   // Starting gems for new users (allows skipping)
          lives: 5,
        ),
        subjects: _seedSubjects(),
      );
      state = initial;
      await _save();
    } else {
      try {
        final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
        state = ProgressState.fromJson(jsonMap);
      } catch (_) {
        // If parsing fails, fallback to fresh state with starting currency
        state = ProgressState(
          user: User(
            id: const Uuid().v4(),
            name: _defaultUserName,
            email: '$_defaultUserName@learnosphere.app',
            totalXP: 0,
            currentStreak: 0,
            level: 1,
            lastActiveDate: null,
            coins: 100, // Starting coins for new users
            gems: 10,   // Starting gems for new users (allows skipping)
            lives: 5,
          ),
          subjects: _seedSubjects(),
        );
        await _save();
      }
    }

    // Hearts auto-refill: 1 life every 20 minutes up to 5
    try {
      final lastRefillIso = _prefs.getString('lives_last_refill_v1');
      DateTime lastRefill = DateTime.tryParse(lastRefillIso ?? '') ?? DateTime.now();
      final now = DateTime.now();
      if (state.user.lives < 5) {
        final minutes = now.difference(lastRefill).inMinutes;
        final livesToAdd = (minutes ~/ 20).clamp(0, 5 - state.user.lives);
        if (livesToAdd > 0) {
          state = state.copyWith(user: state.user.copyWith(lives: state.user.lives + livesToAdd));
          lastRefill = lastRefill.add(Duration(minutes: livesToAdd * 20));
          await _save();
        }
      }
      await _prefs.setString('lives_last_refill_v1', lastRefill.toIso8601String());
    } catch (_) {}

    // Kick off a daily AI generation (if key available) without blocking UI
    // ignore: unawaited_futures
    _runDailyAutoGenerationIfDue();
    
    // Also trigger daily content generation using the new service
    // ignore: unawaited_futures
    Future.microtask(() => DailyContentService.getInstance().generateDailyContentIfDue());
  }

  Future<void> _save() async {
    await _prefs.setString(_prefsKey, jsonEncode(state.toJson()));
  }

  // Public helpers
  User get user => state.user;
  List<Subject> get subjects => state.subjects;

  Subject subjectByType(SubjectType type) {
    return state.subjects.firstWhere((s) => s.type == type);
  }

  int xpForNextLevel(int level) {
    // Progressive curve; keeps getting harder gradually
    final required = 60 + (pow(level, 1.4) * 40).round();
    return required.clamp(50, 99999);
  }

  int get currentLevelRequiredXP => xpForNextLevel(state.user.level);
  int get currentLevelProgressXP => state.user.totalXP % currentLevelRequiredXP;
  double get levelProgress => currentLevelRequiredXP == 0
      ? 0
      : currentLevelProgressXP / currentLevelRequiredXP;

  Future<void> resetAllProgress() async {
    state = ProgressState(
      user: state.user.copyWith(
        totalXP: 0,
        level: 1,
        currentStreak: 0,
        coins: 100, // Starting coins
        gems: 10,   // Starting gems
        lives: 5,
        lastActiveDate: null,
      ),
      subjects: _seedSubjects(),
    );
    await _save();
  }

  Future<void> addXP(int xp) async {
    var u = state.user;
    var remainingXP = xp;

    while (remainingXP > 0) {
      final needed = xpForNextLevel(u.level) - (u.totalXP % xpForNextLevel(u.level));
      if (remainingXP >= needed) {
        // Level up
        u = u.copyWith(
          totalXP: u.totalXP + needed,
          level: u.level + 1,
          gems: u.gems + 5, // default reward: 5 gems per level
          coins: u.coins + 20,
        );
        remainingXP -= needed;
      } else {
        u = u.copyWith(totalXP: u.totalXP + remainingXP);
        remainingXP = 0;
      }
    }

    state = state.copyWith(user: u);
    await _save();
  }

  // Currency helpers
  Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return true;
    if (state.user.coins < amount) return false;
    state = state.copyWith(user: state.user.copyWith(coins: state.user.coins - amount));
    await _save();
    return true;
  }

  Future<bool> spendGems(int amount) async {
    if (amount <= 0) return true;
    if (state.user.gems < amount) return false;
    state = state.copyWith(user: state.user.copyWith(gems: state.user.gems - amount));
    await _save();
    return true;
  }

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    state = state.copyWith(user: state.user.copyWith(coins: state.user.coins + amount));
    await _save();
  }

  Future<void> addGems(int amount) async {
    if (amount <= 0) return;
    state = state.copyWith(user: state.user.copyWith(gems: state.user.gems + amount));
    await _save();
  }

  Future<bool> refillHeartsWithGems({int cost = 10}) async {
    if (state.user.lives >= 5) return true;
    final ok = await spendGems(cost);
    if (!ok) return false;
    state = state.copyWith(user: state.user.copyWith(lives: 5));
    await _save();
    return true;
  }

  Future<bool> freezeStreakWithGems({int cost = 5}) async {
    // Sets lastActiveDate to yesterday to preserve streak if missed once
    final ok = await spendGems(cost);
    if (!ok) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    state = state.copyWith(user: state.user.copyWith(lastActiveDate: yesterday));
    await _save();
    return true;
  }

  Future<void> recordActivityForStreak() async {
    final today = DateTime.now();
    final last = state.user.lastActiveDate;
    int newStreak = state.user.currentStreak;
    int gemsEarned = 0;

    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    if (last == null) {
      newStreak = 1;
      gemsEarned = 1; // First day bonus
    } else if (isSameDay(today, last)) {
      // already counted today - no changes
      return;
    } else {
      final yesterday = today.subtract(const Duration(days: 1));
      if (isSameDay(yesterday, last)) {
        newStreak = state.user.currentStreak + 1;
        
        // Streak milestone rewards
        if (newStreak % 7 == 0) {
          gemsEarned = 5; // Weekly milestone: 5 gems
        } else if (newStreak % 3 == 0) {
          gemsEarned = 2; // Every 3 days: 2 gems
        } else {
          gemsEarned = 1; // Daily: 1 gem
        }
      } else {
        newStreak = 1; // reset streak
        gemsEarned = 1; // Fresh start bonus
      }
    }

    state = state.copyWith(
      user: state.user.copyWith(
        currentStreak: newStreak,
        lastActiveDate: today,
        gems: state.user.gems + gemsEarned,
      ),
    );
    await _save();
  }

  // Lives (hearts)
  Future<void> loseLife() async {
    if (state.user.lives <= 0) return;
    state = state.copyWith(user: state.user.copyWith(lives: state.user.lives - 1));
    await _save();
  }

  Future<void> gainLife([int count = 1]) async {
    state = state.copyWith(user: state.user.copyWith(lives: min(5, state.user.lives + count)));
    await _save();
  }

  /// Unlock a lesson by adding it to the appropriate skill
  /// Used by unlimited generation to integrate generated content into the main progression system
  Future<void> unlockLesson(String lessonId) async {
    try {
      // Parse lesson ID to extract skill information
      // Expected format: skillId_L... or similar
      final parts = lessonId.split('_');
      if (parts.length < 2) {
        if (kDebugMode) {
          print('Invalid lesson ID format: $lessonId');
        }
        return;
      }
      
      final skillId = parts[0];
      
      // Find the skill across all subjects and add the lesson
      final List<Subject> updatedSubjects = [];
      bool lessonAdded = false;
      
      for (final subject in state.subjects) {
        final List<Unit> updatedUnits = [];
        
        for (final unit in subject.units) {
          final List<Skill> updatedSkills = [];
          
          for (final skill in unit.skills) {
            if (skill.id == skillId) {
              // Check if lesson already exists
              final existingLesson = skill.lessons.any((l) => l.id == lessonId);
              if (!existingLesson) {
                // This skill matches - mark it as unlocked and note that we found it
                updatedSkills.add(
                  Skill(
                    id: skill.id,
                    name: skill.name,
                    description: skill.description,
                    crowns: skill.crowns,
                    maxCrowns: skill.maxCrowns,
                    isUnlocked: true, // Ensure skill is unlocked
                    lessons: skill.lessons, // Lessons are managed separately by unlimited generator
                  ),
                );
                lessonAdded = true;
              } else {
                updatedSkills.add(skill);
              }
            } else {
              updatedSkills.add(skill);
            }
          }
          
          updatedUnits.add(
            Unit(
              id: unit.id,
              name: unit.name,
              description: unit.description,
              skills: updatedSkills,
              isUnlocked: unit.isUnlocked,
            ),
          );
        }
        
        final totalSkills = updatedUnits.fold<int>(0, (acc, u) => acc + u.skills.length);
        final completedSkills = updatedUnits
            .expand((u) => u.skills)
            .where((sk) => sk.crowns >= 1)
            .length;
        
        updatedSubjects.add(
          Subject(
            id: subject.id,
            name: subject.name,
            type: subject.type,
            description: subject.description,
            iconUrl: subject.iconUrl,
            units: updatedUnits,
            totalSkills: totalSkills,
            completedSkills: completedSkills,
          ),
        );
      }
      
      if (lessonAdded) {
        state = state.copyWith(subjects: updatedSubjects);
        await _save();
        
        if (kDebugMode) {
          print('Successfully unlocked lesson: $lessonId for skill: $skillId');
        }
      } else {
        if (kDebugMode) {
          print('Could not find skill for lesson: $lessonId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unlocking lesson $lessonId: $e');
      }
    }
  }

  Future<void> completeLesson({
    required SubjectType subject,
    required String skillId,
    required Lesson lesson,
    required int correctAnswers,
    required int totalAnswers,
    BuildContext? context,
  }) async {
    // Calculate earned XP proportional to accuracy
    final accuracy = totalAnswers == 0 ? 0 : (correctAnswers / totalAnswers);
    final xpEarned = max(1, (lesson.xpReward * accuracy).round());

    // Update subject/skill/lesson completion
    final List<Subject> updatedSubjects = [];

    for (final s in state.subjects) {
      if (s.type != subject) {
        updatedSubjects.add(s);
        continue;
      }

      final List<Unit> updatedUnits = [];
      for (final u in s.units) {
        final List<Skill> updatedSkills = [];
        for (final sk in u.skills) {
          if (sk.id != skillId) {
            updatedSkills.add(sk);
            continue;
          }

          // mark the lesson as completed
          final updatedLessons = sk.lessons.map((ls) {
            if (ls.id == lesson.id) {
              return Lesson(
                id: ls.id,
                title: ls.title,
                description: ls.description,
                xpReward: ls.xpReward,
                isCompleted: true,
                questions: ls.questions,
              );
            }
            return ls;
          }).toList();

          // Increase crowns every 3 completed lessons in this skill
          final completedCount = updatedLessons.where((l) => l.isCompleted).length;
          final extraCrowns = completedCount ~/ 3; // 0..infinity
          final newCrowns = max(sk.crowns, extraCrowns);

          // Generate and append the next lesson to make the skill unlimited
          final nextDifficulty = completedCount + 1;
          final nextLesson = await _createNextLesson(
            subject: subject,
            skillId: sk.id,
            skillName: sk.name,
            difficulty: nextDifficulty,
            baseXP: (lesson.xpReward + 2).clamp(8, 9999),
          );
          updatedLessons.add(nextLesson);

          updatedSkills.add(
            Skill(
              id: sk.id,
              name: sk.name,
              description: sk.description,
              crowns: newCrowns,
              maxCrowns: max(sk.maxCrowns, newCrowns + 2), // allow to keep growing
              isUnlocked: true,
              lessons: updatedLessons,
            ),
          );
        }
        updatedUnits.add(
          Unit(
            id: u.id,
            name: u.name,
            description: u.description,
            skills: updatedSkills,
            isUnlocked: u.isUnlocked,
          ),
        );
      }

      final totalSkills = updatedUnits.fold<int>(0, (acc, u) => acc + u.skills.length);
      final completedSkills = updatedUnits
          .expand((u) => u.skills)
          .where((sk) => sk.crowns >= 1)
          .length;

      updatedSubjects.add(
        Subject(
          id: s.id,
          name: s.name,
          type: s.type,
          description: s.description,
          iconUrl: s.iconUrl,
          units: updatedUnits,
          totalSkills: totalSkills,
          completedSkills: completedSkills,
        ),
      );
    }

    state = state.copyWith(subjects: updatedSubjects);

    // Store previous streak for milestone detection
    final previousStreak = state.user.currentStreak;

    // Rewards & streak
    await addXP(xpEarned);
    await recordActivityForStreak();

    // Check for streak milestone and show notification
    final newStreak = state.user.currentStreak;
    if (context != null && newStreak > previousStreak) {
      // Calculate gems earned from streak (this mirrors the logic in recordActivityForStreak)
      int gemsFromStreak = 1; // Default daily gem
      if (newStreak % 7 == 0) {
        gemsFromStreak = 5; // Weekly milestone
      } else if (newStreak % 3 == 0) {
        gemsFromStreak = 2; // Every 3 days
      }

      // Import and show milestone notification
       // Note: We'll need to import this in the files that call completeLesson
       try {
         StreakNotificationService.showStreakMilestone(
           context,
           newStreak,
           gemsFromStreak,
         );
       } catch (e) {
         // Fallback: simple snackbar if import fails
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('🔥 $newStreak-day streak! +$gemsFromStreak gems'),
             backgroundColor: Colors.orange,
           ),
         );
       }
    }

    // Check if we need to generate new chapter (Category E Task E3)
    // Commented out to avoid circular dependency
    /*
    try {
      final chapterResult = await _chapterGenerator.checkAndGenerateIfNeeded(subject);
      if (chapterResult != null && context != null) {
        if (kDebugMode) {
          debugPrint('[ProgressService] 🎉 New chapter generated: ${chapterResult.chapter.title}');
        }

        // Show notification to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(chapterResult.notificationMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Navigate to chapter preview screen
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProgressService] Error checking for chapter generation: $e');
      }
    }
    */

    // Optionally coins reward for finishing lesson
    state = state.copyWith(
      user: state.user.copyWith(coins: state.user.coins + 5),
    );

    // Trigger automated content generation after lesson completion
    await _triggerAutomatedContentGeneration(subject, skillId);
    
    // Track comprehensive lesson completion if applicable
    await _trackComprehensiveLessonCompletion(subject, skillId, xpEarned);

    await _save();
  }

  Future<Lesson> _createNextLesson({
    required SubjectType subject,
    required String skillId,
    required String skillName,
    required int difficulty,
    required int baseXP,
  }) async {
    // Generate questions using fallback method (AI removed)
    final questions = _generateQuestionsForSkill(subject, skillId, difficulty);

    return Lesson(
      id: '${skillId}_L${const Uuid().v4().substring(0, 6)}',
      title: '$skillName — Level $difficulty',
      description: 'Practice level $difficulty',
      xpReward: baseXP + (difficulty ~/ 2),
      isCompleted: false,
      questions: questions,
    );
  }

  /// Trigger automated content generation based on user progress - DISABLED FOR AI REMOVAL
  Future<void> _triggerAutomatedContentGeneration(SubjectType subject, String skillId) async {
    // AI content generation disabled - using manual content only
    return;
  }

  /// Run once per day: pre-generate a buffer of lessons across unlocked skills - DISABLED FOR AI REMOVAL
  /// Uses procedural generation; always available.
  Future<void> _runDailyAutoGenerationIfDue() async {
    // AI generation disabled - using manual content only
    return;
  }

  String _dayKey(DateTime dt) => '${dt.year}-${dt.month}-${dt.day}';
  // Subject scaffolding and procedural generation
  List<Subject> _seedSubjects() {
    return [
      _buildSubject(SubjectType.math, 'Mathematics',
          'From basic arithmetic to advanced algebra',
          icon:
              'https://images.unsplash.com/photo-1635372722656-389f87a941b7?w=200&h=200&fit=crop'),
      _buildSubject(SubjectType.physics, 'Physics',
          'Explore the laws that govern our universe',
          icon:
              'https://images.unsplash.com/photo-1636466497217-26a8cbeaf0aa?w=200&h=200&fit=crop'),
      _buildSubject(SubjectType.chemistry, 'Chemistry',
          'Discover the building blocks of matter',
          icon:
              'https://images.unsplash.com/photo-1582719471384-894fbb16e074?w=200&h=200&fit=crop'),
      _buildSubject(SubjectType.biology, 'Biology',
          'Understand the science of living organisms',
          icon:
              'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=200&h=200&fit=crop'),
    ];
  }

  Subject _buildSubject(SubjectType type, String name, String description,
      {required String icon}) {
    final units = _defaultUnitsFor(type);
    final totalSkills = units.fold<int>(0, (acc, u) => acc + u.skills.length);
    final completedSkills = units
        .expand((u) => u.skills)
        .where((sk) => sk.crowns > 0)
        .length;
    return Subject(
      id: type.name,
      name: name,
      type: type,
      description: description,
      iconUrl: icon,
      units: units,
      totalSkills: totalSkills,
      completedSkills: completedSkills,
    );
  }

  List<Unit> _defaultUnitsFor(SubjectType type) {
    switch (type) {
      case SubjectType.math:
        return [
          Unit(
            id: 'arith',
            name: 'Arithmetic Basics',
            description: 'Foundation of math with numbers',
            isUnlocked: true,
            skills: [
              _skill('addition', 'Addition & Subtraction',
                  'Learn to add and subtract numbers', baseXP: 10, type: type),
              _skill('multiplication', 'Multiplication & Division',
                  'Master times tables and division', baseXP: 12, type: type),
              _skill('fractions', 'Fractions Fundamentals',
                  'Understanding parts of a whole', baseXP: 12, type: type),
            ],
          ),
          Unit(
            id: 'algebra',
            name: 'Algebra Introduction',
            description: 'Working with variables and expressions',
            isUnlocked: false,
            skills: [
              _skill('variables', 'Variables & Expressions',
                  'What is x? Working with unknowns', baseXP: 14, type: type,
                  unlocked: false),
            ],
          ),
        ];
      case SubjectType.physics:
        return [
          Unit(
            id: 'mechanics',
            name: 'Mechanics 101',
            description: 'Motion, forces, and energy',
            isUnlocked: true,
            skills: [
              _skill('newton', 'Newtonian Motion',
                  'Forces, acceleration, F = m·a', baseXP: 12, type: type),
              _skill('energy', 'Work & Energy',
                  'Kinetic and potential energy', baseXP: 12, type: type),
            ],
          ),
          Unit(
            id: 'waves',
            name: 'Waves & Optics',
            description: 'Light, sound, and wave behavior',
            isUnlocked: false,
            skills: [
              _skill('optics', 'Basic Optics',
                  'Reflection, refraction, lenses', baseXP: 14, type: type,
                  unlocked: false),
            ],
          ),
        ];
      case SubjectType.chemistry:
        return [
          Unit(
            id: 'atoms',
            name: 'Atomic Structure',
            description: 'Protons, neutrons, electrons',
            isUnlocked: true,
            skills: [
              _skill('periodic', 'Periodic Table Basics',
                  'Groups, periods, and trends', baseXP: 10, type: type),
              _skill('bonding', 'Chemical Bonding',
                  'Ionic vs covalent bonds', baseXP: 12, type: type),
            ],
          ),
          Unit(
            id: 'reactions',
            name: 'Chemical Reactions',
            description: 'Balancing and types of reactions',
            isUnlocked: false,
            skills: [
              _skill('stoich', 'Stoichiometry',
                  'Moles and reaction yields', baseXP: 14, type: type,
                  unlocked: false),
            ],
          ),
        ];
      case SubjectType.biology:
        return [
          Unit(
            id: 'cells',
            name: 'Cell Biology',
            description: 'Cells, organelles, and functions',
            isUnlocked: true,
            skills: [
              _skill('cell_parts', 'Cell Parts',
                  'Organelles and their roles', baseXP: 10, type: type),
              _skill('genetics', 'Genetics Basics',
                  'DNA, genes, and traits', baseXP: 12, type: type),
            ],
          ),
          Unit(
            id: 'ecosystems',
            name: 'Ecosystems',
            description: 'Interactions and energy flow',
            isUnlocked: false,
            skills: [
              _skill('food_chain', 'Food Chains & Webs',
                  'Producers, consumers, decomposers', baseXP: 12, type: type,
                  unlocked: false),
            ],
          ),
        ];
      case SubjectType.science:
        return [
          Unit(
            id: 'scientific_method',
            name: 'Scientific Method',
            description: 'Observation, hypothesis, experimentation',
            isUnlocked: true,
            skills: [
              _skill('observation', 'Observation Skills',
                  'Making accurate observations and measurements', baseXP: 10, type: type),
              _skill('hypothesis', 'Hypothesis Formation',
                  'Creating testable hypotheses', baseXP: 12, type: type),
            ],
          ),
          Unit(
            id: 'research',
            name: 'Research Methods',
            description: 'Data collection and analysis',
            isUnlocked: false,
            skills: [
              _skill('data_analysis', 'Data Analysis',
                  'Interpreting graphs and statistics', baseXP: 14, type: type,
                  unlocked: false),
            ],
          ),
        ];
      case SubjectType.english:
        return [
          Unit(
            id: 'grammar',
            name: 'Grammar Fundamentals',
            description: 'Parts of speech and sentence structure',
            isUnlocked: true,
            skills: [
              _skill('parts_of_speech', 'Parts of Speech',
                  'Nouns, verbs, adjectives, adverbs', baseXP: 10, type: type),
              _skill('sentence_structure', 'Sentence Structure',
                  'Subject, predicate, clauses', baseXP: 12, type: type),
            ],
          ),
          Unit(
            id: 'literature',
            name: 'Literature Analysis',
            description: 'Reading comprehension and literary devices',
            isUnlocked: false,
            skills: [
              _skill('literary_devices', 'Literary Devices',
                  'Metaphor, simile, symbolism', baseXP: 14, type: type,
                  unlocked: false),
            ],
          ),
        ];
      case SubjectType.art:
        return [
          Unit(
            id: 'drawing',
            name: 'Drawing Basics',
            description: 'Line, shape, and form',
            isUnlocked: true,
            skills: [
              _skill('line_drawing', 'Line Drawing',
                  'Different types of lines and their uses', baseXP: 10, type: type),
              _skill('shading', 'Shading Techniques',
                  'Creating depth with light and shadow', baseXP: 12, type: type),
            ],
          ),
          Unit(
            id: 'color_theory',
            name: 'Color Theory',
            description: 'Understanding color relationships',
            isUnlocked: false,
            skills: [
              _skill('color_wheel', 'Color Wheel',
                  'Primary, secondary, and tertiary colors', baseXP: 14, type: type,
                  unlocked: false),
            ],
          ),
        ];
      case SubjectType.music:
        return [
          Unit(
            id: 'rhythm',
            name: 'Rhythm & Beat',
            description: 'Time signatures and note values',
            isUnlocked: true,
            skills: [
              _skill('note_values', 'Note Values',
                  'Whole, half, quarter, eighth notes', baseXP: 10, type: type),
              _skill('time_signatures', 'Time Signatures',
                  '4/4, 3/4, and other common time signatures', baseXP: 12, type: type),
            ],
          ),
          Unit(
            id: 'melody',
            name: 'Melody & Harmony',
            description: 'Scales, intervals, and chords',
            isUnlocked: false,
            skills: [
              _skill('scales', 'Musical Scales',
                  'Major and minor scales', baseXP: 14, type: type,
                  unlocked: false),
            ],
          ),
        ];
      case SubjectType.physicalEducation:
        return [
          Unit(
            id: 'fitness',
            name: 'Physical Fitness',
            description: 'Cardiovascular and strength training',
            isUnlocked: true,
            skills: [
              _skill('cardio', 'Cardiovascular Fitness',
                  'Heart health and endurance exercises', baseXP: 10, type: type),
              _skill('strength', 'Strength Training',
                  'Building muscle strength and endurance', baseXP: 12, type: type),
            ],
          ),
          Unit(
            id: 'sports',
            name: 'Sports & Games',
            description: 'Team sports and individual activities',
            isUnlocked: false,
            skills: [
              _skill('team_sports', 'Team Sports',
                  'Basketball, soccer, volleyball basics', baseXP: 14, type: type,
                  unlocked: false),
            ],
          ),
        ];
      case SubjectType.computerScience:
        return [
          Unit(
            id: 'programming',
            name: 'Programming Fundamentals',
            description: 'Basic programming concepts and syntax',
            isUnlocked: true,
            skills: [
              _skill('variables', 'Variables & Data Types',
                  'Understanding variables, integers, strings, booleans', baseXP: 10, type: type),
              _skill('loops', 'Loops & Conditionals',
                  'For loops, while loops, if-else statements', baseXP: 12, type: type),
              _skill('functions', 'Functions',
                  'Creating and calling functions with parameters', baseXP: 14, type: type),
            ],
          ),
          Unit(
            id: 'algorithms',
            name: 'Algorithms & Data Structures',
            description: 'Problem-solving and data organization',
            isUnlocked: false,
            skills: [
              _skill('sorting', 'Sorting Algorithms',
                  'Bubble sort, merge sort, quick sort', baseXP: 16, type: type,
                  unlocked: false),
              _skill('arrays', 'Arrays & Lists',
                  'Working with arrays and dynamic lists', baseXP: 14, type: type,
                  unlocked: false),
            ],
          ),
        ];
      case SubjectType.geography:
        return [
          Unit(
            id: 'physical',
            name: 'Physical Geography',
            description: 'Earth\'s physical features and processes',
            isUnlocked: true,
            skills: [
              _skill('landforms', 'Landforms',
                  'Mountains, valleys, rivers, coastal features', baseXP: 10, type: type),
              _skill('climate', 'Climate & Weather',
                  'Weather patterns, climate zones, atmospheric processes', baseXP: 12, type: type),
              _skill('ecosystems', 'Ecosystems',
                  'Biomes, habitats, environmental interactions', baseXP: 12, type: type),
            ],
          ),
          Unit(
            id: 'human',
            name: 'Human Geography',
            description: 'Human activities and cultural patterns',
            isUnlocked: false,
            skills: [
              _skill('population', 'Population & Settlement',
                  'Demographics, urbanization, migration patterns', baseXP: 14, type: type,
                  unlocked: false),
              _skill('culture', 'Cultural Geography',
                  'Languages, religions, cultural diffusion', baseXP: 12, type: type,
                  unlocked: false),
            ],
          ),
        ];
      case SubjectType.history:
        return [
          Unit(
            id: 'ancient',
            name: 'Ancient Civilizations',
            description: 'Early human societies and cultures',
            isUnlocked: true,
            skills: [
              _skill('mesopotamia', 'Mesopotamia',
                  'Sumerians, Babylonians, early writing systems', baseXP: 10, type: type),
              _skill('egypt', 'Ancient Egypt',
                  'Pharaohs, pyramids, Egyptian society', baseXP: 12, type: type),
              _skill('greece', 'Ancient Greece',
                  'Democracy, philosophy, Greek culture', baseXP: 12, type: type),
            ],
          ),
          Unit(
            id: 'medieval',
            name: 'Medieval Period',
            description: 'Middle Ages and feudal societies',
            isUnlocked: false,
            skills: [
              _skill('feudalism', 'Feudalism',
                  'Medieval social structure and governance', baseXP: 14, type: type,
                  unlocked: false),
              _skill('crusades', 'The Crusades',
                  'Religious wars and cultural exchange', baseXP: 14, type: type,
                  unlocked: false),
            ],
          ),
        ];
    }
  }

  Skill _skill(String id, String name, String desc,
      {required int baseXP,
      required SubjectType type,
      bool unlocked = true}) {
    // Procedurally generate an initial set of lessons per skill
    final List<Lesson> lessons = List.generate(5, (i) {
      final xp = baseXP + i * 2;
      final lId = '${id}_L${i + 1}';
      return Lesson(
        id: lId,
        title: '$name — Lesson ${i + 1}',
        description: 'Practice set ${i + 1}',
        xpReward: xp,
        isCompleted: false,
        questions: _generateQuestionsForSkill(type, id, i + 1),
      );
    });
    return Skill(
      id: id,
      name: name,
      description: desc,
      crowns: 0,
      maxCrowns: 5,
      isUnlocked: unlocked,
      lessons: lessons,
    );
  }

  List<Question> _generateQuestionsForSkill(
      SubjectType subject, String skillId, int difficulty) {
    // Use the new question pool service for anti-repetition
    return _generateQuestionsFromPools(subject, skillId, 4, difficulty);
  }

  /// Generate questions using the new pool system with anti-repetition
  List<Question> _generateQuestionsFromPools(
      SubjectType subject, String skillId, int count, int difficulty) {
    try {
      // Try to use the pool service first
      _questionPoolService.generateQuestionsFromPools(
        subject, 
        skillId, 
        count,
        preferredCategories: _getCategoriesForDifficulty(difficulty),
      );
      
      // Convert Future to sync by using a fallback for now
      // In a real implementation, this would be properly async
      return _generateFallbackQuestions(subject, skillId, difficulty, count);
    } catch (e) {
      // Fallback to original generation if pool service fails
      return _generateFallbackQuestions(subject, skillId, difficulty, count);
    }
  }

  /// Get preferred question categories based on difficulty level
  List<QuestionCategory> _getCategoriesForDifficulty(int difficulty) {
    switch (difficulty) {
      case 1:
        return [QuestionCategory.factual, QuestionCategory.conceptual];
      case 2:
        return [QuestionCategory.computational, QuestionCategory.analytical];
      case 3:
        return [QuestionCategory.practical, QuestionCategory.comparative];
      case 4:
      case 5:
        return [QuestionCategory.creative, QuestionCategory.analytical];
      default:
        return QuestionCategory.values;
    }
  }

  /// Fallback question generation using the original system
  List<Question> _generateFallbackQuestions(
      SubjectType subject, String skillId, int difficulty, int count) {
    final rng = Random(subject.index + skillId.hashCode + difficulty + DateTime.now().millisecondsSinceEpoch % 9973);

    List<Question> mc(List<Map<String, dynamic>> items) {
      items.shuffle(rng);
      return items.take(count).map((m) {
        final options = List<String>.from(m['options'] as List)
          ..shuffle(rng);
        return Question(
          id: const Uuid().v4(),
          type: QuestionType.multipleChoice,
          questionText: m['q'] as String,
          options: options,
          correctAnswer: m['a'] as String,
          explanation: m['ex'] as String,
          hint: m['hint'] as String?,
          subject: subject,
        );
      }).toList();
    }

    switch (subject) {
      case SubjectType.math:
        return _generateMathQuestions(skillId, difficulty, rng);
      case SubjectType.physics:
        return _generatePhysicsQuestions(skillId, difficulty, rng, mc);
      case SubjectType.chemistry:
        return _generateChemistryQuestions(skillId, difficulty, rng, mc);
      case SubjectType.biology:
        return _generateBiologyQuestions(skillId, difficulty, rng, mc);
      case SubjectType.science:
        return _generateScienceQuestions(skillId, difficulty, rng, mc);
      case SubjectType.english:
        return _generateEnglishQuestions(skillId, difficulty, rng, mc);
      case SubjectType.history:
        return _generateHistoryQuestions(skillId, difficulty, rng, mc);
      case SubjectType.geography:
        return _generateGeographyQuestions(skillId, difficulty, rng, mc);
      case SubjectType.art:
        return _generateArtQuestions(skillId, difficulty, rng, mc);
      case SubjectType.music:
        return _generateMusicQuestions(skillId, difficulty, rng, mc);
      case SubjectType.physicalEducation:
        return _generatePhysicalEducationQuestions(skillId, difficulty, rng, mc);
      case SubjectType.computerScience:
        return _generateComputerScienceQuestions(skillId, difficulty, rng, mc);
    }
  }

  List<Question> _generateMathQuestions(String skillId, int difficulty, Random rng) {
    final a = rng.nextInt(9 + difficulty) + max(1, difficulty - 1);
    final b = rng.nextInt(9 + difficulty) + 1;
    
    switch (skillId) {
      case 'addition':
        // Only addition and subtraction
        final isAdd = rng.nextBool();
        final answer = isAdd ? a + b : a - b;
        final expr = isAdd ? '$a + $b' : '$a - $b';
        final operation = isAdd ? 'addition' : 'subtraction';
        
        final comp = Question(
          id: const Uuid().v4(),
          type: QuestionType.numericInput,
          questionText: 'Compute: $expr',
          options: const [],
          correctAnswer: '${answer}',
          explanation: 'The result of $expr is $answer.',
          hint: 'Perform the $operation step by step.',
          subject: SubjectType.math,
        );
        
        final pool = [
          {
            'q': 'What is $a + $b?',
            'options': ['${a + b}', '${a + b + 1}', '${a + b - 1}', '${a + b + 2}'],
            'a': '${a + b}',
            'ex': '$a + $b = ${a + b}',
            'hint': 'Add the numbers together.',
          },
          {
            'q': 'What is $a - $b?',
            'options': ['${a - b}', '${a - b + 1}', '${a - b - 1}', '${a - b + 2}'],
            'a': '${a - b}',
            'ex': '$a - $b = ${a - b}',
            'hint': 'Subtract the second number from the first.',
          },
        ];
        return [comp, ..._mc(pool, rng, SubjectType.math)];
        
      case 'multiplication':
        // Only multiplication and division
        final isMult = rng.nextBool();
        num answer;
        String expr;
        
        if (isMult) {
          answer = a * b;
          expr = '$a × $b';
        } else {
          final divisor = max(1, b);
          final dividend = a * divisor;
          answer = dividend ~/ divisor;
          expr = '$dividend ÷ $divisor';
        }
        
        final comp = Question(
          id: const Uuid().v4(),
          type: QuestionType.numericInput,
          questionText: 'Compute: $expr',
          options: const [],
          correctAnswer: '${answer.round()}',
          explanation: 'The result of $expr is ${answer.round()}.',
          hint: isMult ? 'Multiply the numbers.' : 'Divide the first number by the second.',
          subject: SubjectType.math,
        );
        
        final pool = [
          {
            'q': 'What is $a × $b?',
            'options': ['${a * b}', '${a * b + 1}', '${a * b - 1}', '${a * b + 2}'],
            'a': '${a * b}',
            'ex': '$a × $b = ${a * b}',
            'hint': 'Multiply the numbers together.',
          },
          {
            'q': 'What is ${a * b} ÷ $a?',
            'options': ['$b', '${b + 1}', '${b - 1}', '${b + 2}'],
            'a': '$b',
            'ex': '${a * b} ÷ $a = $b',
            'hint': 'Division is the opposite of multiplication.',
          },
        ];
        return [comp, ..._mc(pool, rng, SubjectType.math)];
        
      case 'fractions':
        // Fraction-specific questions
        final num1 = rng.nextInt(8) + 1;
        final den1 = rng.nextInt(8) + 2;
        final num2 = rng.nextInt(8) + 1;
        final den2 = rng.nextInt(8) + 2;
        
        final pool = [
          {
            'q': 'Which fraction is larger: $num1/$den1 or $num2/$den2?',
            'options': ['$num1/$den1', '$num2/$den2', 'They are equal', 'Cannot determine'],
            'a': (num1 / den1) > (num2 / den2) ? '$num1/$den1' : '$num2/$den2',
            'ex': 'Convert to decimals: ${(num1 / den1).toStringAsFixed(2)} vs ${(num2 / den2).toStringAsFixed(2)}',
            'hint': 'Convert to decimals or find common denominator.',
          },
          {
            'q': 'What is 1/2 + 1/4?',
            'options': ['3/4', '2/6', '1/3', '2/4'],
            'a': '3/4',
            'ex': '1/2 + 1/4 = 2/4 + 1/4 = 3/4',
            'hint': 'Find a common denominator.',
          },
        ];
        return _mc(pool, rng, SubjectType.math);
        
      case 'variables':
        // Algebra with variables
        final coeff = rng.nextInt(5) + 2;
        final constant = rng.nextInt(10) + 1;
        
        final pool = [
          {
            'q': 'If x = 3, what is ${coeff}x + $constant?',
            'options': ['${coeff * 3 + constant}', '${coeff * 3 + constant + 1}', '${coeff * 3 + constant - 1}', '${coeff + constant}'],
            'a': '${coeff * 3 + constant}',
            'ex': 'Substitute x = 3: ${coeff}(3) + $constant = ${coeff * 3} + $constant = ${coeff * 3 + constant}',
            'hint': 'Replace x with 3 and calculate.',
          },
          {
            'q': 'Solve for x: x + $constant = ${constant + 5}',
            'options': ['5', '${constant + 5}', '$constant', '${constant - 5}'],
            'a': '5',
            'ex': 'x + $constant = ${constant + 5}, so x = ${constant + 5} - $constant = 5',
            'hint': 'Subtract $constant from both sides.',
          },
        ];
        return _mc(pool, rng, SubjectType.math);
        
      default:
        // Fallback to general arithmetic
        final ops = ['+', '-', '*', '/'];
        final maxOp = (1 + difficulty ~/ 3).clamp(1, ops.length);
        final op = ops[rng.nextInt(maxOp)];
        num answer;
        String expr;
        switch (op) {
          case '+':
            answer = a + b;
            expr = '$a + $b';
            break;
          case '-':
            answer = a - b;
            expr = '$a - $b';
            break;
          case '*':
            answer = a * b;
            expr = '$a × $b';
            break;
          default:
            final divisor = max(1, b);
            final dividend = a * divisor;
            answer = dividend ~/ divisor;
            expr = '$dividend ÷ $divisor';
            break;
        }
        final comp = Question(
          id: const Uuid().v4(),
          type: QuestionType.numericInput,
          questionText: 'Compute: $expr',
          options: const [],
          correctAnswer: '${answer.round()}',
          explanation: 'The result of $expr is ${answer.round()}.',
          hint: 'Follow order of operations.',
          subject: SubjectType.math,
        );
        final pool = [
          {
            'q': 'Which is larger?',
            'options': ['${a + b - 1}', '${a + b}', '${a + b + 1}', '${a + b - 2}'],
            'a': '${a + b + 1}',
            'ex': 'Among the options, ${a + b + 1} is the largest.',
            'hint': 'Compare magnitudes.',
          },
        ];
        return [comp, ..._mc(pool, rng, SubjectType.math)];
    }
  }

  List<Question> _generatePhysicsQuestions(String skillId, int difficulty, Random rng, Function mc) {
    switch (skillId) {
      case 'newton':
        // Newton's laws and force questions
        final m = rng.nextInt(8) + 2; // kg
        final aAcc = rng.nextInt(5 + difficulty) + 1; // m/s^2
        final F = m * aAcc;
        
        final pool = [
          {
            'q': 'What is Newton\'s first law?',
            'options': ['Objects at rest stay at rest unless acted upon by force', 'F = ma', 'Action equals reaction', 'Energy is conserved'],
            'a': 'Objects at rest stay at rest unless acted upon by force',
            'ex': 'Newton\'s first law is the law of inertia.',
            'hint': 'Think about inertia.',
          },
          {
            'q': 'If F = m·a and m=$m kg, a=$aAcc m/s², what is F?',
            'options': ['$F N', '${F + 2} N', '${F - 2} N', '$F J'],
            'a': '$F N',
            'ex': 'F = m·a = $m × $aAcc = $F N.',
            'hint': 'Multiply mass and acceleration.',
          },
          {
            'q': 'What is the SI unit of force?',
            'options': ['Newton', 'Joule', 'Watt', 'Pascal'],
            'a': 'Newton',
            'ex': 'Force is measured in Newtons (N).',
            'hint': 'Named after Isaac Newton.',
          },
        ];
        return mc(pool);
        
      case 'energy':
        // Energy and work questions
        final m = rng.nextInt(10) + 1;
        final v = rng.nextInt(8) + 2;
        final ke = 0.5 * m * v * v;
        
        final pool = [
          {
            'q': 'Which quantity is measured in Joules?',
            'options': ['Energy', 'Force', 'Power', 'Pressure'],
            'a': 'Energy',
            'ex': 'Energy/work are measured in Joules (J).',
            'hint': 'Power is Watts, force is Newtons.',
          },
          {
            'q': 'What is kinetic energy proportional to?',
            'options': ['v²', 'v', 'm', 'Both m and v²'],
            'a': 'Both m and v²',
            'ex': 'KE = ½mv², so it\'s proportional to both mass and velocity squared.',
            'hint': 'Remember the kinetic energy formula.',
          },
          {
            'q': 'If m=${m}kg and v=${v}m/s, what is KE?',
            'options': ['${ke.round()} J', '${(ke + 10).round()} J', '${(ke - 10).round()} J', '${(ke * 2).round()} J'],
            'a': '${ke.round()} J',
            'ex': 'KE = ½mv² = ½ × $m × $v² = ${ke.round()} J',
            'hint': 'Use KE = ½mv²',
          },
        ];
        return mc(pool);
        
      case 'optics':
        // Optics questions
        final pool = [
          {
            'q': 'What happens when light hits a mirror?',
            'options': ['Reflection', 'Refraction', 'Absorption', 'Diffraction'],
            'a': 'Reflection',
            'ex': 'Mirrors reflect light according to the law of reflection.',
            'hint': 'Think about what mirrors do.',
          },
          {
            'q': 'Which type of lens converges light rays?',
            'options': ['Convex', 'Concave', 'Flat', 'Cylindrical'],
            'a': 'Convex',
            'ex': 'Convex lenses are thicker in the middle and converge light.',
            'hint': 'Convex means curved outward.',
          },
        ];
        return mc(pool);
        
      default:
        // General physics fallback
        final pool = [
          {
            'q': 'What is the SI unit of force?',
            'options': ['Newton', 'Joule', 'Watt', 'Pascal'],
            'a': 'Newton',
            'ex': 'Force is measured in Newtons (N).',
            'hint': 'Named after Isaac Newton.',
          },
        ];
        return mc(pool);
    }
  }

  List<Question> _generateChemistryQuestions(String skillId, int difficulty, Random rng, Function mc) {
    switch (skillId) {
      case 'periodic':
        // Periodic table questions
        final pool = [
          {
            'q': 'What is the symbol for Gold?',
            'options': ['Au', 'Ag', 'Go', 'Gd'],
            'a': 'Au',
            'ex': 'Gold\'s symbol is Au from the Latin "aurum".',
            'hint': 'Think of the Latin name.',
          },
          {
            'q': 'Which group contains noble gases?',
            'options': ['Group 18', 'Group 1', 'Group 17', 'Group 2'],
            'a': 'Group 18',
            'ex': 'Noble gases are in Group 18 (rightmost column).',
            'hint': 'They\'re on the far right.',
          },
          {
            'q': 'What determines an element\'s identity?',
            'options': ['Number of protons', 'Number of neutrons', 'Number of electrons', 'Atomic mass'],
            'a': 'Number of protons',
            'ex': 'The atomic number (protons) defines the element.',
            'hint': 'Think about atomic number.',
          },
        ];
        return mc(pool);
        
      case 'bonding':
        // Chemical bonding questions
        final pool = [
          {
            'q': 'Which bond involves sharing electrons?',
            'options': ['Covalent', 'Ionic', 'Metallic', 'Hydrogen'],
            'a': 'Covalent',
            'ex': 'Covalent bonds share electron pairs.',
            'hint': 'Co- means together.',
          },
          {
            'q': 'What type of bond forms between Na and Cl?',
            'options': ['Ionic', 'Covalent', 'Metallic', 'Hydrogen'],
            'a': 'Ionic',
            'ex': 'Na loses an electron to Cl, forming ions that attract.',
            'hint': 'Metal + nonmetal = ionic.',
          },
          {
            'q': 'Which has the strongest bond?',
            'options': ['Triple bond', 'Double bond', 'Single bond', 'Hydrogen bond'],
            'a': 'Triple bond',
            'ex': 'More shared electron pairs = stronger bond.',
            'hint': 'More electrons shared = stronger.',
          },
        ];
        return mc(pool);
        
      case 'stoich':
        // Stoichiometry questions
        final pool = [
          {
            'q': 'How many atoms are in one mole?',
            'options': ['6.022 × 10²³', '6.022 × 10²²', '6.022 × 10²⁴', '1.000 × 10²³'],
            'a': '6.022 × 10²³',
            'ex': 'Avogadro\'s number is 6.022 × 10²³.',
            'hint': 'Remember Avogadro\'s number.',
          },
          {
            'q': 'What is the molar mass of water (H₂O)?',
            'options': ['18 g/mol', '16 g/mol', '20 g/mol', '14 g/mol'],
            'a': '18 g/mol',
            'ex': 'H₂O = 2(1) + 16 = 18 g/mol',
            'hint': 'Add atomic masses: H=1, O=16.',
          },
        ];
        return mc(pool);
        
      default:
        // General chemistry fallback
        final pool = [
          {
            'q': 'NaCl is commonly known as?',
            'options': ['Table salt', 'Baking soda', 'Sugar', 'Chalk'],
            'a': 'Table salt',
            'ex': 'NaCl is sodium chloride (table salt).',
            'hint': 'On dining tables.',
          },
        ];
        return mc(pool);
    }
  }

  List<Question> _generateBiologyQuestions(String skillId, int difficulty, Random rng, Function mc) {
    switch (skillId) {
      case 'cell_parts':
        // Cell organelles and parts
        final organelles = {
          'Mitochondria': 'ATP production',
          'Ribosome': 'Protein synthesis',
          'Nucleus': 'Genetic control',
          'Chloroplast': 'Photosynthesis',
          'Lysosome': 'Waste breakdown',
          'Golgi apparatus': 'Protein packaging',
        };
        final left = organelles.keys.toList()..shuffle(rng);
        final right = organelles.values.toList()..shuffle(rng);
        final pairCount = rng.nextInt(3) + 3;
        final leftPick = left.take(pairCount).toList();
        final rightPick = right.take(pairCount).toList();

        final matchQ = Question(
          id: const Uuid().v4(),
          type: QuestionType.dragDrop,
          questionText: 'Match the organelle to its function',
          options: [
            'LEFT:${leftPick.join('|')}',
            'RIGHT:${rightPick.join('|')}',
          ],
          correctAnswer: leftPick.map((l) => '$l:${organelles[l]}').join(';'),
          explanation: 'Common cell organelles and their functions.',
          hint: 'Recall basic cell biology roles.',
          subject: SubjectType.biology,
        );
        
        final pool = [
          {
            'q': 'Which organelle contains genetic material?',
            'options': ['Nucleus', 'Mitochondria', 'Ribosome', 'Vacuole'],
            'a': 'Nucleus',
            'ex': 'The nucleus contains DNA.',
            'hint': 'Control center.',
          },
          {
            'q': 'What is the powerhouse of the cell?',
            'options': ['Mitochondria', 'Nucleus', 'Ribosome', 'Lysosome'],
            'a': 'Mitochondria',
            'ex': 'Mitochondria produce ATP (energy).',
            'hint': 'Think about energy production.',
          },
        ];
        final list = mc(pool);
        list.insert(rng.nextInt(list.length + 1), matchQ);
        return list;
        
      case 'genetics':
        // Genetics questions
        final pool = [
          {
            'q': 'DNA is composed of units called…',
            'options': ['Nucleotides', 'Amino acids', 'Fatty acids', 'Monosaccharides'],
            'a': 'Nucleotides',
            'ex': 'DNA monomers are nucleotides.',
            'hint': 'Nucleo- relates to nucleus.',
          },
          {
            'q': 'How many chromosomes do humans have?',
            'options': ['46', '23', '48', '44'],
            'a': '46',
            'ex': 'Humans have 23 pairs = 46 chromosomes.',
            'hint': '23 pairs from each parent.',
          },
          {
            'q': 'What does DNA stand for?',
            'options': ['Deoxyribonucleic acid', 'Deoxyribose nucleic acid', 'Deoxy nucleic acid', 'Double nucleic acid'],
            'a': 'Deoxyribonucleic acid',
            'ex': 'DNA is deoxyribonucleic acid.',
            'hint': 'Deoxy-ribo-nucleic acid.',
          },
        ];
        return mc(pool);
        
      case 'food_chain':
        // Food chain and ecosystem questions
        final pool = [
          {
            'q': 'What are organisms that make their own food called?',
            'options': ['Producers', 'Primary consumers', 'Secondary consumers', 'Decomposers'],
            'a': 'Producers',
            'ex': 'Producers (like plants) make their own food through photosynthesis.',
            'hint': 'They produce their own energy.',
          },
          {
            'q': 'What do decomposers do?',
            'options': ['Break down dead organisms', 'Eat plants', 'Eat other animals', 'Make food from sunlight'],
            'a': 'Break down dead organisms',
            'ex': 'Decomposers break down dead material and recycle nutrients.',
            'hint': 'They decompose dead things.',
          },
        ];
        return mc(pool);
        
      default:
        // General biology fallback
        final pool = [
          {
            'q': 'What is the basic unit of life?',
            'options': ['Cell', 'Atom', 'Molecule', 'Tissue'],
            'a': 'Cell',
            'ex': 'Cells are the basic units of all living things.',
            'hint': 'Think about the smallest living unit.',
          },
        ];
        return mc(pool);
    }
  }

  List<Question> _generateComputerScienceQuestions(String skillId, int difficulty, Random rng, Function mc) {
    switch (skillId) {
      case 'variables':
        final pool = [
          {
            'q': 'Which of these is a valid variable name in most programming languages?',
            'options': ['myVariable', '2ndVariable', 'my-variable', 'my variable'],
            'a': 'myVariable',
            'ex': 'Variable names cannot start with numbers or contain spaces/hyphens.',
            'hint': 'Think about naming conventions.',
          },
          {
            'q': 'What data type would you use to store the text "Hello World"?',
            'options': ['String', 'Integer', 'Boolean', 'Float'],
            'a': 'String',
            'ex': 'Strings are used to store text data.',
            'hint': 'Text data type.',
          },
          {
            'q': 'What value does a boolean variable hold?',
            'options': ['True or False', 'Numbers only', 'Text only', 'Any value'],
            'a': 'True or False',
            'ex': 'Boolean variables can only be true or false.',
            'hint': 'Binary choice.',
          },
        ];
        return mc(pool);

      case 'loops':
        final pool = [
          {
            'q': 'What does a "for loop" typically do?',
            'options': ['Repeats code a specific number of times', 'Runs code once', 'Checks a condition', 'Stores data'],
            'a': 'Repeats code a specific number of times',
            'ex': 'For loops iterate a predetermined number of times.',
            'hint': 'Think about repetition.',
          },
          {
            'q': 'When would you use a "while loop"?',
            'options': ['When you don\'t know how many times to repeat', 'To store variables', 'To define functions', 'To import libraries'],
            'a': 'When you don\'t know how many times to repeat',
            'ex': 'While loops continue until a condition becomes false.',
            'hint': 'Condition-based repetition.',
          },
        ];
        return mc(pool);

      case 'functions':
        final pool = [
          {
            'q': 'What is a function parameter?',
            'options': ['Input value passed to a function', 'Output of a function', 'Name of a function', 'Type of function'],
            'a': 'Input value passed to a function',
            'ex': 'Parameters are inputs that functions receive to work with.',
            'hint': 'What goes into a function.',
          },
          {
            'q': 'What does "return" do in a function?',
            'options': ['Sends a value back to the caller', 'Starts the function', 'Ends the program', 'Creates a variable'],
            'a': 'Sends a value back to the caller',
            'ex': 'Return statements send results back from functions.',
            'hint': 'What comes out of a function.',
          },
        ];
        return mc(pool);

      case 'sorting':
        final pool = [
          {
            'q': 'Which sorting algorithm is generally fastest for large datasets?',
            'options': ['Quick Sort', 'Bubble Sort', 'Selection Sort', 'Insertion Sort'],
            'a': 'Quick Sort',
            'ex': 'Quick Sort has average O(n log n) time complexity.',
            'hint': 'Think about efficiency.',
          },
        ];
        return mc(pool);

      case 'arrays':
        final pool = [
          {
            'q': 'What is an array index?',
            'options': ['Position of an element in the array', 'Size of the array', 'Type of the array', 'Name of the array'],
            'a': 'Position of an element in the array',
            'ex': 'Array indices indicate the position of elements, usually starting from 0.',
            'hint': 'Position indicator.',
          },
        ];
        return mc(pool);

      default:
        final pool = [
          {
            'q': 'What does CPU stand for?',
            'options': ['Central Processing Unit', 'Computer Processing Unit', 'Central Program Unit', 'Computer Program Unit'],
            'a': 'Central Processing Unit',
            'ex': 'CPU is the main processor that executes instructions.',
            'hint': 'The brain of the computer.',
          },
        ];
        return mc(pool);
    }
  }

  List<Question> _generateGeographyQuestions(String skillId, int difficulty, Random rng, Function mc) {
    switch (skillId) {
      case 'landforms':
        final pool = [
          {
            'q': 'What is the highest mountain in the world?',
            'options': ['Mount Everest', 'K2', 'Mount McKinley', 'Mount Kilimanjaro'],
            'a': 'Mount Everest',
            'ex': 'Mount Everest is 8,848 meters tall, the highest peak on Earth.',
            'hint': 'Located in the Himalayas.',
          },
          {
            'q': 'What type of landform is formed by river erosion?',
            'options': ['Valley', 'Mountain', 'Plateau', 'Desert'],
            'a': 'Valley',
            'ex': 'Rivers carve valleys through erosion over long periods.',
            'hint': 'Water cuts through land.',
          },
          {
            'q': 'What is a delta?',
            'options': ['Land formed by river deposits', 'A type of mountain', 'A desert region', 'An ocean trench'],
            'a': 'Land formed by river deposits',
            'ex': 'Deltas form where rivers deposit sediment as they enter larger bodies of water.',
            'hint': 'Where rivers meet the sea.',
          },
        ];
        return mc(pool);

      case 'climate':
        final pool = [
          {
            'q': 'What causes seasons on Earth?',
            'options': ['Earth\'s tilt on its axis', 'Distance from the Sun', 'Ocean currents', 'Mountain ranges'],
            'a': 'Earth\'s tilt on its axis',
            'ex': 'Earth\'s 23.5-degree tilt causes different parts to receive varying sunlight throughout the year.',
            'hint': 'Think about Earth\'s position.',
          },
          {
            'q': 'Which climate zone is characterized by hot, dry summers and mild, wet winters?',
            'options': ['Mediterranean', 'Tropical', 'Desert', 'Tundra'],
            'a': 'Mediterranean',
            'ex': 'Mediterranean climates have distinct wet and dry seasons.',
            'hint': 'Named after a famous sea.',
          },
        ];
        return mc(pool);

      case 'ecosystems':
        final pool = [
          {
            'q': 'Which biome has the highest biodiversity?',
            'options': ['Tropical Rainforest', 'Desert', 'Tundra', 'Grassland'],
            'a': 'Tropical Rainforest',
            'ex': 'Tropical rainforests contain more species than any other biome.',
            'hint': 'Hot and wet environment.',
          },
        ];
        return mc(pool);

      case 'population':
        final pool = [
          {
            'q': 'What is urbanization?',
            'options': ['Movement of people from rural to urban areas', 'Building new cities', 'Population decline', 'Agricultural development'],
            'a': 'Movement of people from rural to urban areas',
            'ex': 'Urbanization is the process of people moving to cities from countryside.',
            'hint': 'Rural to urban migration.',
          },
        ];
        return mc(pool);

      case 'culture':
        final pool = [
          {
            'q': 'What is cultural diffusion?',
            'options': ['Spread of cultural traits between groups', 'Loss of culture', 'Cultural isolation', 'Cultural conflict'],
            'a': 'Spread of cultural traits between groups',
            'ex': 'Cultural diffusion occurs when cultures share and adopt each other\'s practices.',
            'hint': 'Cultures spreading and mixing.',
          },
        ];
        return mc(pool);

      default:
        final pool = [
          {
            'q': 'What are the seven continents?',
            'options': ['Asia, Africa, North America, South America, Antarctica, Europe, Australia', 'Asia, Africa, America, Antarctica, Europe, Australia', 'Asia, Africa, North America, South America, Europe, Australia', 'Asia, Africa, America, Europe, Australia, Oceania'],
            'a': 'Asia, Africa, North America, South America, Antarctica, Europe, Australia',
            'ex': 'The seven continents include all major landmasses on Earth.',
            'hint': 'Count them carefully.',
          },
        ];
        return mc(pool);
    }
  }

  List<Question> _generateHistoryQuestions(String skillId, int difficulty, Random rng, Function mc) {
    switch (skillId) {
      case 'mesopotamia':
        final pool = [
          {
            'q': 'Which civilization is credited with inventing the first writing system?',
            'options': ['Sumerians', 'Egyptians', 'Greeks', 'Romans'],
            'a': 'Sumerians',
            'ex': 'The Sumerians developed cuneiform, one of the earliest writing systems.',
            'hint': 'They lived in Mesopotamia.',
          },
          {
            'q': 'What was the Code of Hammurabi?',
            'options': ['Ancient law code', 'Religious text', 'Military strategy', 'Trade agreement'],
            'a': 'Ancient law code',
            'ex': 'Hammurabi\'s Code was one of the first written legal codes.',
            'hint': 'Rules and punishments.',
          },
        ];
        return mc(pool);

      case 'egypt':
        final pool = [
          {
            'q': 'What were Egyptian pyramids primarily built for?',
            'options': ['Tombs for pharaohs', 'Religious temples', 'Grain storage', 'Military fortresses'],
            'a': 'Tombs for pharaohs',
            'ex': 'Pyramids served as elaborate burial sites for Egyptian rulers.',
            'hint': 'Final resting place.',
          },
          {
            'q': 'What is the Rosetta Stone famous for?',
            'options': ['Helping decode hieroglyphs', 'Religious ceremonies', 'Military victories', 'Trade records'],
            'a': 'Helping decode hieroglyphs',
            'ex': 'The Rosetta Stone contained the same text in multiple scripts, enabling translation.',
            'hint': 'Translation key.',
          },
        ];
        return mc(pool);

      case 'greece':
        final pool = [
          {
            'q': 'What type of government did ancient Athens develop?',
            'options': ['Democracy', 'Monarchy', 'Oligarchy', 'Theocracy'],
            'a': 'Democracy',
            'ex': 'Athens developed the first known democracy, where citizens could vote.',
            'hint': 'Rule by the people.',
          },
          {
            'q': 'Who was Socrates?',
            'options': ['Greek philosopher', 'Military general', 'Political leader', 'Mathematician'],
            'a': 'Greek philosopher',
            'ex': 'Socrates was a famous philosopher known for the Socratic method.',
            'hint': 'Thinker and teacher.',
          },
        ];
        return mc(pool);

      case 'feudalism':
        final pool = [
          {
            'q': 'What was the feudal system based on?',
            'options': ['Land ownership and loyalty', 'Money and trade', 'Religious authority', 'Democratic voting'],
            'a': 'Land ownership and loyalty',
            'ex': 'Feudalism was built on land grants in exchange for military service and loyalty.',
            'hint': 'Land for service.',
          },
        ];
        return mc(pool);

      case 'crusades':
        final pool = [
          {
            'q': 'What were the Crusades?',
            'options': ['Religious wars between Christians and Muslims', 'Trade expeditions', 'Scientific expeditions', 'Colonial conquests'],
            'a': 'Religious wars between Christians and Muslims',
            'ex': 'The Crusades were military campaigns to control holy lands.',
            'hint': 'Holy wars.',
          },
        ];
        return mc(pool);

      default:
        final pool = [
          {
            'q': 'What does BCE stand for in historical dating?',
            'options': ['Before Common Era', 'Before Christian Era', 'Before Current Era', 'Before Classical Era'],
            'a': 'Before Common Era',
            'ex': 'BCE is the modern term for dates before year 1 CE.',
            'hint': 'Modern dating system.',
          },
        ];
        return mc(pool);
    }
  }

  List<Question> _generateScienceQuestions(String skillId, int difficulty, Random rng, Function mc) {
    switch (skillId) {
      case 'scientific_method':
        final pool = [
          {
            'q': 'What is the first step in the scientific method?',
            'a': 'Observation',
            'options': ['Observation', 'Hypothesis', 'Experiment', 'Conclusion'],
            'ex': 'The scientific method begins with careful observation of phenomena.',
            'hint': 'Scientists start by watching and noting what happens.',
          },
          {
            'q': 'What is a hypothesis?',
            'a': 'An educated guess',
            'options': ['An educated guess', 'A proven fact', 'A final answer', 'A measurement'],
            'ex': 'A hypothesis is an educated guess that can be tested through experiments.',
            'hint': 'It\'s a testable prediction based on observations.',
          },
        ];
        return mc(pool);
      default:
        return [];
    }
  }

  List<Question> _generateEnglishQuestions(String skillId, int difficulty, Random rng, Function mc) {
    switch (skillId) {
      case 'grammar':
        final pool = [
          {
            'q': 'Which word is a noun in this sentence: "The cat runs quickly"?',
            'a': 'cat',
            'options': ['cat', 'runs', 'quickly', 'the'],
            'ex': 'A noun is a person, place, thing, or idea. "Cat" is a thing.',
            'hint': 'Look for a person, place, thing, or idea.',
          },
          {
            'q': 'What type of word is "quickly" in the sentence "The cat runs quickly"?',
            'a': 'Adverb',
            'options': ['Adverb', 'Adjective', 'Noun', 'Verb'],
            'ex': 'An adverb modifies a verb, adjective, or another adverb. "Quickly" describes how the cat runs.',
            'hint': 'This word describes how the action is performed.',
          },
        ];
        return mc(pool);
      default:
        return [];
    }
  }

  List<Question> _generateArtQuestions(String skillId, int difficulty, Random rng, Function mc) {
    switch (skillId) {
      case 'color_theory':
        final pool = [
          {
            'q': 'What are the primary colors?',
            'a': 'Red, blue, yellow',
            'options': ['Red, blue, yellow', 'Red, green, blue', 'Orange, purple, green', 'Black, white, gray'],
            'ex': 'Primary colors cannot be created by mixing other colors together.',
            'hint': 'These colors cannot be made by mixing others.',
          },
          {
            'q': 'What color do you get when you mix red and yellow?',
            'a': 'Orange',
            'options': ['Orange', 'Purple', 'Green', 'Brown'],
            'ex': 'Red and yellow are adjacent on the color wheel and create orange when mixed.',
            'hint': 'Think about colors you see in a sunset.',
          },
        ];
        return mc(pool);
      default:
        return [];
    }
  }

  List<Question> _generateMusicQuestions(String skillId, int difficulty, Random rng, Function mc) {
    switch (skillId) {
      case 'notes':
        final pool = [
          {
            'q': 'How many lines are on a musical staff?',
            'a': '5',
            'options': ['5', '4', '6', '7'],
            'ex': 'A standard musical staff has 5 horizontal lines with 4 spaces between them.',
            'hint': 'Count the horizontal lines where notes are placed.',
          },
          {
            'q': 'What clef is most commonly used for higher-pitched instruments?',
            'a': 'Treble clef',
            'options': ['Treble clef', 'Bass clef', 'Alto clef', 'Tenor clef'],
            'ex': 'The treble clef is used for higher-pitched notes and instruments like violin and flute.',
            'hint': 'This clef looks like a fancy letter G.',
          },
        ];
        return mc(pool);
      default:
        return [];
    }
  }

  List<Question> _generatePhysicalEducationQuestions(String skillId, int difficulty, Random rng, Function mc) {
    switch (skillId) {
      case 'fitness':
        final pool = [
          {
            'q': 'How many minutes of physical activity should children get daily?',
            'a': '60 minutes',
            'options': ['30 minutes', '60 minutes', '90 minutes', '120 minutes'],
            'ex': 'Health experts recommend at least 60 minutes of physical activity daily for children.',
            'hint': 'Think about recommended daily exercise for kids.',
          },
          {
            'q': 'Which exercise is best for cardiovascular health?',
            'a': 'Running',
            'options': ['Running', 'Weightlifting', 'Stretching', 'Yoga'],
            'ex': 'Running is an aerobic exercise that strengthens the heart and improves circulation.',
            'hint': 'This exercise gets your heart pumping fast.',
          },
        ];
        return mc(pool);
      default:
        return [];
    }
  }

  List<Question> _mc(List<Map<String, dynamic>> items, Random rng, SubjectType subject) {
    items.shuffle(rng);
    return items.take(4).map((m) {
      final options = List<String>.from(m['options'] as List)
        ..shuffle(rng);
      return Question(
        id: const Uuid().v4(),
        type: QuestionType.multipleChoice,
        questionText: m['q'] as String,
        options: options,
        correctAnswer: m['a'] as String,
        explanation: m['ex'] as String,
        hint: m['hint'] as String?,
        subject: subject,
      );
    }).toList();
  }

  /// Track comprehensive lesson completion for analytics and progress
  Future<void> _trackComprehensiveLessonCompletion(
    SubjectType subject,
    String skillId,
    int xpEarned,
  ) async {
    try {
      final completionData = {
        'timestamp': DateTime.now().toIso8601String(),
        'subject': subject.toString(),
        'skillId': skillId,
        'xpEarned': xpEarned,
        'userId': state.user.id,
      };

      // Store completion data for analytics
      final existingData = _prefs.getStringList(_comprehensiveProgressKey) ?? [];
      existingData.add(jsonEncode(completionData));
      
      // Keep only last 100 completions to prevent storage bloat
      if (existingData.length > 100) {
        existingData.removeRange(0, existingData.length - 100);
      }
      
      await _prefs.setStringList(_comprehensiveProgressKey, existingData);

      // Optionally trigger comprehensive lesson generation for this subject
      if (Random().nextDouble() < 0.3) { // 30% chance to generate new content
        _generateComprehensiveLessonAsync(subject, skillId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error tracking comprehensive lesson completion: $e');
      }
    }
  }

  /// Generate comprehensive lesson asynchronously without blocking UI
  void _generateComprehensiveLessonAsync(SubjectType subject, String skillId) {
    Future.microtask(() async {
      try {
        final lessons = await _comprehensiveGenerator.getLessonsForSkill(
          subject: subject,
          skillId: skillId,
          skillName: skillId, // Use skillId as skillName for now
          difficulty: 1, // Start with basic difficulty
          lessonCount: 1, // Generate one lesson
        );
        final lesson = lessons.isNotEmpty ? lessons.first : null;
        
        final validation = await _validationService.validateLesson(
          questions: lesson?.questions ?? [],
          subject: subject,
          skillId: skillId,
          difficulty: 1,
        );
        
        if (validation.isValid) {
          if (kDebugMode) {
            print('Generated comprehensive lesson for $subject:$skillId');
          }
        } else {
          if (kDebugMode) {
            print('Comprehensive lesson validation failed: ${validation.recommendations}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error generating comprehensive lesson: $e');
        }
      }
    });
  }

  /// Get comprehensive lesson completion statistics
  Future<Map<String, dynamic>> getComprehensiveLessonStats() async {
    try {
      final completionData = _prefs.getStringList(_comprehensiveProgressKey) ?? [];
      final completions = completionData
          .map((data) => jsonDecode(data) as Map<String, dynamic>)
          .toList();

      final totalCompletions = completions.length;
      final totalXP = completions.fold<int>(
        0,
        (sum, completion) => sum + (completion['xpEarned'] as int? ?? 0),
      );

      final subjectBreakdown = <String, int>{};
      for (final completion in completions) {
        final subject = completion['subject'] as String? ?? 'unknown';
        subjectBreakdown[subject] = (subjectBreakdown[subject] ?? 0) + 1;
      }

      return {
        'totalCompletions': totalCompletions,
        'totalXP': totalXP,
        'subjectBreakdown': subjectBreakdown,
        'lastCompletion': completions.isNotEmpty 
            ? completions.last['timestamp'] 
            : null,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting comprehensive lesson stats: $e');
      }
      return {
        'totalCompletions': 0,
        'totalXP': 0,
        'subjectBreakdown': <String, int>{},
        'lastCompletion': null,
      };
    }
  }


}

// Immutable state snapshot
class ProgressState {
  final User user;
  final List<Subject> subjects;

  const ProgressState({required this.user, required this.subjects});

  const ProgressState.initial()
      : user = const User(
          id: 'init',
          name: 'Loading',
          email: 'loading@learnosphere.app',
          totalXP: 0,
          currentStreak: 0,
          level: 1,
          coins: 100, // Starting coins
          gems: 10,   // Starting gems
          lives: 5,
        ),
        subjects = const [];

  ProgressState copyWith({User? user, List<Subject>? subjects}) =>
      ProgressState(user: user ?? this.user, subjects: subjects ?? this.subjects);

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'subjects': subjects.map((s) => s.toJson()).toList(),
      };

  factory ProgressState.fromJson(Map<String, dynamic> json) => ProgressState(
        user: User.fromJson(json['user'] as Map<String, dynamic>),
        subjects: (json['subjects'] as List)
            .map((e) => Subject.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
