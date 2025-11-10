// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../platform_views/content_manager.dart';
import '../platform_views/slots.dart';
import 'label_and_value.dart';
import 'semantics.dart';

/// Manages the semantic element corresponding to a platform view.
///
/// The element in the semantics tree exists only to supply the ARIA traversal
/// order. The actual content of the platform view is managed by
/// [PlatformViewManager].
///
/// The traversal order is established using "aria-owns", by pointing to the
/// element that hosts the view contents. As of this writing, Safari on macOS
/// and on iOS does not support "aria-owns". All other browsers on all operating
/// systems support it.
///
/// See also:
///   * https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-owns
///   * https://bugs.webkit.org/show_bug.cgi?id=223798
class SemanticPlatformView extends SemanticRole {
  SemanticPlatformView(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.platformView,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.ariaLabel,
      );

  /// Ignores pointer events on all platform view nodes.
  ///
  /// This is so that the platform views are not obscured by semantic elements
  /// and can be reached by inspecting the web page.
  @override
  bool get acceptsPointerEvents => false;

  @override
  void update() {
    super.update();

    if (semanticsObject.isPlatformView) {
      final int platformViewId = semanticsObject.platformViewId;
      final bool isHidden = semanticsObject.flags.isHidden;

      if (isHidden) {
        // When hidden, remove aria-owns since the platform view is not part
        // of the accessibility tree.
        removeAttribute('aria-owns');
      } else {
        setAttribute('aria-owns', getPlatformViewDomId(platformViewId));
      }

      PlatformViewManager.instance.updatePlatformViewAccessibility(platformViewId, isHidden);
    } else {
      removeAttribute('aria-owns');
    }
  }

  @override
  bool focusAsRouteDefault() {
    // It's unclear how it's possible to auto-focus on something inside a
    // platform view without knowing what's in it. If the framework adds API for
    // focusing on platform view internals, this method will be able to do more,
    // but for now there's nothing to focus on.
    return false;
  }
}
