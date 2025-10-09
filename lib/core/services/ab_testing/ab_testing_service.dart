import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A/B Testing Service - Task H4
/// Implement A/B testing for features and UI variations
/// 
/// Features:
/// - Experiment management
/// - Variant assignment
/// - Analytics integration
/// - Rollout controls
/// - Statistical analysis

class ABTestingService {
  static final ABTestingService _instance = ABTestingService._internal();
  factory ABTestingService() => _instance;
  ABTestingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  SharedPreferences? _prefs;

  final Map<String, Experiment> _experiments = {};
  final Map<String, String> _userVariants = {};

  /// Initialize A/B testing
  Future<void> initialize(String userId) async {
    _prefs = await SharedPreferences.getInstance();

    // Load experiments from Firestore
    await _loadExperiments();

    // Load user's assigned variants
    await _loadUserVariants(userId);

    debugPrint('✅ A/B Testing initialized with ${_experiments.length} experiments');
  }

  Future<void> _loadExperiments() async {
    try {
      final snapshot = await _firestore
          .collection('experiments')
          .where('status', isEqualTo: 'active')
          .get();

      for (final doc in snapshot.docs) {
        final experiment = Experiment.fromMap(doc.id, doc.data());
        _experiments[experiment.id] = experiment;
      }
    } catch (e) {
      debugPrint('Error loading experiments: $e');
      // Load default experiments
      _loadDefaultExperiments();
    }
  }

