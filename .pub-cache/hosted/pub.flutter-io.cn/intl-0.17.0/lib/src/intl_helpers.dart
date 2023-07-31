// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library for general helper code associated with the intl library
/// rather than confined to specific parts of it.

library intl_helpers;

import 'global_state.dart' as global_state;
import 'intl_helpers.dart' as helpers;

/// Type for the callback action when a message translation is not found.
typedef MessageIfAbsent = String Function(
    String? messageText, List<Object>? args);

/// This is used as a marker for a locale data map that hasn't been initialized,
/// and will throw an exception on any usage that isn't the fallback
/// patterns/symbols provided.
class UninitializedLocaleData<F> implements MessageLookup {
  final String message;
  final F fallbackData;
  UninitializedLocaleData(this.message, this.fallbackData);

  bool _isFallback(String key) => canonicalizedLocale(key) == 'en_US';

  F operator [](String key) =>
      _isFallback(key) ? fallbackData : _throwException();

  /// If a message is looked up before any locale initialization, record it,
  /// and throw an exception with that information once the locale is
  /// initialized.
  ///
  /// Set this during development to find issues with race conditions between
  /// message caching and locale initialization. If the results of Intl.message
  /// calls aren't being cached, then this won't help.
  ///
  /// There's nothing that actually sets this, so checking this requires
  /// patching the code here.
  static final bool throwOnFallback = false;

  /// The messages that were called before the locale was initialized.
  final List<String> _badMessages = [];

  void _reportErrors() {
    if (throwOnFallback && _badMessages.isNotEmpty) {
      throw StateError(
          'The following messages were called before locale initialization:'
          ' $_uninitializedMessages');
    }
  }

  String get _uninitializedMessages =>
      (_badMessages.toSet().toList()..sort()).join('\n    ');

  String? lookupMessage(String? messageText, String? locale, String? name,
      List<Object>? args, String? meaning,
      {MessageIfAbsent? ifAbsent}) {
    if (throwOnFallback) {
      _badMessages.add((name ?? messageText)!);
    }
    return messageText;
  }

  /// Given an initial locale or null, returns the locale that will be used
  /// for messages.
  String findLocale(String? locale) =>
      locale ?? global_state.getCurrentLocale();

  List<String> get keys => _throwException() as List<String>;

  bool containsKey(String key) {
    if (!_isFallback(key)) {
      _throwException();
    }
    return true;
  }

  F _throwException() {
    throw LocaleDataException('Locale data has not been initialized'
        ', call $message.');
  }

  void addLocale(String localeName, Function findLocale) => _throwException();
}

abstract class MessageLookup {
  String? lookupMessage(String? messageText, String? locale, String? name,
      List<Object>? args, String? meaning,
      {MessageIfAbsent? ifAbsent});
  void addLocale(String localeName, Function findLocale);
}

class LocaleDataException implements Exception {
  final String message;
  LocaleDataException(this.message);
  String toString() => 'LocaleDataException: $message';
}

///  An abstract superclass for data readers to keep the type system happy.
abstract class LocaleDataReader {
  Future<String> read(String locale);
}

/// The internal mechanism for looking up messages. We expect this to be set
/// by the implementing package so that we're not dependent on its
/// implementation.
MessageLookup messageLookup =
    UninitializedLocaleData('initializeMessages(<locale>)', null);

/// Initialize the message lookup mechanism. This is for internal use only.
/// User applications should import `message_lookup_by_library.dart` and call
/// `initializeMessages`
void initializeInternalMessageLookup(Function lookupFunction) {
  if (messageLookup is UninitializedLocaleData<dynamic>) {
    // This line has to be precisely this way to work around an analyzer crash.
    (messageLookup as UninitializedLocaleData<dynamic>)._reportErrors();
    messageLookup = lookupFunction();
  }
}

/// If a message is a string literal without interpolation, compute
/// a name based on that and the meaning, if present.
// NOTE: THIS LOGIC IS DUPLICATED IN intl_translation AND THE TWO MUST MATCH.
String? computeMessageName(String? name, String? text, String? meaning) {
  if (name != null && name != '') return name;
  return meaning == null ? text : '${text}_$meaning';
}

String canonicalizedLocale(String? aLocale) {
// Locales of length < 5 are presumably two-letter forms, or else malformed.
// We return them unmodified and if correct they will be found.
// Locales longer than 6 might be malformed, but also do occur. Do as
// little as possible to them, but make the '-' be an '_' if it's there.
// We treat C as a special case, and assume it wants en_ISO for formatting.
// TODO(alanknight): en_ISO is probably not quite right for the C/Posix
// locale for formatting. Consider adding C to the formats database.
  if (aLocale == null) return global_state.getCurrentLocale();
  if (aLocale == 'C') return 'en_ISO';
  if (aLocale.length < 5) return aLocale;
  if (aLocale[2] != '-' && (aLocale[2] != '_')) return aLocale;
  var region = aLocale.substring(3);
// If it's longer than three it's something odd, so don't touch it.
  if (region.length <= 3) region = region.toUpperCase();
  return '${aLocale[0]}${aLocale[1]}_$region';
}

String? verifiedLocale(String? newLocale, bool Function(String) localeExists,
    String? Function(String)? onFailure) {
// TODO(alanknight): Previously we kept a single verified locale on the Intl
// object, but with different verification for different uses, that's more
// difficult. As a result, we call this more often. Consider keeping
// verified locales for each purpose if it turns out to be a performance
// issue.
  if (newLocale == null) {
    return verifiedLocale(
        global_state.getCurrentLocale(), localeExists, onFailure);
  }
  if (localeExists(newLocale)) {
    return newLocale;
  }
  for (var each in [
    helpers.canonicalizedLocale(newLocale),
    helpers.shortLocale(newLocale),
    'fallback'
  ]) {
    if (localeExists(each)) {
      return each;
    }
  }
  return (onFailure ?? _throwLocaleError)(newLocale);
}

/// The default action if a locale isn't found in verifiedLocale. Throw
/// an exception indicating the locale isn't correct.
String _throwLocaleError(String localeName) {
  throw ArgumentError('Invalid locale "$localeName"');
}

/// Return the short version of a locale name, e.g. 'en_US' => 'en'
String shortLocale(String aLocale) {
  if (aLocale.length < 2) return aLocale;
  return aLocale.substring(0, 2).toLowerCase();
}
