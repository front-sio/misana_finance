import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'locale_cubit.dart';
import 'app_strings.dart';


extension LocaleHelper on BuildContext {
  bool get isSw => read<LocaleCubit>().state.languageCode == 'sw';
  bool get isSwWatch => watch<LocaleCubit>().state.languageCode == 'sw';


  String trSw(String sw, String en) => isSw ? sw : en;

 
  String trSwWatch(String sw, String en) => isSwWatch ? sw : en;
}

extension AppStringsExtension on BuildContext {
  // Greeting messages
  String get goodMorning => trSw(AppStrings.goodMorningSw, AppStrings.goodMorningEn);
  String get goodAfternoon => trSw(AppStrings.goodAfternoonSw, AppStrings.goodAfternoonEn);
  String get goodEvening => trSw(AppStrings.goodEveningSw, AppStrings.goodEveningEn);
  
  // Splash page messages
  String get welcomeToMisana => trSw(AppStrings.welcomeToMisanaSw, AppStrings.welcomeToMisanaEn);
  String get securingFuture => trSw(AppStrings.securingFutureSw, AppStrings.securingFutureEn);
  String get buildingWealth => trSw(AppStrings.buildingWealthSw, AppStrings.buildingWealthEn);
  String get trustedPartner => trSw(AppStrings.trustedPartnerSw, AppStrings.trustedPartnerEn);
  String get empoweringGrowth => trSw(AppStrings.empoweringGrowthSw, AppStrings.empoweringGrowthEn);
  String get creatingProsperity => trSw(AppStrings.creatingProsperitySw, AppStrings.creatingProsperityEn);
  String get checkingSession => trSw(AppStrings.checkingSessionSw, AppStrings.checkingSessionEn);
  String get takingLonger => trSw(AppStrings.takingLongerSw, AppStrings.takingLongerEn);
  String get financialJourney => trSw(AppStrings.financialJourneySw, AppStrings.financialJourneyEn);
  String get misanaBrand => trSw(AppStrings.misanaBrandSw, AppStrings.misanaBrandEn);
  
  // Onboarding page messages
  String get welcomeToMisanaOnboarding => trSw(AppStrings.welcomeToMisanaOnboardingSw, AppStrings.welcomeToMisanaOnboardingEn);
  String get trustedPartnerOnboarding => trSw(AppStrings.trustedPartnerOnboardingSw, AppStrings.trustedPartnerOnboardingEn);
  String get setYourGoals => trSw(AppStrings.setYourGoalsSw, AppStrings.setYourGoalsEn);
  String get setYourGoalsDesc => trSw(AppStrings.setYourGoalsDescSw, AppStrings.setYourGoalsDescEn);
  String get saveFlexibly => trSw(AppStrings.saveFlexiblySw, AppStrings.saveFlexiblyEn);
  String get saveFlexiblyDesc => trSw(AppStrings.saveFlexiblyDescSw, AppStrings.saveFlexiblyDescEn);
  String get trackProgress => trSw(AppStrings.trackProgressSw, AppStrings.trackProgressEn);
  String get trackProgressDesc => trSw(AppStrings.trackProgressDescSw, AppStrings.trackProgressDescEn);
  String get bankGradeSecurity => trSw(AppStrings.bankGradeSecuritySw, AppStrings.bankGradeSecurityEn);
  String get bankGradeSecurityDesc => trSw(AppStrings.bankGradeSecurityDescSw, AppStrings.bankGradeSecurityDescEn);
  String get skip => trSw(AppStrings.skipSw, AppStrings.skipEn);
  String get next => trSw(AppStrings.nextSw, AppStrings.nextEn);
  String get getStarted => trSw(AppStrings.getStartedSw, AppStrings.getStartedEn);
}