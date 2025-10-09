import '../models/subject.dart';
import '../models/ai_prompt_template.dart';
import 'prompt_template_registry.dart';
// AI prompt templates removed for AI cleanup

/// Mathematics Prompt Templates
/// Part of Phase C: Redesign AI Question Generation System
class MathPromptTemplates {
  /// Register all mathematics templates with the registry
  static void registerAll(PromptTemplateRegistry registry) {
    registry.registerTemplate(_createAdditionSubtractionTemplate());
    registry.registerTemplate(_createMultiplicationDivisionTemplate());
    registry.registerTemplate(_createFractionsTemplate());
    registry.registerTemplate(_createDecimalsTemplate());
    registry.registerTemplate(_createAlgebraTemplate());
    registry.registerTemplate(_createGeometryTemplate());
  }

  /// Addition and Subtraction Template
  static AIPromptTemplate _createAdditionSubtractionTemplate() {
    return AIPromptTemplate(
      skillId: 'addition_subtraction',
      skillName: 'Addition and Subtraction',
      gradeLevel: 'Grades 1-5',
      subject: SubjectType.math,
      
      conceptsToTest: [
        'Single-digit addition (3+5, 7+2)',
        'Single-digit subtraction (9-4, 6-3)',
        'Two-digit addition with/without carrying',
        'Two-digit subtraction with/without borrowing',
        'Three-digit addition and subtraction',
        'Word problems with addition/subtraction',
        'Missing number problems (15 + ? = 23)',
        'Real-world applications (money, time, measurement)',
      ],
      
      questionFormats: [
        'Direct calculation: "What is 15 + 27?"',
        'Word problems: "Sarah has 12 apples. She buys 8 more. How many does she have now?"',
        'Missing number: "23 + ? = 45"',
        'Comparison: "Which is greater: 34 + 12 or 50 - 5?"',
        'Multi-step: "John has 50 dollars. He spends 15 on lunch and 12 on a book. How much is left?"',
      ],
      
      difficultyScaling: {
        '1-3': 'Numbers 0-20, single-digit operations, no carrying/borrowing, one-step problems, concrete scenarios',
        '4-6': 'Numbers 0-100, two-digit operations, simple carrying/borrowing, two-step problems, word problems',
        '7-10': 'Numbers 0-1000, three-digit operations, complex carrying/borrowing, multi-step problems, real-world applications',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'What is 5 + 3?',
            correctAnswer: '8',
            explanation: '5 + 3 = 8. Count up from 5: 6, 7, 8.',
            options: ['6', '7', '8', '9'],
          ),
          ExampleQuestion(
            question: 'What is 9 - 4?',
            correctAnswer: '5',
            explanation: '9 - 4 = 5. Count down from 9: 8, 7, 6, 5.',
            options: ['4', '5', '6', '7'],
          ),
          ExampleQuestion(
            question: 'Sarah has 7 candies. She gets 5 more. How many candies does she have now?',
            correctAnswer: '12',
            explanation: '7 + 5 = 12 candies total.',
            options: ['10', '11', '12', '13'],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'What is 45 + 38?',
            correctAnswer: '83',
            explanation: '45 + 38 = 83. Add ones: 5+8=13 (carry 1). Add tens: 4+3+1=8.',
            options: ['73', '83', '93', '82'],
          ),
          ExampleQuestion(
            question: 'What is 72 - 28?',
            correctAnswer: '44',
            explanation: '72 - 28 = 44. Borrow from tens: 12-8=4, 6-2=4.',
            options: ['44', '54', '46', '42'],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'What is 456 + 789?',
            correctAnswer: '1245',
            explanation: '456 + 789 = 1245. Add column by column with carrying.',
            options: ['1145', '1235', '1245', '1345'],
          ),
          ExampleQuestion(
            question: 'A store had 523 items. They sold 178. How many items are left?',
            correctAnswer: '345',
            explanation: '523 - 178 = 345 items remaining.',
            options: ['345', '355', '445', '335'],
          ),
        ],
      },
      
      formulas: [
        'a + b = b + a (commutative property)',
        'a - b ≠ b - a (subtraction is not commutative)',
        'Check subtraction: a - b = c means a = b + c',
      ],
      
