# 🔥 LearnoSphere - Firebase Configuration & Verification Guide

## 📋 Overview

This guide helps you verify and configure all Firebase services for the LearnoSphere educational app.

---

## ✅ CURRENT FIREBASE CONFIGURATION

### Firebase Project Details
Based on `android/app/google-services.json`:

- **Project ID**: `lulli-fy`
- **Project Number**: `908072160379`
- **Storage Bucket**: `lulli-fy.firebasestorage.app`
- **Package Name**: `com.example.sp`
- **App ID**: `1:908072160379:android:d18fbac46d805d251566de`
- **API Key**: `AIzaSyDhGHlxakwKw9x4xzgfmmzHYpEF37lTpbU`

### Configuration Status
- ✅ `google-services.json` is present in `android/app/`
- ✅ Firebase SDK initialized in app
- ✅ Package name matches: `com.example.sp`

---

## 🔧 FIREBASE SERVICES VERIFICATION CHECKLIST

### 1. Firebase Console Access

#### 1.1 Access Your Project
1. Visit: https://console.firebase.google.com/
2. Sign in with your Google account
3. Select project: **lulli-fy**
4. Verify you can access the dashboard

#### 1.2 Verify App Registration
- [ ] Navigate to **Project Settings** (gear icon)
- [ ] Go to **Your apps** section
- [ ] Verify Android app is registered
- [ ] Package name: `com.example.sp`
- [ ] SHA-1 certificate fingerprint added (required for Google Sign-In)

**To get SHA-1 fingerprint**:
```bash
# For debug builds
cd android
./gradlew signingReport

# Look for SHA-1 under "Variant: debug"
```

---

### 2. Firebase Authentication

#### 2.1 Enable Authentication Methods
1. Go to **Authentication** → **Sign-in method**
2. Enable the following providers:

**Required Providers**:
- [ ] **Email/Password** - Enable this for basic authentication
- [ ] **Google** - Enable for Google Sign-In (requires SHA-1)

**Optional Providers** (if you want to add them):
- [ ] **Anonymous** - For guest users
- [ ] **Phone** - For SMS authentication
- [ ] **Facebook** - For Facebook login
- [ ] **Apple** - For Apple Sign-In

#### 2.2 Configure Email/Password Settings
- [ ] **Email enumeration protection**: Enable (recommended)
- [ ] **Email link sign-in**: Enable if using passwordless login
- [ ] **Password policy**: Set minimum requirements

#### 2.3 Configure Google Sign-In
1. Enable Google provider
2. Add **Web client ID** (auto-generated)
3. Add **SHA-1 certificate** in Project Settings
4. Download updated `google-services.json`
5. Replace old file in `android/app/google-services.json`

#### 2.4 Test Authentication
- [ ] Create a test user account
- [ ] Sign in with test account
- [ ] Verify user appears in Authentication → Users
- [ ] Test password reset flow
- [ ] Test Google Sign-In (if enabled)

**Test Commands**:
```dart
// In your app, test these flows:
// 1. Sign up new user
// 2. Sign in existing user
// 3. Sign out
// 4. Password reset
// 5. Google Sign-In
```

---

### 3. Cloud Firestore

#### 3.1 Create Firestore Database
1. Go to **Firestore Database**
2. Click **Create database**
3. Choose mode:
   - **Production mode** (recommended for production)
   - **Test mode** (for development - allows all reads/writes)
4. Select location: Choose closest to your users
5. Click **Enable**

#### 3.2 Set Up Security Rules

