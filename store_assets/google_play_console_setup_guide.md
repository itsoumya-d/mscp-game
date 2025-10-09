# Google Play Console Setup Guide

## 🎯 **Current Status**
✅ **Release APK built and signed** (51.7 MB)
✅ **Signing keystore configured** (`sp-release-key.jks`)
✅ **App running on Android emulator** for screenshots
⏳ **Screenshots in progress** (8 required)
⏳ **Google Play Console setup** (next step)

## 📋 **Prerequisites Completed**
- [x] Release APK: `E:\sp\build\app\outputs\flutter-apk\app-release.apk`
- [x] App signing configured with keystore
- [x] Privacy policy and terms of service created
- [x] App descriptions and metadata prepared
- [x] App icon and promotional materials ready

## 🏪 **Google Play Console Setup Steps**

### **Step 1: Account Setup**
1. **Visit**: [Google Play Console](https://play.google.com/console)
2. **Sign in** with your Google account
3. **Accept** the Developer Distribution Agreement
4. **Pay** the $25 one-time registration fee
5. **Verify** your developer account

### **Step 2: Create New App**
1. **Click "Create app"** in the Play Console
2. **Fill in app details**:
   - **App name**: StudyPal
   - **Default language**: English (United States)
   - **App or game**: App
   - **Free or paid**: Free
3. **Accept** Play App Signing terms
4. **Create** the app

### **Step 3: App Information**
Navigate to **"App information"** and complete:

#### **App Details**
- **App name**: StudyPal
- **Short description**: AI-powered personalized learning companion
- **Full description**: Use content from `E:\sp\store_assets\descriptions\google_play_description.md`
- **App icon**: Upload from `E:\sp\assets\icons\studypal_icon.jpg`
- **Feature graphic**: Create 1024 x 500 px promotional image
- **Category**: Education
- **Tags**: Education, Learning, AI, Study

#### **Store Listing**
- **Screenshots**: Upload 8 screenshots (1080 x 1920 px)
  - Home screen
  - Lesson interface
  - Profile screen
  - Difficulty selection
  - Subject selection
  - Onboarding flow
  - Settings screen
  - Store/gems screen

### **Step 4: Content Rating**
1. **Complete content rating questionnaire**
2. **Select appropriate age ratings**
3. **Generate rating certificates**

### **Step 5: Target Audience**
1. **Select target age groups**
2. **Specify if app appeals to children**
3. **Complete any required declarations**

### **Step 6: App Access**
1. **Specify if app requires special access**
2. **Provide instructions for reviewers** (if needed)
3. **Add demo account credentials** (if applicable)

### **Step 7: Ads Declaration**
1. **Declare if app contains ads** (No for StudyPal)
2. **Complete ads policy compliance**

## 📱 **App Bundle Upload**

### **Option A: Upload APK (Current)**
1. **Go to "Release" → "Production"**
2. **Click "Create new release"**
3. **Upload** `app-release.apk`
4. **Add release notes**
5. **Review and rollout**

### **Option B: Generate App Bundle (Recommended)**
```powershell
# Generate App Bundle (.aab) - more efficient
flutter build appbundle --release
```
- **File location**: `build\app\outputs\bundle\release\app-release.aab`
- **Benefits**: Smaller download size, dynamic delivery

## 🔐 **App Signing Configuration**

### **Current Setup** ✅
- **Keystore**: `sp-release-key.jks`
- **Key alias**: `sp-key`
- **Passwords**: Configured in `key.properties`

### **Play App Signing** (Recommended)
1. **Enable Play App Signing** in console
2. **Upload signing key** to Google
3. **Google manages** app signing automatically

## 📊 **Store Listing Optimization**

### **Keywords** (100 characters max)
```
study, learn, education, AI, personalized, tutor, exam, practice, quiz, knowledge
```

### **Short Description** (80 characters max)
```
AI-powered personalized learning companion for effective studying
```

### **App Title Optimization**
- **Primary**: StudyPal
- **Alternative**: StudyPal - AI Learning Companion

## ✅ **Pre-Launch Checklist**

### **Required Assets**
- [ ] App icon (512 x 512 px)
- [ ] Feature graphic (1024 x 500 px)
- [ ] Screenshots (8 images, 1080 x 1920 px)
- [ ] Privacy policy URL
- [ ] App description and metadata

### **Technical Requirements**
- [x] Release APK/AAB signed and ready
- [x] Version code and name set
- [x] Permissions properly declared
- [x] Target SDK version appropriate
- [x] App signing configured

### **Compliance**
- [x] Privacy policy created
- [x] Terms of service created
- [ ] Content rating completed
- [ ] Target audience specified
- [ ] Ads declaration completed

## 🚀 **Release Process**

### **Testing Track Progression**
1. **Internal testing** → Small team testing
2. **Alpha testing** → Closed testing with specific users
3. **Beta testing** → Open testing with larger audience
4. **Production** → Public release

### **Rollout Strategy**
1. **Start with 5%** of users
2. **Monitor crash reports** and reviews
3. **Gradually increase** to 100%
4. **Monitor performance** metrics

## 📈 **Post-Launch Monitoring**

### **Key Metrics to Track**
- **Install rate** and conversion
- **Crash-free sessions** (target: >99%)
- **User ratings** and reviews
- **Retention rates** (1-day, 7-day, 30-day)
- **Performance metrics** (ANRs, crashes)

### **Optimization Opportunities**
- **A/B testing** store listing elements
- **Keyword optimization** based on search data
- **Screenshot optimization** based on conversion rates
- **Description updates** based on user feedback

## 🔗 **Useful Resources**
- [Google Play Console Help](https://support.google.com/googleplay/android-developer/)
- [App Bundle Documentation](https://developer.android.com/guide/app-bundle)
- [Store Listing Best Practices](https://developer.android.com/distribute/best-practices/launch/store-listing)
- [Content Rating Guidelines](https://support.google.com/googleplay/android-developer/answer/188189)

---
**Next Steps**: Complete screenshot capture, then proceed with Google Play Console account setup and app creation.