      commonMistakes: [
        'Forgetting to carry when sum > 9',
        'Forgetting to borrow when subtracting larger from smaller',
        'Adding instead of subtracting in word problems',
        'Misaligning place values',
      ],
    );
  }

  /// Multiplication and Division Template
  static AIPromptTemplate _createMultiplicationDivisionTemplate() {
    return AIPromptTemplate(
      skillId: 'multiplication_division',
      skillName: 'Multiplication and Division',
      gradeLevel: 'Grades 3-6',
      subject: SubjectType.math,
      
      conceptsToTest: [
        'Multiplication tables 1-12',
        'Multiplication as repeated addition',
        'Division as inverse of multiplication',
        'Division with remainders',
        'Two-digit by one-digit multiplication',
        'Two-digit by two-digit multiplication',
        'Long division',
        'Word problems with multiplication/division',
        'Order of operations with × and ÷',
      ],
      
      questionFormats: [
        'Direct calculation: "What is 7 × 8?"',
        'Word problems: "If 6 boxes have 8 apples each, how many apples total?"',
        'Missing number: "? × 6 = 42"',
        'Division: "What is 56 ÷ 8?"',
        'Division with remainder: "What is 17 ÷ 5?"',
        'Multi-step: "24 cookies shared equally among 6 children. How many does each get?"',
      ],
      
      difficultyScaling: {
        '1-3': 'Tables 1-5, numbers 1-50, no remainders, one-step problems, multiplication as repeated addition',
        '4-6': 'Tables 1-10, numbers 1-100, simple remainders, two-step problems, two-digit × one-digit',
        '7-10': 'Tables 1-12, numbers 1-1000, complex remainders, multi-step problems, two-digit × two-digit, long division',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'What is 3 × 4?',
            correctAnswer: '12',
            explanation: '3 × 4 = 12. Think: 3 + 3 + 3 + 3 = 12.',
            options: ['9', '10', '12', '15'],
          ),
          ExampleQuestion(
            question: 'What is 12 ÷ 3?',
            correctAnswer: '4',
            explanation: '12 ÷ 3 = 4. How many 3s in 12? Four 3s.',
            options: ['3', '4', '5', '6'],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'What is 8 × 7?',
            correctAnswer: '56',
            explanation: '8 × 7 = 56. This is from the multiplication table.',
            options: ['48', '54', '56', '63'],
          ),
          ExampleQuestion(
            question: 'What is 23 × 4?',
            correctAnswer: '92',
            explanation: '23 × 4 = 92. (20 × 4) + (3 × 4) = 80 + 12 = 92.',
            options: ['82', '88', '92', '96'],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'What is 34 × 27?',
            correctAnswer: '918',
            explanation: '34 × 27 = 918. Use standard multiplication algorithm.',
            options: ['818', '918', '928', '1018'],
          ),
          ExampleQuestion(
            question: 'What is 456 ÷ 12?',
            correctAnswer: '38',
            explanation: '456 ÷ 12 = 38. Use long division.',
            options: ['36', '37', '38', '39'],
          ),
        ],
      },
      
      formulas: [
        'a × b = b × a (commutative property)',
        'a ÷ b = c means a = b × c',
        'Division with remainder: a ÷ b = q remainder r, where a = b × q + r',
      ],
      
      commonMistakes: [
        'Confusing multiplication and addition',
        'Forgetting to carry in multiplication',
        'Dividing incorrectly with remainders',
        'Mixing up order in division (12 ÷ 3 ≠ 3 ÷ 12)',
      ],
    );
  }

  /// Fractions Template
  static AIPromptTemplate _createFractionsTemplate() {
    return AIPromptTemplate(
      skillId: 'fractions',
      skillName: 'Fractions',
      gradeLevel: 'Grades 4-7',
      subject: SubjectType.math,
      
      conceptsToTest: [
        'Understanding fractions (numerator/denominator)',
        'Equivalent fractions',
        'Simplifying fractions',
        'Comparing fractions',
        'Adding fractions with same denominator',
        'Adding fractions with different denominators',
        'Subtracting fractions',
        'Multiplying fractions',
        'Dividing fractions',
        'Mixed numbers and improper fractions',
      ],
      
      questionFormats: [
        'Simplify: "Simplify 6/8"',
        'Compare: "Which is larger: 2/3 or 3/4?"',
        'Add: "What is 1/4 + 2/4?"',
        'Multiply: "What is 2/3 × 3/5?"',
        'Word problems: "Sarah ate 1/4 of a pizza. John ate 1/3. Who ate more?"',
      ],
      
      difficultyScaling: {
        '1-3': 'Simple fractions (halves, thirds, quarters), same denominators, visual representations',
        '4-6': 'Common fractions, different denominators, simplifying, equivalent fractions',
        '7-10': 'Complex fractions, mixed numbers, all operations, multi-step problems',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'What is 1/2 + 1/2?',
            correctAnswer: '1',
            explanation: '1/2 + 1/2 = 2/2 = 1 whole.',
            options: ['1/2', '1', '2', '1/4'],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'What is 2/3 + 1/4?',
            correctAnswer: '11/12',
            explanation: '2/3 + 1/4 = 8/12 + 3/12 = 11/12.',
            options: ['3/7', '11/12', '5/6', '1'],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'What is 2 1/3 × 1 1/2?',
            correctAnswer: '3 1/2',
            explanation: '2 1/3 × 1 1/2 = 7/3 × 3/2 = 21/6 = 3 1/2.',
            options: ['3', '3 1/2', '4', '3 1/3'],
          ),
        ],
      },
      
      formulas: [
        'a/b + c/b = (a+c)/b (same denominator)',
        'a/b + c/d = (ad+bc)/(bd) (different denominators)',
        'a/b × c/d = (a×c)/(b×d)',
        'a/b ÷ c/d = a/b × d/c (multiply by reciprocal)',
      ],
    );
  }

  /// Decimals Template
  static AIPromptTemplate _createDecimalsTemplate() {
    return AIPromptTemplate(
      skillId: 'decimals',
      skillName: 'Decimals',
      gradeLevel: 'Grades 4-7',
      subject: SubjectType.math,
      
      conceptsToTest: [
        'Understanding place value (tenths, hundredths)',
        'Comparing decimals',
        'Adding decimals',
        'Subtracting decimals',
        'Multiplying decimals',
        'Dividing decimals',
        'Converting fractions to decimals',
        'Converting decimals to fractions',
        'Rounding decimals',
      ],
      
      questionFormats: [
        'Add: "What is 3.5 + 2.7?"',
        'Multiply: "What is 0.5 × 0.4?"',
        'Compare: "Which is larger: 0.45 or 0.5?"',
        'Convert: "What is 3/4 as a decimal?"',
        'Word problems: "A book costs \$12.50. With 10% discount, what is the price?"',
      ],
      
      difficultyScaling: {
        '1-3': 'Tenths only, simple addition/subtraction, comparing decimals',
        '4-6': 'Hundredths, all operations, converting fractions/decimals',
        '7-10': 'Thousandths, complex operations, percentages, real-world applications',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'What is 0.5 + 0.3?',
            correctAnswer: '0.8',
            explanation: '0.5 + 0.3 = 0.8 (5 tenths + 3 tenths = 8 tenths).',
            options: ['0.7', '0.8', '0.9', '1.0'],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'What is 3.45 × 2?',
            correctAnswer: '6.90',
            explanation: '3.45 × 2 = 6.90. Multiply as whole numbers, then place decimal.',
            options: ['6.80', '6.90', '7.00', '6.45'],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'What is 12.5 ÷ 0.25?',
            correctAnswer: '50',
            explanation: '12.5 ÷ 0.25 = 50. Move decimal points to make divisor whole.',
            options: ['40', '45', '50', '55'],
          ),
        ],
      },
      
      formulas: [
        'To multiply decimals: multiply as whole numbers, count decimal places',
        'To divide by decimal: move decimal point in both numbers',
        'Percent = decimal × 100',
      ],
    );
  }

  /// Algebra Template (Basic)
  static AIPromptTemplate _createAlgebraTemplate() {
    return AIPromptTemplate(
      skillId: 'algebra',
      skillName: 'Algebra',
      gradeLevel: 'Grades 6-9',
      subject: SubjectType.math,
      
      conceptsToTest: [
        'Variables and expressions',
        'Solving one-step equations',
        'Solving two-step equations',
        'Simplifying expressions',
        'Combining like terms',
        'Distributive property',
        'Solving inequalities',
        'Graphing linear equations',
      ],
      
      questionFormats: [
        'Solve: "Solve for x: 2x + 5 = 13"',
        'Simplify: "Simplify: 3x + 2x - 4"',
        'Evaluate: "If x = 3, what is 2x + 5?"',
        'Word problems: "John has x apples. He gets 5 more. He now has 12. Find x."',
      ],
      
      difficultyScaling: {
        '1-3': 'One-step equations, simple expressions, positive integers only',
        '4-6': 'Two-step equations, combining like terms, distributive property',
        '7-10': 'Multi-step equations, inequalities, word problems, negative numbers',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'Solve for x: x + 5 = 12',
            correctAnswer: '7',
            explanation: 'x + 5 = 12, so x = 12 - 5 = 7.',
            options: ['5', '6', '7', '8'],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'Solve for x: 2x + 5 = 13',
            correctAnswer: '4',
            explanation: '2x + 5 = 13. Subtract 5: 2x = 8. Divide by 2: x = 4.',
            options: ['3', '4', '5', '6'],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'Solve for x: 3(x - 2) + 4 = 16',
            correctAnswer: '6',
            explanation: '3(x-2)+4=16. Expand: 3x-6+4=16. Simplify: 3x-2=16. 3x=18. x=6.',
            options: ['4', '5', '6', '7'],
          ),
        ],
      },
      
      formulas: [
        'Distributive property: a(b + c) = ab + ac',
        'Inverse operations: addition ↔ subtraction, multiplication ↔ division',
      ],
    );
  }

  /// Geometry Template (Basic)
  static AIPromptTemplate _createGeometryTemplate() {
    return AIPromptTemplate(
      skillId: 'geometry',
      skillName: 'Geometry',
      gradeLevel: 'Grades 5-9',
      subject: SubjectType.math,
      
      conceptsToTest: [
        'Perimeter of rectangles and squares',
        'Area of rectangles and squares',
        'Area of triangles',
        'Area of circles',
        'Volume of rectangular prisms',
        'Angles (acute, obtuse, right)',
        'Pythagorean theorem',
        'Properties of shapes',
      ],
      
      questionFormats: [
        'Calculate: "What is the area of a rectangle with length 8 and width 5?"',
        'Find perimeter: "A square has side length 6. What is its perimeter?"',
        'Angles: "Two angles in a triangle are 60° and 70°. What is the third angle?"',
        'Word problems: "A garden is 12m by 8m. What is its area?"',
      ],
      
      difficultyScaling: {
        '1-3': 'Perimeter and area of squares/rectangles, simple shapes',
        '4-6': 'Area of triangles, circles, volume of prisms, angle basics',
        '7-10': 'Pythagorean theorem, complex shapes, multi-step problems',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'What is the perimeter of a square with side length 5?',
            correctAnswer: '20',
            explanation: 'Perimeter = 4 × side = 4 × 5 = 20.',
            options: ['15', '20', '25', '30'],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'What is the area of a triangle with base 10 and height 6?',
            correctAnswer: '30',
            explanation: 'Area = (1/2) × base × height = (1/2) × 10 × 6 = 30.',
            options: ['25', '30', '35', '60'],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'A right triangle has legs of length 3 and 4. What is the hypotenuse?',
            correctAnswer: '5',
            explanation: 'Using Pythagorean theorem: a² + b² = c². 3² + 4² = 9 + 16 = 25. c = √25 = 5.',
            options: ['4', '5', '6', '7'],
          ),
        ],
      },
      
      formulas: [
        'Perimeter of rectangle: P = 2(l + w)',
        'Area of rectangle: A = l × w',
        'Area of triangle: A = (1/2) × base × height',
        'Area of circle: A = πr²',
        'Pythagorean theorem: a² + b² = c²',
      ],
    );
  }
}

