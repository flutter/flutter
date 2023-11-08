// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

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
      : super(Role.tappable, semanticsObject, owner) {
    _clickListener = createDomEventListener((DomEvent click) {
      PointerBinding.instance!.clickDebouncer.onClick(
        click,
        semanticsObject.id,
        _isListening,
      );
    });
    owner.element.addEventListener('click', _clickListener);
  }

  DomEventListener? _clickListener;
  bool _isListening = false;

  @override
  void update() {
    final bool wasListening = _isListening;
    _isListening = semanticsObject.enabledState() != EnabledState.disabled && semanticsObject.isTappable;
    if (wasListening != _isListening) {
      _updateAttribute();
    }
  }

  void _updateAttribute() {
    // The `flt-tappable` attribute marks the element for the ClickDebouncer to
    // to know that it should debounce click events on this element. The
    // contract is that the element that has this attribute is also the element
    // that receives pointer and "click" events.
    if (_isListening) {
      owner.element.setAttribute('flt-tappable', '');
    } else {
      owner.element.removeAttribute('flt-tappable');
    }
  }

  @override
  void dispose() {
    owner.removeEventListener('click', _clickListener);
    _clickListener = null;
    super.dispose();
  }
}
