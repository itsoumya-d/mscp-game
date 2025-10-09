import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import '../models/subject.dart';

/// Service for managing comprehensive lesson storage with robust indexing
/// Handles storage, retrieval, and management of lessons containing all 7 question types
class ComprehensiveLessonStorageService {
  static const String _lessonsIndexKey = 'comprehensive_lessons_index';
  static const String _lessonDataPrefix = 'comprehensive_lesson_';
  static const String _subjectIndexPrefix = 'subject_index_';
  static const String _skillIndexPrefix = 'skill_index_';
  static const String _typeIndexPrefix = 'type_index_';
  static const String _metadataKey = 'comprehensive_lessons_metadata';
  
  // Storage limits and configuration
  static const int maxLessonsPerSubject = 50;
  static const int maxTotalLessons = 500;
  static const Duration lessonExpiration = Duration(days: 30);
  static const Duration indexRebuildInterval = Duration(days: 7);

  /// Store a comprehensive lesson with full indexing
  Future<String> storeComprehensiveLesson({
    required SubjectType subject,
    required String skillId,
    required String skillName,
    required List<Question> questions,
    required int difficulty,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validate lesson completeness
      final validation = await _validateLessonCompleteness(questions);
      if (!validation['isComplete']) {
        throw Exception('Lesson incomplete: ${validation['missingTypes']}');
      }

      final prefs = await SharedPreferences.getInstance();
      final lessonId = _generateLessonId(subject, skillId, difficulty);
      
      // Create lesson data
      final lessonData = {
        'id': lessonId,
        'subject': subject.name,
        'skillId': skillId,
        'skillName': skillName,
        'difficulty': difficulty,
        'questions': questions.map((q) => q.toJson()).toList(),
        'questionTypes': questions.map((q) => q.type.name).toList(),
        'createdAt': DateTime.now().toIso8601String(),
        'lastAccessed': DateTime.now().toIso8601String(),
        'accessCount': 0,
        'metadata': metadata ?? {},
        'version': '1.0',
      };

      // Store lesson data
      final lessonKey = '$_lessonDataPrefix$lessonId';
      await prefs.setString(lessonKey, jsonEncode(lessonData));

      // Update indexes
      await _updateIndexes(lessonId, lessonData);

      // Update metadata
      await _updateStorageMetadata();

      // Cleanup if needed
      await _performMaintenanceIfNeeded();

      return lessonId;

    } catch (e) {
      print('Error storing comprehensive lesson: $e');
      rethrow;
    }
  }

