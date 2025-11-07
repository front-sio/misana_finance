# Localization Guide

This document explains how to use and extend the localization system in the Misana Finance app.

## Overview

The app supports two languages:
- **English (en_US)** - Default language
- **Swahili (sw_TZ)** - Kiswahili

## Architecture

The localization system consists of three main files:

1. **`lib/core/i18n/app_strings.dart`** - Contains all string constants in both languages
2. **`lib/core/i18n/locale_extensions.dart`** - Provides convenient extensions to access localized strings
3. **`lib/core/i18n/locale_cubit.dart`** - Manages the current locale state

## How to Use Localized Strings

### 1. In Your Widget

Import the locale extensions:

```dart
import 'package:misana_finance_app/core/i18n/locale_extensions.dart';
```

Then use the convenient getters on the BuildContext:

```dart
Text(context.welcomeToMisana)  // Will show "Welcome to Misana Finance" or "Karibu Misana Finance"
Text(context.goodMorning)       // Will show "Good Morning" or "Habari za Asubuhi"
Text(context.skip)              // Will show "Skip" or "Ruka"
```

### 2. Changing the Language

To change the app language, use the LocaleCubit:

```dart
// Switch to Swahili
context.read<LocaleCubit>().setSwahili();

// Switch to English
context.read<LocaleCubit>().setEnglish();

// Set from a language code string
context.read<LocaleCubit>().setFromCode('sw_TZ');
```

### 3. Getting the Current Language

```dart
// Check if current language is Swahili
bool isSwahili = context.isSw;

// Watch for language changes (will rebuild widget)
bool isSwahili = context.isSwWatch;
```

## Adding New Strings

To add new localized strings to the app:

### Step 1: Add Constants to `app_strings.dart`

```dart
class AppStrings {
  // ... existing strings ...
  
  // Add your new strings
  static const String myNewStringEn = 'My English Text';
  static const String myNewStringSw = 'Maandishi Yangu ya Kiswahili';
}
```

### Step 2: Add Extension Getter to `locale_extensions.dart`

```dart
extension AppStringsExtension on BuildContext {
  // ... existing getters ...
  
  // Add your new getter
  String get myNewString => trSw(AppStrings.myNewStringSw, AppStrings.myNewStringEn);
}
```

### Step 3: Use in Your Widget

```dart
Text(context.myNewString)
```

## Available Strings

### Greeting Messages
- `context.goodMorning` - Good Morning / Habari za Asubuhi
- `context.goodAfternoon` - Good Afternoon / Habari za Mchana
- `context.goodEvening` - Good Evening / Habari za Jioni

### Splash Page
- `context.welcomeToMisana` - Welcome to Misana Finance / Karibu Misana Finance
- `context.securingFuture` - Securing your financial future / Kulinda mustakabali wako wa kifedha
- `context.buildingWealth` - Building wealth together / Kujenga utajiri pamoja
- `context.trustedPartner` - Your trusted financial partner / Mshirika wako wa kuaminika wa kifedha
- `context.empoweringGrowth` - Empowering financial growth / Kukuza ukuaji wa kifedha
- `context.creatingProsperity` - Creating prosperity for all / Kuunda mafanikio kwa wote
- `context.checkingSession` - Checking your session... / Inakagua kipindi chako...
- `context.takingLonger` - Taking longer than expected. Retrying... / Inachukua muda mrefu kuliko ilivyotarajiwa. Inajaribu tena...
- `context.financialJourney` - Your Financial Journey Starts Here / Safari Yako ya Kifedha Inaanza Hapa
- `context.misanaBrand` - Misana / Misana

### Onboarding Page
- `context.welcomeToMisanaOnboarding` - Welcome to Misana / Karibu Misana
- `context.trustedPartnerOnboarding` - Your trusted partner for secure savings and financial growth. / Mshirika wako wa kuaminika kwa akiba salama na ukuaji wa kifedha.
- `context.setYourGoals` - Set Your Goals / Weka Malengo Yako
- `context.setYourGoalsDesc` - Create personalized savings plans and reach your financial goals faster. / Unda mipango ya akiba binafsi na ufikie malengo yako ya kifedha haraka.
- `context.saveFlexibly` - Save Flexibly / Hifadhi kwa Urahisi
- `context.saveFlexiblyDesc` - Choose how much and how often you want to save - daily, weekly, or monthly. / Chagua kiasi na mara ngapi unataka kuhifadhi - kila siku, wiki, au mwezi.
- `context.trackProgress` - Track Progress / Fuatilia Maendeleo
- `context.trackProgressDesc` - Watch your savings grow with detailed insights and analytics. / Angalia akiba yako ikikua na ufahamu wa kina na uchambuzi.
- `context.bankGradeSecurity` - Bank-Grade Security / Usalama wa Kiwango cha Benki
- `context.bankGradeSecurityDesc` - Your savings are protected with advanced security measures. / Akiba yako inalindwa na hatua za usalama za hali ya juu.
- `context.skip` - Skip / Ruka
- `context.next` - Next / Ifuatayo
- `context.getStarted` - Get Started / Anza

## Best Practices

1. **Always add both English and Swahili versions** when adding new strings
2. **Use descriptive constant names** that clearly indicate the string's purpose
3. **Keep strings organized** by feature or screen in the AppStrings class
4. **Test with both languages** to ensure proper display and layout
5. **Consider text length differences** between languages when designing UI

## Example: Complete Implementation

Here's a complete example of adding a new localized button:

```dart
// 1. In app_strings.dart
class AppStrings {
  static const String continueButtonEn = 'Continue';
  static const String continueButtonSw = 'Endelea';
}

// 2. In locale_extensions.dart
extension AppStringsExtension on BuildContext {
  String get continueButton => trSw(AppStrings.continueButtonSw, AppStrings.continueButtonEn);
}

// 3. In your widget
ElevatedButton(
  onPressed: () { /* action */ },
  child: Text(context.continueButton),
)
```

## Troubleshooting

### Strings not updating when language changes

Make sure you're using the context-based getters (like `context.welcomeToMisana`) rather than accessing `AppStrings` constants directly.

### Widget not rebuilding on language change

Use `context.isSwWatch` instead of `context.isSw` when you need the widget to rebuild on language changes.

### Missing translations

Check that you've added both the English and Swahili constants in `app_strings.dart` and the corresponding getter in `locale_extensions.dart`.
