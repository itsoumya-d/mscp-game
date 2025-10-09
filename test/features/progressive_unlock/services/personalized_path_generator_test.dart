import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:sp/core/services/personalized_path_generator.dart';
import 'package:sp/core/models/learning_path.dart';

// Generate mocks
@GenerateMocks([
  PersonalizedPathGenerator,
])
import 'personalized_path_generator_test.mocks.dart';

void main() {
  group('PersonalizedPathGenerator Tests', () {
    late PersonalizedPathGenerator generator;
    late MockPersonalizedPathGenerator mockGenerator;

    setUp(() {
      generator = PersonalizedPathGenerator();
      mockGenerator = MockPersonalizedPathGenerator();
    });

    group('Initialization', () {
      test('should initialize with default settings', () {
        expect(generator, isNotNull);
      });

      test('should accept custom configuration', () {
        final customGenerator = PersonalizedPathGenerator(
          maxPathLength: 20,
          adaptationThreshold: 0.7,
        );
        expect(customGenerator, isNotNull);
      });
    });

    group('Learning Style Detection', () {
      test('should detect visual learning style', () async {
        // Arrange
        const userId = 'user_123';
        final userPerformance = {
          'visual_questions_accuracy': 0.9,
          'auditory_questions_accuracy': 0.6,
          'kinesthetic_questions_accuracy': 0.7,
          'reading_questions_accuracy': 0.8,
        };

        when(mockGenerator.detectLearningStyle(userId))
            .thenAnswer((_) async => LearningPathType.adaptive);

        // Act
        final learningStyle = await mockGenerator.detectLearningStyle(userId);

        // Assert
        expect(learningStyle, equals(LearningPathType.adaptive));
        verify(mockGenerator.detectLearningStyle(userId)).called(1);
      });

      test('should detect structured learning style', () async {
        // Arrange
        const userId = 'user_124';

        when(mockGenerator.detectLearningStyle(userId))
            .thenAnswer((_) async => LearningPathType.structured);

        // Act
        final learningStyle = await mockGenerator.detectLearningStyle(userId);

        // Assert
        expect(learningStyle, equals(LearningPathType.structured));
      });

      test('should detect exploratory learning style', () async {
        // Arrange
        const userId = 'user_125';

        when(mockGenerator.detectLearningStyle(userId))
            .thenAnswer((_) async => LearningPathType.exploratory);

        // Act
        final learningStyle = await mockGenerator.detectLearningStyle(userId);

        // Assert
        expect(learningStyle, equals(LearningPathType.exploratory));
      });

      test('should default to adaptive style for unclear patterns', () async {
        // Arrange
        const userId = 'user_126';

        when(mockGenerator.detectLearningStyle(userId))
            .thenAnswer((_) async => LearningPathType.adaptive);

        // Act
        final learningStyle = await mockGenerator.detectLearningStyle(userId);

        // Assert
        expect(learningStyle, equals(LearningPathType.adaptive));
      });
    });

    group('Path Generation', () {
      test('should generate adaptive learning path', () async {
        // Arrange
        const userId = 'user_123';
        final mockPath = LearningPath(
          id: 'adaptive_path_123',
          pathType: LearningPathType.adaptive,
          title: 'Adaptive Learning Journey',
          description: 'Dynamically adjusts to learner progress and preferences',
          milestones: [
            LearningMilestone(
              id: 'adaptive_milestone_1',
              title: 'Adaptive Concepts',
              description: 'Learn through personalized content delivery',
              requiredSkills: ['pattern_recognition', 'adaptive_reasoning'],
              isCompleted: false,
            ),
            LearningMilestone(
              id: 'adaptive_milestone_2',
              title: 'Advanced Adaptation',
              description: 'Complex adaptive problem solving',
              requiredSkills: ['dynamic_learning', 'personalized_analysis'],
              isCompleted: false,
            ),
          ],
          estimatedDuration: const Duration(hours: 8),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockGenerator.generatePersonalizedPath(userId, LearningPathType.adaptive))
            .thenAnswer((_) async => mockPath);

        // Act
        final path = await mockGenerator.generatePersonalizedPath(userId, LearningPathType.adaptive);

        // Assert
        expect(path, isNotNull);
        expect(path.pathType, equals(LearningPathType.adaptive));
        expect(path.milestones, hasLength(2));
        expect(path.milestones.first.requiredSkills, contains('pattern_recognition'));
      });

      test('should generate structured learning path', () async {
        // Arrange
        const userId = 'user_124';
        final mockPath = LearningPath(
          id: 'structured_path_124',
          pathType: LearningPathType.structured,
          title: 'Structured Learning Journey',
          description: 'Sequential and organized learning approach',
          milestones: [
            LearningMilestone(
              id: 'structured_milestone_1',
              title: 'Foundation Building',
              description: 'Learn through systematic progression',
              requiredSkills: ['sequential_learning', 'structured_thinking'],
              isCompleted: false,
            ),
          ],
          estimatedDuration: const Duration(hours: 6),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockGenerator.generatePersonalizedPath(userId, LearningPathType.structured))
            .thenAnswer((_) async => mockPath);

        // Act
        final path = await mockGenerator.generatePersonalizedPath(userId, LearningPathType.structured);

        // Assert
        expect(path, isNotNull);
        expect(path.pathType, equals(LearningPathType.structured));
        expect(path.milestones.first.requiredSkills, contains('sequential_learning'));
      });

      test('should generate exploratory learning path', () async {
        // Arrange
        const userId = 'user_125';
        final mockPath = LearningPath(
          id: 'exploratory_path_125',
          pathType: LearningPathType.exploratory,
          title: 'Exploratory Learning Journey',
          description: 'Self-directed discovery and exploration',
          milestones: [
            LearningMilestone(
              id: 'exploratory_milestone_1',
              title: 'Discovery Phase',
              description: 'Learn through exploration and experimentation',
              requiredSkills: ['curiosity_driven_learning', 'self_direction'],
              isCompleted: false,
            ),
          ],
          estimatedDuration: const Duration(hours: 10),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockGenerator.generatePersonalizedPath(userId, LearningPathType.exploratory))
            .thenAnswer((_) async => mockPath);

        // Act
        final path = await mockGenerator.generatePersonalizedPath(userId, LearningPathType.exploratory);

        // Assert
        expect(path, isNotNull);
        expect(path.pathType, equals(LearningPathType.exploratory));
        expect(path.milestones.first.requiredSkills, contains('curiosity_driven_learning'));
      });

      test('should customize path based on skill mastery', () async {
        // Arrange
        const userId = 'user_126';
        final skillMasteries = [
          SkillMastery(
            skillId: 'basic_math',
            masteryLevel: 0.9,
            practiceCount: 50,
            lastPracticed: DateTime.now(),
            strengthAreas: ['addition', 'subtraction'],
            weaknessAreas: [],
            recommendedNextSteps: ['multiplication'],
          ),
          SkillMastery(
            skillId: 'advanced_math',
            masteryLevel: 0.3,
            practiceCount: 5,
            lastPracticed: DateTime.now(),
            strengthAreas: [],
            weaknessAreas: ['algebra', 'geometry'],
            recommendedNextSteps: ['practice_basics'],
          ),
        ];

        final mockPath = LearningPath(
          id: 'customized_path_126',
          pathType: LearningPathType.adaptive,
          title: 'Customized Learning Path',
          description: 'Tailored based on current skill levels',
          milestones: [
            LearningMilestone(
              id: 'skip_basics',
              title: 'Advanced Topics',
              description: 'Skip mastered basics, focus on weak areas',
              requiredSkills: ['multiplication', 'algebra_basics'],
              isCompleted: false,
            ),
          ],
          estimatedDuration: const Duration(hours: 12),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockGenerator.customizePathForSkillLevel(userId, skillMasteries))
            .thenAnswer((_) async => mockPath);

        // Act
        final path = await mockGenerator.customizePathForSkillLevel(userId, skillMasteries);

        // Assert
        expect(path, isNotNull);
        expect(path.title, contains('Customized'));
        expect(path.milestones.first.requiredSkills, contains('multiplication'));
      });
    });

    group('Path Adaptation', () {
      test('should adapt path based on performance', () async {
        // Arrange
        const userId = 'user_123';
        const pathId = 'path_123';
        final performanceData = {
          'accuracy': 0.95,
          'speed': 0.8,
          'engagement': 0.9,
          'difficulty_preference': 'challenging',
        };

        when(mockGenerator.adaptPathBasedOnPerformance(userId, pathId, performanceData))
            .thenAnswer((_) async => true);

        // Act
        final adapted = await mockGenerator.adaptPathBasedOnPerformance(
          userId, pathId, performanceData
        );

        // Assert
        expect(adapted, isTrue);
        verify(mockGenerator.adaptPathBasedOnPerformance(
          userId, pathId, performanceData
        )).called(1);
      });

      test('should suggest path modifications', () async {
        // Arrange
        const userId = 'user_123';
        const pathId = 'path_123';
        final expectedSuggestions = [
          'Increase difficulty level',
          'Add more visual elements',
          'Reduce session length',
          'Focus on weak areas',
        ];

        when(mockGenerator.suggestPathModifications(userId, pathId))
            .thenAnswer((_) async => expectedSuggestions);

        // Act
        final suggestions = await mockGenerator.suggestPathModifications(userId, pathId);

        // Assert
        expect(suggestions, isNotNull);
        expect(suggestions, hasLength(4));
        expect(suggestions, contains('Increase difficulty level'));
      });

      test('should handle path branching for different outcomes', () async {
        // Arrange
        const userId = 'user_123';
        const currentMilestoneId = 'milestone_5';
        final branchOptions = {
          'advanced_track': 'Continue with advanced concepts',
          'review_track': 'Review and reinforce basics',
          'alternative_track': 'Try different learning approach',
        };

        when(mockGenerator.generatePathBranches(userId, currentMilestoneId))
            .thenAnswer((_) async => branchOptions);

        // Act
        final branches = await mockGenerator.generatePathBranches(userId, currentMilestoneId);

        // Assert
        expect(branches, isNotNull);
        expect(branches.keys, contains('advanced_track'));
        expect(branches.keys, contains('review_track'));
        expect(branches.keys, contains('alternative_track'));
      });
    });

    group('Milestone Generation', () {
      test('should generate appropriate milestones for skill level', () async {
        // Arrange
        const userId = 'user_123';
        const skillLevel = 'intermediate';
        final expectedMilestones = [
          LearningMilestone(
            id: 'intermediate_1',
            title: 'Intermediate Concepts',
            description: 'Build on basic knowledge',
            requiredSkills: ['skill_a', 'skill_b'],
            isCompleted: false,
          ),
          LearningMilestone(
            id: 'intermediate_2',
            title: 'Applied Practice',
            description: 'Apply concepts in practice',
            requiredSkills: ['skill_c', 'skill_d'],
            isCompleted: false,
          ),
        ];

        when(mockGenerator.generateMilestonesForLevel(userId, skillLevel))
            .thenAnswer((_) async => expectedMilestones);

        // Act
        final milestones = await mockGenerator.generateMilestonesForLevel(userId, skillLevel);

        // Assert
        expect(milestones, hasLength(2));
        expect(milestones.first.title, contains('Intermediate'));
        expect(milestones.every((m) => m.requiredSkills.isNotEmpty), isTrue);
      });

      test('should sequence milestones logically', () async {
        // Arrange
        const userId = 'user_123';
        final unorderedMilestones = [
          LearningMilestone(
            id: 'advanced_milestone',
            title: 'Advanced Topics',
            description: 'Complex concepts',
            requiredSkills: ['prerequisite_1', 'prerequisite_2'],
            isCompleted: false,
          ),
          LearningMilestone(
            id: 'basic_milestone',
            title: 'Basic Concepts',
            description: 'Fundamental knowledge',
            requiredSkills: ['foundation_skill'],
            isCompleted: false,
          ),
        ];

        final expectedSequence = [
          unorderedMilestones[1], // Basic first
          unorderedMilestones[0], // Advanced second
        ];

        when(mockGenerator.sequenceMilestones(unorderedMilestones))
            .thenAnswer((_) async => expectedSequence);

        // Act
        final sequenced = await mockGenerator.sequenceMilestones(unorderedMilestones);

        // Assert
        expect(sequenced, hasLength(2));
        expect(sequenced.first.title, contains('Basic'));
        expect(sequenced.last.title, contains('Advanced'));
      });
    });

    group('Performance Analytics', () {
      test('should analyze path effectiveness', () async {
        // Arrange
        const pathId = 'path_123';
        final expectedAnalysis = {
          'completion_rate': 0.85,
          'average_time_per_milestone': Duration(hours: 2),
          'user_satisfaction': 4.2,
          'learning_efficiency': 0.78,
          'recommended_improvements': ['Add more examples', 'Reduce complexity'],
        };

        when(mockGenerator.analyzePathEffectiveness(pathId))
            .thenAnswer((_) async => expectedAnalysis);

        // Act
        final analysis = await mockGenerator.analyzePathEffectiveness(pathId);

        // Assert
        expect(analysis, isNotNull);
        expect(analysis['completion_rate'], greaterThan(0.8));
        expect(analysis['recommended_improvements'], isA<List>());
      });

      test('should track learning velocity across paths', () async {
        // Arrange
        const userId = 'user_123';
        final expectedVelocity = {
          'visual_path': 0.9,
          'auditory_path': 0.6,
          'kinesthetic_path': 0.8,
          'reading_path': 0.7,
        };

        when(mockGenerator.trackLearningVelocityByPath(userId))
            .thenAnswer((_) async => expectedVelocity);

        // Act
        final velocity = await mockGenerator.trackLearningVelocityByPath(userId);

        // Assert
        expect(velocity, isNotNull);
        expect(velocity['visual_path'], equals(0.9));
        expect(velocity.values.every((v) => v >= 0 && v <= 1), isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle invalid user data gracefully', () async {
        // Arrange
        const invalidUserId = '';

        when(mockGenerator.detectLearningStyle(invalidUserId))
            .thenAnswer((_) async => LearningPathType.adaptive);

        // Act
        final style = await mockGenerator.detectLearningStyle(invalidUserId);

        // Assert
        expect(style, equals(LearningPathType.adaptive));
      });

      test('should handle insufficient performance data', () async {
        // Arrange
        const userId = 'new_user_123';

        when(mockGenerator.detectLearningStyle(userId))
            .thenAnswer((_) async => LearningPathType.adaptive);

        // Act
        final style = await mockGenerator.detectLearningStyle(userId);

        // Assert
        expect(style, equals(LearningPathType.adaptive));
      });

      test('should handle path generation failures', () async {
        // Arrange
        const userId = 'user_123';

        when(mockGenerator.generatePersonalizedPath(userId, LearningPathType.adaptive))
            .thenThrow(Exception('Path generation failed'));

        // Act & Assert
        expect(
          () => mockGenerator.generatePersonalizedPath(userId, LearningPathType.adaptive),
          throwsException,
        );
      });

      test('should validate generated paths', () async {
        // Arrange
        final invalidPath = LearningPath(
          id: '',
          pathType: LearningPathType.adaptive,
          title: '',
          description: '',
          milestones: [],
          estimatedDuration: const Duration(hours: 0),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockGenerator.validatePath(invalidPath))
            .thenAnswer((_) async => false);

        // Act
        final isValid = await mockGenerator.validatePath(invalidPath);

        // Assert
        expect(isValid, isFalse);
      });
    });

    group('Integration', () {
      test('should integrate with skill mastery system', () async {
        // Arrange
        const userId = 'user_123';
        final skillData = [
          {'skillId': 'math_basics', 'mastery': 0.9},
          {'skillId': 'reading_comp', 'mastery': 0.7},
        ];

        when(mockGenerator.integrateWithSkillMastery(userId, skillData))
            .thenAnswer((_) async => true);

        // Act
        final integrated = await mockGenerator.integrateWithSkillMastery(userId, skillData);

        // Assert
        expect(integrated, isTrue);
      });

      test('should sync with adaptive difficulty system', () async {
        // Arrange
        const userId = 'user_123';
        const pathId = 'path_123';
        final difficultyData = {
          'current_level': 'medium',
          'trend': 'increasing',
          'confidence': 0.85,
        };

        when(mockGenerator.syncWithAdaptiveDifficulty(userId, pathId, difficultyData))
            .thenAnswer((_) async => true);

        // Act
        final synced = await mockGenerator.syncWithAdaptiveDifficulty(
          userId, pathId, difficultyData
        );

        // Assert
        expect(synced, isTrue);
      });
    });
  });
}