// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

/// Listens to HTML "click" gestures detected by the browser.
///
/// This gestures is different from the click and tap gestures detected by the
/// framework from raw pointer events. When an assistive technology is enabled
/// the browser may not send us pointer events. In that mode we forward HTML
/// click as [ui.SemanticsAction.tap].
class Tappable extends RoleManager {
  Tappable(SemanticsObject semanticsObject)
      : super(Role.tappable, semanticsObject);

  html.EventListener _clickListener;

  @override
  void update() {
    final html.Element element = semanticsObject.element;

    semanticsObject.setAriaRole(
        'button', semanticsObject.hasFlag(ui.SemanticsFlag.isButton));

    if (!semanticsObject.hasFlag(ui.SemanticsFlag.isEnabled) &&
        semanticsObject.hasFlag(ui.SemanticsFlag.isButton)) {
      semanticsObject.element.setAttribute('aria-disabled', 'true');
      _stopListening();
    } else {
      // Excluding text fields because text fields have browser-specific logic
      // for recognizing taps and activating the keyboard.
      if (semanticsObject.hasAction(ui.SemanticsAction.tap) &&
          !semanticsObject.hasFlag(ui.SemanticsFlag.isTextField)) {
        if (_clickListener == null) {
          _clickListener = (_) {
            if (semanticsObject.owner.gestureMode !=
                GestureMode.browserGestures) {
              return;
            }
            window.invokeOnSemanticsAction(
                semanticsObject.id, ui.SemanticsAction.tap, null);
          };
          element.addEventListener('click', _clickListener);
        }
      } else {
        _stopListening();
      }
    }
  }

  void _stopListening() {
    if (_clickListener == null) {
      return;
    }

    semanticsObject.element.removeEventListener('click', _clickListener);
    _clickListener = null;
  }

  @override
  void dispose() {
    _stopListening();
    semanticsObject.setAriaRole('button', false);
  }
}
