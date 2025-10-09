import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/flashcard.dart';

/// Service for handling multimedia content in flashcards
class MultimediaService {
  static const String _cachePrefix = 'multimedia_cache_';
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const Duration _cacheExpiry = Duration(days: 7);

  /// Generate multimedia content for a flashcard based on subject and topic
  Future<List<MultimediaContent>> generateMultimediaContent({
    required String subject,
    required String topic,
    required String difficulty,
    required MultimediaType preferredType,
  }) async {
    try {
      List<MultimediaContent> content = [];

      switch (subject.toLowerCase()) {
        case 'math':
          content = await _generateMathMultimedia(topic, difficulty, preferredType);
          break;
        case 'physics':
          content = await _generatePhysicsMultimedia(topic, difficulty, preferredType);
          break;
        case 'chemistry':
          content = await _generateChemistryMultimedia(topic, difficulty, preferredType);
          break;
        case 'biology':
          content = await _generateBiologyMultimedia(topic, difficulty, preferredType);
          break;
        case 'computer science':
          content = await _generateComputerScienceMultimedia(topic, difficulty, preferredType);
          break;
        default:
          content = await _generateGenericMultimedia(topic, difficulty, preferredType);
      }

      // Cache the generated content
      await _cacheMultimediaContent(content);
      
      return content;
    } catch (e) {
      print('Error generating multimedia content: $e');
      return [];
    }
  }

  /// Generate math-specific multimedia content
  Future<List<MultimediaContent>> _generateMathMultimedia(
    String topic,
    String difficulty,
    MultimediaType preferredType,
  ) async {
    List<MultimediaContent> content = [];

    // Generate mathematical diagrams and visualizations
    if (preferredType == MultimediaType.image || preferredType == MultimediaType.animation) {
      if (topic.contains('geometry') || topic.contains('triangle') || topic.contains('circle')) {
        content.add(MultimediaContent(
          id: 'math_geometry_${DateTime.now().millisecondsSinceEpoch}',
          type: MultimediaType.image,
          url: await _generateGeometryDiagram(topic, difficulty),
          description: 'Interactive geometry diagram for $topic',
          metadata: {
            'subject': 'math',
            'topic': topic,
            'difficulty': difficulty,
            'interactive': true,
          },
        ));
      }

      if (topic.contains('graph') || topic.contains('function') || topic.contains('equation')) {
        content.add(MultimediaContent(
          id: 'math_graph_${DateTime.now().millisecondsSinceEpoch}',
          type: MultimediaType.animation,
          url: await _generateFunctionGraph(topic, difficulty),
          description: 'Animated function graph for $topic',
          metadata: {
            'subject': 'math',
            'topic': topic,
            'difficulty': difficulty,
            'animated': true,
          },
        ));
      }

      if (topic.contains('algebra') || topic.contains('equation')) {
        content.add(MultimediaContent(
          id: 'math_steps_${DateTime.now().millisecondsSinceEpoch}',
          type: MultimediaType.animation,
          url: await _generateStepByStepSolution(topic, difficulty),
          description: 'Step-by-step solution animation for $topic',
          metadata: {
            'subject': 'math',
            'topic': topic,
            'difficulty': difficulty,
            'stepByStep': true,
          },
        ));
      }
    }

    // Generate audio explanations for complex concepts
    if (preferredType == MultimediaType.audio) {
      content.add(MultimediaContent(
        id: 'math_audio_${DateTime.now().millisecondsSinceEpoch}',
        type: MultimediaType.audio,
        url: await _generateMathAudioExplanation(topic, difficulty),
        description: 'Audio explanation for $topic',
        metadata: {
          'subject': 'math',
          'topic': topic,
          'difficulty': difficulty,
          'duration': '2-3 minutes',
        },
      ));
    }

    return content;
  }

