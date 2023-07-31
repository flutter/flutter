// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library provides internationalization and localization. This includes
/// message formatting and replacement, date and number formatting and parsing,
/// and utilities for working with Bidirectional text.
///
/// For things that require locale or other data, there are multiple different
/// ways of making that data available, which may require importing different
/// libraries. See the class comments for more details.
library intl;

import 'dart:async';

import 'src/global_state.dart' as global_state;
import 'src/intl/date_format.dart' show DateFormat;
import 'src/intl_helpers.dart' as helpers;
import 'src/plural_rules.dart' as plural_rules;

export 'src/intl/bidi.dart' show Bidi;
export 'src/intl/bidi_formatter.dart' show BidiFormatter;
export 'src/intl/date_format.dart' show DateFormat;
export 'src/intl/micro_money.dart' show MicroMoney;
export 'src/intl/number_format.dart' show NumberFormat;
export 'src/intl/text_direction.dart' show TextDirection;

/// The Intl class provides a common entry point for internationalization
/// related tasks. An Intl instance can be created for a particular locale
/// and used to create a date format via `anIntl.date()`. Static methods
/// on this class are also used in message formatting.
///
/// Examples:
///
/// ```dart
/// String today(DateTime date) => Intl.message(
///       "Today's date is $date",
///       name: 'today',
///       args: [date],
///       desc: 'Indicate the current date',
///       examples: const {'date': 'June 8, 2012'},
///     );
/// print(today(DateTime.now().toString());
///
/// String howManyPeople(int numberOfPeople, String place) => Intl.plural(
///       numberOfPeople,
///       zero: 'I see no one at all in $place.',
///       one: 'I see $numberOfPeople other person in $place.',
///       other: 'I see $numberOfPeople other people in $place.',
///       name: 'howManyPeople',
///       args: [numberOfPeople, place],
///       desc: 'Description of how many people are seen in a place.',
///       examples: const {'numberOfPeople': 3, 'place': 'London'},
///     );
/// ```
///
/// Calling `howManyPeople(2, 'Athens');` would
/// produce "I see 2 other people in Athens." as output in the default locale.
/// If run in a different locale it would produce appropriately translated
/// output.
///
/// You can set the default locale.
///
/// ```dart
/// Intl.defaultLocale = 'pt_BR';
/// ```

class Intl {
  /// String indicating the locale code with which the message is to be
  /// formatted (such as en-CA).
  final String _locale;

  /// The default locale. This defaults to being set from systemLocale, but
  /// can also be set explicitly, and will then apply to any new instances where
  /// the locale isn't specified. Note that a locale parameter to
  /// [Intl.withLocale]
  /// will supercede this value while that operation is active. Using
  /// [Intl.withLocale] may be preferable if you are using different locales
  /// in the same application.
  static String? get defaultLocale => global_state.defaultLocale;

  static set defaultLocale(String? newLocale) =>
      global_state.defaultLocale = newLocale;

  /// The system's locale, as obtained from the window.navigator.language
  /// or other operating system mechanism. Note that due to system limitations
  /// this is not automatically set, and must be set by importing one of
  /// intl_browser.dart or intl_standalone.dart and calling findSystemLocale().
  static String get systemLocale => global_state.systemLocale;
  static set systemLocale(String locale) => global_state.systemLocale = locale;

  /// Return a new date format using the specified [pattern].
  /// If [desiredLocale] is not specified, then we default to [locale].
  DateFormat date([String? pattern, String? desiredLocale]) {
    var actualLocale = (desiredLocale == null) ? locale : desiredLocale;
    return DateFormat(pattern, actualLocale);
  }

  /// Constructor optionally [aLocale] for specifics of the language
  /// locale to be used, otherwise, we will attempt to infer it (acceptable if
  /// Dart is running on the client, we can infer from the browser/client
  /// preferences).
  Intl([String? aLocale])
      : _locale = aLocale != null ? aLocale : getCurrentLocale();

