/// EYUS (Efficient, Youthful, User-friendly, Scalable) File Structure
/// 
/// This utility implements best practices for file organization in Flutter applications,
/// focusing on maintainability, scalability, and developer experience.

import 'dart:io';
import 'package:path/path.dart' as path;

/// EYUS File Structure Manager
/// 
/// Provides utilities for organizing and managing files according to EYUS principles:
/// - Efficient: Fast access and minimal nesting
/// - Youthful: Modern patterns and conventions
/// - User-friendly: Clear naming and intuitive organization
/// - Scalable: Supports growth without restructuring
class EyusFileStructure {
  static const String _configFileName = 'eyus_config.json';
  
  /// Core directory structure following EYUS principles
  static const Map<String, List<String>> coreStructure = {
    'lib': [
      'core',
      'features',
      'shared',
      'app',
    ],
    'lib/core': [
      'models',
      'services',
      'utils',
      'constants',
      'extensions',
      'exceptions',
    ],
    'lib/features': [
      // Feature-based organization
      // Each feature should contain: models, services, widgets, screens
    ],
    'lib/shared': [
      'widgets',
      'themes',
      'localization',
      'assets',
    ],
    'lib/app': [
      'routes',
      'config',
      'providers',
    ],
    'test': [
      'unit',
      'widget',
      'integration',
      'mocks',
    ],
    'assets': [
      'images',
      'icons',
      'fonts',
      'data',
    ],
  };

  /// Feature template structure
  static const Map<String, List<String>> featureTemplate = {
    'models': [],
    'services': [],
    'widgets': [],
    'screens': [],
    'providers': [],
  };

  /// File naming conventions
  static const Map<String, String> namingConventions = {
    'models': 'snake_case.dart',
    'services': 'snake_case_service.dart',
    'widgets': 'snake_case_widget.dart',
    'screens': 'snake_case_screen.dart',
    'providers': 'snake_case_provider.dart',
    'utils': 'snake_case_utils.dart',
    'constants': 'snake_case_constants.dart',
    'extensions': 'snake_case_extensions.dart',
    'exceptions': 'snake_case_exception.dart',
  };

  /// Initialize EYUS structure in the given directory
  static Future<void> initializeStructure(String projectPath) async {
    final projectDir = Directory(projectPath);
    if (!await projectDir.exists()) {
      throw EyusException('Project directory does not exist: $projectPath');
    }

    // Create core structure
    for (final entry in coreStructure.entries) {
      final dirPath = path.join(projectPath, entry.key);
      await _createDirectoryIfNotExists(dirPath);

      for (final subDir in entry.value) {
        final subDirPath = path.join(dirPath, subDir);
        await _createDirectoryIfNotExists(subDirPath);
      }
    }

    // Create configuration file
    await _createConfigFile(projectPath);
  }

  /// Create a new feature following EYUS structure
  static Future<void> createFeature(String projectPath, String featureName) async {
    final featurePath = path.join(projectPath, 'lib', 'features', featureName);
    
    if (await Directory(featurePath).exists()) {
      throw EyusException('Feature already exists: $featureName');
    }

    // Create feature directory structure
    for (final entry in featureTemplate.entries) {
      final dirPath = path.join(featurePath, entry.key);
      await _createDirectoryIfNotExists(dirPath);
    }

    // Create barrel file for the feature
    await _createFeatureBarrelFile(featurePath, featureName);
  }

  /// Validate project structure against EYUS standards
  static Future<EyusValidationResult> validateStructure(String projectPath) async {
    final result = EyusValidationResult();
    
    // Check core directories
    for (final entry in coreStructure.entries) {
      final dirPath = path.join(projectPath, entry.key);
      final dir = Directory(dirPath);
      
      if (!await dir.exists()) {
        result.addError('Missing core directory: ${entry.key}');
        continue;
      }

      // Check subdirectories
      for (final subDir in entry.value) {
        final subDirPath = path.join(dirPath, subDir);
        if (!await Directory(subDirPath).exists()) {
          result.addWarning('Missing subdirectory: ${entry.key}/$subDir');
        }
      }
    }

    // Check naming conventions
    await _validateNamingConventions(projectPath, result);

    // Check for common anti-patterns
    await _checkAntiPatterns(projectPath, result);

    return result;
  }

