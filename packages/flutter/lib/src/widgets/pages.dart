// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'navigator.dart';
import 'overlay.dart';
import 'routes.dart';

/// A modal route that replaces the entire screen.
abstract class PageRoute<T> extends ModalRoute<T> {
  /// Creates a modal route that replaces the entire screen.
  PageRoute({
    RouteSettings settings: const RouteSettings()
  }) : super(settings: settings);

  @override
  bool get opaque => true;

  @override
  bool get barrierDismissable => false;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => nextRoute is PageRoute<dynamic>;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> nextRoute) => nextRoute is PageRoute<dynamic>;

  @override
  AnimationController createAnimationController() {
    AnimationController controller = super.createAnimationController();
    if (settings.isInitialRoute)
      controller.value = 1.0;
    return controller;
  }

  /// Subclasses can override this method to customize how heroes are inserted.
  void insertHeroOverlayEntry(OverlayEntry entry, Object tag, OverlayState overlay) {
    overlay.insert(entry);
  }
}