**For Development** (Test Mode):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2025, 12, 31);
    }
  }
}
```

**For Production** (Recommended):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // User profiles - users can only read/write their own data
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // User progress - users can only access their own progress
    match /user_progress/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Generated content - read-only for all authenticated users
    match /generated_content/{document=**} {
      allow read: if request.auth != null;
      allow write: if false; // Only backend can write
    }
    
    // Lessons - read-only for all authenticated users
    match /lessons/{document=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    // Subjects - read-only for all authenticated users
    match /subjects/{document=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    // Achievements - users can read all, write only their own
    match /achievements/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Leaderboard - read-only for all authenticated users
    match /leaderboard/{document=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

#### 3.3 Create Collections
Create these collections in Firestore:

- [ ] **users** - User profile data
  - Fields: `uid`, `email`, `displayName`, `photoURL`, `createdAt`, `lastLogin`

- [ ] **user_progress** - User learning progress
  - Fields: `userId`, `currentLevel`, `totalXP`, `completedLessons`, `achievements`

- [ ] **generated_content** - AI-generated lessons and questions
  - Fields: `subject`, `chapterId`, `lessons`, `createdAt`, `difficulty`

- [ ] **lessons** - Lesson metadata
  - Fields: `lessonId`, `title`, `description`, `subject`, `difficulty`, `xpReward`

- [ ] **subjects** - Subject information
  - Fields: `subjectId`, `name`, `description`, `icon`, `color`

- [ ] **achievements** - User achievements
  - Fields: `userId`, `achievementId`, `unlockedAt`, `progress`

- [ ] **leaderboard** - Global leaderboard
  - Fields: `userId`, `displayName`, `totalXP`, `level`, `rank`

#### 3.4 Test Firestore Operations
- [ ] Create a test document
- [ ] Read the document
- [ ] Update the document
- [ ] Delete the document
- [ ] Test security rules with different users

---

### 4. Firebase Storage

#### 4.1 Enable Storage
1. Go to **Storage**
2. Click **Get started**
3. Choose security rules mode
4. Select storage location
5. Click **Done**

#### 4.2 Set Up Storage Rules

**For Development**:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.time < timestamp.date(2025, 12, 31);
    }
  }
}
```

