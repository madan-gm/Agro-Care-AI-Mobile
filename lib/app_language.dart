import 'package:flutter/foundation.dart';

/// Shared app-wide language: 'en' for English and 'kn' for Kannada.
final ValueNotifier<String> appLanguage = ValueNotifier<String>('en');

String appText(String english, String kannada) =>
    appLanguage.value == 'kn' ? kannada : english;
