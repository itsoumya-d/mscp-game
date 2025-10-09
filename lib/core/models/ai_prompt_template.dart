import 'subject.dart';

/// Example question for AI prompt templates
class ExampleQuestion {
  final String question;
  final String correctAnswer;
  final String explanation;
  final List<String> options;

  const ExampleQuestion({
    required this.question,
    required this.correctAnswer,
    required this.explanation,
    this.options = const [],
  });

  Map<String, dynamic> toJson() => {
    'question': question,
    'correctAnswer': correctAnswer,
    'explanation': explanation,
    'options': options,
  };

  factory ExampleQuestion.fromJson(Map<String, dynamic> json) => ExampleQuestion(
    question: json['question'] as String,
    correctAnswer: json['correctAnswer'] as String,
    explanation: json['explanation'] as String,
    options: List<String>.from(json['options'] as List? ?? []),
  );
}

/// AI prompt template for generating subject-specific questions
class AIPromptTemplate {
  final String skillId;
  final String skillName;
  final String gradeLevel;
  final SubjectType subject;
  final List<String> conceptsToTest;
  final List<String> questionFormats;
  final Map<String, String> difficultyScaling;
  final Map<int, List<ExampleQuestion>> exampleQuestions;
  final List<String> relevantFormulas;
  final List<String> commonMistakes;
  final List<String> formulas; // Add formulas field
  final String additionalContext; // Add additionalContext field

  const AIPromptTemplate({
    required this.skillId,
    required this.skillName,
    required this.gradeLevel,
    required this.subject,
    required this.conceptsToTest,
    required this.questionFormats,
    required this.difficultyScaling,
    required this.exampleQuestions,
    this.relevantFormulas = const [],
    this.commonMistakes = const [],
    this.formulas = const [], // Add formulas parameter
    this.additionalContext = '', // Add additionalContext parameter
  });

  /// Generate AI prompt for this template
  String generatePrompt({
    required int level,
    required int questionCount,
    String? customTopic,
  }) {
    final difficultyRange = _getDifficultyRange(level);
    final difficultyDescription = difficultyScaling[difficultyRange] ?? 'Standard difficulty';
    
    return '''
Generate $questionCount ${subject.name} questions for $skillName (Level $level).

SKILL: $skillName
GRADE LEVEL: $gradeLevel
DIFFICULTY: $difficultyDescription

CONCEPTS TO TEST:
${conceptsToTest.map((c) => '- $c').join('\n')}

QUESTION FORMATS:
${questionFormats.map((f) => '- $f').join('\n')}

${relevantFormulas.isNotEmpty ? '''
RELEVANT FORMULAS:
${relevantFormulas.map((f) => '- $f').join('\n')}
''' : ''}

${commonMistakes.isNotEmpty ? '''
COMMON MISTAKES TO AVOID:
${commonMistakes.map((m) => '- $m').join('\n')}
''' : ''}

EXAMPLE QUESTIONS:
${_getExampleQuestionsText(level)}

Generate $questionCount questions following these guidelines:
1. Match the difficulty level ($difficultyDescription)
2. Cover the specified concepts
3. Use varied question formats
4. Include clear explanations
5. Provide multiple choice options where appropriate
''';
  }

  String _getDifficultyRange(int level) {
    if (level <= 3) return '1-3';
    if (level <= 6) return '4-6';
    return '7-10';
  }

  String _getExampleQuestionsText(int level) {
    final targetLevel = level <= 3 ? 1 : (level <= 6 ? 5 : 10);
    final examples = exampleQuestions[targetLevel] ?? [];
    
    if (examples.isEmpty) return 'No example questions available.';
    
    return examples.map((example) => '''
Q: ${example.question}
A: ${example.correctAnswer}
Explanation: ${example.explanation}
${example.options.isNotEmpty ? 'Options: ${example.options.join(', ')}' : ''}
''').join('\n');
  }

  Map<String, dynamic> toJson() => {
    'skillId': skillId,
    'skillName': skillName,
    'gradeLevel': gradeLevel,
    'subject': subject.name,
    'conceptsToTest': conceptsToTest,
    'questionFormats': questionFormats,
    'difficultyScaling': difficultyScaling,
    'exampleQuestions': exampleQuestions.map(
      (key, value) => MapEntry(
        key.toString(),
        value.map((q) => q.toJson()).toList(),
      ),
    ),
    'relevantFormulas': relevantFormulas,
    'commonMistakes': commonMistakes,
  };

  factory AIPromptTemplate.fromJson(Map<String, dynamic> json) => AIPromptTemplate(
    skillId: json['skillId'] as String,
    skillName: json['skillName'] as String,
    gradeLevel: json['gradeLevel'] as String,
    subject: SubjectType.values.firstWhere((s) => s.name == json['subject']),
    conceptsToTest: List<String>.from(json['conceptsToTest'] as List),
    questionFormats: List<String>.from(json['questionFormats'] as List),
    difficultyScaling: Map<String, String>.from(json['difficultyScaling'] as Map),
    exampleQuestions: (json['exampleQuestions'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        int.parse(key),
        (value as List).map((q) => ExampleQuestion.fromJson(q as Map<String, dynamic>)).toList(),
      ),
    ),
    relevantFormulas: List<String>.from(json['relevantFormulas'] as List? ?? []),
    commonMistakes: List<String>.from(json['commonMistakes'] as List? ?? []),
  );
}