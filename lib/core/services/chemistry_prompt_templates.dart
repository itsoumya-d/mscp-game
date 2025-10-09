import '../models/subject.dart';
import '../models/ai_prompt_template.dart';
import '../services/prompt_template_registry.dart';
// AI prompt templates removed for AI cleanup

/// Chemistry Prompt Templates
/// Enhanced AI Content Generation - Category E Task E1
class ChemistryPromptTemplates {
  /// Register all chemistry templates with the registry
  static void registerAll(PromptTemplateRegistry registry) {
    registry.registerTemplate(_createAtomicStructureTemplate());
    registry.registerTemplate(_createChemicalBondingTemplate());
    registry.registerTemplate(_createChemicalReactionsTemplate());
    registry.registerTemplate(_createStoichiometryTemplate());
    registry.registerTemplate(_createAcidsBasesTemplate());
  }

  /// Atomic Structure Template
  static AIPromptTemplate _createAtomicStructureTemplate() {
    return AIPromptTemplate(
      skillId: 'atomic_structure',
      skillName: 'Atomic Structure and Periodic Table',
      gradeLevel: 'Grades 8-10',
      subject: SubjectType.chemistry,
      
      conceptsToTest: [
        'Protons, neutrons, and electrons',
        'Atomic number and mass number',
        'Isotopes and atomic mass',
        'Electron configuration',
        'Periodic table organization',
        'Groups and periods',
        'Valence electrons',
        'Ion formation',
      ],
      
      questionFormats: [
        'Identify: "What is the atomic number of carbon?"',
        'Calculate: "An atom has 17 protons and 18 neutrons. What is its mass number?"',
        'Conceptual: "Why do elements in the same group have similar properties?"',
        'Application: "How many valence electrons does oxygen have?"',
      ],
      
      difficultyScaling: {
        '1-3': 'Basic atomic structure, simple element identification, proton/electron counting, common elements',
        '4-6': 'Isotopes, mass number calculations, electron configuration basics, periodic trends',
        '7-10': 'Complex electron configurations, ion formation, periodic trends explanation, advanced concepts',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'What is the chemical symbol for oxygen?',
            correctAnswer: 'O',
            explanation: 'Oxygen has the chemical symbol O on the periodic table.',
            options: ['O', 'Ox', 'Og', 'Om'],
          ),
          ExampleQuestion(
            question: 'How many protons does carbon have?',
            correctAnswer: '6',
            explanation: 'Carbon has atomic number 6, which means it has 6 protons.',
            options: ['4', '6', '12', '14'],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'An atom has 11 protons and 12 neutrons. What is its mass number?',
            correctAnswer: '23',
            explanation: 'Mass number = protons + neutrons = 11 + 12 = 23. This is sodium-23.',
            options: ['11', '12', '23', '34'],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'What is the electron configuration of chlorine (atomic number 17)?',
            correctAnswer: '1s² 2s² 2p⁶ 3s² 3p⁵',
            explanation: 'Chlorine has 17 electrons: 2 in 1s, 2 in 2s, 6 in 2p, 2 in 3s, and 5 in 3p.',
            options: ['1s² 2s² 2p⁶ 3s² 3p⁵', '1s² 2s² 2p⁶ 3s² 3p⁶', '1s² 2s² 2p⁶ 3s¹ 3p⁶', '1s² 2s² 2p⁵ 3s² 3p⁶'],
          ),
        ],
      },
      
      formulas: [
        'Mass number = protons + neutrons',
        'Atomic number = number of protons',
        'Neutral atom: protons = electrons',
        'Ion charge = protons - electrons',
      ],
      
