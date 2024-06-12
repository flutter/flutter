// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';
import 'platform_view.dart';

/// The platform-specific implementation of [HtmlElementView].
extension HtmlElementViewImpl on HtmlElementView {
  /// Creates an [HtmlElementView] that renders a DOM element with the given
  /// [tagName].
  static HtmlElementView createFromTagName({
    Key? key,
    required String tagName,
    bool isVisible = true,
    ElementCreatedCallback? onElementCreated,
  }) {
    throw UnimplementedError('HtmlElementView is only available on Flutter Web');
  }

  /// Called from [HtmlElementView.build] to build the widget tree.
  ///
  /// This is not expected to be invoked in non-web environments. It throws if
  /// that happens.
  ///
  /// The implementation on Flutter Web builds a platform view and handles its
  /// lifecycle.
  Widget buildImpl(BuildContext context) {
    throw UnimplementedError('HtmlElementView is only available on Flutter Web');
  }
}
