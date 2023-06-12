// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This defines a class for loading locale data incrementally from
/// an external source as JSON. The external sources expected are either
/// local files or via HTTP request.

library lazy_locale_data;

import 'dart:convert';
import 'intl_helpers.dart';

/// This implements the very basic map-type operations which are used
/// in locale lookup, and looks them up based on a URL that defines
/// the external source.
class LazyLocaleData {
  /// This holds the data we have loaded.
  Map<dynamic, dynamic> map;

  /// The object that actually does the data reading.
  final LocaleDataReader _reader;

  /// In order to avoid a potentially remote call to see if a locale
  /// is available, we hold a complete list of all the available
  /// locales.
  List<String> availableLocales;

  /// Given a piece of remote data, apply [_creationFunction] to it to
  /// convert it into the right form. Typically this means converting it
  /// from a Map into an object form.
  final Function _creationFunction;

  /// The set of available locales.
  Set<String> availableLocaleSet;

  /// The constructor. The [_reader] specifies where the data comes
  /// from. The [_creationFunction] creates the appropriate data type
  /// from the remote data (which typically comes in as a Map). The
  /// [keys] lists the set of remotely available locale names so we know which
  /// things can be fetched without having to check remotely.
  LazyLocaleData(this._reader, this._creationFunction, this.availableLocales)
      : map = {},
        availableLocaleSet = Set.from(availableLocales);

  ///  Tests if we have data for the locale available. Note that this returns
  /// true even if the data is known to be available remotely but not yet
  /// loaded.
  bool containsKey(String locale) => availableLocaleSet.contains(locale);

  /// Returns the list of keys/locale names.
  List<String> get keys => availableLocales;

  /// Returns the data stored for [localeName]. If no data has been loaded
  /// for [localeName], throws an exception. If no data is available for
  /// [localeName] then throw an exception with a different message.
  dynamic operator [](String localeName) {
    if (containsKey(localeName)) {
      dynamic data = map[localeName];
      if (data == null) {
        throw LocaleDataException('Locale $localeName has not been initialized.'
            ' Call initializeDateFormatting($localeName, <data url>) first');
      } else {
        return data;
      }
    } else {
      unsupportedLocale(localeName);
    }
  }

  /// Throw an exception indicating that the locale has no data available,
  /// either locally or remotely.
  void unsupportedLocale(String localeName) {
    throw LocaleDataException('Locale $localeName has no data available');
  }

  /// Initialize for locale. Internal use only. As a user, call
  /// initializeDateFormatting instead.
  Future<void> initLocale(String localeName) {
    var data = _reader.read(localeName);
    // ignore: void_checks
    return jsonData(data).then((input) {
      map[localeName] = _creationFunction(input);
    });
  }

  /// Given a Future [input] whose value is expected to be a string in JSON
  /// form, return another future that parses the JSON into a usable format.
  Future<dynamic> jsonData(Future<String> input) {
    return input.then((response) => json.decode(response));
  }
}
