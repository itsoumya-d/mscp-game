import 'package:flutter/foundation.dart';

/// Real-World Applications Service - Task F4
/// Show how concepts apply to real life
/// 
/// Features:
/// - Real-world examples
/// - Career connections
/// - Case studies
/// - Industry applications
/// - Interactive scenarios

class RealWorldApplicationsService {
  static final RealWorldApplicationsService _instance =
      RealWorldApplicationsService._internal();
  factory RealWorldApplicationsService() => _instance;
  RealWorldApplicationsService._internal();

  /// Get real-world applications for a topic
  Future<List<RealWorldApplication>> getApplications({
    required String subject,
    required String topic,
  }) async {
    // In production, fetch from Firestore or manual content database
    return _generateApplications(subject, topic);
  }

  /// Get career connections for a topic
  Future<List<CareerConnection>> getCareerConnections({
    required String subject,
    required String topic,
  }) async {
    // In production, fetch from database
    return _generateCareerConnections(subject, topic);
  }

  /// Get case studies
  Future<List<CaseStudy>> getCaseStudies({
    required String subject,
    required String topic,
  }) async {
    // In production, fetch from database
    return _generateCaseStudies(subject, topic);
  }

  List<RealWorldApplication> _generateApplications(String subject, String topic) {
    // Example applications - in production, these would be from a database
    return [
      RealWorldApplication(
        id: 'app_1',
        title: 'Everyday Shopping',
        description:
            'Use $topic when calculating discounts, comparing prices, and managing budgets at the store.',
        subject: subject,
        topic: topic,
        category: ApplicationCategory.dailyLife,
        examples: [
          'Calculate 20% off sale prices',
          'Compare unit prices of different products',
          'Track spending against budget',
        ],
        imageUrl: 'https://via.placeholder.com/400x300',
        difficulty: ApplicationDifficulty.beginner,
        interactiveScenario: InteractiveScenario(
          title: 'Shopping Challenge',
          description: 'You have \$50. Can you buy all items on your list?',
          steps: [
            'Review your shopping list',
            'Calculate total cost',
            'Apply available discounts',
            'Check if within budget',
          ],
        ),
      ),
      RealWorldApplication(
        id: 'app_2',
        title: 'Technology & Engineering',
        description:
            '$topic is fundamental in designing software, building structures, and creating technology.',
        subject: subject,
        topic: topic,
        category: ApplicationCategory.technology,
        examples: [
          'Computer graphics and game development',
          'GPS navigation systems',
          'Smartphone apps and algorithms',
        ],
        imageUrl: 'https://via.placeholder.com/400x300',
        difficulty: ApplicationDifficulty.advanced,
        interactiveScenario: InteractiveScenario(
          title: 'Build a Simple App',
          description: 'Use $topic to create a calculator app',
          steps: [
            'Design the user interface',
            'Implement calculation logic',
            'Test with different inputs',
            'Optimize performance',
          ],
        ),
      ),
      RealWorldApplication(
        id: 'app_3',
        title: 'Sports & Fitness',
        description:
            'Athletes and coaches use $topic to analyze performance and improve training.',
        subject: subject,
        topic: topic,
        category: ApplicationCategory.sports,
        examples: [
          'Calculate running pace and distance',
          'Track workout progress over time',
          'Analyze game statistics',
        ],
        imageUrl: 'https://via.placeholder.com/400x300',
        difficulty: ApplicationDifficulty.intermediate,
        interactiveScenario: InteractiveScenario(
          title: 'Training Plan',
          description: 'Create a personalized workout schedule',
          steps: [
            'Set fitness goals',
            'Calculate target heart rate',
            'Plan weekly workouts',
            'Track progress',
          ],
        ),
      ),
    ];
  }

  List<CareerConnection> _generateCareerConnections(String subject, String topic) {
    return [
      CareerConnection(
        id: 'career_1',
        careerTitle: 'Software Engineer',
        description:
            'Software engineers use $topic daily to write code, solve problems, and build applications.',
        subject: subject,
        topic: topic,
        howItsUsed:
            'Used in algorithms, data structures, optimization, and system design.',
        salaryRange: '\$80,000 - \$150,000',
        education: 'Bachelor\'s degree in Computer Science or related field',
        skills: [
          'Programming',
          'Problem solving',
          'Logical thinking',
          'Mathematics',
        ],
        dayInLife: [
          'Write and review code',
          'Debug and fix issues',
          'Design new features',
          'Collaborate with team',
        ],
        imageUrl: 'https://via.placeholder.com/400x300',
      ),
      CareerConnection(
        id: 'career_2',
        careerTitle: 'Data Scientist',
        description:
            'Data scientists analyze data and build models using $topic and statistics.',
        subject: subject,
        topic: topic,
        howItsUsed:
            'Essential for statistical analysis, machine learning, and data visualization.',
        salaryRange: '\$90,000 - \$160,000',
        education: 'Bachelor\'s or Master\'s degree in Data Science, Statistics, or related field',
        skills: [
          'Statistics',
          'Programming (Python, R)',
          'Machine Learning',
          'Data Visualization',
        ],
        dayInLife: [
          'Analyze datasets',
          'Build predictive models',
          'Create visualizations',
          'Present findings',
        ],
        imageUrl: 'https://via.placeholder.com/400x300',
      ),
      CareerConnection(
        id: 'career_3',
        careerTitle: 'Financial Analyst',
        description:
            'Financial analysts use $topic to evaluate investments and forecast trends.',
        subject: subject,
        topic: topic,
        howItsUsed:
            'Critical for financial modeling, risk assessment, and investment analysis.',
        salaryRange: '\$60,000 - \$120,000',
        education: 'Bachelor\'s degree in Finance, Economics, or related field',
        skills: [
          'Financial modeling',
          'Excel proficiency',
          'Analytical thinking',
          'Communication',
        ],
        dayInLife: [
          'Analyze financial data',
          'Create reports',
          'Make recommendations',
          'Monitor markets',
        ],
        imageUrl: 'https://via.placeholder.com/400x300',
      ),
    ];
  }