  /// Retrieve a comprehensive lesson by ID
  Future<Map<String, dynamic>?> getComprehensiveLesson(String lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lessonKey = '$_lessonDataPrefix$lessonId';
      final lessonDataJson = prefs.getString(lessonKey);

      if (lessonDataJson == null) return null;

      final lessonData = jsonDecode(lessonDataJson) as Map<String, dynamic>;
      
      // Check if lesson has expired
      final createdAt = DateTime.parse(lessonData['createdAt']);
      if (DateTime.now().difference(createdAt) > lessonExpiration) {
        await _removeLesson(lessonId);
        return null;
      }

      // Update access tracking
      lessonData['lastAccessed'] = DateTime.now().toIso8601String();
      lessonData['accessCount'] = (lessonData['accessCount'] ?? 0) + 1;
      await prefs.setString(lessonKey, jsonEncode(lessonData));

      return lessonData;

    } catch (e) {
      print('Error retrieving lesson $lessonId: $e');
      return null;
    }
  }

  /// Get lessons by subject with pagination
  Future<List<Map<String, dynamic>>> getLessonsBySubject(
    SubjectType subject, {
    int limit = 10,
    int offset = 0,
    String? skillFilter,
    int? difficultyFilter,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subjectIndexKey = '$_subjectIndexPrefix${subject.name}';
      final indexJson = prefs.getString(subjectIndexKey);

      if (indexJson == null) return [];

      final lessonIds = List<String>.from(jsonDecode(indexJson));
      final lessons = <Map<String, dynamic>>[];

      for (final lessonId in lessonIds.skip(offset).take(limit)) {
        final lesson = await getComprehensiveLesson(lessonId);
        if (lesson != null) {
          // Apply filters
          if (skillFilter != null && lesson['skillId'] != skillFilter) continue;
          if (difficultyFilter != null && lesson['difficulty'] != difficultyFilter) continue;
          
          lessons.add(lesson);
        }
      }

      return lessons;

    } catch (e) {
      print('Error getting lessons by subject: $e');
      return [];
    }
  }

  /// Get lessons by skill
  Future<List<Map<String, dynamic>>> getLessonsBySkill(
    String skillId, {
    int limit = 10,
    SubjectType? subjectFilter,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final skillIndexKey = '$_skillIndexPrefix$skillId';
      final indexJson = prefs.getString(skillIndexKey);

      if (indexJson == null) return [];

      final lessonIds = List<String>.from(jsonDecode(indexJson));
      final lessons = <Map<String, dynamic>>[];

      for (final lessonId in lessonIds.take(limit)) {
        final lesson = await getComprehensiveLesson(lessonId);
        if (lesson != null) {
          if (subjectFilter != null && lesson['subject'] != subjectFilter.name) continue;
          lessons.add(lesson);
        }
      }

      return lessons;

    } catch (e) {
      print('Error getting lessons by skill: $e');
      return [];
    }
  }

  /// Get lessons containing specific question types
  Future<List<Map<String, dynamic>>> getLessonsByQuestionTypes(
    List<QuestionType> questionTypes, {
    int limit = 10,
    bool requireAllTypes = false,
  }) async {
    try {
      final lessons = <Map<String, dynamic>>[];
      final targetTypes = questionTypes.map((t) => t.name).toSet();

      for (final questionType in questionTypes) {
        final prefs = await SharedPreferences.getInstance();
        final typeIndexKey = '$_typeIndexPrefix${questionType.name}';
        final indexJson = prefs.getString(typeIndexKey);

        if (indexJson == null) continue;

        final lessonIds = List<String>.from(jsonDecode(indexJson));

        for (final lessonId in lessonIds.take(limit)) {
          final lesson = await getComprehensiveLesson(lessonId);
          if (lesson != null) {
            final lessonTypes = Set<String>.from(lesson['questionTypes']);
            
            if (requireAllTypes) {
              if (targetTypes.every((type) => lessonTypes.contains(type))) {
                lessons.add(lesson);
              }
            } else {
              if (targetTypes.any((type) => lessonTypes.contains(type))) {
                lessons.add(lesson);
              }
            }
          }
        }
      }

      // Remove duplicates and limit results
      final uniqueLessons = <String, Map<String, dynamic>>{};
      for (final lesson in lessons) {
        uniqueLessons[lesson['id']] = lesson;
      }

      return uniqueLessons.values.take(limit).toList();

    } catch (e) {
      print('Error getting lessons by question types: $e');
      return [];
    }
  }

  /// Search lessons with advanced filtering
  Future<List<Map<String, dynamic>>> searchLessons({
    SubjectType? subject,
    String? skillId,
    List<QuestionType>? questionTypes,
    int? minDifficulty,
    int? maxDifficulty,
    DateTime? createdAfter,
    DateTime? createdBefore,
    int limit = 20,
    String? sortBy = 'createdAt',
    bool ascending = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final indexJson = prefs.getString(_lessonsIndexKey);

      if (indexJson == null) return [];

      final allLessonIds = List<String>.from(jsonDecode(indexJson));
      final matchingLessons = <Map<String, dynamic>>[];

      for (final lessonId in allLessonIds) {
        final lesson = await getComprehensiveLesson(lessonId);
        if (lesson == null) continue;

        // Apply filters
        if (subject != null && lesson['subject'] != subject.name) continue;
        if (skillId != null && lesson['skillId'] != skillId) continue;
        if (minDifficulty != null && lesson['difficulty'] < minDifficulty) continue;
        if (maxDifficulty != null && lesson['difficulty'] > maxDifficulty) continue;

        if (createdAfter != null) {
          final createdAt = DateTime.parse(lesson['createdAt']);
          if (createdAt.isBefore(createdAfter)) continue;
        }

        if (createdBefore != null) {
          final createdAt = DateTime.parse(lesson['createdAt']);
          if (createdAt.isAfter(createdBefore)) continue;
        }

        if (questionTypes != null) {
          final lessonTypes = Set<String>.from(lesson['questionTypes']);
          final targetTypes = questionTypes.map((t) => t.name).toSet();
          if (!targetTypes.every((type) => lessonTypes.contains(type))) continue;
        }

        matchingLessons.add(lesson);
      }

      // Sort results
      matchingLessons.sort((a, b) {
        dynamic aValue = a[sortBy];
        dynamic bValue = b[sortBy];

        if (aValue is String && bValue is String) {
          return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
        } else if (aValue is int && bValue is int) {
          return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
        }

        return 0;
      });

      return matchingLessons.take(limit).toList();

    } catch (e) {
      print('Error searching lessons: $e');
      return [];
    }
  }

  /// Get storage statistics and health metrics
  Future<Map<String, dynamic>> getStorageStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataJson = prefs.getString(_metadataKey);
      
      Map<String, dynamic> metadata = {};
      if (metadataJson != null) {
        metadata = jsonDecode(metadataJson);
      }

      final indexJson = prefs.getString(_lessonsIndexKey);
      final totalLessons = indexJson != null ? 
          (jsonDecode(indexJson) as List).length : 0;

      // Calculate subject distribution
      final subjectDistribution = <String, int>{};
      for (final subject in SubjectType.values) {
        final subjectIndexKey = '$_subjectIndexPrefix${subject.name}';
        final subjectIndexJson = prefs.getString(subjectIndexKey);
        if (subjectIndexJson != null) {
          subjectDistribution[subject.name] = 
              (jsonDecode(subjectIndexJson) as List).length;
        }
      }

      // Calculate question type coverage
      final typeCoverage = <String, int>{};
      for (final type in QuestionType.values) {
        final typeIndexKey = '$_typeIndexPrefix${type.name}';
        final typeIndexJson = prefs.getString(typeIndexKey);
        if (typeIndexJson != null) {
          typeCoverage[type.name] = 
              (jsonDecode(typeIndexJson) as List).length;
        }
      }

      return {
        'totalLessons': totalLessons,
        'maxCapacity': maxTotalLessons,
        'utilizationPercentage': (totalLessons / maxTotalLessons * 100).round(),
        'subjectDistribution': subjectDistribution,
        'questionTypeCoverage': typeCoverage,
        'lastMaintenance': metadata['lastMaintenance'],
        'lastIndexRebuild': metadata['lastIndexRebuild'],
        'storageHealth': _calculateStorageHealth(totalLessons, metadata),
      };

    } catch (e) {
      print('Error getting storage statistics: $e');
      return {
        'totalLessons': 0,
        'maxCapacity': maxTotalLessons,
        'utilizationPercentage': 0,
        'subjectDistribution': <String, int>{},
        'questionTypeCoverage': <String, int>{},
        'storageHealth': 'unknown',
      };
    }
  }

  /// Validate lesson completeness (all 7 question types)
  Future<Map<String, dynamic>> _validateLessonCompleteness(List<Question> questions) async {
    final presentTypes = questions.map((q) => q.type).toSet();
    final missingTypes = QuestionType.values.where((type) => !presentTypes.contains(type)).toList();
    
    return {
      'isComplete': missingTypes.isEmpty,
      'totalRequired': QuestionType.values.length,
      'totalPresent': presentTypes.length,
      'missingTypes': missingTypes.map((t) => t.name).toList(),
      'presentTypes': presentTypes.map((t) => t.name).toList(),
    };
  }

  /// Generate unique lesson ID
  String _generateLessonId(SubjectType subject, String skillId, int difficulty) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${subject.name}_${skillId}_${difficulty}_$timestamp';
  }

  /// Update all indexes for a lesson
  Future<void> _updateIndexes(String lessonId, Map<String, dynamic> lessonData) async {
    final prefs = await SharedPreferences.getInstance();

    // Update main index
    await _addToIndex(_lessonsIndexKey, lessonId);

    // Update subject index
    final subjectIndexKey = '$_subjectIndexPrefix${lessonData['subject']}';
    await _addToIndex(subjectIndexKey, lessonId);

    // Update skill index
    final skillIndexKey = '$_skillIndexPrefix${lessonData['skillId']}';
    await _addToIndex(skillIndexKey, lessonId);

    // Update question type indexes
    final questionTypes = List<String>.from(lessonData['questionTypes']);
    for (final type in questionTypes) {
      final typeIndexKey = '$_typeIndexPrefix$type';
      await _addToIndex(typeIndexKey, lessonId);
    }
  }

  /// Add lesson ID to an index
  Future<void> _addToIndex(String indexKey, String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final indexJson = prefs.getString(indexKey);
    
    List<String> index = [];
    if (indexJson != null) {
      index = List<String>.from(jsonDecode(indexJson));
    }

    if (!index.contains(lessonId)) {
      index.add(lessonId);
      await prefs.setString(indexKey, jsonEncode(index));
    }
  }

  /// Remove lesson and update indexes
  Future<void> _removeLesson(String lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get lesson data before removal
      final lessonKey = '$_lessonDataPrefix$lessonId';
      final lessonDataJson = prefs.getString(lessonKey);
      
      if (lessonDataJson != null) {
        final lessonData = jsonDecode(lessonDataJson) as Map<String, dynamic>;
        
        // Remove from indexes
        await _removeFromIndex(_lessonsIndexKey, lessonId);
        await _removeFromIndex('$_subjectIndexPrefix${lessonData['subject']}', lessonId);
        await _removeFromIndex('$_skillIndexPrefix${lessonData['skillId']}', lessonId);
        
        final questionTypes = List<String>.from(lessonData['questionTypes']);
        for (final type in questionTypes) {
          await _removeFromIndex('$_typeIndexPrefix$type', lessonId);
        }
      }

      // Remove lesson data
      await prefs.remove(lessonKey);

    } catch (e) {
      print('Error removing lesson $lessonId: $e');
    }
  }

  /// Remove lesson ID from an index
  Future<void> _removeFromIndex(String indexKey, String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final indexJson = prefs.getString(indexKey);
    
    if (indexJson != null) {
      final index = List<String>.from(jsonDecode(indexJson));
      index.remove(lessonId);
      await prefs.setString(indexKey, jsonEncode(index));
    }
  }

  /// Update storage metadata
  Future<void> _updateStorageMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final metadata = {
      'lastUpdated': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
    await prefs.setString(_metadataKey, jsonEncode(metadata));
  }

  /// Perform maintenance if needed
  Future<void> _performMaintenanceIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataJson = prefs.getString(_metadataKey);
      
      Map<String, dynamic> metadata = {};
      if (metadataJson != null) {
        metadata = jsonDecode(metadataJson);
      }

      final now = DateTime.now();
      DateTime? lastMaintenance;
      
      if (metadata['lastMaintenance'] != null) {
        lastMaintenance = DateTime.parse(metadata['lastMaintenance']);
      }

      // Perform maintenance if it's been more than a day
      if (lastMaintenance == null || now.difference(lastMaintenance).inDays >= 1) {
        await _performMaintenance();
        metadata['lastMaintenance'] = now.toIso8601String();
        await prefs.setString(_metadataKey, jsonEncode(metadata));
      }

    } catch (e) {
      print('Error in maintenance check: $e');
    }
  }

  /// Perform storage maintenance
  Future<void> _performMaintenance() async {
    try {
      // Remove expired lessons
      await _removeExpiredLessons();
      
      // Cleanup orphaned indexes
      await _cleanupOrphanedIndexes();
      
      // Enforce storage limits
      await _enforceStorageLimits();

    } catch (e) {
      print('Error during maintenance: $e');
    }
  }

  /// Remove expired lessons
  Future<void> _removeExpiredLessons() async {
    final prefs = await SharedPreferences.getInstance();
    final indexJson = prefs.getString(_lessonsIndexKey);
    
    if (indexJson == null) return;

    final lessonIds = List<String>.from(jsonDecode(indexJson));
    final now = DateTime.now();

    for (final lessonId in lessonIds) {
      final lessonKey = '$_lessonDataPrefix$lessonId';
      final lessonDataJson = prefs.getString(lessonKey);
      
      if (lessonDataJson != null) {
        final lessonData = jsonDecode(lessonDataJson) as Map<String, dynamic>;
        final createdAt = DateTime.parse(lessonData['createdAt']);
        
        if (now.difference(createdAt) > lessonExpiration) {
          await _removeLesson(lessonId);
        }
      }
    }
  }

  /// Cleanup orphaned index entries
  Future<void> _cleanupOrphanedIndexes() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_subjectIndexPrefix) || 
          key.startsWith(_skillIndexPrefix) || 
          key.startsWith(_typeIndexPrefix)) {
        
        final indexJson = prefs.getString(key);
        if (indexJson != null) {
          final index = List<String>.from(jsonDecode(indexJson));
          final validIds = <String>[];
          
          for (final lessonId in index) {
            final lessonKey = '$_lessonDataPrefix$lessonId';
            if (prefs.containsKey(lessonKey)) {
              validIds.add(lessonId);
            }
          }
          
          if (validIds.length != index.length) {
            await prefs.setString(key, jsonEncode(validIds));
          }
        }
      }
    }
  }

  /// Enforce storage limits
  Future<void> _enforceStorageLimits() async {
    final prefs = await SharedPreferences.getInstance();
    final indexJson = prefs.getString(_lessonsIndexKey);
    
    if (indexJson == null) return;

    final lessonIds = List<String>.from(jsonDecode(indexJson));
    
    if (lessonIds.length > maxTotalLessons) {
      // Remove oldest lessons
      final lessonsToRemove = lessonIds.length - maxTotalLessons;
      
      for (int i = 0; i < lessonsToRemove; i++) {
        await _removeLesson(lessonIds[i]);
      }
    }
  }

  /// Calculate storage health status
  String _calculateStorageHealth(int totalLessons, Map<String, dynamic> metadata) {
    final utilization = totalLessons / maxTotalLessons;
    
    if (utilization < 0.5) return 'excellent';
    if (utilization < 0.7) return 'good';
    if (utilization < 0.9) return 'fair';
    return 'critical';
  }

  /// Clear all stored lessons (for testing/reset)
  Future<void> clearAllLessons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final keysToRemove = keys.where((key) => 
          key.startsWith(_lessonDataPrefix) ||
          key.startsWith(_subjectIndexPrefix) ||
          key.startsWith(_skillIndexPrefix) ||
          key.startsWith(_typeIndexPrefix) ||
          key == _lessonsIndexKey ||
          key == _metadataKey
      ).toList();

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

    } catch (e) {
      print('Error clearing all lessons: $e');
    }
  }
}