  /// Generate physics-specific multimedia content
  Future<List<MultimediaContent>> _generatePhysicsMultimedia(
    String topic,
    String difficulty,
    MultimediaType preferredType,
  ) async {
    List<MultimediaContent> content = [];

    if (preferredType == MultimediaType.animation || preferredType == MultimediaType.image) {
      // Physics simulations and animations
      if (topic.contains('motion') || topic.contains('velocity') || topic.contains('acceleration')) {
        content.add(MultimediaContent(
          id: 'physics_motion_${DateTime.now().millisecondsSinceEpoch}',
          type: MultimediaType.animation,
          url: await _generateMotionSimulation(topic, difficulty),
          description: 'Interactive motion simulation for $topic',
          metadata: {
            'subject': 'physics',
            'topic': topic,
            'difficulty': difficulty,
            'simulation': true,
          },
        ));
      }

      if (topic.contains('wave') || topic.contains('sound') || topic.contains('light')) {
        content.add(MultimediaContent(
          id: 'physics_wave_${DateTime.now().millisecondsSinceEpoch}',
          type: MultimediaType.animation,
          url: await _generateWaveAnimation(topic, difficulty),
          description: 'Wave propagation animation for $topic',
          metadata: {
            'subject': 'physics',
            'topic': topic,
            'difficulty': difficulty,
            'waveform': true,
          },
        ));
      }

      if (topic.contains('circuit') || topic.contains('electric') || topic.contains('magnetic')) {
        content.add(MultimediaContent(
          id: 'physics_circuit_${DateTime.now().millisecondsSinceEpoch}',
          type: MultimediaType.image,
          url: await _generateCircuitDiagram(topic, difficulty),
          description: 'Interactive circuit diagram for $topic',
          metadata: {
            'subject': 'physics',
            'topic': topic,
            'difficulty': difficulty,
            'interactive': true,
          },
        ));
      }
    }

    return content;
  }

  /// Generate chemistry-specific multimedia content
  Future<List<MultimediaContent>> _generateChemistryMultimedia(
    String topic,
    String difficulty,
    MultimediaType preferredType,
  ) async {
    List<MultimediaContent> content = [];

    if (preferredType == MultimediaType.image || preferredType == MultimediaType.animation) {
      // Molecular structures and reactions
      if (topic.contains('molecule') || topic.contains('bond') || topic.contains('structure')) {
        content.add(MultimediaContent(
          id: 'chemistry_molecule_${DateTime.now().millisecondsSinceEpoch}',
          type: MultimediaType.animation,
          url: await _generateMolecularStructure(topic, difficulty),
          description: '3D molecular structure for $topic',
          metadata: {
            'subject': 'chemistry',
            'topic': topic,
            'difficulty': difficulty,
            '3d': true,
            'rotatable': true,
          },
        ));
      }

      if (topic.contains('reaction') || topic.contains('equation') || topic.contains('balance')) {
        content.add(MultimediaContent(
          id: 'chemistry_reaction_${DateTime.now().millisecondsSinceEpoch}',
          type: MultimediaType.animation,
          url: await _generateReactionAnimation(topic, difficulty),
          description: 'Chemical reaction animation for $topic',
          metadata: {
            'subject': 'chemistry',
            'topic': topic,
            'difficulty': difficulty,
            'animated': true,
            'stepwise': true,
          },
        ));
      }

      if (topic.contains('periodic') || topic.contains('element') || topic.contains('table')) {
        content.add(MultimediaContent(
          id: 'chemistry_periodic_${DateTime.now().millisecondsSinceEpoch}',
          type: MultimediaType.image,
          url: await _generatePeriodicTableSection(topic, difficulty),
          description: 'Interactive periodic table section for $topic',
          metadata: {
            'subject': 'chemistry',
            'topic': topic,
            'difficulty': difficulty,
            'interactive': true,
            'highlighted': true,
          },
        ));
      }
    }

    return content;
  }