  /// Use this for a message that will be translated for different locales. The
  /// expected usage is that this is inside an enclosing function that only
  /// returns the value of this call and provides a scope for the variables that
  /// will be substituted in the message.
  ///
  /// The [messageText] is the string to be translated, which may be
  /// interpolated based on one or more variables.
  ///
  /// The [args] is a list containing the arguments of the enclosing function.
  /// If there are no arguments, [args] can be omitted.
  ///
  /// The [name] is required only for messages that have [args], and optional
  /// for messages without [args]. It is used at runtime to look up the message
  /// and pass the appropriate arguments to it. If provided, [name] must be
  /// globally unique in the program. It must match the enclosing function name,
  /// or if the function is a method of a class, [name] can also be of the form
  /// <className>_<methodName>, to make it easier to distinguish messages with
  /// the same name but in different classes.
  ///
  /// The [desc] provides a description of the message usage.
  ///
  /// The [examples] is a const Map of examples for each interpolated variable.
  /// For example
  ///
  /// ```dart
  /// String hello(String yourName) => Intl.message(
  ///       'Hello, $yourName',
  ///       name: 'hello',
  ///       args: [yourName],
  ///       desc: 'Say hello',
  ///       examples: const {'yourName': 'Sparky'},
  ///     );
  /// ```
  ///
  /// The source code will be processed via the analyzer to extract out the
  /// message data, so only a subset of valid Dart code is accepted. In
  /// particular, everything must be literal and cannot refer to variables
  /// outside the scope of the enclosing function. The [examples] map must be a
  /// valid const literal map. Similarly, the [desc] argument must be a single,
  /// simple string and [skip] a boolean literal. These three arguments will not
  /// be used at runtime but will be extracted from the source code and used as
  /// additional data for translators. For more information see the "Messages"
  /// section of the main
  /// [package documentation] (https://pub.dev/packages/intl).
  ///
  /// The [skip] arg will still validate the message, but will be filtered from
  /// the extracted message output. This can be useful to set up placeholder
  /// messages during development whose text aren't finalized yet without having
  /// the placeholder automatically translated.
  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  // We want to try to inline these messages, but not inline the internal
  // messages, so it will eliminate the descriptions and other information
  // not needed at runtime.
  static String message(String messageText,
          {String? desc = '',
          Map<String, Object>? examples,
          String? locale,
          String? name,
          List<Object>? args,
          String? meaning,
          bool? skip}) =>
      _message(messageText, locale, name, args, meaning);

  /// Omit the compile-time only parameters so dart2js can see to drop them.
  @pragma('dart2js:noInline')
  static String _message(String? messageText, String? locale, String? name,
      List<Object>? args, String? meaning) {
    return _lookupMessage(messageText, locale, name, args, meaning)!;
  }

  static String? _lookupMessage(String? messageText, String? locale,
      String? name, List<Object>? args, String? meaning) {
    return helpers.messageLookup
        .lookupMessage(messageText, locale, name, args, meaning);
  }

  /// Return the locale for this instance. If none was set, the locale will
  /// be the default.
  String get locale => _locale;

  /// Given [newLocale] return a locale that we have data for that is similar
  /// to it, if possible.
  ///
  /// If [newLocale] is found directly, return it. If it can't be found, look up
  /// based on just the language (e.g. 'en_CA' -> 'en'). Also accepts '-'
  /// as a separator and changes it into '_' for lookup, and changes the
  /// country to uppercase.
  ///
  /// There is a special case that if a locale named "fallback" is present
  /// and has been initialized, this will return that name. This can be useful
  /// for messages where you don't want to just use the text from the original
  /// source code, but wish to have a universal fallback translation.
  ///
  /// Note that null is interpreted as meaning the default locale, so if
  /// [newLocale] is null the default locale will be returned.
  ///
  /// Can return `null` only if verification fails and `onFailure` returns
  /// null. Otherwise, throws instead.
  static String? verifiedLocale(
          String? newLocale, bool Function(String) localeExists,
          {String? Function(String)? onFailure}) =>
      helpers.verifiedLocale(newLocale, localeExists, onFailure);