      commonMistakes: [
        'Confusing atomic number with mass number',
        'Forgetting that atomic number = protons',
        'Not accounting for neutrons in mass number',
        'Mixing up groups and periods',
        'Incorrect electron configuration order',
      ],
    );
  }

  /// Chemical Bonding Template
  static AIPromptTemplate _createChemicalBondingTemplate() {
    return AIPromptTemplate(
      skillId: 'chemical_bonding',
      skillName: 'Chemical Bonding',
      gradeLevel: 'Grades 9-11',
      subject: SubjectType.chemistry,
      
      conceptsToTest: [
        'Ionic bonding (metal + nonmetal)',
        'Covalent bonding (nonmetal + nonmetal)',
        'Metallic bonding',
        'Lewis dot structures',
        'Electronegativity and polarity',
        'Molecular geometry (VSEPR)',
        'Intermolecular forces',
        'Bond energy and strength',
      ],
      
      questionFormats: [
        'Identify: "What type of bond forms between sodium and chlorine?"',
        'Draw: "Draw the Lewis structure for water (H₂O)"',
        'Predict: "Is the bond between H and Cl polar or nonpolar?"',
        'Compare: "Which has stronger intermolecular forces: H₂O or CH₄?"',
      ],
      
      difficultyScaling: {
        '1-3': 'Basic bond types, simple ionic/covalent identification, common molecules',
        '4-6': 'Lewis structures, polarity, electronegativity differences, molecular shapes',
        '7-10': 'Complex molecules, VSEPR theory, intermolecular forces, bond energy calculations',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'What type of bond forms between sodium (Na) and chlorine (Cl)?',
            correctAnswer: 'Ionic bond',
            explanation: 'Sodium is a metal and chlorine is a nonmetal, so they form an ionic bond.',
            options: ['Ionic bond', 'Covalent bond', 'Metallic bond', 'Hydrogen bond'],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'How many valence electrons does carbon have, and how many bonds can it typically form?',
            correctAnswer: '4 valence electrons, 4 bonds',
            explanation: 'Carbon has 4 valence electrons and typically forms 4 covalent bonds to achieve a stable octet.',
            options: ['2 valence electrons, 2 bonds', '4 valence electrons, 4 bonds', '6 valence electrons, 2 bonds', '8 valence electrons, 0 bonds'],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'What is the molecular geometry of ammonia (NH₃) according to VSEPR theory?',
            correctAnswer: 'Trigonal pyramidal',
            explanation: 'NH₃ has 3 bonding pairs and 1 lone pair on nitrogen, giving it a trigonal pyramidal shape.',
            options: ['Linear', 'Trigonal planar', 'Trigonal pyramidal', 'Tetrahedral'],
          ),
        ],
      },
      
      formulas: [
        'Electronegativity difference > 1.7 → Ionic',
        'Electronegativity difference < 1.7 → Covalent',
        'Octet rule: atoms tend to gain/lose/share electrons to have 8 valence electrons',
      ],
      
      commonMistakes: [
        'Confusing ionic and covalent bonding',
        'Forgetting lone pairs in Lewis structures',
        'Not considering molecular geometry',
        'Mixing up polar and nonpolar molecules',
      ],
    );
  }

  /// Chemical Reactions Template
  static AIPromptTemplate _createChemicalReactionsTemplate() {
    return AIPromptTemplate(
      skillId: 'chemical_reactions',
      skillName: 'Chemical Reactions',
      gradeLevel: 'Grades 9-11',
      subject: SubjectType.chemistry,
      
      conceptsToTest: [
        'Types of reactions (synthesis, decomposition, single/double replacement, combustion)',
        'Balancing chemical equations',
        'Law of conservation of mass',
        'Reactants and products',
        'Coefficients and subscripts',
        'Predicting products',
        'Reaction indicators (color change, gas, precipitate)',
      ],
      
      questionFormats: [
        'Balance: "Balance the equation: H₂ + O₂ → H₂O"',
        'Identify: "What type of reaction is 2H₂O → 2H₂ + O₂?"',
        'Predict: "What are the products when magnesium burns in oxygen?"',
        'Calculate: "If 2 moles of H₂ react with O₂, how many moles of H₂O form?"',
      ],
      
      difficultyScaling: {
        '1-3': 'Simple balancing, reaction type identification, basic concepts, whole number coefficients',
        '4-6': 'Complex balancing, predicting products, two-step problems, common reactions',
        '7-10': 'Multi-step reactions, limiting reactants, percent yield, advanced stoichiometry',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'Balance the equation: H₂ + O₂ → H₂O',
            correctAnswer: '2H₂ + O₂ → 2H₂O',
            explanation: 'We need 2 H₂ molecules and 1 O₂ molecule to make 2 H₂O molecules, balancing both H and O atoms.',
            options: ['H₂ + O₂ → H₂O', '2H₂ + O₂ → 2H₂O', 'H₂ + 2O₂ → H₂O', '2H₂ + 2O₂ → 2H₂O'],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'What type of reaction is: 2H₂O → 2H₂ + O₂?',
            correctAnswer: 'Decomposition',
            explanation: 'This is a decomposition reaction where one compound breaks down into two or more simpler substances.',
            options: ['Synthesis', 'Decomposition', 'Single replacement', 'Combustion'],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'In the reaction 2Al + 3CuSO₄ → Al₂(SO₄)₃ + 3Cu, if 5.4 g of Al reacts completely, how many moles of Cu are produced? (Al = 27 g/mol)',
            correctAnswer: '0.3 moles',
            explanation: 'Moles of Al = 5.4/27 = 0.2 mol. From stoichiometry: 2 mol Al → 3 mol Cu, so 0.2 mol Al → 0.3 mol Cu.',
            options: ['0.2 moles', '0.3 moles', '0.4 moles', '0.6 moles'],
          ),
        ],
      },
      
      formulas: [
        'Moles = mass / molar mass',
        'Mole ratio from balanced equation',
        'Percent yield = (actual / theoretical) × 100%',
      ],
    );
  }

  /// Stoichiometry Template
  static AIPromptTemplate _createStoichiometryTemplate() {
    return AIPromptTemplate(
      skillId: 'stoichiometry',
      skillName: 'Stoichiometry and Mole Calculations',
      gradeLevel: 'Grades 10-12',
      subject: SubjectType.chemistry,
      
      conceptsToTest: [
        'Mole concept (6.02 × 10²³ particles)',
        'Molar mass calculations',
        'Mole-to-mole conversions',
        'Mass-to-mass conversions',
        'Limiting reactants',
        'Percent yield',
        'Empirical and molecular formulas',
      ],
      
      questionFormats: [
        'Calculate: "How many moles are in 36 g of water? (H₂O = 18 g/mol)"',
        'Convert: "How many grams of CO₂ form from 2 moles of C? (C + O₂ → CO₂)"',
        'Limiting: "Which is the limiting reactant: 2 mol H₂ or 1 mol O₂ in 2H₂ + O₂ → 2H₂O?"',
      ],
      
      difficultyScaling: {
        '1-3': 'Simple mole calculations, molar mass, basic conversions, one-step problems',
        '4-6': 'Mole-to-mass conversions, stoichiometry from balanced equations, two-step problems',
        '7-10': 'Limiting reactants, percent yield, empirical formulas, multi-step calculations',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'How many moles are in 44 g of CO₂? (C = 12 g/mol, O = 16 g/mol)',
            correctAnswer: '1 mole',
            explanation: 'Molar mass of CO₂ = 12 + 2(16) = 44 g/mol. Moles = 44 g / 44 g/mol = 1 mole.',
            options: ['0.5 moles', '1 mole', '2 moles', '44 moles'],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'In the reaction N₂ + 3H₂ → 2NH₃, how many moles of NH₃ form from 6 moles of H₂?',
            correctAnswer: '4 moles',
            explanation: 'From stoichiometry: 3 mol H₂ → 2 mol NH₃, so 6 mol H₂ → 4 mol NH₃.',
            options: ['2 moles', '3 moles', '4 moles', '6 moles'],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'If 10 g of H₂ reacts with 80 g of O₂ to form water, what is the limiting reactant? (H₂ = 2 g/mol, O₂ = 32 g/mol, 2H₂ + O₂ → 2H₂O)',
            correctAnswer: 'O₂',
            explanation: 'Moles: H₂ = 10/2 = 5 mol, O₂ = 80/32 = 2.5 mol. Need 5 mol H₂ : 2.5 mol O₂ (2:1 ratio). Have exactly 2:1, but O₂ runs out first making 5 mol H₂O.',
            options: ['H₂', 'O₂', 'Both equal', 'Neither'],
          ),
        ],
      },
      
      formulas: [
        'Moles = mass / molar mass',
        'Avogadro\'s number = 6.02 × 10²³ particles/mol',
        'Percent yield = (actual yield / theoretical yield) × 100%',
      ],
    );
  }

  /// Acids and Bases Template
  static AIPromptTemplate _createAcidsBasesTemplate() {
    return AIPromptTemplate(
      skillId: 'acids_bases',
      skillName: 'Acids, Bases, and pH',
      gradeLevel: 'Grades 10-12',
      subject: SubjectType.chemistry,
      
      conceptsToTest: [
        'Properties of acids and bases',
        'pH scale (0-14)',
        'Strong vs weak acids/bases',
        'Neutralization reactions',
        'Indicators (litmus, phenolphthalein)',
        'Hydronium and hydroxide ions',
        'Buffer solutions',
      ],
      
      questionFormats: [
        'Identify: "Is a solution with pH 3 acidic, basic, or neutral?"',
        'Calculate: "What is the pH of a solution with [H⁺] = 1 × 10⁻⁵ M?"',
        'Predict: "What happens when HCl reacts with NaOH?"',
        'Compare: "Which is stronger: HCl or CH₃COOH?"',
      ],
      
      difficultyScaling: {
        '1-3': 'Basic acid/base properties, pH scale interpretation, simple identification',
        '4-6': 'pH calculations, neutralization reactions, strong vs weak acids',
        '7-10': 'Buffer solutions, Ka/Kb calculations, titration curves, advanced concepts',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'Is a solution with pH 2 acidic, basic, or neutral?',
            correctAnswer: 'Acidic',
            explanation: 'pH < 7 is acidic, pH = 7 is neutral, pH > 7 is basic. pH 2 is acidic.',
            options: ['Acidic', 'Basic', 'Neutral', 'Cannot determine'],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'What is the pH of a solution with [H⁺] = 1 × 10⁻⁴ M?',
            correctAnswer: '4',
            explanation: 'pH = -log[H⁺] = -log(1 × 10⁻⁴) = 4',
            options: ['2', '4', '10', '14'],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'What is the pH of a 0.01 M HCl solution? (HCl is a strong acid)',
            correctAnswer: '2',
            explanation: 'HCl fully dissociates: [H⁺] = 0.01 M = 1 × 10⁻² M. pH = -log(10⁻²) = 2',
            options: ['1', '2', '12', '14'],
          ),
        ],
      },
      
      formulas: [
        'pH = -log[H⁺]',
        '[H⁺][OH⁻] = 1 × 10⁻¹⁴ (at 25°C)',
        'pH + pOH = 14',
        'Neutralization: acid + base → salt + water',
      ],
      
      commonMistakes: [
        'Confusing pH and pOH',
        'Forgetting that lower pH = more acidic',
        'Not recognizing strong vs weak acids',
        'Incorrect log calculations',
      ],
    );
  }
}

