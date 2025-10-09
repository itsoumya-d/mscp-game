import 'package:flutter/foundation.dart';
import '../models/subject.dart';
import '../models/ai_prompt_template.dart';
import 'prompt_template_registry.dart';
import 'math_prompt_templates.dart';
import 'physics_prompt_templates.dart';
// AI prompt templates removed for AI cleanup
import 'chemistry_prompt_templates.dart';
import 'biology_prompt_templates.dart';

/// Initializes all AI prompt templates for all subjects
/// Enhanced AI Content Generation - Category E Task E1
class PromptTemplateInitializer {
  static bool _initialized = false;

  /// Initialize all subject-specific prompt templates
  /// This should be called once at app startup
  static void initializeAll() {
    if (_initialized) {
      if (kDebugMode) {
        debugPrint('[PromptTemplateInitializer] Templates already initialized');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('[PromptTemplateInitializer] Initializing all prompt templates...');
    }

    final registry = PromptTemplateRegistry.instance;
    
    // Clear any existing templates (for testing/hot reload)
    registry.clearAll();

    // Register all subject templates
    MathPromptTemplates.registerAll(registry);
    PhysicsPromptTemplates.registerAll(registry);
    ChemistryPromptTemplates.registerAll(registry);
    BiologyPromptTemplates.registerAll(registry);

    _initialized = true;

    if (kDebugMode) {
      debugPrint('[PromptTemplateInitializer] ✅ Initialized ${registry.templateCount} templates');
      _logTemplatesSummary(registry);
    }
  }

  /// Log summary of registered templates
  static void _logTemplatesSummary(PromptTemplateRegistry registry) {
    if (!kDebugMode) return;

    debugPrint('[PromptTemplateInitializer] Template Summary:');
    debugPrint('  - Math: ${registry.getTemplatesForSubject(SubjectType.math).length} templates');
    debugPrint('  - Physics: ${registry.getTemplatesForSubject(SubjectType.physics).length} templates');
    debugPrint('  - Chemistry: ${registry.getTemplatesForSubject(SubjectType.chemistry).length} templates');
    debugPrint('  - Biology: ${registry.getTemplatesForSubject(SubjectType.biology).length} templates');
    
    // List all template keys
    debugPrint('[PromptTemplateInitializer] Registered templates:');
    for (final key in registry.getAllTemplateKeys()) {
      debugPrint('  - $key');
    }
  }

  /// Check if templates are initialized
  static bool get isInitialized => _initialized;

  /// Force re-initialization (for testing)
  static void forceReinitialize() {
    _initialized = false;
    initializeAll();
  }

  /// Get template for a specific subject and skill
  /// Automatically initializes if not already done
  static AIPromptTemplate? getTemplate(SubjectType subject, String skillId) {
    if (!_initialized) {
      initializeAll();
    }
    return PromptTemplateRegistry.instance.getTemplate(skillId);
  }

  /// Get all templates for a subject
  /// Automatically initializes if not already done
  static List<AIPromptTemplate> getTemplatesForSubject(SubjectType subject) {
    if (!_initialized) {
      initializeAll();
    }
    return PromptTemplateRegistry.instance.getTemplatesForSubject(subject);
  }

  /// Check if template exists
  /// Automatically initializes if not already done
  static bool hasTemplate(SubjectType subject, String skillId) {
    if (!_initialized) {
      initializeAll();
    }
    return PromptTemplateRegistry.instance.hasTemplate(skillId);
  }
}