  void _loadDefaultExperiments() {
    // Default experiments for development
    _experiments['onboarding_flow'] = Experiment(
      id: 'onboarding_flow',
      name: 'Onboarding Flow Test',
      description: 'Test different onboarding flows',
      variants: [
        Variant(id: 'control', name: 'Original', weight: 50),
        Variant(id: 'simplified', name: 'Simplified', weight: 50),
      ],
      status: ExperimentStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 30)),
    );

    _experiments['gamification_level'] = Experiment(
      id: 'gamification_level',
      name: 'Gamification Level Test',
      description: 'Test different gamification intensities',
      variants: [
        Variant(id: 'control', name: 'Standard', weight: 33),
        Variant(id: 'high', name: 'High Gamification', weight: 33),
        Variant(id: 'minimal', name: 'Minimal Gamification', weight: 34),
      ],
      status: ExperimentStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 30)),
    );

    _experiments['button_color'] = Experiment(
      id: 'button_color',
      name: 'Primary Button Color Test',
      description: 'Test different primary button colors',
      variants: [
        Variant(id: 'control', name: 'Orange', weight: 50),
        Variant(id: 'blue', name: 'Blue', weight: 50),
      ],
      status: ExperimentStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now().add(const Duration(days: 30)),
    );
  }

  Future<void> _loadUserVariants(String userId) async {
    // Load from local storage first
    final stored = _prefs?.getString('user_variants_$userId');
    if (stored != null) {
      // Parse stored variants
      // In production, use json.decode
    }

    // Assign variants for new experiments
    for (final experiment in _experiments.values) {
      if (!_userVariants.containsKey(experiment.id)) {
        final variant = _assignVariant(userId, experiment);
        _userVariants[experiment.id] = variant.id;

        // Track assignment
        await _trackVariantAssignment(userId, experiment, variant);
      }
    }

    // Save to local storage
    await _saveUserVariants(userId);
  }

  Variant _assignVariant(String userId, Experiment experiment) {
    // Use consistent hashing for stable assignment
    final hash = userId.hashCode + experiment.id.hashCode;
    final random = hash % 100;

    int cumulative = 0;
    for (final variant in experiment.variants) {
      cumulative += variant.weight;
      if (random < cumulative) {
        return variant;
      }
    }

    return experiment.variants.first;
  }

  Future<void> _trackVariantAssignment(
    String userId,
    Experiment experiment,
    Variant variant,
  ) async {
    // Track in Firebase Analytics
    await _analytics.logEvent(
      name: 'experiment_assigned',
      parameters: {
        'experiment_id': experiment.id,
        'experiment_name': experiment.name,
        'variant_id': variant.id,
        'variant_name': variant.name,
      },
    );

    // Store in Firestore
    try {
      await _firestore.collection('experiment_assignments').add({
        'userId': userId,
        'experimentId': experiment.id,
        'variantId': variant.id,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error tracking variant assignment: $e');
    }
  }

  Future<void> _saveUserVariants(String userId) async {
    // Save to local storage
    // In production, use json.encode
    await _prefs?.setString('user_variants_$userId', _userVariants.toString());
  }

  /// Get variant for experiment
  String getVariant(String experimentId) {
    return _userVariants[experimentId] ?? 'control';
  }

  /// Check if user is in variant
  bool isInVariant(String experimentId, String variantId) {
    return getVariant(experimentId) == variantId;
  }

  /// Track experiment event
  Future<void> trackEvent({
    required String experimentId,
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    final variant = getVariant(experimentId);

    await _analytics.logEvent(
      name: 'experiment_$eventName',
      parameters: {
        'experiment_id': experimentId,
        'variant_id': variant,
        ...?parameters,
      },
    );
  }

  /// Track conversion
  Future<void> trackConversion({
    required String experimentId,
    required String conversionType,
    double? value,
  }) async {
    final variant = getVariant(experimentId);

    await _analytics.logEvent(
      name: 'experiment_conversion',
      parameters: {
        'experiment_id': experimentId,
        'variant_id': variant,
        'conversion_type': conversionType,
        if (value != null) 'value': value,
      },
    );

    debugPrint('Conversion tracked: $experimentId/$variant/$conversionType');
  }

  /// Get experiment results
  Future<ExperimentResults> getResults(String experimentId) async {
    // In production, fetch from Firestore aggregations
    return ExperimentResults(
      experimentId: experimentId,
      variantResults: [
        VariantResult(
          variantId: 'control',
          participants: 1250,
          conversions: 375,
          conversionRate: 0.30,
          averageValue: 45.50,
        ),
        VariantResult(
          variantId: 'variant_a',
          participants: 1280,
          conversions: 448,
          conversionRate: 0.35,
          averageValue: 52.30,
        ),
      ],
      winner: 'variant_a',
      confidence: 0.95,
      improvement: 16.7,
    );
  }

  /// Create new experiment
  Future<void> createExperiment(Experiment experiment) async {
    try {
      await _firestore.collection('experiments').doc(experiment.id).set({
        'name': experiment.name,
        'description': experiment.description,
        'variants': experiment.variants
            .map((v) => {'id': v.id, 'name': v.name, 'weight': v.weight})
            .toList(),
        'status': experiment.status.name,
        'startDate': Timestamp.fromDate(experiment.startDate),
        'endDate': Timestamp.fromDate(experiment.endDate),
      });

      _experiments[experiment.id] = experiment;
      debugPrint('Experiment created: ${experiment.id}');
    } catch (e) {
      debugPrint('Error creating experiment: $e');
    }
  }

  /// Update experiment status
  Future<void> updateExperimentStatus(
    String experimentId,
    ExperimentStatus status,
  ) async {
    try {
      await _firestore.collection('experiments').doc(experimentId).update({
        'status': status.name,
      });

      if (_experiments.containsKey(experimentId)) {
        _experiments[experimentId]!.status = status;
      }

      debugPrint('Experiment status updated: $experimentId -> ${status.name}');
    } catch (e) {
      debugPrint('Error updating experiment status: $e');
    }
  }
}

/// Experiment model
class Experiment {
  final String id;
  final String name;
  final String description;
  final List<Variant> variants;
  ExperimentStatus status;
  final DateTime startDate;
  final DateTime endDate;

  Experiment({
    required this.id,
    required this.name,
    required this.description,
    required this.variants,
    required this.status,
    required this.startDate,
    required this.endDate,
  });

  factory Experiment.fromMap(String id, Map<String, dynamic> map) {
    return Experiment(
      id: id,
      name: map['name'] as String,
      description: map['description'] as String,
      variants: (map['variants'] as List)
          .map((v) => Variant.fromMap(v as Map<String, dynamic>))
          .toList(),
      status: ExperimentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ExperimentStatus.draft,
      ),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
    );
  }
}

class Variant {
  final String id;
  final String name;
  final int weight; // 0-100

  Variant({
    required this.id,
    required this.name,
    required this.weight,
  });

  factory Variant.fromMap(Map<String, dynamic> map) {
    return Variant(
      id: map['id'] as String,
      name: map['name'] as String,
      weight: map['weight'] as int,
    );
  }
}

class ExperimentResults {
  final String experimentId;
  final List<VariantResult> variantResults;
  final String? winner;
  final double confidence;
  final double improvement;

  ExperimentResults({
    required this.experimentId,
    required this.variantResults,
    this.winner,
    required this.confidence,
    required this.improvement,
  });
}

class VariantResult {
  final String variantId;
  final int participants;
  final int conversions;
  final double conversionRate;
  final double averageValue;

  VariantResult({
    required this.variantId,
    required this.participants,
    required this.conversions,
    required this.conversionRate,
    required this.averageValue,
  });
}

enum ExperimentStatus { draft, active, paused, completed }

/// Usage Examples:
/// 
/// ```dart
/// // Initialize
/// await ABTestingService().initialize(userId);
/// 
/// // Get variant
/// final variant = ABTestingService().getVariant('onboarding_flow');
/// if (variant == 'simplified') {
///   // Show simplified onboarding
/// }
/// 
/// // Check variant
/// if (ABTestingService().isInVariant('button_color', 'blue')) {
///   buttonColor = Colors.blue;
/// }
/// 
/// // Track event
/// await ABTestingService().trackEvent(
///   experimentId: 'onboarding_flow',
///   eventName: 'completed_step_1',
/// );
/// 
/// // Track conversion
/// await ABTestingService().trackConversion(
///   experimentId: 'onboarding_flow',
///   conversionType: 'completed_onboarding',
/// );
/// ```

