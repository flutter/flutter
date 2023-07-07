import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:webviewx/src/utils/source_type.dart';

/// A copy from the original webview's navigation delegate typedef
typedef NavigationDelegate = FutureOr<NavigationDecision> Function(
  NavigationRequest navigation,
);

/// Describes the state of JavaScript support in a given web view.
enum JavascriptMode {
  /// JavaScript execution is disabled.
  disabled,

  /// JavaScript execution is not restricted.
  unrestricted,
}

/// Describes the state of automatic media playback
enum AutoMediaPlaybackPolicy {
  /// Starting any kind of media playback requires a user action.
  ///
  /// For example: JavaScript code cannot start playing media unless the code was executed
  /// as a result of a user action (like a touch event).
  requireUserActionForAllMediaTypes,

  /// Starting any kind of media playback is always allowed.
  ///
  /// For example: JavaScript code that's triggered when the page is loaded can start playing
  /// video or audio.
  alwaysAllow,
}

/// A decision on how to handle a navigation request.
enum NavigationDecision {
  /// Prevent the navigation from taking place.
  prevent,

  /// Allow the navigation to take place.
  navigate,
}

/// A copy of the original NavigationRequest from webview_flutter.
///
/// This was needed because I couldn't extract the information I needed from inside the webview package.
class NavigationRequest {
  /// Constructor
  const NavigationRequest({
    required this.content,
    required this.isForMainFrame,
  });

  /// The URL that will be loaded if the navigation is executed.
  // final String content;
  final NavigationContent content;

  /// Whether the navigation request is to be loaded as the main frame.
  final bool isForMainFrame;

  @override
  String toString() {
    return 'NavigationRequest(content: $content, isForMainFrame: $isForMainFrame)';
  }
}

/// Used in [NavigationRequest] in order to also send the `sourceType`, not just the `source`
class NavigationContent {
  /// Source of the incoming page
  final String source;

  /// SourceType of the incoming page
  final SourceType sourceType;

  /// Constructor
  const NavigationContent(this.source, this.sourceType);

  @override
  String toString() {
    return 'NavigationContent(source: $source, sourceType: ${describeEnum(sourceType)})';
  }
}

/// Error returned in `WebView.onWebResourceError` when a web resource loading error has occurred.
class WebResourceError {
  /// Creates a new [WebResourceError]
  ///
  /// A user should not need to instantiate this class, but will receive one in
  /// [WebResourceErrorCallback].
  const WebResourceError({
    required this.errorCode,
    required this.description,
    this.domain,
    this.errorType,
    this.failingUrl,
  });

  /// Raw code of the error from the respective platform.
  ///
  /// On Android, the error code will be a constant from a
  /// [WebViewClient](https://developer.android.com/reference/android/webkit/WebViewClient#summary) and
  /// will have a corresponding [errorType].
  ///
  /// On iOS, the error code will be a constant from `NSError.code` in
  /// Objective-C. See
  /// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ErrorHandlingCocoa/ErrorObjectsDomains/ErrorObjectsDomains.html
  /// for more information on error handling on iOS. Some possible error codes
  /// can be found at https://developer.apple.com/documentation/webkit/wkerrorcode?language=objc.
  final int errorCode;

  /// The domain of where to find the error code.
  ///
  /// This field is only available on iOS and represents a "domain" from where
  /// the [errorCode] is from. This value is taken directly from an `NSError`
  /// in Objective-C. See
  /// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ErrorHandlingCocoa/ErrorObjectsDomains/ErrorObjectsDomains.html
  /// for more information on error handling on iOS.
  final String? domain;

  /// Description of the error that can be used to communicate the problem to the user.
  final String description;

  /// The type this error can be categorized as.
  ///
  /// This will never be `null` on Android, but can be `null` on iOS.
  final WebResourceErrorType? errorType;

  /// Gets the URL for which the resource request was made.
  ///
  /// This value is not provided on iOS. Alternatively, you can keep track of
  /// the last values provided to [WebViewPlatformController.loadUrl].
  final String? failingUrl;
}

/// Possible error type categorizations used by [WebResourceError].
enum WebResourceErrorType {
  /// User authentication failed on server.
  authentication,

  /// Malformed URL.
  badUrl,

  /// Failed to connect to the server.
  connect,

  /// Failed to perform SSL handshake.
  failedSslHandshake,

  /// Generic file error.
  file,

  /// File not found.
  fileNotFound,

  /// Server or proxy hostname lookup failed.
  hostLookup,

  /// Failed to read or write to the server.
  io,

  /// User authentication failed on proxy.
  proxyAuthentication,

  /// Too many redirects.
  redirectLoop,

  /// Connection timed out.
  timeout,

  /// Too many requests during this load.
  tooManyRequests,

  /// Generic error.
  unknown,

  /// Resource load was canceled by Safe Browsing.
  unsafeResource,

  /// Unsupported authentication scheme (not basic or digest).
  unsupportedAuthScheme,

  /// Unsupported URI scheme.
  unsupportedScheme,

  /// The web content process was terminated.
  webContentProcessTerminated,

  /// The web view was invalidated.
  webViewInvalidated,

  /// A JavaScript exception occurred.
  javaScriptExceptionOccurred,

  /// The result of JavaScript execution could not be returned.
  javaScriptResultTypeIsUnsupported,
}
