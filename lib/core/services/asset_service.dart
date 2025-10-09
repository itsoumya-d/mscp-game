import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/subject.dart';

/// Asset Service - Centralized asset management
/// Provides consistent access to SVG assets, icons, and other visual elements
class AssetService {
  static const String _basePath = 'assets';
  static const String _iconsPath = '$_basePath/icons';
  static const String _subjectsPath = '$_basePath/subjects';
  static const String _imagesPath = '$_basePath/images';
  static const String _achievementsPath = '$_basePath/achievements';
  static const String _illustrationsPath = '$_basePath/illustrations';
  static const String _animationsPath = '$_basePath/animations';

  // Core app icons
  static const String logo = '$_iconsPath/logo.svg';
  static const String defaultAvatar = '$_iconsPath/default_avatar.svg';
  static const String studypalIcon = '$_iconsPath/studypal_icon.svg';

  // Subject icons mapping
  static const Map<SubjectType, String> _subjectIcons = {
    SubjectType.math: '$_subjectsPath/math.svg',
    SubjectType.physics: '$_subjectsPath/physics.svg',
    SubjectType.chemistry: '$_subjectsPath/chemistry.svg',
    SubjectType.biology: '$_subjectsPath/biology.svg',
    SubjectType.science: '$_subjectsPath/science.svg',
    SubjectType.english: '$_subjectsPath/english.svg',
    SubjectType.art: '$_subjectsPath/art.svg',
    SubjectType.music: '$_subjectsPath/music.svg',
    SubjectType.physicalEducation: '$_subjectsPath/physical_education.svg',
    SubjectType.computerScience: '$_subjectsPath/computer_science.svg',
    SubjectType.geography: '$_subjectsPath/geography.svg',
    SubjectType.history: '$_subjectsPath/history.svg',
  };

  // Core images
  static const String backgroundPattern = '$_imagesPath/background_pattern.svg';
  static const String celebrationBg = '$_imagesPath/celebration_bg.svg';
  static const String gameBackground = '$_imagesPath/game_background.svg';

  // Educational illustrations
  static const String mathConcepts = '$_illustrationsPath/math_concepts.svg';
  static const String scienceExperiment = '$_illustrationsPath/science_experiment.svg';
  static const String studySession = '$_illustrationsPath/study_session.svg';
  static const String achievement = '$_illustrationsPath/achievement.svg';
  static const String learning = '$_illustrationsPath/learning.svg';
  static const String progress = '$_illustrationsPath/progress.svg';
  static const String collaboration = '$_illustrationsPath/collaboration.svg';
  static const String creativity = '$_illustrationsPath/creativity.svg';
  static const String discovery = '$_illustrationsPath/discovery.svg';
  static const String innovation = '$_illustrationsPath/innovation.svg';

  // Animation files
  static const Map<String, String> animations = {
    'loading': '$_animationsPath/loading.json',
    'success': '$_animationsPath/success.json',
    'celebration': '$_animationsPath/celebration.json',
    'levelUp': '$_animationsPath/level_up.json',
    'achievement': '$_animationsPath/achievement.json',
    'error': '$_animationsPath/error.json',
    'thinking': '$_animationsPath/thinking.json',
    'sparkles': '$_animationsPath/sparkles.json',
  };

  /// Get subject icon path
  static String getSubjectIconPath(SubjectType subjectType) {
    return _subjectIcons[subjectType] ?? _subjectsPath + '/science.svg';
  }

