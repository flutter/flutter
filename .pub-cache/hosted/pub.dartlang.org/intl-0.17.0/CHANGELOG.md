## 0.17.0

* Stable release for null safety.

## 0.17.0-nullsafety.2

* Update SDK constraints to >=2.12.0-0 <3.0.0 based on beta release guidelines.

## 0.17.0-nullsafety.1

* Allow prereleases of the 2.12 Dart SDK.

## 0.17.0-nullsafety

 * Migrate to null safety.
 * Add `@pragma('vm:prefer-inline')` to `Intl` methods that already have
   `@pragma('dart2js:tryInline')`, for the same reason: to help omit message
   descriptions from compiled output.
 * **Breaking Change** [#123][]: Fix parsing of two-digit years to match the
   documented behavior. Previously a two-digit year would be parsed to a value
   in the range [0, 99]. Now it is parsed relative to the current date,
   returning a value between 80 years in the past and 20 years in the future.
 * Use package:clock to get the current date/time.
 * Fix some more analysis complaints.
 * Update documentation to indicate that time zone specifiers are not yet
   implemented [#264][].

## 0.16.2
 * Fix bug with dates in January being treated as ordinal. e.g. 2020-01-32 would
   be accepted as valid and the day treated as day-of-year.
 * Compact currency formats will avoid displaying unnecessary trailing zeros
   in compact formats for currencies which specify decimal places.

## 0.16.1
 * Add an analysis_options.yaml and fix or suppress all the complaints from it.
 * Add unit tests using dart:ffi to compare formatting output to ICU.
 * Bump SDK requirements up to 2.5.0 for dart:ffi availability.
 * Attempt to compensate for erratic errors in DateTime creation better, and add
   tests for the compensation.
 * Add a MessageFormat class. It can prepares strings for display to users,
   with optional arguments (variables/placeholders). Common data types will
   be formatted properly for the given locale. It handles both pluralization
   and gender. Think of it as "internationalization aware printf."
 * Change plural behavior with floating point howMany argument so that doubles
   that are equal to integers print the same as the integer 1. That is, '1
   dollar', rather than '1.0 dollars'.
 * Add package:intl/locale.dart that exports a standards-compliant Locale class.

## 0.16.0
 * Fix 'k' formatting (1 to 24 hours) which incorrectly showed 0 to 23.
 * Tighten up types in a couple of places.
 * Add dart2js pragmas for inlining to help remove descriptions and other
   compile-time information from the output.

## 0.15.8
 * Add return type to some internal methods to improve dart2js output.
 * Change parameter types in some public methods from dynamic (implicit or
   explicit) to Object. In particular, the examples and args parameters on
   Intl.message, Intl.plural, Intl.gender, and Intl.select, as well as the args
   parameter on MessageLookup.
 * Allow Dart enums in an Intl.select call. The map of cases can either take
   enums directly, or the short string name of the enum. Requires
   intl_translation 0.17.4 to take advantage of this.

## 0.15.7
 * Upate to require Dart 2.0. Remove deprecated calls,
 * Compensate for rare cases where a parsed Date in date-only format gets a
   1:00am time. This is presumably because of DST time-shifts. We may not be
   able to correct these dates, because midnight may not exist at a transition
   date, but we can cause the strict parsing to not fail for these dates.
 * Update tests to split VM and web number tests, since larger integers now fail
   to compile with dart2js.

## 0.15.6
 * More upper case constant removal.

## 0.15.5
 * Add type parameters on numberFormatSymbols for Dart 2 compatibility. Note
   that it only adds them on the right-hand side because adding them to the
   static type can cause unnecessary cast warnings.
 * Replace uses of JSON constant for Dart 2 compatibility.

## 0.15.4
 * A couple of minor Dart 2 fixes.

## 0.15.3
 * Add a customPattern parameter to the currency constructor. This can be used
   to provide a custom pattern if you have one, e.g. for accounting formats.
 * Update data to CLDR 32.0.1
 * Update for Dart 2.0 fixed-size integers.
 * Add missing support for specifying decimalDigits in compactSimpleCurrency.
 * Fix doc comments for DateFormat (Pull request #156)
 * Added a skip argument to not output the message in the extract step.
 * Compensate for parsing a Date that happens at a DST transition, particularly
   in Brazil, where the transition happens at midnight. This can result in a
   time of 11:00pm the previous day, or of 1:00am the next day. Make sure that
   the the 11:00pm case does not cause us to get the wrong date.

## 0.15.2
 * Group the padding digits to the left of the number, if present. e.g. 00,001.
 * Tweak lookup code to support translated messages as JSON rather than code.
 * Update data to CLDR 31.0.1
 * Adds locales en_MY, fr_CH, it_CH, and ps.
 * Use locale digits for printing DateTime. This can also be disabled for a
   particular locale use useNativeDigitsByDefaultFor or for a particular
   DateFormat instance use useNativeDigits.
 * Provide a library for custom-initialized DateTime and number formatting. This
   allows easier custom locales and synchronous initialization.

## 0.15.1
 * Use the platform.locale API to get the OS platform.
 * Convert to use package:test

## 0.15.0
 * Fix compactCurrency to correctly use passed-in symbol.
 * A tweak to the way we retry on DateTime.asDate to compensate for a VM bug.
 * Update CLDR version to 30.
 * Cache the last result of isRtlLanguage
 * Some strong mode fixes
 * Allow passing enums to a select.
 * Remove the cacheBlocker parameter from HttpRequestDataReader
 * Optimize padding numbers when printing
 * Remove the out of date example directory
 * Add a facility to check if messages are being called before locale
   initialization, which can lead to errors if the results are being cached. See
   UninitializedLocaleData.throwOnFallback.
 * Restore dependency on path which was removed when intl_translation was
   separated.
 * Improve the error message when date parsing fails validation to show what the
   parsed date was.

## 0.14.0
 * MAJOR BREAKING CHANGE! Remove message extraction and code generation into a
   separate intl_translation package. This means packages with a runtime
   dependency on intl don't also depend on analyzer, barback, and so forth.

## 0.13.1
 * Update CLDR data to version 29.
 * Add a toBeginningOfSentenceCase() method which converts the first character
   of a string to uppercase. It may become more clever about that for locales
   with different conventions over time.
 * Fixed the use of currency-specific decimal places, which weren't being used
   if the currency was the default for the locale.
 * Add support for currency in compact number formats.
 * Added support for "Q" and "QQ" numeric quarter formatting, which fixes "QQQ"
   and "QQQQ" in the zh_CN locale.
 * As part of deprecating transformer usage, allow `rewrite_intl_messages.dart`
   to add names and arguments to messages with parameters. Make the transformer
   not generate names for zero-argument methods and just use the name+meaning
   instead.
 * Move barback from dev dependencies into public (see
   https://github.com/dart-lang/intl/issues/120 )

## 0.13.0
 * Add support for compact number formats ("1.2K") and for significant digits in
   number formats.
 * Add a NumberFormat.simpleCurrency constructor which will attempt to
   automatically determine the currency symbol. Very simple implementation but
   can be expanded to be per-locale.
 * Fix a problem where, in a message, a literal dollar sign followed by a number
   was seen as a valid identifier, resulting in invalid code being generated.
 * Add support for locale-specific plural rules. Note that this changes the
   interpretation of plurals and so is potentially breaking. For example, in
   English three will now be treated as "other" rather than as "few".
 * Add `onMessage` top level variable, which defaults to `print`. Warning and
   error messages will all now go through this function instead of calling
   `print` directly.
 * Move top-level variables in `extract_messages.dart` into a MessageExtraction
   object. This is a breaking change for code that imports
   `extract_messages.dart`, which probably only means message format
   readers/extractors like `extract_to_arb.dart` and `generate_from_arb.dart`.
 * Cache the message lookup for a locale, reducing unnecessary locale validation
   and lookup.

## 0.12.7+1
 * Change the signature for args and examples in Intl.plural/gender/select to
   match Intl.message, allowing dynamic values.
 * Parameters to initializeDateFormatting are optional.
 * Extend DateFormat.parseLoose() to allow arbitrary amounts of whitespace
   before literal fields (as well as after), and treat all whitespace around
   literal fields as optional even if the literal field's pattern has leading
   or trailing whitespace.
 * Fix DateFormat.parseLoose() returning unexpected values in certain cases
   where a pattern was missing from the input string.
 * Fix DateFormat.parseLoose() ignoring the value of numeric standalone months
   ('LL' pattern).
 * Remove relative imports on `generate_locale_data_files.dart`

## 0.12.7
 * Update SDK dependency to 1.12.0, to reflect use of null-aware operators.
 * Add a transformer to automatically add the "name" and "args" parameters to
   Intl.message and related calls. This removes a lot of tedious repetition.
 * Fix typo in README.
 * Make Intl strong-mode compatible.

## 0.12.6
  * Update links in README.md to point to current dartdocs.
  * Update locale data to CLDR 28.
  * Remove library directive from generated libraries. Conflicted with linter.
  * Support @@locale in ARB files as well as the older _locale
  * Print a message when generating from ARB files if we guess the locale
    from the file name when there's no explicit @@locale or _locale in the file.
  * Switch all the source to use line comments.
  * Slight improvement to the error message when parsing dates has an invalid
    value.
  * Introduce new NumberFormat.currency constructor which can explicitly take a
    separate currency name and symbol, as well as the number of decimal digits.
  * Provide a default number of decimal digits per-currency.
  * Deprecate NumberFormat.currencyPattern.

## 0.12.5
  * Parse Eras in DateFormat.
  * Update pubspec.yaml to allow newer version of fixnum and analyzer.
  * Improvements to the compiled size of generated messages code with dart2js.
  * Allow adjacent literal strings to be used for message names/descriptions.
  * Provide a better error message for some cases of bad parameters
    to plural/gender/select messages.
  * Introduce a simple MicroMoney class that can represent currency values
    scaled by a constant factor.

## 0.12.4+3
  * update analyzer to '<0.28.0' and fixnum to '<0.11.0'

## 0.12.4+2
  * update analyzer to '<0.27.0'

## 0.12.4+1
  * Allow the name of an Intl.message to be "ClassName_methodName", as
    well as "functionName". This makes it easier to disambiguate
    messages with the same name but in different classes.

## 0.12.4
  * Handle spaces in ARB files where we didn't handle them before, and
  where Google translation toolkit is now putting them.

## 0.12.3

  * Use latest version of 'analyzer' and 'args' packages.

## 0.12.2+1
  * Adds a special locale name "fallback" in verifiedLocale. So if a translation
  is provided for that locale and has been initialized, anything that doesn't
  find a closer match will use that locale. This can be used instead of having
  it default to the text in the original source messages.

## 0.12.1
  * Adds a DateFormat.parseLoose that accepts mixed case and missing
  delimiters when parsing dates. It also allows arbitrary amounts of
  whitespace anywhere that whitespace is expected. So, for example,
  in en-US locale a yMMMd format would accept "SEP 3   2014", even
  though it would generate "Sep 3, 2014". This is fairly limited, and
  its reliability in other locales is not known.

## 0.12.0+3
  * Update pubspec dependencies to allow analyzer version 23.

## 0.12.0+2
  * No user impacting changes. Tighten up a couple method signatures to specify
  that int is required.

## 0.12.0+1
  * Fixes bug with printing a percent or permille format with no fraction
  part and a number with no integer part. For example, print 0.12 with a
  format pattern of "#%". The test for whether
  there was a printable integer part tested the basic number, so it ignored the
  integer digits. This was introduced in 0.11.2 when we stopped multiplying
  the input number in the percent/permille case.

## 0.12.0
  * Make withLocale and defaultLocale use a zone, so async operations
    inside withLocale also get the correct locale. Bumping the version
    as this might be considered breaking, or at least
    behavior-changing.

## 0.11.12
  * Number formatting now accepts "int-like" inputs that don't have to
    conform to the num interface. In particular, you can now pass an Int64
    from the fixnum package and format it. In addition, this no longer
    multiplies the result, so it won't lose precision on a few additional
    cases in JS.

## 0.11.11
  * Add a -no-embedded-plurals flag to reject plurals and genders that
    have either leading or trailing text around them. This follows the
    ICU recommendation that a plural or gender should contain the
    entire phrase/sentence, not just part of it.

## 0.11.10
  * Fix some style glitches with naming. The only publicly visible one
    is DateFormat.parseUtc, but the parseUTC variant is still retained
    for backward-compatibility.

  * Provide a better error message when generating translated versions
    and the name of a variable substitution in the message doesn't
    match the name in the translation.

## 0.11.9
  * Fix bug with per-mille parsing (only divided by 100, not 1000)

  * Support percent and per-mille formats with both positive and negative
    variations. Previously would throw an exception for too many modifiers.

## 0.11.8

  * Support NumberFormats with two different grouping sizes, e.g.
    1,23,45,67,890

## 0.11.7
  * Moved petitparser into a regular dependency so pub run works.

  * Improved code layout of the package.

  * Added a DateFormat.parseStrict method that rejects DateTimes with invalid
    values and requires it to be the whole string.

## 0.11.6

  * Catch analyzer errors and do not generate messages for that file. Previously
    this would stop the message extraction on syntax errors and not give error
    messages as good as the compiler would produce. Just let the compiler do it.

## 0.11.5

 * Change to work with both petitparser 1.1.x and 1.2.x versions.

## 0.11.4

 * Broaden the pubspec constraints to allow current analyzer versions.

## 0.11.3

 * Add a --[no]-use-deferred-loading flag to generate_from_arb.dart and
   generally make the deferred loading of message libraries optional.

## 0.11.2

 * Missed canonicalization of locales in one place in message library generation.

 * Added a simple debug script for message_extraction_test.

## 0.11.1

 * Negative numbers were being parsed as positive.

## 0.11.0

 * Switch the message format from a custom JSON format to
   the ARB format ( https://code.google.com/p/arb/ )

## 0.10.0

 * Make message catalogs use deferred loading.

 * Update CLDR Data to version 25 for dates and numbers.

 * Update analyzer dependency to allow later versions.

 * Adds workaround for flakiness in DateTime creation, removes debugging code
   associated with that.

## 0.9.9

* Add NumberFormat.parse()

* Allow NumberFormat constructor to take an optional currency name/symbol, so
  you can format for a particular locale without it dictating the currency, and
  also supply the currency symbols which we don't have yet.

* Canonicalize locales more consistently, avoiding a number of problems if you
  use a non-canonical form.

* For locales whose length is longer than 6 change "-" to "_" in position 3 when
  canonicalizing. Previously anything of length > 6 was left completely alone.

## 0.9.8

* Add a "meaning" optional parameter for Intl.message to distinguish between
  two messages with identical text.

* Handle two different messages with the same text.

* Allow complex string literals in arguments (e.g. multi-line)

[#123]: https://github.com/dart-lang/intl/issues/123
[#264]: https://github.com/dart-lang/intl/issues/264
