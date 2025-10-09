import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/achievement_service.dart';

final achievementServiceProvider = Provider<AchievementService>((ref) {
  return AchievementService();
});