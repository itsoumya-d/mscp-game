/// Store Compliance Service
/// 
/// Ensures compliance with Play Store and App Store guidelines and requirements.
/// Handles privacy policies, data collection transparency, content ratings,
/// and other compliance-related functionality.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Main service for handling store compliance requirements
class StoreComplianceService {
  static const String _privacyConsentKey = 'privacy_consent_given';
  static const String _dataCollectionConsentKey = 'data_collection_consent';
  static const String _ageVerificationKey = 'age_verification_completed';
  static const String _complianceVersionKey = 'compliance_version';
  static const String _currentComplianceVersion = '1.0.0';

  late SharedPreferences _prefs;
  late PackageInfo _packageInfo;
  late DeviceInfoPlugin _deviceInfo;

  /// Initialize the compliance service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _packageInfo = await PackageInfo.fromPlatform();
    _deviceInfo = DeviceInfoPlugin();
    
    await _checkComplianceVersion();
  }

  /// Check if user has given privacy consent
  bool get hasPrivacyConsent => _prefs.getBool(_privacyConsentKey) ?? false;

  /// Check if user has given data collection consent
  bool get hasDataCollectionConsent => _prefs.getBool(_dataCollectionConsentKey) ?? false;

  /// Check if age verification is completed
  bool get isAgeVerified => _prefs.getBool(_ageVerificationKey) ?? false;

  /// Check if all compliance requirements are met
  bool get isCompliant => hasPrivacyConsent && hasDataCollectionConsent && isAgeVerified;

  /// Record privacy consent
  Future<void> recordPrivacyConsent(bool granted) async {
    await _prefs.setBool(_privacyConsentKey, granted);
    await _logComplianceEvent('privacy_consent', {'granted': granted});
  }

  /// Record data collection consent
  Future<void> recordDataCollectionConsent(bool granted) async {
    await _prefs.setBool(_dataCollectionConsentKey, granted);
    await _logComplianceEvent('data_collection_consent', {'granted': granted});
  }

  /// Record age verification
  Future<void> recordAgeVerification(int age) async {
    final isVerified = age >= 13; // COPPA compliance
    await _prefs.setBool(_ageVerificationKey, isVerified);
    await _logComplianceEvent('age_verification', {
      'age': age,
      'verified': isVerified,
    });
  }

  /// Get privacy policy content
  Future<String> getPrivacyPolicy() async {
    try {
      return await rootBundle.loadString('assets/legal/privacy_policy.txt');
    } catch (e) {
      return _getDefaultPrivacyPolicy();
    }
  }

  /// Get terms of service content
  Future<String> getTermsOfService() async {
    try {
      return await rootBundle.loadString('assets/legal/terms_of_service.txt');
    } catch (e) {
      return _getDefaultTermsOfService();
    }
  }

  /// Get data collection disclosure
  Future<DataCollectionDisclosure> getDataCollectionDisclosure() async {
    return DataCollectionDisclosure(
      personalDataCollected: [
        'User progress and performance data',
        'Game session statistics',
        'Device information for analytics',
        'Crash reports for app improvement',
      ],
      purposeOfCollection: [
        'Personalize learning experience',
        'Track educational progress',
        'Improve app performance',
        'Provide customer support',
      ],
      dataSharing: [
        'Anonymous analytics with third-party services',
        'Crash reports with development team',
        'No personal data sold to third parties',
      ],
      dataRetention: 'Data is retained for as long as the account is active, plus 30 days for backup purposes.',
      userRights: [
        'Right to access personal data',
        'Right to delete personal data',
        'Right to correct inaccurate data',
        'Right to data portability',
      ],
    );
  }

  /// Get content rating information
  ContentRating getContentRating() {
    return ContentRating(
      esrbRating: 'E for Everyone',
      pegiRating: '3+',
      description: 'Educational content suitable for all ages. No violence, inappropriate language, or adult themes.',
      contentDescriptors: [
        'Educational content',
        'Interactive elements',
        'Progress tracking',
      ],
    );
  }

  /// Check app permissions compliance
  Future<PermissionCompliance> checkPermissionCompliance() async {
    final permissions = await _getRequestedPermissions();
    final compliance = PermissionCompliance();

    for (final permission in permissions) {
      final justification = _getPermissionJustification(permission);
      compliance.addPermission(permission, justification);
    }

    return compliance;
  }

  /// Generate compliance report
  Future<ComplianceReport> generateComplianceReport() async {
    final deviceInfo = await _getDeviceInfo();
    final permissions = await checkPermissionCompliance();
    final dataDisclosure = await getDataCollectionDisclosure();

    return ComplianceReport(
      appVersion: _packageInfo.version,
      buildNumber: _packageInfo.buildNumber,
      complianceVersion: _currentComplianceVersion,
      deviceInfo: deviceInfo,
      privacyConsent: hasPrivacyConsent,
      dataCollectionConsent: hasDataCollectionConsent,
      ageVerified: isAgeVerified,
      permissions: permissions,
      dataDisclosure: dataDisclosure,
      contentRating: getContentRating(),
      generatedAt: DateTime.now(),
    );
  }

  /// Validate store listing compliance
  Future<StoreListingCompliance> validateStoreListing() async {
    final compliance = StoreListingCompliance();

    // Check app name compliance
    if (_packageInfo.appName.length > 50) {
      compliance.addIssue('App name exceeds 50 characters');
    }

    // Check for prohibited content
    final prohibitedWords = ['free', 'best', 'top', '#1'];
    for (final word in prohibitedWords) {
      if (_packageInfo.appName.toLowerCase().contains(word.toLowerCase())) {
        compliance.addWarning('App name contains potentially prohibited word: $word');
      }
    }

    // Validate version compliance
    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(_packageInfo.version)) {
      compliance.addIssue('Version format should follow semantic versioning (x.y.z)');
    }

    return compliance;
  }

  /// Handle data deletion request (GDPR/CCPA compliance)
  Future<void> handleDataDeletionRequest() async {
    // Clear all user data
    await _prefs.clear();
    
    // Log the deletion request
    await _logComplianceEvent('data_deletion_request', {
      'timestamp': DateTime.now().toIso8601String(),
      'user_initiated': true,
    });

    // In a real app, this would also:
    // - Delete data from remote servers
    // - Remove user from analytics
    // - Clear cached data
    // - Notify backend services
  }

  /// Export user data (GDPR compliance)
  Future<Map<String, dynamic>> exportUserData() async {
    final userData = <String, dynamic>{};

    // Collect all user data
    final keys = _prefs.getKeys();
    for (final key in keys) {
      final value = _prefs.get(key);
      if (value != null) {
        userData[key] = value;
      }
    }

    // Add metadata
    userData['export_timestamp'] = DateTime.now().toIso8601String();
    userData['app_version'] = _packageInfo.version;
    userData['data_format_version'] = '1.0';

    await _logComplianceEvent('data_export_request', {
      'data_points_exported': userData.length,
    });

    return userData;
  }

  /// Check for compliance updates
  Future<bool> checkForComplianceUpdates() async {
    final currentVersion = _prefs.getString(_complianceVersionKey) ?? '0.0.0';
    return _isNewerVersion(_currentComplianceVersion, currentVersion);
  }

  /// Update compliance to latest version
  Future<void> updateCompliance() async {
    await _prefs.setString(_complianceVersionKey, _currentComplianceVersion);
    
    // Reset consent if major compliance changes
    if (await checkForComplianceUpdates()) {
      await _prefs.setBool(_privacyConsentKey, false);
      await _prefs.setBool(_dataCollectionConsentKey, false);
    }

    await _logComplianceEvent('compliance_updated', {
      'new_version': _currentComplianceVersion,
    });
  }

  // Private helper methods

  Future<void> _checkComplianceVersion() async {
    if (await checkForComplianceUpdates()) {
      await updateCompliance();
    }
  }

  Future<List<String>> _getRequestedPermissions() async {
    // In a real implementation, this would read from AndroidManifest.xml
    // and Info.plist to get actual requested permissions
    return [
      'INTERNET',
      'ACCESS_NETWORK_STATE',
      'WRITE_EXTERNAL_STORAGE',
      'READ_EXTERNAL_STORAGE',
    ];
  }

  String _getPermissionJustification(String permission) {
    const justifications = {
      'INTERNET': 'Required for syncing progress and downloading educational content',
      'ACCESS_NETWORK_STATE': 'Used to check network connectivity for online features',
      'WRITE_EXTERNAL_STORAGE': 'Needed to save game progress and educational materials',
      'READ_EXTERNAL_STORAGE': 'Required to access saved educational content',
      'CAMERA': 'Used for AR learning features and photo-based questions',
      'MICROPHONE': 'Needed for voice-based learning activities',
    };

    return justifications[permission] ?? 'Permission used for core app functionality';
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceData = <String, dynamic>{};

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      deviceData['platform'] = 'Android';
      deviceData['version'] = androidInfo.version.release;
      deviceData['sdk_int'] = androidInfo.version.sdkInt;
      deviceData['manufacturer'] = androidInfo.manufacturer;
      deviceData['model'] = androidInfo.model;
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      deviceData['platform'] = 'iOS';
      deviceData['version'] = iosInfo.systemVersion;
      deviceData['model'] = iosInfo.model;
      deviceData['name'] = iosInfo.name;
    }

    return deviceData;
  }

  Future<void> _logComplianceEvent(String event, Map<String, dynamic> data) async {
    final logEntry = {
      'event': event,
      'timestamp': DateTime.now().toIso8601String(),
      'app_version': _packageInfo.version,
      'data': data,
    };

    // In a real implementation, this would send to analytics service
    if (kDebugMode) {
      print('Compliance Event: ${jsonEncode(logEntry)}');
    }
  }

  bool _isNewerVersion(String newVersion, String currentVersion) {
    final newParts = newVersion.split('.').map(int.parse).toList();
    final currentParts = currentVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (newParts[i] > currentParts[i]) return true;
      if (newParts[i] < currentParts[i]) return false;
    }

    return false;
  }

  String _getDefaultPrivacyPolicy() {
    return '''
Privacy Policy for Educational Learning App

Last updated: ${DateTime.now().toString().split(' ')[0]}

1. Information We Collect
We collect information you provide directly to us, such as when you create an account, use our educational features, or contact us for support.

2. How We Use Your Information
- To provide and maintain our educational services
- To personalize your learning experience
- To track your educational progress
- To improve our app and services

3. Information Sharing
We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy.

4. Data Security
We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.

5. Children's Privacy
Our app is designed for educational use and complies with COPPA requirements for children under 13.

6. Contact Us
If you have questions about this Privacy Policy, please contact us at support@educationalapp.com
''';
  }

  String _getDefaultTermsOfService() {
    return '''
Terms of Service for Educational Learning App

Last updated: ${DateTime.now().toString().split(' ')[0]}

1. Acceptance of Terms
By using our app, you agree to these Terms of Service.

2. Description of Service
Our app provides educational content and learning tools for students.

3. User Accounts
You are responsible for maintaining the confidentiality of your account information.

4. Acceptable Use
You agree to use the app only for lawful educational purposes.

5. Intellectual Property
All content in the app is owned by us or our licensors and is protected by copyright and other intellectual property laws.

6. Limitation of Liability
We are not liable for any indirect, incidental, special, or consequential damages.

7. Changes to Terms
We may update these terms from time to time. Continued use of the app constitutes acceptance of new terms.

8. Contact Information
For questions about these Terms, contact us at legal@educationalapp.com
''';
  }
}

