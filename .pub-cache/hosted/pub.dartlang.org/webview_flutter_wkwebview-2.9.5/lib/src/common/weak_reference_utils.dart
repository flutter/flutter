// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Helper method for creating callbacks methods with a weak reference.
///
/// Example:
/// ```
/// final JavascriptChannelRegistry javascriptChannelRegistry = ...
///
/// final WKScriptMessageHandler handler = WKScriptMessageHandler(
///   didReceiveScriptMessage: withWeakRefenceTo(
///     javascriptChannelRegistry,
///     (WeakReference<JavascriptChannelRegistry> weakReference) {
///       return (
///         WKUserContentController userContentController,
///         WKScriptMessage message,
///       ) {
///         weakReference.target?.onJavascriptChannelMessage(
///           message.name,
///           message.body!.toString(),
///         );
///       };
///     },
///   ),
/// );
/// ```
S withWeakRefenceTo<T extends Object, S extends Object>(
  T reference,
  S Function(WeakReference<T> weakReference) onCreate,
) {
  final WeakReference<T> weakReference = WeakReference<T>(reference);
  return onCreate(weakReference);
}
