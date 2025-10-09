import '../models/subject.dart';

/// Central registry for skill IDs across the application
/// Ensures consistency between frontend UI and backend content generation
class SkillIdRegistry {
  /// Skill IDs for each subject (matches frontend Subject definitions)
  static const Map<SubjectType, List<String>> skillIds = {
    SubjectType.math: [
      'addition',        // Addition & Subtraction
      'multiplication',  // Multiplication & Division
      'fractions',       // Fractions & Decimals
      'variables',       // Variables & Expressions (Algebra)
      'geometry',        // Geometry
      'measurement',     // Measurement
    ],
    SubjectType.physics: [
      'mechanics',       // Mechanics
      'energy',          // Energy
      'electricity',     // Electricity
      'waves',           // Waves
      'thermodynamics',  // Thermodynamics
    ],
    SubjectType.chemistry: [
      'atoms',           // Atomic Structure
      'bonding',         // Chemical Bonding
      'reactions',       // Chemical Reactions
      'stoichiometry',   // Stoichiometry
      'acids_bases',     // Acids & Bases
    ],
    SubjectType.biology: [
      'cells',           // Cell Biology
      'genetics',        // Genetics
      'evolution',       // Evolution
      'ecology',         // Ecology
      'human_body',      // Human Body
    ],
    SubjectType.computerScience: [
      'variables',       // Variables
      'loops',           // Loops
      'functions',       // Functions
      'algorithms',      // Algorithms
      'data_structures', // Data Structures
    ],
    SubjectType.geography: [
      'landforms',       // Landforms
      'climate',         // Climate
      'ecosystems',      // Ecosystems
      'countries',       // Countries
      'maps',            // Maps
    ],
    SubjectType.history: [
      'ancient',         // Ancient History
      'medieval',        // Medieval History
      'modern',          // Modern History
      'world_wars',      // World Wars
      'civilizations',   // Civilizations
    ],
    SubjectType.science: [
      'scientific_method',
      'experiments',
      'observations',
      'hypotheses',
      'theory',
    ],
    SubjectType.english: [
      'grammar',
      'vocabulary',
      'reading',
      'writing',
      'literature',
    ],
    SubjectType.art: [
      'drawing',
      'painting',
      'sculpture',
      'art_history',
      'color_theory',
    ],
    SubjectType.music: [
      'rhythm',
      'melody',
      'harmony',
      'instruments',
      'music_theory',
    ],
    SubjectType.physicalEducation: [
      'fitness',
      'sports',
      'health',
      'nutrition',
      'exercise',
    ],
  };

  /// Human-readable skill names for each skill ID
  static const Map<String, String> skillNames = {
    // Math
    'addition': 'Addition & Subtraction',
    'multiplication': 'Multiplication & Division',
    'fractions': 'Fractions & Decimals',
    'variables': 'Variables & Expressions',
    'geometry': 'Geometry',
    'measurement': 'Measurement',
    
    // Physics
    'mechanics': 'Mechanics',
    'energy': 'Energy',
    'electricity': 'Electricity',
    'waves': 'Waves',
    'thermodynamics': 'Thermodynamics',
    
    // Chemistry
    'atoms': 'Atomic Structure',
    'bonding': 'Chemical Bonding',
    'reactions': 'Chemical Reactions',
    'stoichiometry': 'Stoichiometry',
    'acids_bases': 'Acids & Bases',
    
    // Biology
    'cells': 'Cell Biology',
    'genetics': 'Genetics',
    'evolution': 'Evolution',
    'ecology': 'Ecology',
    'human_body': 'Human Body',
    
    // Computer Science
    'loops': 'Loops',
    'functions': 'Functions',
    'algorithms': 'Algorithms',
    'data_structures': 'Data Structures',
    
    // Geography
    'landforms': 'Landforms',
    'climate': 'Climate',
    'ecosystems': 'Ecosystems',
    'countries': 'Countries',
    'maps': 'Maps',
    
    // History
    'ancient': 'Ancient History',
    'medieval': 'Medieval History',
    'modern': 'Modern History',
    'world_wars': 'World Wars',
    'civilizations': 'Civilizations',
    
    // Science
    'scientific_method': 'Scientific Method',
    'experiments': 'Experiments',
    'observations': 'Observations',
    'hypotheses': 'Hypotheses',
    'theory': 'Theory',
    
    // English
    'grammar': 'Grammar',
    'vocabulary': 'Vocabulary',
    'reading': 'Reading',
    'writing': 'Writing',
    'literature': 'Literature',
    
    // Art
    'drawing': 'Drawing',
    'painting': 'Painting',
    'sculpture': 'Sculpture',
    'art_history': 'Art History',
    'color_theory': 'Color Theory',
    
    // Music
    'rhythm': 'Rhythm',
    'melody': 'Melody',
    'harmony': 'Harmony',
    'instruments': 'Instruments',
    'music_theory': 'Music Theory',
    
    // Physical Education
    'fitness': 'Fitness',
    'sports': 'Sports',
    'health': 'Health',
    'nutrition': 'Nutrition',
    'exercise': 'Exercise',
  };

