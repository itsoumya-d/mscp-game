import '../models/subject.dart';
import '../models/ai_prompt_template.dart';
import '../services/prompt_template_registry.dart';
// AI prompt templates removed for AI cleanup

/// Biology Prompt Templates
/// Enhanced AI Content Generation - Category E Task E1
class BiologyPromptTemplates {
  /// Register all biology templates with the registry
  static void registerAll(PromptTemplateRegistry registry) {
    registry.registerTemplate(_createCellBiologyTemplate());
    registry.registerTemplate(_createGeneticsTemplate());
    registry.registerTemplate(_createEvolutionTemplate());
    registry.registerTemplate(_createEcologyTemplate());
    registry.registerTemplate(_createHumanBodyTemplate());
  }

  /// Cell Biology Template
  static AIPromptTemplate _createCellBiologyTemplate() {
    return AIPromptTemplate(
      skillId: 'cell_biology',
      skillName: 'Cell Structure and Function',
      gradeLevel: 'Grades 7-10',
      subject: SubjectType.biology,
      
      conceptsToTest: [
        'Cell theory',
        'Prokaryotic vs eukaryotic cells',
        'Cell organelles and their functions',
        'Cell membrane structure and transport',
        'Mitochondria and cellular respiration',
        'Chloroplasts and photosynthesis',
        'Nucleus and genetic material',
        'Cell division (mitosis and meiosis)',
      ],
      
      questionFormats: [
        'Identify: "What is the powerhouse of the cell?"',
        'Function: "What is the main function of the cell membrane?"',
        'Compare: "What is the difference between plant and animal cells?"',
        'Process: "What happens during mitosis?"',
      ],
      
      difficultyScaling: {
        '1-3': 'Basic organelles, simple functions, cell types, common structures',
        '4-6': 'Organelle interactions, transport mechanisms, cell processes, comparisons',
        '7-10': 'Complex processes, cell division details, molecular mechanisms, advanced concepts',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'What is the powerhouse of the cell?',
            correctAnswer: 'Mitochondria',
            explanation: 'Mitochondria produce ATP (energy) for the cell through cellular respiration.',
            options: ['Mitochondria', 'Nucleus', 'Ribosome', 'Chloroplast'],
          ),
          ExampleQuestion(
            question: 'Which organelle controls what enters and leaves the cell?',
            correctAnswer: 'Cell membrane',
            explanation: 'The cell membrane is selectively permeable and controls the movement of substances in and out of the cell.',
            options: ['Cell wall', 'Cell membrane', 'Nucleus', 'Cytoplasm'],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'What is the main difference between prokaryotic and eukaryotic cells?',
            correctAnswer: 'Eukaryotic cells have a nucleus; prokaryotic cells do not',
            explanation: 'The key difference is that eukaryotic cells have a membrane-bound nucleus, while prokaryotic cells lack a nucleus.',
            options: ['Eukaryotic cells are smaller', 'Prokaryotic cells have more organelles', 'Eukaryotic cells have a nucleus; prokaryotic cells do not', 'Prokaryotic cells have a cell wall'],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'During which phase of mitosis do chromosomes line up at the cell\'s equator?',
            correctAnswer: 'Metaphase',
            explanation: 'In metaphase, chromosomes align at the metaphase plate (cell\'s equator) before being separated.',
            options: ['Prophase', 'Metaphase', 'Anaphase', 'Telophase'],
          ),
        ],
      },
      
      formulas: [
        'Photosynthesis: 6CO₂ + 6H₂O + light → C₆H₁₂O₆ + 6O₂',
        'Cellular respiration: C₆H₁₂O₆ + 6O₂ → 6CO₂ + 6H₂O + ATP',
      ],
      
      commonMistakes: [
        'Confusing mitochondria with chloroplasts',
        'Mixing up prokaryotic and eukaryotic features',
        'Not distinguishing between plant and animal cells',
        'Confusing mitosis and meiosis',
      ],
      
