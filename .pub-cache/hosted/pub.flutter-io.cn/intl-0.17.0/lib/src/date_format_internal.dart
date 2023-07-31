// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This contains internal implementation details of the date formatting code
/// which are exposed as public functions because they must be called by other
/// libraries in order to configure the source for the locale data. We don't
/// want them exposed as public API functions in the date formatting library, so
/// they are put in a separate library here. These are for internal use
/// only. User code should import one of the `date_symbol_data...` libraries and
/// call the `initializeDateFormatting` method exposed there.

library date_format_internal;

import '../date_symbols.dart';
import 'intl_helpers.dart';

/// This holds the symbols to be used for date/time formatting, indexed
/// by locale. Note that it will be set differently during initialization,
/// depending on what implementation we are using. By default, it is initialized
/// to an instance of UninitializedLocaleData, so any attempt to use it will
/// result in an informative error message.
// TODO(alanknight): Have a valid type for this. Currently it can be an
// UninitializedLocaleData, Map, or LazyLocaleData.
dynamic get dateTimeSymbols => _dateTimeSymbols;

/// Set the dateTimeSymbols and invalidate cache.
set dateTimeSymbols(dynamic symbols) {
  // With all the mechanisms we have now this should be sufficient. We can
  // have an UninitializedLocaleData which gives us the fallback locale, but
  // when we replace it we invalidate. With a LazyLocaleData we won't change
  // the results for a particular locale, it will just go from throwing to
  // being available. With a Map everything is available.
  _dateTimeSymbols = symbols;
  cachedDateSymbols = null;
  lastDateSymbolLocale = null;
}

dynamic _dateTimeSymbols =
    UninitializedLocaleData('initializeDateFormatting(<locale>)', en_USSymbols);

/// Cache the last used symbols to reduce repeated lookups.
DateSymbols? cachedDateSymbols;

/// Which locale was last used for symbol lookup.
String? lastDateSymbolLocale;

/// This holds the patterns used for date/time formatting, indexed
/// by locale. Note that it will be set differently during initialization,
/// depending on what implementation we are using. By default, it is initialized
/// to an instance of UninitializedLocaleData, so any attempt to use it will
/// result in an informative error message.
// TODO(alanknight): Have a valid type for this. Currently it can be an
// UninitializedLocaleData, Map, or LazyLocaleData.
dynamic dateTimePatterns = UninitializedLocaleData(
    'initializeDateFormatting(<locale>)', en_USPatterns);

/// Initialize the symbols dictionary. This should be passed a function that
/// creates and returns the symbol data. We take a function so that if
/// initializing the data is an expensive operation it need only be done once,
/// no matter how many times this method is called.
void initializeDateSymbols(Function symbols) {
  if (dateTimeSymbols is UninitializedLocaleData<dynamic>) {
    dateTimeSymbols = symbols();
  }
}

/// Initialize the patterns dictionary. This should be passed a function that
/// creates and returns the pattern data. We take a function so that if
/// initializing the data is an expensive operation it need only be done once,
/// no matter how many times this method is called.
void initializeDatePatterns(Function patterns) {
  if (dateTimePatterns is UninitializedLocaleData<dynamic>) {
    dateTimePatterns = patterns();
  }
}

Future<dynamic> initializeIndividualLocaleDateFormatting(Function init) {
  return init(dateTimeSymbols, dateTimePatterns);
}
