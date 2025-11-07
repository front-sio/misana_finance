# Localization Example - How It Works

This document provides a visual example of how the localization system works in the Misana Finance app.

## Before Implementation

### Old Code (Hardcoded Strings)
```dart
// In splash_page.dart
final List<String> _messages = [
  'Welcome to Misana Finance',
  'Securing your financial future',
  'Building wealth together',
  // ... more hardcoded English strings
];

String _getTimeBasedGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}

// In onboarding_page.dart
OnboardContent(
  title: 'Welcome to Misana',
  subtitle: 'Your trusted partner for secure savings and financial growth.',
),
OnboardContent(
  title: 'Set Your Goals',
  subtitle: 'Create personalized savings plans...',
),
```

**Problems:**
- ❌ All strings hardcoded in English
- ❌ No Swahili support
- ❌ Difficult to maintain
- ❌ Strings scattered across files

## After Implementation

### New Code (Localized Strings)

#### Step 1: Define Strings in Central Location
```dart
// lib/core/i18n/app_strings.dart
class AppStrings {
  static const String welcomeToMisanaEn = 'Welcome to Misana Finance';
  static const String welcomeToMisanaSw = 'Karibu Misana Finance';
  
  static const String goodMorningEn = 'Good Morning';
  static const String goodMorningSw = 'Habari za Asubuhi';
  
  // ... all other strings
}
```

#### Step 2: Create Convenient Getters
```dart
// lib/core/i18n/locale_extensions.dart
extension AppStringsExtension on BuildContext {
  String get welcomeToMisana => trSw(
    AppStrings.welcomeToMisanaSw, 
    AppStrings.welcomeToMisanaEn
  );
  
  String get goodMorning => trSw(
    AppStrings.goodMorningSw, 
    AppStrings.goodMorningEn
  );
  
  // ... all other getters
}
```

#### Step 3: Use in Widgets
```dart
// In splash_page.dart
List<String> get _messages => [
  context.welcomeToMisana,
  context.securingFuture,
  context.buildingWealth,
  // ... all localized
];

String _getTimeBasedGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return context.goodMorning;
  if (hour < 17) return context.goodAfternoon;
  return context.goodEvening;
}

// In onboarding_page.dart
List<OnboardContent> _getPages() {
  return [
    OnboardContent(
      title: context.welcomeToMisanaOnboarding,
      subtitle: context.trustedPartnerOnboarding,
    ),
    OnboardContent(
      title: context.setYourGoals,
      subtitle: context.setYourGoalsDesc,
    ),
    // ... all localized
  ];
}
```

**Benefits:**
- ✅ Supports both English and Swahili
- ✅ Centralized string management
- ✅ Type-safe access
- ✅ Easy to maintain and extend

## Usage Example

### Switching Languages

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misana_finance_app/core/i18n/locale_cubit.dart';

// Switch to Swahili
TextButton(
  onPressed: () => context.read<LocaleCubit>().setSwahili(),
  child: Text('Kiswahili'),
)

// Switch to English  
TextButton(
  onPressed: () => context.read<LocaleCubit>().setEnglish(),
  child: Text('English'),
)
```

### String Display Results

| English Mode | Swahili Mode |
|--------------|--------------|
| Good Morning | Habari za Asubuhi |
| Good Afternoon | Habari za Mchana |
| Good Evening | Habari za Jioni |
| Welcome to Misana Finance | Karibu Misana Finance |
| Securing your financial future | Kulinda mustakabali wako wa kifedha |
| Building wealth together | Kujenga utajiri pamoja |
| Set Your Goals | Weka Malengo Yako |
| Save Flexibly | Hifadhi kwa Urahisi |
| Track Progress | Fuatilia Maendeleo |
| Skip | Ruka |
| Next | Ifuatayo |
| Get Started | Anza |

## Adding New Strings

When you need to add a new localized string:

### 1. Add to app_strings.dart
```dart
class AppStrings {
  // ... existing strings ...
  
  static const String saveNowEn = 'Save Now';
  static const String saveNowSw = 'Hifadhi Sasa';
}
```

### 2. Add to locale_extensions.dart
```dart
extension AppStringsExtension on BuildContext {
  // ... existing getters ...
  
  String get saveNow => trSw(AppStrings.saveNowSw, AppStrings.saveNowEn);
}
```

### 3. Use in your widget
```dart
ElevatedButton(
  onPressed: () { /* save action */ },
  child: Text(context.saveNow),
)
```

That's it! The button will automatically display "Save Now" in English or "Hifadhi Sasa" in Swahili based on the current locale.

## Complete Flow Diagram

```
User's Device
     ↓
App Starts with LocaleCubit (default: en_US)
     ↓
Widget calls: context.welcomeToMisana
     ↓
AppStringsExtension getter invoked
     ↓
trSw() checks current locale
     ↓
     ├─ If sw_TZ → Returns "Karibu Misana Finance"
     └─ If en_US → Returns "Welcome to Misana Finance"
     ↓
String displayed in UI

User switches language
     ↓
LocaleCubit.setSwahili() called
     ↓
Locale changes to sw_TZ
     ↓
Widgets rebuild
     ↓
All strings now display in Swahili
```

## Architecture Benefits

1. **Single Source of Truth**: All strings in `app_strings.dart`
2. **Type Safety**: Compile-time checking prevents typos
3. **Easy Testing**: Can easily test both language versions
4. **Scalable**: Easy to add new languages in the future
5. **Maintainable**: Simple pattern to follow
6. **No External Packages**: Uses Flutter's built-in capabilities