  /// Get human-readable skill name for a skill ID
  static String getSkillName(String skillId) {
    return skillNames[skillId] ?? skillId;
  }

  /// Get all skill IDs for a subject
  static List<String> getSkillIdsForSubject(SubjectType subject) {
    return skillIds[subject] ?? ['general'];
  }

  /// Get default skill ID for a subject (first skill in the list)
  static String getDefaultSkillId(SubjectType subject) {
    final skills = skillIds[subject];
    return skills != null && skills.isNotEmpty ? skills.first : 'general';
  }

  /// Check if a skill ID is valid for a subject
  static bool isValidSkillId(SubjectType subject, String skillId) {
    return skillIds[subject]?.contains(skillId) ?? false;
  }

  /// Get skill-specific topic description for AI prompts
  static String getSkillTopic(SubjectType subject, String skillId) {
    final skillName = getSkillName(skillId);
    
    // Return skill-specific topic descriptions
    switch (skillId) {
      // Math
      case 'addition':
        return 'Addition and Subtraction operations with whole numbers';
      case 'multiplication':
        return 'Multiplication and Division operations with whole numbers';
      case 'fractions':
        return 'Fractions, Decimals, and Percentages';
      case 'variables':
        return 'Algebraic Variables and Expressions';
      case 'geometry':
        return 'Geometric Shapes, Angles, and Measurements';
      case 'measurement':
        return 'Units of Measurement and Conversions';
      
      // Physics
      case 'mechanics':
        return 'Motion, Forces, and Newton\'s Laws';
      case 'energy':
        return 'Energy, Work, and Power';
      case 'electricity':
        return 'Electric Circuits and Current';
      case 'waves':
        return 'Wave Properties and Sound';
      case 'thermodynamics':
        return 'Heat, Temperature, and Thermal Energy';
      
      // Chemistry
      case 'atoms':
        return 'Atomic Structure and Elements';
      case 'bonding':
        return 'Chemical Bonds and Molecules';
      case 'reactions':
        return 'Chemical Reactions and Equations';
      case 'stoichiometry':
        return 'Stoichiometry and Mole Calculations';
      case 'acids_bases':
        return 'Acids, Bases, and pH';
      
      // Biology
      case 'cells':
        return 'Cell Structure and Function';
      case 'genetics':
        return 'Genetics and Heredity';
      case 'evolution':
        return 'Evolution and Natural Selection';
      case 'ecology':
        return 'Ecosystems and Food Chains';
      case 'human_body':
        return 'Human Body Systems';
      
      // Default
      default:
        return skillName;
    }
  }

  /// Get difficulty-appropriate topic for a skill and level
  static String getTopicForSkillAndLevel(SubjectType subject, String skillId, int level) {
    final baseTopic = getSkillTopic(subject, skillId);
    
    if (level <= 3) {
      return 'Basic $baseTopic';
    } else if (level <= 6) {
      return 'Intermediate $baseTopic';
    } else {
      return 'Advanced $baseTopic';
    }
  }
}

