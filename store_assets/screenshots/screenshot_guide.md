# Screenshot Capture Guide

## Required Screenshots for App Stores

### Google Play Store Requirements
- **Phone Screenshots:** 1080 x 1920 pixels (minimum 2, maximum 8)
- **7-inch Tablet:** 1200 x 1920 pixels (optional)
- **10-inch Tablet:** 1920 x 1200 pixels (optional)
- **Format:** PNG or JPEG
- **File size:** Maximum 8MB per image

### Apple App Store Requirements
- **iPhone 6.7":** 1290 x 2796 or 1284 x 2778 pixels
- **iPhone 6.5":** 1242 x 2688 or 1284 x 2778 pixels  
- **iPhone 5.5":** 1242 x 2208 pixels
- **iPad Pro 12.9":** 2048 x 2732 pixels
- **Format:** PNG or JPEG
- **File size:** Maximum 8MB per image

## Screenshots to Capture

### 1. Home Screen (home_screen.dart)
**Filename:** `01_home_screen.png`
**Description:** Main dashboard showing subjects, progress, and navigation
**Key Elements:**
- Subject selection grid
- User progress indicators
- Gems counter
- Navigation elements
- Welcome message

### 2. Lesson Screen (lesson_screen.dart)
**Filename:** `02_lesson_in_progress.png`
**Description:** Active lesson showing question and answer options
**Key Elements:**
- Question display
- Multiple choice options
- Progress indicator
- Skip button
- Lesson header

### 3. Profile Screen (profile_screen.dart)
**Filename:** `03_profile_analytics.png`
**Description:** User profile with detailed analytics and statistics
**Key Elements:**
- User avatar and info
- Learning statistics
- Progress charts
- Achievement indicators
- Performance metrics

### 4. Difficulty Selection (difficulty_screen.dart)
**Filename:** `04_difficulty_selection.png`
**Description:** Difficulty level selection interface
**Key Elements:**
- Difficulty level options
- Adaptive difficulty explanation
- User's current level
- Progress indicators

### 5. Subject Selection (subjects screen)
**Filename:** `05_subject_selection.png`
**Description:** Subject selection with available topics
**Key Elements:**
- Subject categories (Math, Science, etc.)
- Subject icons
- Progress indicators per subject
- Unlock status

### 6. Onboarding Flow (onboarding_screen.dart)
**Filename:** `06_onboarding_welcome.png`
**Description:** Welcome screen from onboarding flow
**Key Elements:**
- App introduction
- Key features highlight
- Getting started button
- Attractive visual design

### 7. Settings Screen (settings_screen.dart)
**Filename:** `07_settings_preferences.png`
**Description:** App settings and preferences
**Key Elements:**
- User preferences
- AI configuration options
- Privacy settings
- App information

### 8. Store/Gems Screen (store_screen.dart)
**Filename:** `08_gem_store.png`
**Description:** Gem store and rewards system
**Key Elements:**
- Gem balance
- Reward items
- Achievement system
- Gamification elements

## Manual Screenshot Capture Instructions

### Using Web Version (Recommended)
1. Open http://localhost:8080 in Chrome
2. Open Developer Tools (F12)
3. Click "Toggle Device Toolbar" (Ctrl+Shift+M)
4. Set device to "Responsive"
5. Set dimensions to required size (e.g., 1080 x 1920)
6. Navigate to each screen
7. Right-click → "Capture screenshot" or use Ctrl+Shift+P → "Capture screenshot"

### Using Android Emulator
1. Start Android emulator with appropriate screen size
2. Run `flutter run -d emulator-5554`
3. Navigate to each screen
4. Use emulator's screenshot feature (camera icon in toolbar)
5. Screenshots saved to: `%USERPROFILE%\Pictures\Screenshots`

### Using Physical Device
1. Connect Android/iOS device
2. Enable developer options and USB debugging
3. Run `flutter run -d [device-id]`
4. Use device's built-in screenshot function
5. Transfer screenshots to computer

## Screenshot Optimization

### Image Quality
- Use PNG format for crisp UI elements
- Ensure high resolution (at least required dimensions)
- Avoid compression artifacts
- Use consistent lighting and contrast

### Content Guidelines
- Show realistic, engaging content
- Avoid placeholder text where possible
- Include diverse, representative data
- Highlight key features and benefits
- Ensure text is readable at thumbnail size

### Composition Tips
- Center important UI elements
- Use consistent spacing and alignment
- Show app in active use (not empty states)
- Include visual indicators of progress/achievement
- Maintain brand consistency across all screenshots

## Post-Processing Checklist

### Technical Validation
- [ ] Correct dimensions for target platform
- [ ] File size under 8MB
- [ ] High resolution and clarity
- [ ] Proper format (PNG/JPEG)
- [ ] No pixelation or artifacts

### Content Review
- [ ] No personal information visible
- [ ] Appropriate content for age rating
- [ ] Consistent branding and colors
- [ ] Clear, readable text
- [ ] Engaging and representative content

### Store Optimization
- [ ] Screenshots tell a story
- [ ] Key features highlighted
- [ ] Visual hierarchy guides attention
- [ ] Consistent with app description
- [ ] Competitive differentiation shown

## File Naming Convention

Use the following naming pattern:
- `[platform]_[screen_name]_[size].png`
- Examples:
  - `android_home_1080x1920.png`
  - `ios_lesson_1290x2796.png`
  - `tablet_profile_1920x1200.png`

## Storage Organization

```
screenshots/
├── android/
│   ├── phone/
│   └── tablet/
├── ios/
│   ├── iphone/
│   └── ipad/
└── web/
    └── desktop/
```

## Quality Assurance

Before submitting screenshots:
1. Review on actual devices/screen sizes
2. Check readability at thumbnail size
3. Verify consistent branding
4. Ensure compliance with store guidelines
5. Test with different audiences for clarity
6. Compare with competitor screenshots for positioning

## Tools and Resources

### Recommended Tools
- **Chrome DevTools:** Built-in screenshot capture
- **Android Studio:** Emulator screenshots
- **Xcode Simulator:** iOS screenshots
- **Figma/Sketch:** Design mockups and annotations
- **ImageOptim:** Image compression and optimization

### Online Resources
- Google Play Console Help: Screenshot specifications
- Apple Developer Documentation: App Store screenshots
- ASO tools for competitive analysis
- Image optimization tools for file size reduction