  /// Return the short version of a locale name, e.g. 'en_US' => 'en'
  static String shortLocale(String aLocale) => helpers.shortLocale(aLocale);

  /// Return the name [aLocale] turned into xx_YY where it might possibly be
  /// in the wrong case or with a hyphen instead of an underscore. If
  /// [aLocale] is null, for example, if you tried to get it from IE,
  /// return the current system locale.
  static String canonicalizedLocale(String? aLocale) =>
      helpers.canonicalizedLocale(aLocale);

  /// Formats a message differently depending on [howMany].
  ///
  /// Selects the correct plural form from the provided alternatives.
  /// The [other] named argument is mandatory.
  /// The [precision] is the number of fractional digits that would be rendered
  /// when [howMany] is formatted. In some cases just knowing the numeric value
  /// of [howMany] itsef is not enough, for example "1 mile" vs "1.00 miles"
  ///
  /// For an explanation of plurals and the [zero], [one], [two], [few], [many]
  /// categories see http://cldr.unicode.org/index/cldr-spec/plural-rules
  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  static String plural(num howMany,
      {String? zero,
      String? one,
      String? two,
      String? few,
      String? many,
      required String other,
      String? desc,
      Map<String, Object>? examples,
      String? locale,
      int? precision,
      String? name,
      List<Object>? args,
      String? meaning,
      bool? skip}) {
    // Call our internal method, dropping examples and desc because they're not
    // used at runtime and we want them to be optimized away.
    return _plural(howMany,
        zero: zero,
        one: one,
        two: two,
        few: few,
        many: many,
        other: other,
        locale: locale,
        precision: precision,
        name: name,
        args: args,
        meaning: meaning);
  }

  @pragma('dart2js:noInline')
  static String _plural(num howMany,
      {String? zero,
      String? one,
      String? two,
      String? few,
      String? many,
      required String other,
      String? locale,
      int? precision,
      String? name,
      List<Object>? args,
      String? meaning}) {
    // Look up our translation, but pass in a null message so we don't have to
    // eagerly evaluate calls that may not be necessary.
    var translated = _lookupMessage(null, locale, name, args, meaning);

    /// If there's a translation, return it, otherwise evaluate with our
    /// original text.
    return translated ??
        pluralLogic(howMany,
            zero: zero,
            one: one,
            two: two,
            few: few,
            many: many,
            other: other,
            locale: locale,
            precision: precision);
  }

  /// Internal: Implements the logic for plural selection - use [plural] for
  /// normal messages.
  static T pluralLogic<T>(num howMany,
      {T? zero,
      T? one,
      T? two,
      T? few,
      T? many,
      required T other,
      String? locale,
      int? precision,
      String? meaning}) {
    ArgumentError.checkNotNull(other, 'other');
    ArgumentError.checkNotNull(howMany, 'howMany');
    // If we haven't specified precision and we have a float that is an integer
    // value, turn it into an integer. This gives us the behavior that 1.0 and 1
    // produce the same output, e.g. 1 dollar.
    var truncated = howMany.truncate();
    if (precision == null && truncated == howMany) {
      howMany = truncated;
    }

    // This is for backward compatibility.
    // We interpret the presence of [precision] parameter as an "opt-in" to
    // the new behavior, since [precision] did not exist before.
    // For an English example: if the precision is 2 then the formatted string
    // would not map to 'one' (for example "1.00 miles")
    if (precision == null || precision == 0) {
      // If there's an explicit case for the exact number, we use it. This is
      // not strictly in accord with the CLDR rules, but it seems to be the
      // expectation. At least I see e.g. Russian translations that have a zero
      // case defined. The rule for that locale will never produce a zero, and
      // treats it as other. But it seems reasonable that, even if the language
      // rules treat zero as other, we might want a special message for zero.
      if (howMany == 0 && zero != null) return zero;
      if (howMany == 1 && one != null) return one;
      if (howMany == 2 && two != null) return two;
    }

    var pluralRule = _pluralRule(locale, howMany, precision);
    var pluralCase = pluralRule();
    switch (pluralCase) {
      case plural_rules.PluralCase.ZERO:
        return zero ?? other;
      case plural_rules.PluralCase.ONE:
        return one ?? other;
      case plural_rules.PluralCase.TWO:
        return two ?? few ?? other;
      case plural_rules.PluralCase.FEW:
        return few ?? other;
      case plural_rules.PluralCase.MANY:
        return many ?? other;
      case plural_rules.PluralCase.OTHER:
        return other;
      default:
        throw ArgumentError.value(
            howMany, 'howMany', 'Invalid plural argument');
    }
  }

