// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'web_resource_error_type.dart';

/// Error returned in `WebView.onWebResourceError` when a web resource loading error has occurred.
class WebResourceError {
  /// Creates a new [WebResourceError]
  ///
  /// A user should not need to instantiate this class, but will receive one in
  /// [WebResourceErrorCallback].
  WebResourceError({
    required this.errorCode,
    required this.description,
    this.domain,
    this.errorType,
    this.failingUrl,
  })  : assert(errorCode != null),
        assert(description != null);

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
