import '../models/ai_prompt_template.dart';
import '../models/subject.dart';

/// Registry for managing AI prompt templates across different subjects
class PromptTemplateRegistry {
  static final PromptTemplateRegistry _instance = PromptTemplateRegistry._internal();
  factory PromptTemplateRegistry() => _instance;
  PromptTemplateRegistry._internal();

  /// Singleton instance getter
  static PromptTemplateRegistry get instance => _instance;

  final Map<String, AIPromptTemplate> _templates = {};
  final Map<SubjectType, List<String>> _subjectTemplates = {};

  /// Register a prompt template
  void registerTemplate(AIPromptTemplate template) {
    _templates[template.skillId] = template;
    
    // Add to subject mapping
    _subjectTemplates.putIfAbsent(template.subject, () => []);
    if (!_subjectTemplates[template.subject]!.contains(template.skillId)) {
      _subjectTemplates[template.subject]!.add(template.skillId);
    }
  }

  /// Register multiple templates
  void registerTemplates(List<AIPromptTemplate> templates) {
    for (final template in templates) {
      registerTemplate(template);
    }
  }

  /// Get template by skill ID
  AIPromptTemplate? getTemplate(String skillId) {
    return _templates[skillId];
  }

  /// Get all templates for a subject
  List<AIPromptTemplate> getTemplatesForSubject(SubjectType subject) {
    final skillIds = _subjectTemplates[subject] ?? [];
    return skillIds
        .map((id) => _templates[id])
        .where((template) => template != null)
        .cast<AIPromptTemplate>()
        .toList();
  }

  /// Get all registered skill IDs
  List<String> getAllSkillIds() {
    return _templates.keys.toList();
  }

  /// Get all template keys (alias for getAllSkillIds for compatibility)
  List<String> getAllTemplateKeys() {
    return getAllSkillIds();
  }

  /// Get all registered skill IDs for a subject
  List<String> getSkillIdsForSubject(SubjectType subject) {
    return _subjectTemplates[subject] ?? [];
  }

  /// Check if a template exists
  bool hasTemplate(String skillId) {
    return _templates.containsKey(skillId);
  }

  /// Get template count
  int get templateCount => _templates.length;

  /// Get template count for subject
  int getTemplateCountForSubject(SubjectType subject) {
    return _subjectTemplates[subject]?.length ?? 0;
  }

  /// Clear all templates
  void clear() {
    _templates.clear();
    _subjectTemplates.clear();
  }

  /// Clear all templates (alias for clear for compatibility)
  void clearAll() {
    clear();
  }

  /// Remove template by skill ID
  bool removeTemplate(String skillId) {
    final template = _templates.remove(skillId);
    if (template != null) {
      _subjectTemplates[template.subject]?.remove(skillId);
      return true;
    }
    return false;
  }

  /// Get all templates
  List<AIPromptTemplate> getAllTemplates() {
    return _templates.values.toList();
  }

  /// Get subjects with registered templates
  List<SubjectType> getRegisteredSubjects() {
    return _subjectTemplates.keys.toList();
  }

  /// Export templates to JSON
  Map<String, dynamic> toJson() {
    return {
      'templates': _templates.map((key, value) => MapEntry(key, value.toJson())),
      'subjectTemplates': _subjectTemplates.map(
        (key, value) => MapEntry(key.name, value),
      ),
    };
  }

  /// Import templates from JSON
  void fromJson(Map<String, dynamic> json) {
    clear();
    
    final templatesJson = json['templates'] as Map<String, dynamic>? ?? {};
    for (final entry in templatesJson.entries) {
      final template = AIPromptTemplate.fromJson(entry.value as Map<String, dynamic>);
      registerTemplate(template);
    }
  }
}