import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'locale_cubit.dart';


extension LocaleHelper on BuildContext {
  bool get isSw => read<LocaleCubit>().state.languageCode == 'sw';
  bool get isSwWatch => watch<LocaleCubit>().state.languageCode == 'sw';


  String trSw(String sw, String en) => isSw ? sw : en;

 
  String trSwWatch(String sw, String en) => isSwWatch ? sw : en;
}