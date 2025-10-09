import '../models/subject.dart';
import '../models/ai_prompt_template.dart';
import '../services/prompt_template_registry.dart';
// AI prompt templates removed for AI cleanup

/// Physics Prompt Templates
/// Enhanced AI Content Generation - Category E Task E1
class PhysicsPromptTemplates {
  /// Register all physics templates with the registry
  static void registerAll(PromptTemplateRegistry registry) {
    registry.registerTemplate(_createMechanicsTemplate());
    registry.registerTemplate(_createEnergyTemplate());
    registry.registerTemplate(_createElectricityTemplate());
    registry.registerTemplate(_createWavesTemplate());
    registry.registerTemplate(_createThermodynamicsTemplate());
  }

  /// Mechanics Template (Forces, Motion, Newton's Laws)
  static AIPromptTemplate _createMechanicsTemplate() {
    return AIPromptTemplate(
      skillId: 'mechanics',
      skillName: 'Mechanics - Forces and Motion',
      gradeLevel: 'Grades 8-12',
      subject: SubjectType.physics,
      
      conceptsToTest: [
        'Newton\'s First Law (Inertia)',
        'Newton\'s Second Law (F = ma)',
        'Newton\'s Third Law (Action-Reaction)',
        'Velocity and acceleration',
        'Displacement, distance, and speed',
        'Free fall and gravity',
        'Friction and normal force',
        'Momentum and impulse',
      ],
      
      questionFormats: [
        'Calculate: "A 5 kg object accelerates at 2 m/s². What is the net force?"',
        'Conceptual: "A car moving at constant velocity has what net force?"',
        'Word problems: "A 1000 kg car accelerates from 0 to 20 m/s in 5 seconds. Find the force."',
        'Application: "Why do passengers lurch forward when a bus stops suddenly?"',
      ],
      
      difficultyScaling: {
        '1-3': 'Basic concepts, simple calculations with F=ma, one-step problems, whole numbers, conceptual understanding',
        '4-6': 'Two-step problems, multiple forces, friction included, decimal numbers, real-world scenarios',
        '7-10': 'Complex multi-step problems, vector components, inclined planes, momentum conservation, advanced applications',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'What is the SI unit of force?',
            correctAnswer: 'Newton (N)',
            explanation: 'The Newton is the SI unit of force, named after Isaac Newton.',
            options: ['Newton (N)', 'Joule (J)', 'Watt (W)', 'Pascal (Pa)'],
          ),
          ExampleQuestion(
            question: 'If a 10 kg object accelerates at 2 m/s², what is the net force?',
            correctAnswer: '20 N',
            explanation: 'Using F = ma: F = 10 kg × 2 m/s² = 20 N',
            options: ['5 N', '12 N', '20 N', '200 N'],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'A 50 kg person stands on a scale in an elevator accelerating upward at 2 m/s². What does the scale read? (g = 10 m/s²)',
            correctAnswer: '600 N',
            explanation: 'Normal force N = m(g + a) = 50(10 + 2) = 600 N',
            options: ['500 N', '550 N', '600 N', '700 N'],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'A 2 kg block slides down a 30° incline with coefficient of friction 0.2. What is its acceleration? (g = 10 m/s²)',
            correctAnswer: '3.27 m/s²',
            explanation: 'a = g(sin θ - μ cos θ) = 10(sin 30° - 0.2 cos 30°) = 10(0.5 - 0.173) = 3.27 m/s²',
            options: ['2.5 m/s²', '3.27 m/s²', '4.0 m/s²', '5.0 m/s²'],
          ),
        ],
      },
      
      formulas: [
        'F = ma (Newton\'s Second Law)',
        'v = u + at (velocity with constant acceleration)',
        's = ut + ½at² (displacement with constant acceleration)',
        'v² = u² + 2as (velocity-displacement relation)',
        'p = mv (momentum)',
        'F = Δp/Δt (impulse-momentum theorem)',
        'f = μN (friction force)',
      ],
      
