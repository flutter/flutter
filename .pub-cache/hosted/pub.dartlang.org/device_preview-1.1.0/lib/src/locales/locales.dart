import 'dart:collection';
import 'dart:ui';

/// A locale that has a display name.
class NamedLocale {
  /// Create a new named locale from a [code] and a [name].
  const NamedLocale(
    this.code,
    this.name,
  );

  /// The locale code in the form of `<countryCode>_`
  final String code;

  /// A display name for the locale.
  final String name;

  /// A locale that can be used with widgets.
  Locale get locale {
    final splits = code.split('_');

    final languageCode = splits.first;
    String? countryCode, scriptCode;
    if (splits.length > 2) {
      scriptCode = splits[1];
      countryCode = splits[2];
    } else if (splits.length > 1) {
      countryCode = splits[1];
    }

    return Locale.fromSubtags(
      countryCode: countryCode,
      languageCode: languageCode,
      scriptCode: scriptCode,
    );
  }

  @override
  String toString() => name;
}

Locale basicLocaleListResolution(
  List<Locale>? preferredLocales,
  Iterable<Locale> supportedLocales,
) {
  // preferredLocales can be null when called before the platform has had a chance to
  // initialize the locales. Platforms without locale passing support will provide an empty list.
  // We default to the first supported locale in these cases.
  if (preferredLocales == null || preferredLocales.isEmpty) {
    return supportedLocales.first;
  }
  // Hash the supported locales because apps can support many locales and would
  // be expensive to search through them many times.
  final Map<String, Locale> allSupportedLocales = HashMap<String, Locale>();
  final Map<String, Locale> languageAndCountryLocales =
      HashMap<String, Locale>();
  final Map<String, Locale> languageAndScriptLocales =
      HashMap<String, Locale>();
  final Map<String, Locale> languageLocales = HashMap<String, Locale>();
  final Map<String, Locale> countryLocales = HashMap<String, Locale>();
  for (final locale in supportedLocales) {
    allSupportedLocales[
            '${locale.languageCode}_${locale.scriptCode}_${locale.countryCode}'] ??=
        locale;
    languageAndScriptLocales['${locale.languageCode}_${locale.scriptCode}'] ??=
        locale;
    languageAndCountryLocales[
        '${locale.languageCode}_${locale.countryCode}'] ??= locale;
    languageLocales[locale.languageCode] ??= locale;
    if (locale.countryCode != null) {
      countryLocales[locale.countryCode!] ??= locale;
    }
  }

  // Since languageCode-only matches are possibly low quality, we don't return
  // it instantly when we find such a match. We check to see if the next
  // preferred locale in the list has a high accuracy match, and only return
  // the languageCode-only match when a higher accuracy match in the next
  // preferred locale cannot be found.
  Locale? matchesLanguageCode;
  Locale? matchesCountryCode;
  // Loop over user's preferred locales
  for (var localeIndex = 0;
      localeIndex < preferredLocales.length;
      localeIndex += 1) {
    final userLocale = preferredLocales[localeIndex];
    // Look for perfect match.
    if (allSupportedLocales.containsKey(
      '${userLocale.languageCode}_${userLocale.scriptCode}_${userLocale.countryCode}',
    )) {
      return userLocale;
    }
    // Look for language+script match.
    if (userLocale.scriptCode != null) {
      final match = languageAndScriptLocales[
          '${userLocale.languageCode}_${userLocale.scriptCode}'];
      if (match != null) {
        return match;
      }
    }
    // Look for language+country match.
    if (userLocale.countryCode != null) {
      final match = languageAndCountryLocales[
          '${userLocale.languageCode}_${userLocale.countryCode}'];
      if (match != null) {
        return match;
      }
    }
    // If there was a languageCode-only match in the previous iteration's higher
    // ranked preferred locale, we return it if the current userLocale does not
    // have a better match.
    if (matchesLanguageCode != null) {
      return matchesLanguageCode;
    }
    // Look and store language-only match.
    var match = languageLocales[userLocale.languageCode];
    if (match != null) {
      matchesLanguageCode = match;
      // Since first (default) locale is usually highly preferred, we will allow
      // a languageCode-only match to be instantly matched. If the next preferred
      // languageCode is the same, we defer hastily returning until the next iteration
      // since at worst it is the same and at best an improved match.
      if (localeIndex == 0 &&
          !(localeIndex + 1 < preferredLocales.length &&
              preferredLocales[localeIndex + 1].languageCode ==
                  userLocale.languageCode)) {
        return matchesLanguageCode;
      }
    }
    // countryCode-only match. When all else except default supported locale fails,
    // attempt to match by country only, as a user is likely to be familar with a
    // language from their listed country.
    if (matchesCountryCode == null && userLocale.countryCode != null) {
      match = countryLocales[userLocale.countryCode];
      if (match != null) {
        matchesCountryCode = match;
      }
    }
  }
  // When there is no languageCode-only match. Fallback to matching countryCode only. Country
  // fallback only applies on iOS. When there is no countryCode-only match, we return first
  // suported locale.
  final resolvedLocale =
      matchesLanguageCode ?? matchesCountryCode ?? supportedLocales.first;
  return resolvedLocale;
}
