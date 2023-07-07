// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

/// Details of the change to a web view's url.
///
/// Platform specific implementations can add additional fields by extending
/// this class.
///
/// This example demonstrates how to extend the [UrlChange] to provide
/// additional platform specific parameters:
///
/// ```dart
/// class AndroidUrlChange extends UrlChange {
///   const AndroidUrlChange({required super.url, required this.isReload});
///
///   final bool isReload;
/// }
/// ```
@immutable
class UrlChange {
  /// Creates a new [UrlChange].
  const UrlChange({required this.url});

  /// The new url of the web view.
  final String? url;
}