  List<CaseStudy> _generateCaseStudies(String subject, String topic) {
    return [
      CaseStudy(
        id: 'case_1',
        title: 'How NASA Uses $topic',
        description:
            'Learn how NASA engineers apply $topic to space exploration and rocket science.',
        subject: subject,
        topic: topic,
        organization: 'NASA',
        challenge:
            'Calculate precise trajectories for spacecraft to reach distant planets.',
        solution:
            'Engineers use $topic to model orbital mechanics and plan mission paths.',
        outcome:
            'Successful missions to Mars, Jupiter, and beyond, with pinpoint accuracy.',
        lessonsLearned: [
          'Precision is critical in space exploration',
          'Complex problems require advanced mathematics',
          'Teamwork and collaboration are essential',
        ],
        imageUrl: 'https://via.placeholder.com/400x300',
        videoUrl: 'https://www.youtube.com/watch?v=example',
      ),
      CaseStudy(
        id: 'case_2',
        title: 'Medical Breakthrough',
        description:
            'How doctors use $topic to save lives and improve healthcare.',
        subject: subject,
        topic: topic,
        organization: 'Johns Hopkins Hospital',
        challenge:
            'Determine optimal drug dosages for patients with varying conditions.',
        solution:
            'Medical professionals apply $topic to calculate safe and effective doses.',
        outcome:
            'Improved patient outcomes and reduced medication errors by 40%.',
        lessonsLearned: [
          'Mathematics saves lives',
          'Precision matters in medicine',
          'Continuous learning is essential',
        ],
        imageUrl: 'https://via.placeholder.com/400x300',
        videoUrl: null,
      ),
    ];
  }
}

/// Real-world application model
class RealWorldApplication {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String topic;
  final ApplicationCategory category;
  final List<String> examples;
  final String imageUrl;
  final ApplicationDifficulty difficulty;
  final InteractiveScenario? interactiveScenario;

  RealWorldApplication({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.topic,
    required this.category,
    required this.examples,
    required this.imageUrl,
    required this.difficulty,
    this.interactiveScenario,
  });

  // Convenience getters
  String get example => examples.isNotEmpty ? examples.first : '';
  String? get videoUrl => null;
}

/// Career connection model
class CareerConnection {
  final String id;
  final String careerTitle;
  final String description;
  final String subject;
  final String topic;
  final String howItsUsed;
  final String salaryRange;
  final String education;
  final List<String> skills;
  final List<String> dayInLife;
  final String imageUrl;

  CareerConnection({
    required this.id,
    required this.careerTitle,
    required this.description,
    required this.subject,
    required this.topic,
    required this.howItsUsed,
    required this.salaryRange,
    required this.education,
    required this.skills,
    required this.dayInLife,
    required this.imageUrl,
  });

  // Convenience getters
  String get averageSalary => salaryRange;
  String get educationRequired => education;
  List<String> get skillsUsed => skills;
}

/// Case study model
class CaseStudy {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String topic;
  final String organization;
  final String challenge;
  final String solution;
  final String outcome;
  final List<String> lessonsLearned;
  final String imageUrl;
  final String? videoUrl;

  CaseStudy({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.topic,
    required this.organization,
    required this.challenge,
    required this.solution,
    required this.outcome,
    required this.lessonsLearned,
    required this.imageUrl,
    this.videoUrl,
  });
}

/// Interactive scenario model
class InteractiveScenario {
  final String title;
  final String description;
  final List<String> steps;

  InteractiveScenario({
    required this.title,
    required this.description,
    required this.steps,
  });
}

enum ApplicationCategory {
  dailyLife,
  technology,
  science,
  sports,
  business,
  arts,
  health,
}

enum ApplicationDifficulty {
  beginner,
  intermediate,
  advanced,
}

extension RealWorldApplicationsServiceExtension on RealWorldApplicationsService {
  /// Get applications by topic
  Future<List<RealWorldApplication>> getApplicationsByTopic(String topic) async {
    return await getApplications(subject: 'Math', topic: topic);
  }

  /// Get career connections without parameters
  Future<List<CareerConnection>> getCareerConnectionsForScreen() async {
    return await getCareerConnections(subject: 'Math', topic: 'Algebra');
  }
}