  /// Get subject icon widget
  static Widget getSubjectIcon(
    SubjectType subjectType, {
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    final iconPath = getSubjectIconPath(subjectType);
    return SvgPicture.asset(
      iconPath,
      width: width,
      height: height,
      colorFilter: color != null 
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
      fit: fit,
      placeholderBuilder: (context) => _buildFallbackIcon(subjectType, width, height, color),
    );
  }

  /// Get achievement badge path
  static String getAchievementBadgePath(String achievementId) {
    return '$_achievementsPath/$achievementId.svg';
  }

  /// Get achievement badge widget
  static Widget getAchievementBadge(
    String achievementId, {
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    final badgePath = getAchievementBadgePath(achievementId);
    return SvgPicture.asset(
      badgePath,
      width: width,
      height: height,
      colorFilter: color != null 
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
      fit: fit,
      placeholderBuilder: (context) => _buildFallbackBadge(width, height, color),
    );
  }

  /// Get core app icon widget
  static Widget getCoreIcon(
    String iconPath, {
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    return SvgPicture.asset(
      iconPath,
      width: width,
      height: height,
      colorFilter: color != null 
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
      fit: fit,
      placeholderBuilder: (context) => _buildFallbackIcon(null, width, height, color),
    );
  }

  /// Get illustration widget
  static Widget getIllustration(
    String illustrationPath, {
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    return SvgPicture.asset(
      illustrationPath,
      width: width,
      height: height,
      colorFilter: color != null 
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
      fit: fit,
      placeholderBuilder: (context) => _buildFallbackIllustration(width, height, color),
    );
  }

  /// Get avatar icon widget
  static Widget getAvatarIcon(
    String avatarId, {
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    final avatarPath = '$_iconsPath/$avatarId.svg';
    return SvgPicture.asset(
      avatarPath,
      width: width,
      height: height,
      colorFilter: color != null 
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
      fit: fit,
      placeholderBuilder: (context) => _buildFallbackAvatar(width, height, color),
    );
  }

  /// Get achievement icon widget
  static Widget getAchievementIcon(
    String achievementId, {
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    final achievementPath = '$_achievementsPath/$achievementId.svg';
    return SvgPicture.asset(
      achievementPath,
      width: width,
      height: height,
      colorFilter: color != null 
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
      fit: fit,
      placeholderBuilder: (context) => _buildFallbackBadge(width, height, color),
    );
  }

  /// Get animation asset path
  static String getAnimationPath(String animationType) {
    return animations[animationType] ?? animations['loading']!;
  }

  /// Build fallback icon for subjects
  static Widget _buildFallbackIcon(
    SubjectType? subjectType,
    double? width,
    double? height,
    Color? color,
  ) {
    IconData iconData;
    
    if (subjectType != null) {
      switch (subjectType) {
        case SubjectType.math:
          iconData = Icons.calculate;
          break;
        case SubjectType.physics:
          iconData = Icons.science;
          break;
        case SubjectType.chemistry:
          iconData = Icons.biotech;
          break;
        case SubjectType.biology:
          iconData = Icons.eco;
          break;
        case SubjectType.science:
          iconData = Icons.science_outlined;
          break;
        case SubjectType.english:
          iconData = Icons.menu_book;
          break;
        case SubjectType.art:
          iconData = Icons.palette;
          break;
        case SubjectType.music:
          iconData = Icons.music_note;
          break;
        case SubjectType.physicalEducation:
          iconData = Icons.sports;
          break;
        case SubjectType.computerScience:
          iconData = Icons.computer;
          break;
        case SubjectType.geography:
          iconData = Icons.public;
          break;
        case SubjectType.history:
          iconData = Icons.history_edu;
          break;
      }
    } else {
      iconData = Icons.school;
    }

    return Icon(
      iconData,
      size: width ?? height ?? 24,
      color: color,
    );
  }

  /// Build fallback avatar
  static Widget _buildFallbackAvatar(
    double? width,
    double? height,
    Color? color,
  ) {
    return Icon(
      Icons.person,
      size: width ?? height ?? 24,
      color: color ?? Colors.grey,
    );
  }

  /// Build fallback badge
  static Widget _buildFallbackBadge(
    double? width,
    double? height,
    Color? color,
  ) {
    return Icon(
      Icons.military_tech,
      size: width ?? height ?? 24,
      color: color ?? Colors.amber,
    );
  }

  /// Build fallback illustration
  static Widget _buildFallbackIllustration(
    double? width,
    double? height,
    Color? color,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image,
        size: (width ?? height ?? 100) * 0.5,
        color: color ?? Colors.grey,
      ),
    );
  }

  /// Preload critical assets
  static Future<void> preloadCriticalAssets(BuildContext context) async {
    final List<String> criticalAssets = [
      logo,
      defaultAvatar,
      ...animations.values,
    ];

    // Add subject icons
    criticalAssets.addAll(_subjectIcons.values);

    // Preload SVG assets
    for (final assetPath in criticalAssets) {
      if (assetPath.endsWith('.svg')) {
        try {
          // Simple preload by creating the widget
          SvgPicture.asset(assetPath);
        } catch (e) {
          // Silently handle missing assets
          debugPrint('Failed to preload asset: $assetPath');
        }
      }
    }
  }

  /// Check if asset exists
  static Future<bool> assetExists(String assetPath) async {
    try {
      await DefaultAssetBundle.of(
        // This is a workaround since we don't have context here
        WidgetsBinding.instance.rootElement!,
      ).load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get subject color
  static Color getSubjectColor(SubjectType subjectType) {
    switch (subjectType) {
      case SubjectType.math:
        return Colors.blue;
      case SubjectType.physics:
        return Colors.purple;
      case SubjectType.chemistry:
        return Colors.green;
      case SubjectType.biology:
        return Colors.teal;
      case SubjectType.science:
        return Colors.indigo;
      case SubjectType.english:
        return Colors.orange;
      case SubjectType.art:
        return Colors.pink;
      case SubjectType.music:
        return Colors.deepPurple;
      case SubjectType.physicalEducation:
        return Colors.red;
      case SubjectType.computerScience:
        return Colors.cyan;
      case SubjectType.geography:
        return Colors.brown;
      case SubjectType.history:
        return Colors.amber;
    }
  }
}