  static plural_rules.PluralRule? _cachedPluralRule;
  static String? _cachedPluralLocale;

  static plural_rules.PluralRule _pluralRule(
      String? locale, num howMany, int? precision) {
    plural_rules.startRuleEvaluation(howMany, precision);
    var verifiedLocale = Intl.verifiedLocale(
        locale, plural_rules.localeHasPluralRules,
        onFailure: (locale) => 'default');
    if (_cachedPluralLocale == verifiedLocale) {
      return _cachedPluralRule!;
    } else {
      _cachedPluralRule = plural_rules.pluralRules[verifiedLocale];
      _cachedPluralLocale = verifiedLocale;
      return _cachedPluralRule!;
    }
  }

  /// Format a message differently depending on [targetGender].
  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  static String gender(String targetGender,
      {String? female,
      String? male,
      required String other,
      String? desc,
      Map<String, Object>? examples,
      String? locale,
      String? name,
      List<Object>? args,
      String? meaning,
      bool? skip}) {
    // Call our internal method, dropping args and desc because they're not used
    // at runtime and we want them to be optimized away.
    return _gender(targetGender,
        male: male,
        female: female,
        other: other,
        locale: locale,
        name: name,
        args: args,
        meaning: meaning);
  }

  @pragma('dart2js:noInline')
  static String _gender(String targetGender,
      {String? female,
      String? male,
      required String other,
      String? locale,
      String? name,
      List<Object>? args,
      String? meaning}) {
    // Look up our translation, but pass in a null message so we don't have to
    // eagerly evaluate calls that may not be necessary.
    var translated = _lookupMessage(null, locale, name, args, meaning);

    /// If there's a translation, return it, otherwise evaluate with our
    /// original text.
    return translated ??
        genderLogic(targetGender,
            female: female, male: male, other: other, locale: locale);
  }

  /// Internal: Implements the logic for gender selection - use [gender] for
  /// normal messages.
  static T genderLogic<T>(String targetGender,
      {T? female, T? male, required T other, String? locale}) {
    ArgumentError.checkNotNull(other, 'other');
    switch (targetGender) {
      case 'female':
        return female == null ? other : female;
      case 'male':
        return male == null ? other : male;
      default:
        return other;
    }
  }

  /// Format a message differently depending on [choice].
  ///
  /// We look up the value
  /// of [choice] in [cases] and return the result, or an empty string if
  /// it is not found. Normally used as part
  /// of an Intl.message message that is to be translated.
  ///
  /// It is possible to use a Dart enum as the choice and as the
  /// key in cases, but note that we will process this by truncating
  /// toString() of the enum and using just the name part. We will
  /// do this for any class or strings that are passed, since we
  /// can't actually identify if something is an enum or not.
  ///
  /// The first argument in [args] must correspond to the [choice] Object.
  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  static String select(Object choice, Map<Object, String> cases,
      {String? desc,
      Map<String, Object>? examples,
      String? locale,
      String? name,
      List<Object>? args,
      String? meaning,
      bool? skip}) {
    return _select(choice, cases,
        locale: locale, name: name, args: args, meaning: meaning);
  }