  /// Generate biology-specific multimedia content
  Future<List<MultimediaContent>> _generateBiologyMultimedia(
    String topic,
    String difficulty,
    MultimediaType preferredType,
  ) async {
    List<MultimediaContent> content = [];

    if (preferredType == MultimediaType.image || preferredType == MultimediaType.animation) {
      // Biological diagrams and processes
      if (topic.contains('cell') || topic.contains('organelle') || topic.contains('membrane')) {
        content.add(MultimediaContent(
          id: 'biology_cell_${DateTime.now().millisecondsSinceEpoch}',
          type: MultimediaType.image,
          url: await _generateCellDiagram(topic, difficulty),
          description: 'Detailed cell diagram for $topic',
          metadata: {
            'subject': 'biology',
            'topic': topic,
            'difficulty': difficulty,
            'labeled': true,
            'zoomable': true,
          },
        ));
      }

      if (topic.contains('dna') || topic.contains('rna') || topic.contains('protein')) {
        content.add(MultimediaContent(
          id: 'biology_dna_${DateTime.now().millisecondsSinceEpoch}',
          type: MultimediaType.animation,
          url: await _generateDNAAnimation(topic, difficulty),
          description: 'DNA/RNA process animation for $topic',
          metadata: {
            'subject': 'biology',
            'topic': topic,
            'difficulty': difficulty,
            'molecular': true,
            'process': true,
          },
        ));
      }

      if (topic.contains('ecosystem') || topic.contains('food') || topic.contains('cycle')) {
        content.add(MultimediaContent(
          id: 'biology_ecosystem_${DateTime.now().millisecondsSinceEpoch}',
          type: MultimediaType.image,
          url: await _generateEcosystemDiagram(topic, difficulty),
          description: 'Ecosystem diagram for $topic',
          metadata: {
            'subject': 'biology',
            'topic': topic,
            'difficulty': difficulty,
            'flowchart': true,
            'interactive': true,
          },
        ));
      }
    }

    return content;
  }

  /// Generate computer science-specific multimedia content
  Future<List<MultimediaContent>> _generateComputerScienceMultimedia(
    String topic,
    String difficulty,
    MultimediaType preferredType,
  ) async {
    List<MultimediaContent> content = [];

    if (preferredType == MultimediaType.animation || preferredType == MultimediaType.image) {
      // Algorithm visualizations and code examples
      if (topic.contains('algorithm') || topic.contains('sort') || topic.contains('search')) {
        content.add(MultimediaContent(
          id: 'cs_algorithm_${DateTime.now().millisecondsSinceEpoch}',
          type: MultimediaType.animation,
          url: await _generateAlgorithmVisualization(topic, difficulty),
          description: 'Algorithm visualization for $topic',
          metadata: {
            'subject': 'computer_science',
            'topic': topic,
            'difficulty': difficulty,
            'stepByStep': true,
            'interactive': true,
          },
        ));
      }

      if (topic.contains('data structure') || topic.contains('tree') || topic.contains('graph')) {
        content.add(MultimediaContent(
          id: 'cs_datastructure_${DateTime.now().millisecondsSinceEpoch}',
          type: MultimediaType.animation,
          url: await _generateDataStructureVisualization(topic, difficulty),
          description: 'Data structure visualization for $topic',
          metadata: {
            'subject': 'computer_science',
            'topic': topic,
            'difficulty': difficulty,
            'interactive': true,
            'manipulatable': true,
          },
        ));
      }

      if (topic.contains('code') || topic.contains('program') || topic.contains('syntax')) {
        content.add(MultimediaContent(
          id: 'cs_code_${DateTime.now().millisecondsSinceEpoch}',
          type: MultimediaType.code,
          url: await _generateCodeExample(topic, difficulty),
          description: 'Code example for $topic',
          metadata: {
            'subject': 'computer_science',
            'topic': topic,
            'difficulty': difficulty,
            'executable': true,
            'highlighted': true,
          },
        ));
      }
    }

    return content;
  }

