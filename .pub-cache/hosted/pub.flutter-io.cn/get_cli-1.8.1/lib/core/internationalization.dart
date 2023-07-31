import 'dart:io';

import 'locales.g.dart';

extension Trans on String {
  /// Translation
  String get tr {
    var translations = AppTranslation.translations;
    var localeName = Platform.localeName;
    // Mac return pt-BR;
    localeName = localeName.replaceAll('-', '_');
    // Returns the key if locale is null.

    // if (localeName == null) return this;

    // Checks whether the language code and country code are present, and
    // whether the key is also present.
    if (translations.containsKey(localeName) &&
        translations[localeName]!.containsKey(this)) {
      return translations[localeName]![this]!;

      // Checks if there is a callback language in the absence of the specific
      // country, and if it contains that key.
    } else if (translations.containsKey(localeName.languageCode) &&
        translations[localeName.languageCode]!.containsKey(this)) {
      return translations[localeName.languageCode]![this]!;
      // If there is no corresponding language or corresponding key, return
      // the key.
    } else {
      final key = 'en';
      if (translations.containsKey(key) &&
          translations[key]!.containsKey(this)) {
        return translations[key]![this]!;
      }
      if (translations.containsKey(key.languageCode) &&
          translations[key.languageCode]!.containsKey(this)) {
        return translations[key.languageCode]![this]!;
      }
      return this;
    }
  }

  String trArgs([List<String?> args = const []]) {
    var key = tr;
    if (args.isNotEmpty) {
      for (final arg in args) {
        key = key.replaceFirst(RegExp(r'%s'), arg.toString());
      }
    }
    return key;
  }

  String? trPlural([String? plural, int i = 0]) {
    return i > 1 ? plural?.tr : tr;
  }

  String? trArgsPlural(
      [String? plural, int i = 0, List<String> args = const []]) {
    return i > 1 ? plural?.trArgs(args) : trArgs(args);
  }
}

extension _TranslationUtils on String {
  String get languageCode => split('_').first;
}

class Translation {
  final String _key;
  Translation(this._key);

  @override
  String toString() => tr;

  String get tr => _key.tr;

  String? trArgs([List<String>? args]) => _key.trArgs(args ?? []);
}
