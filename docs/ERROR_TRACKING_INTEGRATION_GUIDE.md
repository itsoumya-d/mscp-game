# 🔧 Error Tracking Integration Guide

**Status**: ✅ Code Updated - Ready for Integration  
**Services**: Firebase Crashlytics + Sentry (optional)  
**Estimated Time**: 30 minutes

---

## ✅ What's Been Done

1. ✅ Added `firebase_crashlytics: ^4.1.3` to pubspec.yaml
2. ✅ Added `sentry_flutter: ^8.9.0` to pubspec.yaml
3. ✅ Updated `lib/core/services/error_tracking_service.dart` with real implementations
4. ✅ Removed all TODO comments and mock code

---

## 📋 Step-by-Step Integration

### **Step 1: Install Dependencies**

Run this command in your terminal:

```bash
flutter pub get
```

This will install:
- `firebase_crashlytics: ^4.1.3`
- `sentry_flutter: ^8.9.0`

---

### **Step 2: Configure Firebase Crashlytics**

#### **2.1: Enable Crashlytics in Firebase Console**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create one if you haven't)
3. Click on "Crashlytics" in the left menu
4. Click "Enable Crashlytics"
5. Follow the setup wizard

#### **2.2: Update Android Configuration**

**File**: `android/app/build.gradle`

Add this at the top (after other plugins):
```gradle
plugins {
    id 'com.android.application'
    id 'kotlin-android'
    id 'com.google.gms.google-services'
    id 'com.google.firebase.crashlytics'  // Add this line
}
```

**File**: `android/build.gradle`

Add this to buildscript dependencies:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
        classpath 'com.google.firebase:firebase-crashlytics-gradle:2.9.9'  // Add this
    }
}
```

#### **2.3: Update iOS Configuration**

**File**: `ios/Podfile`

Add this at the top:
```ruby
# Crashlytics
pod 'FirebaseCrashlytics'
```

Then run:
```bash
cd ios
pod install
cd ..
```

---

### **Step 3: Configure Sentry (Optional but Recommended)**

#### **3.1: Create Sentry Account**

1. Go to [sentry.io](https://sentry.io/)
2. Sign up for free account
3. Create a new project
4. Select "Flutter" as the platform
5. Copy your DSN (looks like: `https://xxxxx@xxxxx.ingest.sentry.io/xxxxx`)

#### **3.2: Save Your Sentry DSN**

Create a file to store your DSN securely:

**File**: `lib/core/config/sentry_config.dart`

```dart
class SentryConfig {
  // Get your DSN from: https://sentry.io/settings/projects/
  static const String dsn = 'YOUR_SENTRY_DSN_HERE';
  
  // Set to true to enable Sentry
  static const bool enabled = true;
}
```

**⚠️ IMPORTANT**: Add this file to `.gitignore` to keep your DSN private:

```
# .gitignore
lib/core/config/sentry_config.dart
```

---

### **Step 4: Initialize Error Tracking in main.dart**