  /// Organize existing files according to EYUS structure
  static Future<void> organizeExistingFiles(String projectPath) async {
    final libDir = Directory(path.join(projectPath, 'lib'));
    if (!await libDir.exists()) {
      throw EyusException('lib directory not found');
    }

    final suggestions = <EyusOrganizationSuggestion>[];
    
    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final suggestion = await _analyzeFileForOrganization(entity);
        if (suggestion != null) {
          suggestions.add(suggestion);
        }
      }
    }

    // Apply suggestions (with user confirmation in real implementation)
    for (final suggestion in suggestions) {
      await _applySuggestion(suggestion);
    }
  }

  /// Generate project documentation based on EYUS structure
  static Future<void> generateDocumentation(String projectPath) async {
    final docContent = StringBuffer();
    
    docContent.writeln('# Project Structure Documentation');
    docContent.writeln('');
    docContent.writeln('This project follows the EYUS (Efficient, Youthful, User-friendly, Scalable) file structure.');
    docContent.writeln('');

    // Document core structure
    docContent.writeln('## Core Structure');
    docContent.writeln('');
    for (final entry in coreStructure.entries) {
      docContent.writeln('### ${entry.key}/');
      for (final subDir in entry.value) {
        docContent.writeln('- `$subDir/` - ${_getDirectoryDescription(subDir)}');
      }
      docContent.writeln('');
    }

    // Document features
    final featuresDir = Directory(path.join(projectPath, 'lib', 'features'));
    if (await featuresDir.exists()) {
      docContent.writeln('## Features');
      docContent.writeln('');
      await for (final entity in featuresDir.list()) {
        if (entity is Directory) {
          final featureName = path.basename(entity.path);
          docContent.writeln('### $featureName');
          docContent.writeln('- Location: `lib/features/$featureName/`');
          docContent.writeln('- Structure: Standard feature template');
          docContent.writeln('');
        }
      }
    }

    // Write documentation file
    final docFile = File(path.join(projectPath, 'STRUCTURE.md'));
    await docFile.writeAsString(docContent.toString());
  }

  /// Get file organization recommendations
  static Future<List<EyusRecommendation>> getRecommendations(String projectPath) async {
    final recommendations = <EyusRecommendation>[];
    
    // Analyze current structure
    final validation = await validateStructure(projectPath);
    
    // Generate recommendations based on validation results
    for (final error in validation.errors) {
      recommendations.add(EyusRecommendation(
        type: RecommendationType.critical,
        title: 'Fix Structure Error',
        description: error,
        action: 'Create missing directory or fix structure issue',
      ));
    }

    for (final warning in validation.warnings) {
      recommendations.add(EyusRecommendation(
        type: RecommendationType.improvement,
        title: 'Structure Improvement',
        description: warning,
        action: 'Consider creating missing directory for better organization',
      ));
    }

    // Analyze file organization
    await _analyzeFileOrganization(projectPath, recommendations);

    return recommendations;
  }

  // Private helper methods

  static Future<void> _createDirectoryIfNotExists(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  static Future<void> _createConfigFile(String projectPath) async {
    final configFile = File(path.join(projectPath, _configFileName));
    final config = {
      'eyus_version': '1.0.0',
      'created_at': DateTime.now().toIso8601String(),
      'structure_type': 'standard',
      'features': <String>[],
    };

    await configFile.writeAsString(_jsonEncode(config));
  }

  static Future<void> _createFeatureBarrelFile(String featurePath, String featureName) async {
    final barrelFile = File(path.join(featurePath, '$featureName.dart'));
    final content = '''
// Barrel file for $featureName feature
// Export all public APIs from this feature

// Models
export 'models/models.dart';

// Services
export 'services/services.dart';

// Widgets
export 'widgets/widgets.dart';

// Screens
export 'screens/screens.dart';

// Providers
export 'providers/providers.dart';
''';

    await barrelFile.writeAsString(content);
  }

  static Future<void> _validateNamingConventions(String projectPath, EyusValidationResult result) async {
    final libDir = Directory(path.join(projectPath, 'lib'));
    
    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final fileName = path.basename(entity.path);
        final relativePath = path.relative(entity.path, from: libDir.path);
        
        if (!_isValidFileName(fileName, relativePath)) {
          result.addWarning('File naming convention issue: $relativePath');
        }
      }
    }
  }

  static bool _isValidFileName(String fileName, String relativePath) {
    // Check if file follows snake_case convention
    final nameWithoutExtension = fileName.replaceAll('.dart', '');
    final snakeCaseRegex = RegExp(r'^[a-z][a-z0-9_]*$');
    
    return snakeCaseRegex.hasMatch(nameWithoutExtension);
  }

  static Future<void> _checkAntiPatterns(String projectPath, EyusValidationResult result) async {
    // Check for deeply nested directories
    await _checkDeepNesting(projectPath, result);
    
    // Check for large files
    await _checkLargeFiles(projectPath, result);
    
    // Check for circular dependencies (simplified check)
    await _checkCircularDependencies(projectPath, result);
  }

  static Future<void> _checkDeepNesting(String projectPath, EyusValidationResult result) async {
    final libDir = Directory(path.join(projectPath, 'lib'));
    
    await for (final entity in libDir.list(recursive: true)) {
      if (entity is Directory) {
        final relativePath = path.relative(entity.path, from: libDir.path);
        final depth = relativePath.split(path.separator).length;
        
        if (depth > 4) {
          result.addWarning('Deep nesting detected: $relativePath (depth: $depth)');
        }
      }
    }
  }

  static Future<void> _checkLargeFiles(String projectPath, EyusValidationResult result) async {
    final libDir = Directory(path.join(projectPath, 'lib'));
    
    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final lines = await entity.readAsLines();
        if (lines.length > 500) {
          final relativePath = path.relative(entity.path, from: libDir.path);
          result.addWarning('Large file detected: $relativePath (${lines.length} lines)');
        }
      }
    }
  }

  static Future<void> _checkCircularDependencies(String projectPath, EyusValidationResult result) async {
    // Simplified circular dependency check
    // In a real implementation, this would use a proper dependency graph
    final libDir = Directory(path.join(projectPath, 'lib'));
    final imports = <String, Set<String>>{};
    
    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final relativePath = path.relative(entity.path, from: libDir.path);
        final content = await entity.readAsString();
        final fileImports = _extractImports(content);
        imports[relativePath] = fileImports;
      }
    }
    
    // Simple cycle detection (would need more sophisticated algorithm for real use)
    for (final entry in imports.entries) {
      for (final import in entry.value) {
        if (imports[import]?.contains(entry.key) == true) {
          result.addWarning('Potential circular dependency: ${entry.key} <-> $import');
        }
      }
    }
  }

  static Set<String> _extractImports(String content) {
    final imports = <String>{};
    final lines = content.split('\n');
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('import ') && !trimmed.contains('package:')) {
        // Extract relative imports only - simplified approach
        final singleQuoteMatch = RegExp(r"import\s+'([^']+)'").firstMatch(trimmed);
        final doubleQuoteMatch = RegExp(r'import\s+"([^"]+)"').firstMatch(trimmed);
        
        String? importPath;
        if (singleQuoteMatch != null) {
          importPath = singleQuoteMatch.group(1);
        } else if (doubleQuoteMatch != null) {
          importPath = doubleQuoteMatch.group(1);
        }
        
        if (importPath != null) {
          if (!importPath.startsWith('package:') && !importPath.startsWith('dart:')) {
            imports.add(importPath);
          }
        }
      }
    }
    
    return imports;
  }

  static Future<EyusOrganizationSuggestion?> _analyzeFileForOrganization(File file) async {
    final content = await file.readAsString();
    final fileName = path.basename(file.path);
    
    // Analyze file content to suggest better organization
    if (content.contains('class') && content.contains('extends StatelessWidget')) {
      if (!file.path.contains('widgets') && !file.path.contains('screens')) {
        return EyusOrganizationSuggestion(
          currentPath: file.path,
          suggestedPath: _suggestWidgetPath(file.path, fileName),
          reason: 'Widget class should be in widgets or screens directory',
        );
      }
    }
    
    if (content.contains('class') && fileName.endsWith('_service.dart')) {
      if (!file.path.contains('services')) {
        return EyusOrganizationSuggestion(
          currentPath: file.path,
          suggestedPath: _suggestServicePath(file.path, fileName),
          reason: 'Service class should be in services directory',
        );
      }
    }
    
    return null;
  }

  static String _suggestWidgetPath(String currentPath, String fileName) {
    final projectRoot = currentPath.split('lib')[0];
    return path.join(projectRoot, 'lib', 'shared', 'widgets', fileName);
  }

  static String _suggestServicePath(String currentPath, String fileName) {
    final projectRoot = currentPath.split('lib')[0];
    return path.join(projectRoot, 'lib', 'core', 'services', fileName);
  }

  static Future<void> _applySuggestion(EyusOrganizationSuggestion suggestion) async {
    final currentFile = File(suggestion.currentPath);
    final suggestedFile = File(suggestion.suggestedPath);
    
    // Create directory if it doesn't exist
    await suggestedFile.parent.create(recursive: true);
    
    // Move file
    await currentFile.rename(suggestion.suggestedPath);
  }

  static String _getDirectoryDescription(String dirName) {
    const descriptions = {
      'models': 'Data models and entities',
      'services': 'Business logic and external service integrations',
      'utils': 'Utility functions and helpers',
      'constants': 'Application constants and configuration',
      'extensions': 'Dart language extensions',
      'exceptions': 'Custom exception classes',
      'widgets': 'Reusable UI components',
      'themes': 'Application theming and styling',
      'localization': 'Internationalization and localization',
      'assets': 'Asset management utilities',
      'routes': 'Navigation and routing configuration',
      'config': 'Application configuration',
      'providers': 'State management providers',
      'screens': 'Screen/page widgets',
    };
    
    return descriptions[dirName] ?? 'Application component';
  }

  static Future<void> _analyzeFileOrganization(String projectPath, List<EyusRecommendation> recommendations) async {
    final libDir = Directory(path.join(projectPath, 'lib'));
    
    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final content = await entity.readAsString();
        final relativePath = path.relative(entity.path, from: libDir.path);
        
        // Check if file is in the right place
        if (content.contains('extends StatelessWidget') || content.contains('extends StatefulWidget')) {
          if (!relativePath.contains('widgets') && !relativePath.contains('screens')) {
            recommendations.add(EyusRecommendation(
              type: RecommendationType.improvement,
              title: 'Widget Organization',
              description: 'Widget found outside widgets/screens directory: $relativePath',
              action: 'Move to appropriate widgets or screens directory',
            ));
          }
        }
      }
    }
  }

  static String _jsonEncode(Map<String, dynamic> data) {
    // Simple JSON encoding for basic data types
    final buffer = StringBuffer();
    buffer.write('{');
    
    final entries = data.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      buffer.write('"${entry.key}":');
      
      if (entry.value is String) {
        buffer.write('"${entry.value}"');
      } else if (entry.value is List) {
        buffer.write('[');
        final list = entry.value as List;
        for (int j = 0; j < list.length; j++) {
          buffer.write('"${list[j]}"');
          if (j < list.length - 1) buffer.write(',');
        }
        buffer.write(']');
      } else {
        buffer.write('${entry.value}');
      }
      
      if (i < entries.length - 1) buffer.write(',');
    }
    
    buffer.write('}');
    return buffer.toString();
  }
}

/// EYUS validation result
class EyusValidationResult {
  final List<String> errors = [];
  final List<String> warnings = [];
  final List<String> suggestions = [];

  void addError(String error) => errors.add(error);
  void addWarning(String warning) => warnings.add(warning);
  void addSuggestion(String suggestion) => suggestions.add(suggestion);

  bool get isValid => errors.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasSuggestions => suggestions.isNotEmpty;
}

/// File organization suggestion
class EyusOrganizationSuggestion {
  final String currentPath;
  final String suggestedPath;
  final String reason;

  EyusOrganizationSuggestion({
    required this.currentPath,
    required this.suggestedPath,
    required this.reason,
  });
}

/// EYUS recommendation
class EyusRecommendation {
  final RecommendationType type;
  final String title;
  final String description;
  final String action;

  EyusRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.action,
  });
}

/// Recommendation types
enum RecommendationType {
  critical,
  improvement,
  suggestion,
}

/// EYUS-specific exception
class EyusException implements Exception {
  final String message;
  
  EyusException(this.message);
  
  @override
  String toString() => 'EyusException: $message';
}