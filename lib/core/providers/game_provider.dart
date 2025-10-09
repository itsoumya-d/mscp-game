import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../controllers/game_controller.dart';
import '../services/game_session_service.dart';
import '../services/game_save_service.dart';
import '../services/analytics_service.dart';
import '../services/progressive_difficulty_service.dart';
import '../services/unified_xp_service.dart';
import '../services/unified_level_service.dart';
import '../services/level_preloader_service.dart';
import '../services/unlock_animation_service.dart';

final gameSessionServiceProvider = Provider<GameSessionService>((ref) {
  return GameSessionService();
});

final gameSaveServiceProvider = Provider<GameSaveService>((ref) {
  return GameSaveService();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

final progressiveDifficultyServiceProvider = Provider<ProgressiveDifficultyService>((ref) {
  return ProgressiveDifficultyService.getInstance();
});

final unifiedXPServiceProvider = Provider<UnifiedXPService>((ref) {
  return UnifiedXPService.getInstance();
});

final unifiedLevelServiceProvider = Provider<UnifiedLevelService>((ref) {
  return UnifiedLevelService.getInstance();
});

final levelPreloaderServiceProvider = Provider<LevelPreloaderService>((ref) {
  return LevelPreloaderService.getInstance();
});

final unlockAnimationServiceProvider = Provider<UnlockAnimationService>((ref) {
  return UnlockAnimationService.instance;
});

final gameControllerProvider = ChangeNotifierProvider<GameController>((ref) {
  return GameController(
    gameSessionService: ref.read(gameSessionServiceProvider),
    gameSaveService: ref.read(gameSaveServiceProvider),
    analyticsService: ref.read(analyticsServiceProvider),
    progressiveDifficultyService: ref.read(progressiveDifficultyServiceProvider),
    unifiedXPService: ref.read(unifiedXPServiceProvider),
    levelService: ref.read(unifiedLevelServiceProvider),
    levelPreloaderService: ref.read(levelPreloaderServiceProvider),
    unlockAnimationService: ref.read(unlockAnimationServiceProvider),
  );
});