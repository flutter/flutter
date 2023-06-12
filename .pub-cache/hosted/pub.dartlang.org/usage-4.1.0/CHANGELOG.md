## 4.1.0
- Analytics hits can now be batched. See details in the documentation of the
  `AnalyticsIO` constructor.
- Allow sendRaw to send Map<String, dynamic> (#161).
- Address a `null_argument_to_non_null_type` analysis issue.
- Change to using 'package:lints' for analysis.

## 4.0.2
- Fix a bug with the analytics ping throttling algorithm.

## 4.0.1
- Force close the http client from `IOAnalytics.close()`.
  This prevents lingering requests from making the application hang.

## 4.0.0
- Publishing a null safe stable release.

## 4.0.0-nullsafety
- Updated to support 2.12.0 and null safety.

## 3.4.2
- A number of cleanups to improve the package health score.

## 3.4.1
- increase the support SDK range to `'<3.0.0'`

## 3.4.0
- bump our minimum SDK constraint to `>=2.0.0-dev.30`
- change to using non-deprecated dart:convert constants

## 3.3.0
- added a `close()` method to the `Analytics` class
- change our minimum SDK from `1.24.0-dev` to `1.24.0` stable

## 3.2.0
- expose the `Analytics.applicationName` and `Analytics.applicationVersion`
  properties
- make it easier for clients to extend the `AnalyticsIO` class
- allow for custom parameters when sending a screenView

## 3.1.1
- make Analytics.clientId available immediately

## 3.1.0
- switch the technique we use to determine the locale to the new dart:io
  `Platform.localeName` field
- change our minimum SDK version to `1.24.0`

## 3.0.1
- expose the `Analytics.clientId` field

## 3.0.0+1
- fixed an NPE in the `usage_io` `getPlatformLocale()` method

## 3.0.0
- removed the use of configurable imports
- removed the Flutter specific entry-point; Flutter apps can now use the
  regular `dart:io` entrypoint (AnalyticsIO)
- moved the uuid library from `lib/src/` to `lib/uuid/`
- fixed an issue with reporting the user language for the dart:io provider
- changed to send additional lines for reported exceptions

## 2.2.2
- adjust the Flutter usage client to Flutter API changes

## 2.2.1
- improve the user agent string for the CLI client

## 2.2.0+1
- bug fix to prevent frequently changing the settings file

## 2.2.0
- added `Analytics.firstRun`
- added `Analytics.enabled`
- removed `Analytics.optIn`

## 2.1.0
- added `Analytics.getSessionValue()`
- added `Analytics.onSend`
- added `AnalyticsImpl.sendRaw()`

## 2.0.0
- added a `usage` implementation for Flutter (uses conditional directives)
- removed `lib/usage_html.dart`; use the new Analytics.create() static method
- removed `lib/usage_io.dart`; use the new Analytics.create() static method
- bumped to `2.0.0` for API changes and library refactorings

## 1.2.0
- added an optional `analyticsUrl` parameter to the usage constructors

## 1.1.0
- fix two strong mode analysis issues (overriding a field declaration with a
  setter/getter pair)

## 1.0.1
- make strong mode compliant
- update some dev package dependencies

## 1.0.0
- Rev'd to 1.0.0!
- No other changes from the `0.0.6` release

## 0.0.6
- Added a web example
- Added a utility method to time async events (`Analytics.startTimer()`)
- Updated the readme to add information about when we send analytics info

## 0.0.5

- Catch errors during pings to Google Analytics, for example in case of a
  missing internet connection
- Track additional browser data, such as screen size and language
- Added tests for `usage` running in a dart:html context
- Changed to a custom implementation of UUID; saved ~376k in compiled JS size

## 0.0.4

- Moved `sanitizeStacktrace` into the main library

## 0.0.3

- Replaced optional positional arguments with named arguments
- Added code coverage! Thanks to https://github.com/Adracus/dart-coveralls and
  coveralls.io.

## 0.0.2

- Fixed a bug in `analytics.sendTiming()`

## 0.0.1

- Initial version, created by Stagehand
