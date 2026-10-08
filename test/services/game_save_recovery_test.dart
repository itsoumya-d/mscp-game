import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sp/core/providers/game_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp/core/models/question.dart';
import 'package:sp/core/models/question_pool.dart';
import 'package:sp/core/models/subject.dart';
import 'package:sp/core/services/game_save_service.dart';
import 'package:sp/core/services/game_session_service.dart';

SevenQuestionGameSession savedGame() => SevenQuestionGameSession(
  id: 'math-level-4',
  subject: SubjectType.math,
  level: 4,
  skillId: 'addition',
  categories: const [QuestionCategory.computational],
  questions: [
    for (final type in QuestionType.values)
      Question(
        id: 'question-${type.name}',
        type: type,
        questionText: 'What is 2 + 2?',
        options: const ['3', '4', '5'],
        correctAnswer: '4',
        explanation: 'Two pairs make four.',
        hint: 'Count both pairs.',
        difficulty: 2,
        subject: SubjectType.math,
      ),
  ],
  userAnswers: const ['4', '3'],
  answerCorrectness: const [true, false, false, false, false, false, false],
  currentQuestionIndex: 2,
  startTime: DateTime.utc(2026, 1, 2, 12),
  score: 100,
  isCompleted: false,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Reset the plugin's singleton cache from the persisted payload, rather than
  // merely constructing another stateless service over the same cache.
  Future<GameSession?> restartAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('game_session_data');
    SharedPreferences.setMockInitialValues({
      if (saved != null) 'game_session_data': saved,
    });
    return GameSaveService().loadGameSession();
  }

  test(
    'restores a playable seven-question save after a storage reload',
    () async {
      final original = savedGame();
      await GameSaveService().saveGameSession(original);

      final loaded = await restartAndLoad();
      expect(loaded, isA<SevenQuestionGameSession>());
      final restored = loaded! as SevenQuestionGameSession;
      expect(restored.toJson(), original.toJson());
      expect(restored.categories, original.categories);
      expect(restored.questions, original.questions);
      expect(
        restored.questions[restored.currentQuestionIndex].id,
        original.questions[2].id,
      );
      expect(restored.level, 4);
      expect(restored.answerCorrectness, original.answerCorrectness);
      expect(restored.isCompleted, isFalse);
      expect(restored.endTime, isNull);
    },
  );

  test(
    'the game controller resumes the reloaded question and progress',
    () async {
      await GameSaveService().saveGameSession(savedGame());
      await restartAndLoad();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(gameControllerProvider);

      await controller.loadSavedGame('math-level-4');

      expect(controller.error, isNull);
      expect(controller.isGameActive, isTrue);
      expect(controller.isGameCompleted, isFalse);
      expect(controller.currentQuestionIndex, 2);
      expect(controller.currentQuestion, savedGame().questions[2]);
      expect(controller.userAnswers, ['4', '3']);
      expect(controller.score, 100);
    },
  );

  test(
    'reads existing seven-question saves without categories or lives',
    () async {
      final legacyJson = jsonDecode(
        File('test/fixtures/legacy_seven_question_game.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      SharedPreferences.setMockInitialValues({
        'game_session_data': jsonEncode(legacyJson),
      });

      final loaded = await GameSaveService().loadGameSession();
      expect(loaded, isA<SevenQuestionGameSession>());
      final restored = loaded! as SevenQuestionGameSession;
      expect(restored.id, legacyJson['id']);
      expect(restored.categories, isEmpty);
      expect(restored.level, 4);
      expect(restored.currentQuestionIndex, 2);
      expect(restored.questions.length, 7);
    },
  );

  test('keeps legacy base game saves readable', () async {
    final original = GameSession(
      id: 'legacy-game',
      subject: SubjectType.math,
      skillId: 'addition',
      categories: const [QuestionCategory.computational],
      questions: savedGame().questions,
      userAnswers: const ['4'],
      currentQuestionIndex: 1,
      startTime: DateTime.utc(2026, 1, 1),
      score: 1,
      lives: 2,
    );
    await GameSaveService().saveGameSession(original);

    final loaded = await restartAndLoad();
    expect(loaded, isNotNull);
    expect(loaded, isNot(isA<SevenQuestionGameSession>()));
    expect(loaded!.toJson(), original.toJson());
  });

  test(
    'preserves completed session status and end time after restart',
    () async {
      final completed = savedGame().copyWith(
        currentQuestionIndex: 7,
        isCompleted: true,
        endTime: DateTime.utc(2026, 1, 2, 12, 5),
      );
      await GameSaveService().saveGameSession(completed);

      final loaded = await restartAndLoad();
      expect(loaded, isA<SevenQuestionGameSession>());
      final restored = loaded! as SevenQuestionGameSession;
      expect(restored.isCompleted, isTrue);
      expect(restored.endTime, completed.endTime);
      expect(restored.currentQuestionIndex, 7);
    },
  );

  test('copying game progress preserves its categories', () {
    final original = savedGame();
    expect(original.copyWith(score: 200).categories, original.categories);
  });

  for (final entry in {
    'truncated JSON': '{incomplete',
    'wrong JSON shape': jsonEncode(['unexpected list']),
    'invalid level': jsonEncode(savedGame().toJson()..['level'] = 'invalid'),
    'unknown subject': jsonEncode(
      savedGame().toJson()..['subject'] = 'unknown',
    ),
  }.entries) {
    test('recovers from ${entry.key} when a new game is saved', () async {
      final badSave = entry.value;
      SharedPreferences.setMockInitialValues({'game_session_data': badSave});
      final service = GameSaveService();
      expect(await service.loadGameSession(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('game_session_data'),
        badSave,
        reason: 'Reading a corrupt save must not erase it.',
      );

      await service.saveGameSession(savedGame());
      expect(await restartAndLoad(), isA<SevenQuestionGameSession>());
    });
  }

  test(
    'clearing a seven-question save does not resurrect it after reload',
    () async {
      final service = GameSaveService();
      await service.saveGameSession(savedGame());
      await service.clearGameSession();
      expect(await restartAndLoad(), isNull);
    },
  );
}
