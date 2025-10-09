import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'firebase_service.dart';
import 'game_save_service.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final Connectivity _connectivity = Connectivity();
  
  Timer? _syncTimer;
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;

  // Initialize the sync service
  Future<void> initialize() async {
    // Start periodic sync every 5 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) => syncAll());
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        // Connection restored, sync immediately
        syncAll();
      }
    });

    // Initial sync
    await syncAll();
  }

  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  // Sync all data types
  Future<void> syncAll() async {
    if (_isSyncing || !_firebaseService.isLoggedIn) return;
    
    _isSyncing = true;
    try {
      final isConnected = await _firebaseService.isConnected();
      if (!isConnected) return;

      await Future.wait([
        syncGameSessions(),
        syncUserProgress(),
        syncAchievements(),
        syncSettings(),
      ]);
      
      await _updateLastSyncTime();
    } catch (e) {
      print('Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Sync game sessions
  Future<void> syncGameSessions() async {
    try {
      // Upload offline sessions
      await _firebaseService.syncOfflineData();
      
      // Download recent sessions from cloud
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt('last_session_sync') ?? 0;
      
      // For now, we'll just mark the sync time
      // In a full implementation, you'd fetch sessions newer than lastSync
      await prefs.setInt('last_session_sync', DateTime.now().millisecondsSinceEpoch);
      
    } catch (e) {
      print('Game session sync failed: $e');
    }
  }

  // Sync user progress
  Future<void> syncUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get local progress data
      final localXP = prefs.getInt('total_xp') ?? 0;
      final localLevel = prefs.getInt('current_level') ?? 1;
      final localStreak = prefs.getInt('current_streak') ?? 0;
      
      // Get cloud progress
      final cloudProfile = await _firebaseService.getUserProfile();
      
      if (cloudProfile != null) {
        final cloudXP = cloudProfile['totalXP'] ?? 0;
        final cloudLevel = cloudProfile['currentLevel'] ?? 1;
        final cloudStreak = cloudProfile['streak'] ?? 0;
        
        // Use the higher values (in case of offline progress)
        final maxXP = localXP > cloudXP ? localXP : cloudXP;
        final maxLevel = localLevel > cloudLevel ? localLevel : cloudLevel;
        final maxStreak = localStreak > cloudStreak ? localStreak : cloudStreak;
        
        // Update both local and cloud with max values
        await prefs.setInt('total_xp', maxXP);
        await prefs.setInt('current_level', maxLevel);
        await prefs.setInt('current_streak', maxStreak);
        
        await _firebaseService.updateUserProfile({
          'totalXP': maxXP,
          'currentLevel': maxLevel,
          'streak': maxStreak,
        });
      }
    } catch (e) {
      print('User progress sync failed: $e');
    }
  }

  // Sync achievements
  Future<void> syncAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get local achievements
      final localAchievementsJson = prefs.getString('achievements') ?? '[]';
      final List<dynamic> localAchievements = jsonDecode(localAchievementsJson);
      
      // Get cloud achievements
      final cloudAchievements = await _firebaseService.getUserAchievements();
      
      // Merge achievements (avoid duplicates)
      final Set<String> allAchievementIds = {};
      final List<Map<String, dynamic>> mergedAchievements = [];
      
      // Add cloud achievements
      for (final achievement in cloudAchievements) {
        final id = achievement['achievementId'] as String;
        if (!allAchievementIds.contains(id)) {
          allAchievementIds.add(id);
          mergedAchievements.add(achievement);
        }
      }
      
      // Add local achievements that aren't in cloud
      for (final achievement in localAchievements) {
        final id = achievement['achievementId'] as String;
        if (!allAchievementIds.contains(id)) {
          allAchievementIds.add(id);
          mergedAchievements.add(achievement);
          
          // Upload to cloud
          await _firebaseService.unlockAchievement(id, achievement);
        }
      }
      
      // Update local storage
      await prefs.setString('achievements', jsonEncode(mergedAchievements));
      
    } catch (e) {
      print('Achievement sync failed: $e');
    }
  }

  // Sync user settings
  Future<void> syncSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get local settings
      final localSettings = {
        'notifications': prefs.getBool('notifications_enabled') ?? true,
        'soundEnabled': prefs.getBool('sound_enabled') ?? true,
        'darkMode': prefs.getBool('dark_mode') ?? true,
        'language': prefs.getString('language') ?? 'en',
      };
      
      // Get cloud profile
      final cloudProfile = await _firebaseService.getUserProfile();
      
      if (cloudProfile != null) {
        final cloudSettings = cloudProfile['preferences'] as Map<String, dynamic>? ?? {};
        
        // Use local settings as priority, but fill gaps from cloud
        final mergedSettings = {...cloudSettings, ...localSettings};
        
        // Update both local and cloud
        await prefs.setBool('notifications_enabled', mergedSettings['notifications'] ?? true);
        await prefs.setBool('sound_enabled', mergedSettings['soundEnabled'] ?? true);
        await prefs.setBool('dark_mode', mergedSettings['darkMode'] ?? true);
        await prefs.setString('language', mergedSettings['language'] ?? 'en');
        
        await _firebaseService.updateUserProfile({
          'preferences': mergedSettings,
        });
      }
    } catch (e) {
      print('Settings sync failed: $e');
    }
  }

  // Save data with automatic cloud sync
  Future<void> saveGameSessionWithSync(GameSession session) async {
    try {
      final isConnected = await _firebaseService.isConnected();
      
      if (isConnected && _firebaseService.isLoggedIn) {
        // Save directly to cloud
        await _firebaseService.saveGameSession(session);
      } else {
        // Save offline for later sync
        await _firebaseService.saveOfflineGameSession(session);
      }
      
      // Always save locally as backup
      await _saveGameSessionLocally(session);
      
    } catch (e) {
      print('Failed to save game session: $e');
      // Fallback to local save
      await _saveGameSessionLocally(session);
    }
  }

  Future<void> _saveGameSessionLocally(GameSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString('local_game_sessions') ?? '[]';
    final List<dynamic> sessions = jsonDecode(existingJson);
    
    sessions.add(session.toJson());
    
    // Keep only last 100 sessions locally
    if (sessions.length > 100) {
      sessions.removeRange(0, sessions.length - 100);
    }
    
    await prefs.setString('local_game_sessions', jsonEncode(sessions));
  }

  // Update progress with sync
  Future<void> updateProgressWithSync(Map<String, dynamic> progressData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Update locally first
      for (final entry in progressData.entries) {
        if (entry.value is int) {
          await prefs.setInt(entry.key, entry.value);
        } else if (entry.value is bool) {
          await prefs.setBool(entry.key, entry.value);
        } else if (entry.value is String) {
          await prefs.setString(entry.key, entry.value);
        }
      }
      
      // Sync to cloud if connected
      final isConnected = await _firebaseService.isConnected();
      if (isConnected && _firebaseService.isLoggedIn) {
        await _firebaseService.updateUserProfile(progressData);
      }
      
    } catch (e) {
      print('Failed to update progress: $e');
    }
  }

  // Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt('last_full_sync') ?? 0;
    final offlineSessionsJson = prefs.getString('offline_game_sessions');
    final offlineSessionsCount = offlineSessionsJson != null 
        ? (jsonDecode(offlineSessionsJson) as List).length 
        : 0;
    
    return {
      'lastSync': DateTime.fromMillisecondsSinceEpoch(lastSync),
      'isConnected': await _firebaseService.isConnected(),
      'isLoggedIn': _firebaseService.isLoggedIn,
      'pendingOfflineSessions': offlineSessionsCount,
      'isSyncing': _isSyncing,
    };
  }

  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_full_sync', DateTime.now().millisecondsSinceEpoch);
  }

  // Force sync (for manual sync button)
  Future<bool> forcSync() async {
    if (_isSyncing) return false;
    
    try {
      await syncAll();
      return true;
    } catch (e) {
      print('Force sync failed: $e');
      return false;
    }
  }
}