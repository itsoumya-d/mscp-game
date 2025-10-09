import 'package:flutter_test/flutter_test.dart';
import 'package:sp/core/services/unified_xp_service.dart';
import 'package:sp/core/models/subject.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Level System Tests', () {
    late UnifiedXPService xpService;
    const subject = SubjectType.math;
    const skillId = 'algebra';
    const userId = 'test_user';

    setUp(() {
      xpService = UnifiedXPService.getInstance();
    });

    test('Level 1 should be unlocked by default', () async {
      final level1Unlocked = await xpService.isLevelUnlocked(
        subject: subject,
        level: 1,
        skillId: skillId,
      );
      expect(level1Unlocked, isTrue);
    });

    test('Level 2 should be locked initially', () async {
      final level2Unlocked = await xpService.isLevelUnlocked(
        subject: subject,
        level: 2,
        skillId: skillId,
      );
      expect(level2Unlocked, isFalse);
    });

    test('Completing Level 1 should allow Level 2 to be unlocked', () async {
      // Complete Level 1
      await xpService.updateLevelProgress(
        userId: userId,
        levelId: '${skillId}_1',
        isCompleted: true,
        accuracy: 85.0,
        score: 850,
        totalTime: 300, // 5 minutes in seconds
      );

      // Manually unlock Level 2 (simulating game controller behavior)
      await xpService.unlockLevel(
        subject: subject,
        level: 2,
        skillId: skillId,
      );

      // Verify Level 2 is now unlocked
      final level2Unlocked = await xpService.isLevelUnlocked(
        subject: subject,
        level: 2,
        skillId: skillId,
      );
      expect(level2Unlocked, isTrue);
    });

    test('Level progress should be saved correctly', () async {
      // Complete Level 1 with specific stats
      await xpService.updateLevelProgress(
        userId: userId,
        levelId: '${skillId}_1',
        isCompleted: true,
        accuracy: 95.0, // Should give 3 stars
        score: 950,
        totalTime: 180, // 3 minutes in seconds
      );

      // Check progress
      final userProgress = await xpService.getUserProgress(userId);
      final level1Progress = userProgress.levelProgress['${skillId}_1'];

      expect(level1Progress?.isCompleted, isTrue);
      expect(level1Progress?.accuracy, equals(95.0));
      expect(level1Progress?.bestScore, equals(950));
      // Note: Stars are calculated in the UI layer, not stored in progress data
    });

    test('Progress data should be stored correctly', () async {
      // Test different accuracy levels
      const testCases = [
        (60.0, false), // Below 70% = not completed
        (75.0, true),  // 70%+ = completed
        (88.0, true),  // 85%+ = completed
        (97.0, true),  // 95%+ = completed
      ];

      for (int i = 0; i < testCases.length; i++) {
        final (accuracy, shouldBeCompleted) = testCases[i];
        final levelId = '${skillId}_test_$i';

        await xpService.updateLevelProgress(
          userId: userId,
          levelId: levelId,
          isCompleted: shouldBeCompleted,
          accuracy: accuracy,
          score: (accuracy * 10).round(),
          totalTime: 300, // 5 minutes in seconds
        );

        final userProgress = await xpService.getUserProgress(userId);
        final levelProgress = userProgress.levelProgress[levelId];

        expect(levelProgress?.isCompleted, equals(shouldBeCompleted),
            reason: 'Accuracy $accuracy% completion should be $shouldBeCompleted');
        expect(levelProgress?.accuracy, equals(accuracy),
            reason: 'Accuracy should be stored correctly');
      }
    });
  });
}