  /// Generate generic multimedia content
  Future<List<MultimediaContent>> _generateGenericMultimedia(
    String topic,
    String difficulty,
    MultimediaType preferredType,
  ) async {
    List<MultimediaContent> content = [];

    // Generate basic diagrams and illustrations
    content.add(MultimediaContent(
      id: 'generic_diagram_${DateTime.now().millisecondsSinceEpoch}',
      type: MultimediaType.image,
      url: await _generateGenericDiagram(topic, difficulty),
      description: 'Diagram for $topic',
      metadata: {
        'topic': topic,
        'difficulty': difficulty,
        'generic': true,
      },
    ));

    return content;
  }

  /// Cache multimedia content for offline access
  Future<void> _cacheMultimediaContent(List<MultimediaContent> content) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheDir = await getApplicationCacheDirectory();
      
      for (final item in content) {
        final cacheKey = '$_cachePrefix${item.id}';
        final cacheData = {
          'id': item.id,
          'type': item.type.toString(),
          'url': item.url,
          'description': item.description,
          'metadata': item.metadata,
          'cachedAt': DateTime.now().toIso8601String(),
        };
        
        await prefs.setString(cacheKey, json.encode(cacheData));
        
        // Cache the actual file if it's a local asset
        if (item.url.startsWith('assets/')) {
          await _cacheAssetFile(item.url, cacheDir.path);
        }
      }
      