**For Production**:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // User profile images
    match /users/{userId}/profile/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId
                   && request.resource.size < 5 * 1024 * 1024 // 5MB limit
                   && request.resource.contentType.matches('image/.*');
    }
    
    // Lesson images - read-only
    match /lessons/{lessonId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    // Achievement badges - read-only
    match /achievements/{fileName} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

#### 4.3 Upload Test Files
- [ ] Upload a test image
- [ ] Download the image
- [ ] Verify URL is accessible
- [ ] Test security rules

---

### 5. Firebase Analytics

#### 5.1 Enable Analytics
1. Go to **Analytics** → **Dashboard**
2. Verify analytics is enabled
3. Check that events are being tracked

#### 5.2 Configure Events
The app should track these events:

**User Events**:
- `sign_up` - User creates account
- `login` - User signs in
- `logout` - User signs out

**Learning Events**:
- `lesson_start` - User starts a lesson
- `lesson_complete` - User completes a lesson
- `quiz_start` - User starts a quiz
- `quiz_complete` - User completes a quiz
- `question_answered` - User answers a question

**Progression Events**:
- `level_up` - User reaches new level
- `xp_earned` - User earns XP
- `achievement_unlocked` - User unlocks achievement

**Engagement Events**:
- `app_open` - User opens app
- `screen_view` - User views a screen
- `button_click` - User clicks a button

#### 5.3 Verify Analytics
- [ ] Open app and perform actions
- [ ] Wait 24 hours for data to appear
- [ ] Check Analytics dashboard for events
- [ ] Verify user properties are set

---

### 6. Firebase Cloud Messaging (Optional)

#### 6.1 Enable FCM
1. Go to **Cloud Messaging**
2. Note the **Server key** and **Sender ID**
3. Add to your app configuration

#### 6.2 Configure Notifications
- [ ] Set up notification channels
- [ ] Test push notifications
- [ ] Configure notification icons
- [ ] Set up notification actions

---

## 🔍 VERIFICATION TESTS

### Test 1: Authentication Flow
```bash
# Run the app
flutter run -d emulator-5554

# Test these flows:
1. Sign up with email/password
2. Sign out
3. Sign in with same credentials
4. Request password reset
5. Sign in with Google (if enabled)
```

**Expected Results**:
- ✅ User created in Firebase Authentication
- ✅ User document created in Firestore `users` collection
- ✅ User can sign in and out successfully
- ✅ Password reset email received

### Test 2: Data Synchronization
```bash
# In the app:
1. Complete a lesson
2. Earn XP
3. Unlock an achievement
4. Close the app
5. Reopen the app
6. Sign in again
```

**Expected Results**:
- ✅ Progress saved to Firestore
- ✅ XP and level synced
- ✅ Achievements synced
- ✅ Data loads correctly after reopening

### Test 3: Offline Mode
```bash
# In the app:
1. Turn off WiFi/mobile data
2. Navigate through app
3. Complete a lesson (if possible)
4. Turn on WiFi/mobile data
```

**Expected Results**:
- ✅ App works offline with cached data
- ✅ Changes sync when back online
- ✅ No data loss

### Test 4: Real-time Updates
```bash
# Open app on two devices:
1. Sign in with same account on both
2. Complete a lesson on device 1
3. Check if progress updates on device 2
```

**Expected Results**:
- ✅ Progress syncs across devices
- ✅ Real-time updates work

---

## 🐛 COMMON ISSUES & SOLUTIONS

### Issue 1: "Default FirebaseApp is not initialized"
**Solution**:
```dart
// Ensure Firebase is initialized in main.dart
await Firebase.initializeApp();
```

### Issue 2: "Permission denied" errors in Firestore
**Solution**:
- Check Firestore security rules
- Ensure user is authenticated
- Verify user has permission to access the document

### Issue 3: Google Sign-In not working
**Solution**:
- Add SHA-1 certificate to Firebase project
- Download updated `google-services.json`
- Enable Google Sign-In in Authentication settings

### Issue 4: Storage upload fails
**Solution**:
- Check Storage security rules
- Verify file size is within limits
- Ensure file type is allowed

### Issue 5: Analytics events not appearing
**Solution**:
- Wait 24 hours for data to appear
- Check that Analytics is enabled
- Verify events are being logged correctly

---

## 📊 FIREBASE USAGE MONITORING

### Check Quotas
1. Go to **Usage and billing** → **Details**
2. Monitor these metrics:
   - **Authentication**: Sign-ins per month
   - **Firestore**: Reads, writes, deletes per day
   - **Storage**: GB stored and downloaded
   - **Cloud Functions**: Invocations per month

### Set Up Alerts
1. Go to **Usage and billing** → **Budgets & alerts**
2. Create budget alerts for:
   - Firestore reads/writes
   - Storage bandwidth
   - Cloud Functions invocations

---

## 🔐 SECURITY BEST PRACTICES

### 1. Security Rules
- ✅ Never use test mode in production
- ✅ Always validate user authentication
- ✅ Restrict write access to authorized users only
- ✅ Validate data types and sizes

### 2. API Keys
- ✅ Restrict API key usage in Firebase Console
- ✅ Add app restrictions (Android package name)
- ✅ Add API restrictions (only allow required APIs)

### 3. User Data
- ✅ Never store sensitive data in Firestore
- ✅ Use Firebase Authentication for passwords
- ✅ Encrypt sensitive data before storing
- ✅ Implement data retention policies

---

## ✅ CONFIGURATION CHECKLIST

Before going to production, verify:

- [ ] Firebase project created and configured
- [ ] `google-services.json` is up to date
- [ ] Authentication methods enabled
- [ ] Firestore database created
- [ ] Security rules configured (production mode)
- [ ] Storage enabled with proper rules
- [ ] Analytics enabled and tracking events
- [ ] SHA-1 certificate added (for Google Sign-In)
- [ ] API keys restricted
- [ ] Budget alerts set up
- [ ] All tests passed

---

**Last Updated**: 2025-10-01  
**Firebase Project**: lulli-fy  
**Status**: Ready for Verification