Update your `main.dart` file:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sp/core/services/error_tracking_service.dart';
import 'package:sp/core/config/sentry_config.dart';  // If using Sentry

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Error Tracking
  await ErrorTrackingService().initialize(
    sentryDsn: SentryConfig.enabled ? SentryConfig.dsn : null,
  );
  
  runApp(const MyApp());
}
```

---

### **Step 5: Test Error Tracking**

#### **5.1: Test Automatic Crash Reporting**

Add a test button to your app:

```dart
ElevatedButton(
  onPressed: () {
    // This will crash the app and send report to Crashlytics
    throw Exception('Test crash for Crashlytics');
  },
  child: const Text('Test Crash'),
)
```

#### **5.2: Test Custom Error Logging**

```dart
try {
  // Your code that might fail
  int result = 10 ~/ 0;  // Division by zero
} catch (e, stackTrace) {
  ErrorTrackingService().recordError(
    e,
    stackTrace,
    reason: 'Division by zero in calculation',
    context: {
      'screen': 'HomeScreen',
      'user_action': 'calculate',
    },
  );
}
```

#### **5.3: Test User Context**

```dart
// When user logs in
ErrorTrackingService().setUserIdentifier(userId);
ErrorTrackingService().setCustomKey('user_level', userLevel);
ErrorTrackingService().setCustomKey('subscription', 'premium');
```

#### **5.4: Test Breadcrumbs**

```dart
// Track user actions
ErrorTrackingService().addBreadcrumb('User opened settings');
ErrorTrackingService().addBreadcrumb('User changed theme to dark');
ErrorTrackingService().addBreadcrumb('User started level 5');
```

---

## 🎯 Usage Examples

### **Example 1: Network Error**

```dart
Future<void> fetchData() async {
  try {
    final response = await http.get(Uri.parse('https://api.example.com/data'));
    if (response.statusCode != 200) {
      ErrorTrackingService().recordNetworkError(
        'https://api.example.com/data',
        response.statusCode,
        'Failed to fetch data',
      );
    }
  } catch (e, stackTrace) {
    ErrorTrackingService().recordError(e, stackTrace);
  }
}
```

### **Example 2: Database Error**

```dart
Future<void> saveToDatabase() async {
  try {
    await database.insert('users', userData);
  } catch (e, stackTrace) {
    ErrorTrackingService().recordDatabaseError(
      'insert into users',
      e,
      stackTrace,
    );
  }
}
```

### **Example 3: Performance Tracking**

```dart
Future<void> loadHeavyData() async {
  final stopwatch = Stopwatch()..start();
  
  try {
    await heavyOperation();
  } finally {
    stopwatch.stop();
    ErrorTrackingService().recordPerformanceIssue(
      'loadHeavyData',
      stopwatch.elapsed,
      context: {'data_size': dataSize},
    );
  }
}
```

### **Example 4: Using Extension**

```dart
try {
  // Your code
} catch (e, stackTrace) {
  e.trackError(stackTrace);  // Simple one-liner!
}
```

---

## 🔍 Viewing Error Reports

### **Firebase Crashlytics**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click "Crashlytics" in left menu
4. View crashes, errors, and analytics

### **Sentry**

1. Go to [sentry.io](https://sentry.io/)
2. Select your project
3. View issues, performance, and releases

---

## ✅ Verification Checklist

After integration, verify:

- [ ] `flutter pub get` runs successfully
- [ ] App builds without errors
- [ ] Firebase Crashlytics is enabled in console
- [ ] Sentry DSN is configured (if using)
- [ ] Error tracking initializes on app start
- [ ] Test crash appears in Crashlytics dashboard
- [ ] Custom errors are logged correctly
- [ ] User context is set properly
- [ ] Breadcrumbs are recorded

---

## 🚨 Troubleshooting

### **Issue: Crashlytics not receiving crashes**

**Solution**:
1. Make sure you've enabled Crashlytics in Firebase Console
2. Check that `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in the correct location
3. Crashes may take 5-10 minutes to appear in dashboard
4. Try force-stopping and restarting the app

### **Issue: Sentry not receiving errors**

**Solution**:
1. Verify your DSN is correct
2. Check that `SentryConfig.enabled` is `true`
3. Make sure you have internet connection
4. Check Sentry project settings

### **Issue: Build errors after adding dependencies**

**Solution**:
1. Run `flutter clean`
2. Run `flutter pub get`
3. For iOS: `cd ios && pod install && cd ..`
4. Rebuild the app

---

## 📊 Best Practices

### **1. Set User Context Early**

```dart
// In your authentication flow
void onUserLogin(User user) {
  ErrorTrackingService().setUserIdentifier(user.id);
  ErrorTrackingService().setCustomKey('email', user.email);
  ErrorTrackingService().setCustomKey('plan', user.subscriptionPlan);
}
```

### **2. Add Breadcrumbs for Important Actions**

```dart
void onLevelComplete(int level) {
  ErrorTrackingService().addBreadcrumb(
    'Level completed',
    data: {'level': level, 'score': score},
  );
}
```

### **3. Track Performance Issues**

```dart
Future<void> criticalOperation() async {
  final stopwatch = Stopwatch()..start();
  try {
    await operation();
  } finally {
    stopwatch.stop();
    if (stopwatch.elapsedMilliseconds > 1000) {
      ErrorTrackingService().recordPerformanceIssue(
        'criticalOperation',
        stopwatch.elapsed,
      );
    }
  }
}
```

### **4. Use Error Boundaries for Widgets**

```dart
ErrorBoundaryWidget(
  child: MyComplexWidget(),
  errorBuilder: (error, stackTrace) {
    return ErrorStateWidget(
      errorType: ErrorType.unknown,
      onRetry: () {
        // Retry logic
      },
    );
  },
)
```

---

## 🎉 Success!

Once you complete these steps, you'll have:

✅ Automatic crash reporting  
✅ Custom error logging  
✅ User context tracking  
✅ Performance monitoring  
✅ Breadcrumb tracking  
✅ Real-time error dashboards  

Your app is now production-ready with enterprise-grade error tracking!

---

## 📞 Need Help?

If you encounter issues:
1. Check the troubleshooting section above
2. Review Firebase Crashlytics docs: https://firebase.google.com/docs/crashlytics
3. Review Sentry docs: https://docs.sentry.io/platforms/flutter/
4. Check the error tracking service code: `lib/core/services/error_tracking_service.dart`

---

**Next Steps**: After error tracking is working, proceed with integrating other completed features like AI services, animations, and social features!