  @pragma('dart2js:noInline')
  static String _select(Object choice, Map<Object, String> cases,
      {String? locale, String? name, List<Object>? args, String? meaning}) {
    // Look up our translation, but pass in a null message so we don't have to
    // eagerly evaluate calls that may not be necessary.
    var stringChoice = choice is String ? choice : '$choice'.split('.').last;
    var modifiedArgs =
        args == null ? null : (<Object>[stringChoice]..addAll(args.skip(1)));
    var translated = _lookupMessage(null, locale, name, modifiedArgs, meaning);

    /// If there's a translation, return it, otherwise evaluate with our
    /// original text.
    return translated ?? selectLogic(choice, cases);
  }

  /// Internal: Implements the logic for select - use [select] for
  /// normal messages.
  static T selectLogic<T>(Object choice, Map<Object, T> cases) {
    // This will work if choice is a string, or if it's e.g. an
    // enum and the map uses the enum values as choices.
    var exact = cases[choice];
    if (exact != null) return exact;
    // If it didn't match exactly, take the toString and
    // take the part after the period. We need to do this
    // because enums print as 'EnumType.enumName' and periods
    // aren't acceptable in ICU select choices.
    var stringChoice = '$choice'.split('.').last;
    var stringMatch = cases[stringChoice];
    if (stringMatch != null) return stringMatch;
    var other = cases['other'];
    if (other == null) {
      throw ArgumentError("The 'other' case must be specified");
    }
    return other;
  }

  /// Run [function] with the default locale set to [locale] and
  /// return the result.
  ///
  /// This is run in a zone, so async operations invoked
  /// from within [function] will still have the locale set.
  ///
  /// In simple usage [function] might be a single
  /// `Intl.message()` call or number/date formatting operation. But it can
  /// also be an arbitrary function that calls multiple Intl operations.
  ///
  /// For example
  ///
  ///       Intl.withLocale('fr', () => NumberFormat.format(123456));
  ///
  /// or
  ///
  ///       hello(name) => Intl.message(
  ///           'Hello $name.',
  ///           name: 'hello',
  ///           args: [name],
  ///           desc: 'Say Hello');
  ///       Intl.withLocale('zh', Timer(Duration(milliseconds:10),
  ///           () => print(hello('World')));
  static dynamic withLocale<T>(String? locale, T Function() function) {
    // TODO(alanknight): Make this return T. This requires work because T might
    // be Future and the caller could get an unawaited Future.  Which is
    // probably an error in their code, but the change is semi-breaking.
    var canonical = Intl.canonicalizedLocale(locale);
    return runZoned(function, zoneValues: {#Intl.locale: canonical});
  }

  /// Accessor for the current locale. This should always == the default locale,
  /// unless for some reason this gets called inside a message that resets the
  /// locale.
  static String getCurrentLocale() {
    return defaultLocale ??= systemLocale;
  }

  String toString() => 'Intl($locale)';
}

/// Convert a string to beginning of sentence case, in a way appropriate to the
/// locale.
///
/// Currently this just converts the first letter to uppercase, which works for
/// many locales, and we have the option to extend this to handle more cases
/// without changing the API for clients. It also hard-codes the case of
/// dotted i in Turkish and Azeri.
String? toBeginningOfSentenceCase(String? input, [String? locale]) {
  if (input == null || input.isEmpty) return input;
  return '${_upperCaseLetter(input[0], locale)}${input.substring(1)}';
}

/// Convert the input single-letter string to upper case. A trivial
/// hard-coded implementation that only handles simple upper case
/// and the dotted i in Turkish/Azeri.
///
/// Private to the implementation of [toBeginningOfSentenceCase].
// TODO(alanknight): Consider hard-coding other important cases.
// See http://www.unicode.org/Public/UNIDATA/SpecialCasing.txt
// TODO(alanknight): Alternatively, consider toLocaleUpperCase in browsers.
// See also https://github.com/dart-lang/sdk/issues/6706
String _upperCaseLetter(String input, String? locale) {
  // Hard-code the important edge case of i->İ
  if (locale != null) {
    if (input == 'i' && locale.startsWith('tr') || locale.startsWith('az')) {
      return '\u0130';
    }
  }
  return input.toUpperCase();
}