      // Clean up old cache entries
      await _cleanupCache();
    } catch (e) {
      print('Error caching multimedia content: $e');
    }
  }

  /// Cache asset file to local storage
  Future<void> _cacheAssetFile(String assetPath, String cacheDir) async {
    try {
      final data = await rootBundle.load(assetPath);
      final fileName = assetPath.split('/').last;
      final file = File('$cacheDir/$fileName');
      await file.writeAsBytes(data.buffer.asUint8List());
    } catch (e) {
      print('Error caching asset file: $e');
    }
  }

  /// Clean up expired cache entries
  Future<void> _cleanupCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      final now = DateTime.now();
      
      for (final key in keys) {
        final cacheData = prefs.getString(key);
        if (cacheData != null) {
          final data = json.decode(cacheData);
          final cachedAt = DateTime.parse(data['cachedAt']);
          
          if (now.difference(cachedAt) > _cacheExpiry) {
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      print('Error cleaning up cache: $e');
    }
  }

  /// Get cached multimedia content
  Future<MultimediaContent?> getCachedContent(String contentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$contentId';
      final cacheData = prefs.getString(cacheKey);
      
      if (cacheData != null) {
        final data = json.decode(cacheData);
        final cachedAt = DateTime.parse(data['cachedAt']);
        
        // Check if cache is still valid
        if (DateTime.now().difference(cachedAt) <= _cacheExpiry) {
          return MultimediaContent(
            id: data['id'],
            type: MultimediaType.values.firstWhere(
              (e) => e.toString() == data['type'],
            ),
            url: data['url'],
            description: data['description'],
            metadata: Map<String, dynamic>.from(data['metadata']),
          );
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting cached content: $e');
      return null;
    }
  }

  /// Generate placeholder methods for different content types
  Future<String> _generateGeometryDiagram(String topic, String difficulty) async {
    // In a real implementation, this would generate SVG diagrams
    return 'assets/diagrams/geometry/${topic.toLowerCase().replaceAll(' ', '_')}_$difficulty.svg';
  }

  Future<String> _generateFunctionGraph(String topic, String difficulty) async {
    return 'assets/animations/math/function_${topic.toLowerCase().replaceAll(' ', '_')}_$difficulty.json';
  }

  Future<String> _generateStepByStepSolution(String topic, String difficulty) async {
    return 'assets/animations/math/steps_${topic.toLowerCase().replaceAll(' ', '_')}_$difficulty.json';
  }

  Future<String> _generateMathAudioExplanation(String topic, String difficulty) async {
    return 'assets/audio/math/${topic.toLowerCase().replaceAll(' ', '_')}_$difficulty.mp3';
  }

  Future<String> _generateMotionSimulation(String topic, String difficulty) async {
    return 'assets/animations/physics/motion_${topic.toLowerCase().replaceAll(' ', '_')}_$difficulty.json';
  }

  Future<String> _generateWaveAnimation(String topic, String difficulty) async {
    return 'assets/animations/physics/wave_${topic.toLowerCase().replaceAll(' ', '_')}_$difficulty.json';
  }

  Future<String> _generateCircuitDiagram(String topic, String difficulty) async {
    return 'assets/diagrams/physics/circuit_${topic.toLowerCase().replaceAll(' ', '_')}_$difficulty.svg';
  }

  Future<String> _generateMolecularStructure(String topic, String difficulty) async {
    return 'assets/models/chemistry/molecule_${topic.toLowerCase().replaceAll(' ', '_')}_$difficulty.json';
  }

  Future<String> _generateReactionAnimation(String topic, String difficulty) async {
    return 'assets/animations/chemistry/reaction_${topic.toLowerCase().replaceAll(' ', '_')}_$difficulty.json';
  }

  Future<String> _generatePeriodicTableSection(String topic, String difficulty) async {
    return 'assets/diagrams/chemistry/periodic_${topic.toLowerCase().replaceAll(' ', '_')}_$difficulty.svg';
  }

  Future<String> _generateCellDiagram(String topic, String difficulty) async {
    return 'assets/diagrams/biology/cell_${topic.toLowerCase().replaceAll(' ', '_')}_$difficulty.svg';
  }

  Future<String> _generateDNAAnimation(String topic, String difficulty) async {
    return 'assets/animations/biology/dna_${topic.toLowerCase().replaceAll(' ', '_')}_$difficulty.json';
  }

  Future<String> _generateEcosystemDiagram(String topic, String difficulty) async {
    return 'assets/diagrams/biology/ecosystem_${topic.toLowerCase().replaceAll(' ', '_')}_$difficulty.svg';
  }

  Future<String> _generateAlgorithmVisualization(String topic, String difficulty) async {
    return 'assets/animations/cs/algorithm_${topic.toLowerCase().replaceAll(' ', '_')}_$difficulty.json';
  }

  Future<String> _generateDataStructureVisualization(String topic, String difficulty) async {
    return 'assets/animations/cs/datastructure_${topic.toLowerCase().replaceAll(' ', '_')}_$difficulty.json';
  }

  Future<String> _generateCodeExample(String topic, String difficulty) async {
    return 'assets/code/cs/${topic.toLowerCase().replaceAll(' ', '_')}_$difficulty.dart';
  }

  Future<String> _generateGenericDiagram(String topic, String difficulty) async {
    return 'assets/diagrams/generic/${topic.toLowerCase().replaceAll(' ', '_')}_$difficulty.svg';
  }

  /// Get multimedia content statistics
  Future<Map<String, int>> getMultimediaStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      
      Map<String, int> stats = {
        'totalCached': 0,
        'images': 0,
        'animations': 0,
        'audio': 0,
        'code': 0,
      };
      
      for (final key in keys) {
        final cacheData = prefs.getString(key);
        if (cacheData != null) {
          final data = json.decode(cacheData);
          stats['totalCached'] = (stats['totalCached'] ?? 0) + 1;
          
          final type = data['type'].toString().split('.').last;
          stats[type] = (stats[type] ?? 0) + 1;
        }
      }
      
      return stats;
    } catch (e) {
      print('Error getting multimedia statistics: $e');
      return {};
    }
  }

  /// Clear all multimedia cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      // Also clear cached files
      final cacheDir = await getApplicationCacheDirectory();
      final files = cacheDir.listSync();
      for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Error clearing multimedia cache: $e');
    }
  }
}