import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Simple global locale controller for the whole app.
/// Default language is Kiswahili (sw_TZ).
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(const Locale('sw', 'TZ'));

  void setSwahili() => emit(const Locale('sw', 'TZ'));
  void setEnglish() => emit(const Locale('en', 'US'));

  void setFromCode(String code) {
    if (code.toLowerCase().startsWith('sw')) {
      setSwahili();
    } else {
      setEnglish();
    }
  }
}