      commonMistakes: [
        'Confusing mass (kg) with weight (N)',
        'Forgetting to convert units (g to kg, cm to m)',
        'Not considering all forces acting on an object',
        'Mixing up velocity and acceleration',
        'Ignoring friction when it\'s present',
      ],
      
      additionalContext: '''
Physics questions should use realistic values and scenarios. Always specify units clearly.
For calculations, show the formula first, then substitute values.
Ensure distractors are plausible (e.g., common calculation errors, unit mistakes).
''',
    );
  }

  /// Energy Template (Kinetic, Potential, Conservation)
  static AIPromptTemplate _createEnergyTemplate() {
    return AIPromptTemplate(
      skillId: 'energy',
      skillName: 'Energy and Work',
      gradeLevel: 'Grades 9-12',
      subject: SubjectType.physics,
      
      conceptsToTest: [
        'Kinetic energy (KE = ½mv²)',
        'Gravitational potential energy (PE = mgh)',
        'Work done by a force (W = Fd cos θ)',
        'Power (P = W/t)',
        'Conservation of mechanical energy',
        'Work-energy theorem',
        'Elastic potential energy',
        'Energy transformations',
      ],
      
      questionFormats: [
        'Calculate: "A 2 kg ball moving at 5 m/s has what kinetic energy?"',
        'Energy conversion: "A 1 kg ball falls from 10 m. What is its speed at ground level?"',
        'Work: "How much work is done lifting a 50 kg object 2 m high?"',
        'Power: "A motor does 1000 J of work in 5 seconds. What is its power?"',
      ],
      
      difficultyScaling: {
        '1-3': 'Simple KE and PE calculations, one-step problems, whole numbers, basic energy concepts',
        '4-6': 'Energy conservation, work calculations, two-step problems, power calculations',
        '7-10': 'Complex energy transformations, efficiency, non-conservative forces, multi-step problems',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'What is the kinetic energy of a 4 kg object moving at 3 m/s?',
            correctAnswer: '18 J',
            explanation: 'KE = ½mv² = ½(4)(3²) = ½(4)(9) = 18 J',
            options: ['12 J', '18 J', '24 J', '36 J'],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'A 2 kg ball is dropped from a height of 5 m. What is its speed just before hitting the ground? (g = 10 m/s²)',
            correctAnswer: '10 m/s',
            explanation: 'Using energy conservation: mgh = ½mv², so v = √(2gh) = √(2×10×5) = 10 m/s',
            options: ['5 m/s', '7.07 m/s', '10 m/s', '14.14 m/s'],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'A 1500 kg car traveling at 20 m/s brakes to a stop over 50 m. What is the average braking force?',
            correctAnswer: '6000 N',
            explanation: 'Using work-energy: W = ΔKE, so F×d = ½mv². F = mv²/(2d) = 1500(20²)/(2×50) = 6000 N',
            options: ['3000 N', '4500 N', '6000 N', '12000 N'],
          ),
        ],
      },
      
      formulas: [
        'KE = ½mv² (kinetic energy)',
        'PE = mgh (gravitational potential energy)',
        'W = Fd cos θ (work done)',
        'P = W/t (power)',
        'ME = KE + PE (mechanical energy)',
        'Efficiency = (useful output / total input) × 100%',
      ],
      
      commonMistakes: [
        'Forgetting the ½ in kinetic energy formula',
        'Using wrong units (mixing J and kJ)',
        'Not squaring velocity in KE formula',
        'Confusing work and power',
        'Ignoring energy losses due to friction',
      ],
    );
  }

  /// Electricity Template (Circuits, Ohm's Law, Power)
  static AIPromptTemplate _createElectricityTemplate() {
    return AIPromptTemplate(
      skillId: 'electricity',
      skillName: 'Electricity and Circuits',
      gradeLevel: 'Grades 9-12',
      subject: SubjectType.physics,
      
      conceptsToTest: [
        'Electric current (I = Q/t)',
        'Voltage and potential difference',
        'Resistance and Ohm\'s Law (V = IR)',
        'Series and parallel circuits',
        'Electric power (P = VI = I²R = V²/R)',
        'Resistors in series and parallel',
        'Kirchhoff\'s laws',
        'Electrical energy and cost',
      ],
      
      questionFormats: [
        'Calculate: "A 12V battery drives 2A through a resistor. What is the resistance?"',
        'Circuit analysis: "Three 6Ω resistors in series have what total resistance?"',
        'Power: "A 100W bulb runs for 5 hours. How much energy is consumed?"',
        'Cost: "If electricity costs \$0.12/kWh, what is the cost of running a 1500W heater for 8 hours?"',
      ],
      
      difficultyScaling: {
        '1-3': 'Simple Ohm\'s Law calculations, basic circuit concepts, one resistor, whole numbers',
        '4-6': 'Series and parallel circuits, power calculations, two-step problems, energy cost',
        '7-10': 'Complex circuits, Kirchhoff\'s laws, mixed series-parallel, efficiency calculations',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'A 12V battery drives 3A through a resistor. What is the resistance?',
            correctAnswer: '4 Ω',
            explanation: 'Using Ohm\'s Law: R = V/I = 12V / 3A = 4 Ω',
            options: ['2 Ω', '4 Ω', '6 Ω', '36 Ω'],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'Three resistors of 2Ω, 3Ω, and 6Ω are connected in parallel. What is the equivalent resistance?',
            correctAnswer: '1 Ω',
            explanation: '1/R = 1/2 + 1/3 + 1/6 = 3/6 + 2/6 + 1/6 = 6/6 = 1, so R = 1 Ω',
            options: ['0.5 Ω', '1 Ω', '2 Ω', '11 Ω'],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'A 1500W electric heater runs for 6 hours daily. If electricity costs \$0.15/kWh, what is the monthly cost (30 days)?',
            correctAnswer: '\$40.50',
            explanation: 'Energy = 1.5 kW × 6 h × 30 days = 270 kWh. Cost = 270 × \$0.15 = \$40.50',
            options: ['\$27.00', '\$40.50', '\$54.00', '\$67.50'],
          ),
        ],
      },
      
      formulas: [
        'V = IR (Ohm\'s Law)',
        'P = VI = I²R = V²/R (electrical power)',
        'E = Pt (electrical energy)',
        'R_series = R₁ + R₂ + R₃ + ...',
        '1/R_parallel = 1/R₁ + 1/R₂ + 1/R₃ + ...',
        'I = Q/t (current)',
      ],
      
      commonMistakes: [
        'Confusing series and parallel resistance formulas',
        'Forgetting to convert W to kW for energy cost',
        'Using wrong power formula for given variables',
        'Not converting time to hours for kWh',
        'Mixing up voltage and current',
      ],
    );
  }

  /// Waves Template (Sound, Light, Wave Properties)
  static AIPromptTemplate _createWavesTemplate() {
    return AIPromptTemplate(
      skillId: 'waves',
      skillName: 'Waves and Sound',
      gradeLevel: 'Grades 9-12',
      subject: SubjectType.physics,
      
      conceptsToTest: [
        'Wave speed (v = fλ)',
        'Frequency and period (f = 1/T)',
        'Wavelength and amplitude',
        'Transverse and longitudinal waves',
        'Sound waves and speed of sound',
        'Reflection and refraction',
        'Doppler effect',
        'Wave interference',
      ],
      
      questionFormats: [
        'Calculate: "A wave has frequency 50 Hz and wavelength 2 m. What is its speed?"',
        'Conceptual: "What type of wave is sound?"',
        'Application: "Why does a siren sound different as an ambulance passes?"',
      ],
      
      difficultyScaling: {
        '1-3': 'Basic wave properties, v=fλ calculations, simple concepts, whole numbers',
        '4-6': 'Period and frequency, wave types, two-step calculations, sound applications',
        '7-10': 'Doppler effect, interference, complex calculations, advanced wave phenomena',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'A wave has a frequency of 10 Hz and wavelength of 5 m. What is its speed?',
            correctAnswer: '50 m/s',
            explanation: 'Using v = fλ: v = 10 Hz × 5 m = 50 m/s',
            options: ['2 m/s', '15 m/s', '50 m/s', '500 m/s'],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'A sound wave has a period of 0.002 seconds. What is its frequency?',
            correctAnswer: '500 Hz',
            explanation: 'f = 1/T = 1/0.002 = 500 Hz',
            options: ['50 Hz', '200 Hz', '500 Hz', '2000 Hz'],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'An ambulance siren has a frequency of 1000 Hz. If the ambulance approaches at 30 m/s and sound speed is 340 m/s, what frequency does a stationary observer hear?',
            correctAnswer: '1097 Hz',
            explanation: 'Doppler: f\' = f(v/(v-vs)) = 1000(340/(340-30)) = 1000(340/310) = 1097 Hz',
            options: ['912 Hz', '1000 Hz', '1097 Hz', '1133 Hz'],
          ),
        ],
      },
      
      formulas: [
        'v = fλ (wave speed)',
        'f = 1/T (frequency and period)',
        'v_sound ≈ 340 m/s (speed of sound in air)',
        'f\' = f(v/(v±vs)) (Doppler effect)',
      ],
    );
  }

  /// Thermodynamics Template (Heat, Temperature, Gas Laws)
  static AIPromptTemplate _createThermodynamicsTemplate() {
    return AIPromptTemplate(
      skillId: 'thermodynamics',
      skillName: 'Heat and Thermodynamics',
      gradeLevel: 'Grades 10-12',
      subject: SubjectType.physics,
      
      conceptsToTest: [
        'Temperature scales (Celsius, Kelvin, Fahrenheit)',
        'Heat transfer (conduction, convection, radiation)',
        'Specific heat capacity (Q = mcΔT)',
        'Thermal expansion',
        'Ideal gas law (PV = nRT)',
        'First law of thermodynamics',
        'Heat engines and efficiency',
      ],
      
      questionFormats: [
        'Calculate: "How much heat is needed to raise 2 kg of water by 10°C? (c = 4200 J/kg°C)"',
        'Conversion: "Convert 100°C to Kelvin"',
        'Gas law: "A gas at 2 atm and 300 K is heated to 600 K. What is the new pressure?"',
      ],
      
      difficultyScaling: {
        '1-3': 'Temperature conversions, basic heat calculations, simple concepts',
        '4-6': 'Specific heat problems, gas law calculations, two-step problems',
        '7-10': 'Complex thermodynamics, efficiency, combined gas laws, multi-step problems',
      },
      
      exampleQuestions: {
        1: [
          ExampleQuestion(
            question: 'Convert 0°C to Kelvin',
            correctAnswer: '273 K',
            explanation: 'K = °C + 273, so 0°C = 273 K',
            options: ['0 K', '100 K', '273 K', '373 K'],
          ),
        ],
        5: [
          ExampleQuestion(
            question: 'How much heat is needed to raise the temperature of 5 kg of water from 20°C to 80°C? (c = 4200 J/kg°C)',
            correctAnswer: '1,260,000 J',
            explanation: 'Q = mcΔT = 5 × 4200 × (80-20) = 5 × 4200 × 60 = 1,260,000 J',
            options: ['420,000 J', '840,000 J', '1,260,000 J', '1,680,000 J'],
          ),
        ],
        10: [
          ExampleQuestion(
            question: 'A heat engine absorbs 1000 J and does 300 J of work. What is its efficiency?',
            correctAnswer: '30%',
            explanation: 'Efficiency = (Work output / Heat input) × 100% = (300/1000) × 100% = 30%',
            options: ['25%', '30%', '33%', '70%'],
          ),
        ],
      },
      
      formulas: [
        'Q = mcΔT (heat transfer)',
        'K = °C + 273 (temperature conversion)',
        'PV = nRT (ideal gas law)',
        'Efficiency = (W_out / Q_in) × 100%',
      ],
    );
  }
}

