# 2.0.4
  * Fixes Platform.operatingSystemVersion ([issue #9](https://github.com/dint-dev/universal_io/issues/9)).

# 2.0.3
  * Fixes various issues.

# 2.0.2
  * Fixes issue [#17](https://github.com/dint-dev/universal_io/issues/17).

# 2.0.1
  * Fixes issues in Node.JS.

# 2.0.0
  * Finishes migration to null safety.

# 2.0.0-nullsafety.2
  * Eliminated unnecessary dependencies.

# 2.0.0-nullsafety.1
  * Improves documentation.
  * Improves BrowserHttpClientException messages.
  * Deprecates libraries _prefer_sdk/io.dart_ and _prefer_universal/io.dart_. Developers should
    import just _io.dart_.

# 2.0.0-nullsafety.0
  * The first null-safe version.
  * Makes changes in BrowserHttpClient / BrowserHttpClientRequest API:
    * The property for enabling credentials mode is now `browserCredentialsMode`. The default is
      `false`.
    * The property for setting response type is now `browserResponseType` ("arraybuffer", "text",
      etc.). By default, if HTTP request header "Accept" contains only text MIMEs ("text/plain",
      etc.), this package uses _responseType_ "text".
    * HTTP client now has `onBrowserHttpClientRequestClose` for using your own logic for setting
      `browserResponseType`.
  * Removes IO adapter API.

# 1.0.2
  * Fixes issue [#11](https://github.com/dint-dev/universal_io/issues/11) (InternetAddress
    parameter).
  * Fixes issue [#12](https://github.com/dint-dev/universal_io/issues/12) (CORS credentials mode).
    Eliminates legacy, complicated behavior. Developers should choose either _omit_ or _include_.
    Improves error messages and documentation related to it.
  * Replaces MD5/SHA1 implementations used by some of the source code copied from _dart:io_. It now
    uses _package:crypto_ instead of implementations copied from _dart:io_.

# 1.0.0
  * Implements recent changes in 'dart:io' (Dart SDK 2.8).
  * HttpDriver is replaced by 'dart:io' HttpOverrides.
  * FileSystemDriver is replaced by 'dart:io' IOOverrides.
  * Various other driver APIs are renamed or removed.
  * BrowserLikeHttpClientRequest is now BrowserHttpClientRequest.
  * BrowserHttpClientRequest implementation is improved.

# 0.8.6
  * Fixed documentation and small fixes related to `nodejs_io`.

# 0.8.5
  * Raised minimum SDK to 2.6 and upgraded dependencies.
  * Changed how CORS credentials mode is enabled. It was previously enabled with a header, but now
    we introduced subclasses for HttpClient and HttpClientRequest. This is a breaking change, but we
    decided not to bump the major version number.
  * Improved analysis and test settings.

# 0.8.4
  * Added 'prefer_sdk/io.dart' and 'prefer_universal/io.dart' libraries for dealing with conditional
    export issues.
  * Library 'package:universal_io/io.dart' now exports SDK version by default.

# 0.8.3
  * Replaced IP address parsing with the new Uri.parseIPv4Address / Uri.parseIPv6Address.
  * Fixed missing HTTP status codes.

# 0.8.2
  * Fixed problems introduced by Dart SDK 2.5.0-dev-2.0.

# 0.8.1
  * Fixed pubspec.yaml and documented Dart SDK 2.5 breaking changes.

# 0.8.0
  * Updated classes to Dart 2.5. See [Dart SDK documentation about the changes](https://github.com/dart-lang/sdk/blob/master/CHANGELOG.md).
    * Various APIs now return `Uint8List` instead of `List<int>`. Examples: `File`, `Socket`, `HttpClientResponse`.
    * Various other breaking changes such as `Cookie` constructor.

# 0.7.3
  * Fixed the following error thrown by the Dart build system in some cases: "Unsupported conditional import of dart:io found in universal_io|lib/io.dart".
  
# 0.7.2
  * Small fixes.
  
# 0.7.1
  * Fixed various bugs.
  * Improved the test suite.
  
# 0.7.0
  * Improved driver base classes and the test suite.
  
# 0.6.0
  * Major refactoring of IODriver API.

# 0.5.1
  * Fixed small bugs.
  
# 0.5.0
  * Fixed various bugs.
  * Re-organized source code.
  * Eliminated dependencies by doing IP parsing in this package.
  * Improved the test suite for drivers.