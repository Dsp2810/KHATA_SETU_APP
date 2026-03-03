import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage.dart';

/// Supported locale codes
const kSupportedLocales = ['en', 'gu', 'hi'];
const kDefaultLocaleCode = 'gu'; // Gujarati fallback
const kSecondaryFallbackCode = 'en';

/// LanguageCubit — manages the active locale with persistent storage.
/// Emits [Locale] changes that trigger full MaterialApp rebuild.
class LanguageCubit extends Cubit<Locale> {
  final LocalStorageService _storage;

  LanguageCubit(this._storage) : super(_resolveInitialLocale(_storage));

  /// Resolve initial locale from storage, device, or fallback
  static Locale _resolveInitialLocale(LocalStorageService storage) {
    final saved = storage.getLanguage();

    // 1. Saved in preferences — validate it
    if (saved.isNotEmpty && kSupportedLocales.contains(saved)) {
      return Locale(saved);
    }

    // 2. Device locale auto-detection (first launch)
    final deviceLocale = PlatformDispatcher.instance.locale;
    if (kSupportedLocales.contains(deviceLocale.languageCode)) {
      storage.saveLanguage(deviceLocale.languageCode);
      return Locale(deviceLocale.languageCode);
    }

    // 3. Default fallback: Gujarati → English
    storage.saveLanguage(kDefaultLocaleCode);
    return const Locale(kDefaultLocaleCode);
  }

  /// Change locale and persist
  void setLocale(String languageCode) {
    if (!kSupportedLocales.contains(languageCode)) {
      languageCode = kDefaultLocaleCode;
    }
    _storage.saveLanguage(languageCode);
    emit(Locale(languageCode));
  }

  /// Current language code
  String get languageCode => state.languageCode;
}
