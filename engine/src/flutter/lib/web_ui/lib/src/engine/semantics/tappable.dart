// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import '../dom.dart';
import '../platform_dispatcher.dart';
import 'semantics.dart';

/// Sets the "button" ARIA role.
class Button extends PrimaryRoleManager {
  Button(SemanticsObject semanticsObject) : super.withBasics(PrimaryRole.button, semanticsObject) {
    setAriaRole('button');
  }

  @override
  void update() {
    super.update();

    if (semanticsObject.enabledState() == EnabledState.disabled) {
      setAttribute('aria-disabled', 'true');
    } else {
      removeAttribute('aria-disabled');
    }
  }
}

/// Listens to HTML "click" gestures detected by the browser.
///
/// This gestures is different from the click and tap gestures detected by the
/// framework from raw pointer events. When an assistive technology is enabled
/// the browser may not send us pointer events. In that mode we forward HTML
/// click as [ui.SemanticsAction.tap].
class Tappable extends RoleManager {
  Tappable(SemanticsObject semanticsObject, PrimaryRoleManager owner)
      : super(Role.tappable, semanticsObject, owner);

  DomEventListener? _clickListener;

  @override
  void update() {
    if (_clickListener == null) {
      _clickListener = createDomEventListener((DomEvent event) {
        // Stop dom from reacting since it will be handled entirely on the
        // flutter side.
        event.preventDefault();
        if (!semanticsObject.isTappable || semanticsObject.enabledState() == EnabledState.disabled) {
          return;
        }
        if (semanticsObject.owner.gestureMode != GestureMode.browserGestures) {
          return;
        }
        EnginePlatformDispatcher.instance.invokeOnSemanticsAction(
            semanticsObject.id, ui.SemanticsAction.tap, null);
      });
      owner.addEventListener('click', _clickListener);
    }
  }

  void _stopListening() {
    if (_clickListener == null) {
      return;
    }

    owner.removeEventListener('click', _clickListener);
    _clickListener = null;
  }

  @override
  void dispose() {
    super.dispose();
    _stopListening();
  }
}