/// Data collection disclosure information
class DataCollectionDisclosure {
  final List<String> personalDataCollected;
  final List<String> purposeOfCollection;
  final List<String> dataSharing;
  final String dataRetention;
  final List<String> userRights;

  DataCollectionDisclosure({
    required this.personalDataCollected,
    required this.purposeOfCollection,
    required this.dataSharing,
    required this.dataRetention,
    required this.userRights,
  });

  Map<String, dynamic> toJson() {
    return {
      'personal_data_collected': personalDataCollected,
      'purpose_of_collection': purposeOfCollection,
      'data_sharing': dataSharing,
      'data_retention': dataRetention,
      'user_rights': userRights,
    };
  }
}

/// Content rating information
class ContentRating {
  final String esrbRating;
  final String pegiRating;
  final String description;
  final List<String> contentDescriptors;

  ContentRating({
    required this.esrbRating,
    required this.pegiRating,
    required this.description,
    required this.contentDescriptors,
  });

  Map<String, dynamic> toJson() {
    return {
      'esrb_rating': esrbRating,
      'pegi_rating': pegiRating,
      'description': description,
      'content_descriptors': contentDescriptors,
    };
  }
}

/// Permission compliance tracking
class PermissionCompliance {
  final Map<String, String> _permissions = {};