      additionalContext: '''
Focus on structure-function relationships. Explain WHY organelles have specific features.
Use analogies (e.g., "mitochondria are like power plants") but also provide scientific explanations.
''',
    );
  }

  /// Genetics Template
  static AIPromptTemplate _createGeneticsTemplate() {
    return AIPromptTemplate(
      skillId: 'genetics',
      skillName: 'Genetics and Heredity',
      gradeLevel: 'Grades 8-12',
      subject: SubjectType.biology,
      
      conceptsToTest: [
        'DNA structure (double helix, base pairing)',
        'Genes and alleles',
        'Dominant and recessive traits',
        'Punnett squares',
        'Genotype vs phenotype',
        'Mendelian inheritance',
        'Sex-linked traits',
        'Mutations and genetic variation',
      ],
      
      questionFormats: [
        'Identify: "What are the four bases in DNA?"',
        'Calculate: "In a cross between Tt × Tt, what percentage of offspring will be tall (T is dominant)?"',
        'Predict: "If both parents have brown eyes (Bb), what is the probability their child has blue eyes (bb)?"',
        'Explain: "Why are some traits sex-linked?"',
      ],
      
      difficultyScaling: {
        '1-3': 'Basic DNA structure, simple dominant/recessive, basic Punnett squares (monohybrid)',
        '4-6': 'Genotype/phenotype predictions, probability calculations, incomplete dominance',
        '7-10': 'Dihybrid crosses, sex-linked traits, pedigree analysis, complex inheritance patterns',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'What are the four nitrogen bases in DNA?',
            correctAnswer: 'Adenine, Thymine, Guanine, Cytosine',
            explanation: 'DNA contains four bases: Adenine (A), Thymine (T), Guanine (G), and Cytosine (C).',
            options: ['A, T, G, C', 'A, U, G, C', 'A, T, G, U', 'A, B, C, D'],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'In pea plants, tall (T) is dominant over short (t). What percentage of offspring from Tt × Tt will be tall?',
            correctAnswer: '75%',
            explanation: 'Punnett square: TT (25%), Tt (50%), tt (25%). TT and Tt are tall = 75%.',
            options: ['25%', '50%', '75%', '100%'],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'A woman with normal vision (XᴺXⁿ) marries a colorblind man (XⁿY). What percentage of their sons will be colorblind?',
            correctAnswer: '50%',
            explanation: 'Sons get Y from father and either Xᴺ or Xⁿ from mother. 50% get Xⁿ and are colorblind.',
            options: ['0%', '25%', '50%', '100%'],
          ),
        ],
      },
      
      formulas: [
        'Base pairing: A-T, G-C',
        'Probability = (number of desired outcomes) / (total outcomes)',
        'Monohybrid cross ratios: 3:1 (phenotype), 1:2:1 (genotype)',
      ],
      
      commonMistakes: [
        'Confusing genotype and phenotype',
        'Incorrect Punnett square setup',
        'Not understanding dominant vs recessive',
        'Forgetting sex-linked inheritance patterns',
      ],
    );
  }

  /// Evolution Template
  static AIPromptTemplate _createEvolutionTemplate() {
    return AIPromptTemplate(
      skillId: 'evolution',
      skillName: 'Evolution and Natural Selection',
      gradeLevel: 'Grades 9-12',
      subject: SubjectType.biology,
      
      conceptsToTest: [
        'Natural selection',
        'Adaptation and fitness',
        'Evidence for evolution (fossils, anatomy, DNA)',
        'Darwin\'s theory',
        'Speciation',
        'Genetic drift and gene flow',
        'Coevolution',
        'Convergent and divergent evolution',
      ],
      
      questionFormats: [
        'Explain: "What is natural selection?"',
        'Example: "How did giraffes evolve long necks?"',
        'Evidence: "What evidence supports evolution?"',
        'Compare: "What is the difference between convergent and divergent evolution?"',
      ],
      
      difficultyScaling: {
        '1-3': 'Basic natural selection, simple adaptations, Darwin\'s observations',
        '4-6': 'Mechanisms of evolution, evidence types, fitness and survival',
        '7-10': 'Speciation, genetic drift, coevolution, complex evolutionary patterns',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'What is natural selection?',
            correctAnswer: 'The process where organisms better adapted to their environment survive and reproduce',
            explanation: 'Natural selection is the mechanism of evolution where individuals with advantageous traits are more likely to survive and pass on their genes.',
            options: [
              'The process where organisms better adapted to their environment survive and reproduce',
              'The process where all organisms evolve at the same rate',
              'The process where humans select traits in organisms',
              'The process where organisms choose their traits'
            ],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'Which of the following is evidence for evolution?',
            correctAnswer: 'All of the above',
            explanation: 'Fossil records, comparative anatomy, DNA similarities, and embryology all provide evidence for evolution.',
            options: ['Fossil records', 'DNA similarities', 'Homologous structures', 'All of the above'],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'What is the difference between convergent and divergent evolution?',
            correctAnswer: 'Convergent: different species develop similar traits; Divergent: related species develop different traits',
            explanation: 'Convergent evolution occurs when unrelated species develop similar traits (e.g., wings in birds and bats). Divergent evolution occurs when related species develop different traits due to different environments.',
            options: [
              'Convergent: species merge; Divergent: species split',
              'Convergent: different species develop similar traits; Divergent: related species develop different traits',
              'Convergent: fast evolution; Divergent: slow evolution',
              'Convergent: genetic; Divergent: environmental'
            ],
          ),
        ],
      },
      
      commonMistakes: [
        'Thinking evolution is goal-directed',
        'Confusing natural selection with Lamarckism',
        'Not understanding that evolution occurs in populations, not individuals',
        'Mixing up convergent and divergent evolution',
      ],
    );
  }

  /// Ecology Template
  static AIPromptTemplate _createEcologyTemplate() {
    return AIPromptTemplate(
      skillId: 'ecology',
      skillName: 'Ecology and Ecosystems',
      gradeLevel: 'Grades 7-10',
      subject: SubjectType.biology,
      
      conceptsToTest: [
        'Food chains and food webs',
        'Energy flow in ecosystems',
        'Trophic levels',
        'Producers, consumers, decomposers',
        'Symbiotic relationships (mutualism, commensalism, parasitism)',
        'Population dynamics',
        'Biomes and habitats',
        'Carbon and nitrogen cycles',
      ],
      
      questionFormats: [
        'Identify: "What is a producer in an ecosystem?"',
        'Analyze: "In a food chain, where does energy come from?"',
        'Calculate: "If 10,000 J of energy is available at the producer level, how much reaches the tertiary consumer?"',
        'Classify: "What type of relationship is between bees and flowers?"',
      ],
      
      difficultyScaling: {
        '1-3': 'Basic food chains, producer/consumer identification, simple relationships',
        '4-6': 'Food webs, energy transfer, symbiotic relationships, population concepts',
        '7-10': 'Biogeochemical cycles, energy pyramids, complex interactions, ecosystem dynamics',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'What is a producer in an ecosystem?',
            correctAnswer: 'An organism that makes its own food through photosynthesis',
            explanation: 'Producers (like plants) make their own food using sunlight through photosynthesis.',
            options: [
              'An organism that makes its own food through photosynthesis',
              'An organism that eats other organisms',
              'An organism that breaks down dead matter',
              'An organism that lives in water'
            ],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'What type of symbiotic relationship exists between a bee and a flower?',
            correctAnswer: 'Mutualism',
            explanation: 'Bees get nectar from flowers, and flowers get pollinated by bees. Both benefit, which is mutualism.',
            options: ['Mutualism', 'Commensalism', 'Parasitism', 'Competition'],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'If 10,000 J of energy is available at the producer level, approximately how much energy reaches the secondary consumer level? (Use 10% energy transfer rule)',
            correctAnswer: '100 J',
            explanation: 'Energy transfer: Producers (10,000 J) → Primary consumers (1,000 J) → Secondary consumers (100 J). Each level transfers ~10%.',
            options: ['10 J', '100 J', '1,000 J', '5,000 J'],
          ),
        ],
      },
      
      formulas: [
        'Energy transfer: ~10% passes to next trophic level',
        'Population growth: dN/dt = rN (exponential)',
        'Carrying capacity: K (maximum population size)',
      ],
      
      commonMistakes: [
        'Confusing food chains and food webs',
        'Not understanding energy loss between trophic levels',
        'Mixing up symbiotic relationship types',
        'Thinking energy cycles (it flows one-way)',
      ],
    );
  }

  /// Human Body Systems Template
  static AIPromptTemplate _createHumanBodyTemplate() {
    return AIPromptTemplate(
      skillId: 'human_body',
      skillName: 'Human Body Systems',
      gradeLevel: 'Grades 6-9',
      subject: SubjectType.biology,
      
      conceptsToTest: [
        'Circulatory system (heart, blood vessels, blood)',
        'Respiratory system (lungs, gas exchange)',
        'Digestive system (organs, nutrient absorption)',
        'Nervous system (brain, neurons, reflexes)',
        'Skeletal system (bones, joints)',
        'Muscular system (muscle types, movement)',
        'Immune system (white blood cells, antibodies)',
        'Homeostasis',
      ],
      
      questionFormats: [
        'Identify: "What is the main function of the heart?"',
        'Explain: "How does the respiratory system work?"',
        'Sequence: "What is the path of food through the digestive system?"',
        'Function: "What do white blood cells do?"',
      ],
      
      difficultyScaling: {
        '1-3': 'Basic organ identification, simple functions, major systems',
        '4-6': 'System interactions, processes, organ functions, homeostasis basics',
        '7-10': 'Detailed mechanisms, system integration, disease and disorders, advanced physiology',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'What is the main function of the heart?',
            correctAnswer: 'To pump blood throughout the body',
            explanation: 'The heart is a muscular organ that pumps blood to deliver oxygen and nutrients to all body cells.',
            options: [
              'To pump blood throughout the body',
              'To filter waste from blood',
              'To produce red blood cells',
              'To digest food'
            ],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'What is the correct order of food passing through the digestive system?',
            correctAnswer: 'Mouth → Esophagus → Stomach → Small intestine → Large intestine',
            explanation: 'Food travels from mouth to esophagus, then stomach for digestion, small intestine for nutrient absorption, and large intestine for water absorption.',
            options: [
              'Mouth → Stomach → Esophagus → Small intestine → Large intestine',
              'Mouth → Esophagus → Stomach → Small intestine → Large intestine',
              'Mouth → Esophagus → Small intestine → Stomach → Large intestine',
              'Mouth → Stomach → Small intestine → Esophagus → Large intestine'
            ],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'What is homeostasis?',
            correctAnswer: 'The maintenance of stable internal conditions in the body',
            explanation: 'Homeostasis is the process by which the body maintains stable internal conditions (temperature, pH, glucose levels) despite external changes.',
            options: [
              'The process of cell division',
              'The maintenance of stable internal conditions in the body',
              'The breakdown of food for energy',
              'The transport of oxygen in blood'
            ],
          ),
        ],
      },
      
      commonMistakes: [
        'Confusing arteries and veins',
        'Not understanding gas exchange in lungs',
        'Mixing up organ functions',
        'Forgetting system interactions',
      ],
    );
  }
}