  void addPermission(String permission, String justification) {
    _permissions[permission] = justification;
  }

  Map<String, String> get permissions => Map.unmodifiable(_permissions);

  bool get isCompliant => _permissions.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'permissions': _permissions,
      'is_compliant': isCompliant,
    };
  }
}

/// Store listing compliance validation
class StoreListingCompliance {
  final List<String> _issues = [];
  final List<String> _warnings = [];

  void addIssue(String issue) => _issues.add(issue);
  void addWarning(String warning) => _warnings.add(warning);

  List<String> get issues => List.unmodifiable(_issues);
  List<String> get warnings => List.unmodifiable(_warnings);

  bool get isCompliant => _issues.isEmpty;
  bool get hasWarnings => _warnings.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'is_compliant': isCompliant,
      'issues': _issues,
      'warnings': _warnings,
    };
  }
}

/// Comprehensive compliance report
class ComplianceReport {
  final String appVersion;
  final String buildNumber;
  final String complianceVersion;
  final Map<String, dynamic> deviceInfo;
  final bool privacyConsent;
  final bool dataCollectionConsent;
  final bool ageVerified;
  final PermissionCompliance permissions;
  final DataCollectionDisclosure dataDisclosure;
  final ContentRating contentRating;
  final DateTime generatedAt;

  ComplianceReport({
    required this.appVersion,
    required this.buildNumber,
    required this.complianceVersion,
    required this.deviceInfo,
    required this.privacyConsent,
    required this.dataCollectionConsent,
    required this.ageVerified,
    required this.permissions,
    required this.dataDisclosure,
    required this.contentRating,
    required this.generatedAt,
  });

  bool get isFullyCompliant =>
      privacyConsent &&
      dataCollectionConsent &&
      ageVerified &&
      permissions.isCompliant;

  Map<String, dynamic> toJson() {
    return {
      'app_version': appVersion,
      'build_number': buildNumber,
      'compliance_version': complianceVersion,
      'device_info': deviceInfo,
      'privacy_consent': privacyConsent,
      'data_collection_consent': dataCollectionConsent,
      'age_verified': ageVerified,
      'permissions': permissions.toJson(),
      'data_disclosure': dataDisclosure.toJson(),
      'content_rating': contentRating.toJson(),
      'is_fully_compliant': isFullyCompliant,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}