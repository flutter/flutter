// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// Manages semantics objects that represent editable text fields.
///
/// This role is implemented via a content-editable HTML element. This role does
/// not proactively switch modes depending on the current
/// [EngineSemanticsOwner.gestureMode]. However, in Chrome on Android it ignores
/// browser gestures when in pointer mode. In Safari on iOS touch events are
/// used to detect text box invocation. This is because Safari issues touch
/// events even when Voiceover is enabled.
class TextField extends RoleManager {
  TextField(SemanticsObject semanticsObject)
      : super(Role.textField, semanticsObject) {
    final html.HtmlElement editableDomElement =
        semanticsObject.hasFlag(ui.SemanticsFlag.isMultiline)
            ? html.TextAreaElement()
            : html.InputElement();
    persistentTextEditingElement = PersistentTextEditingElement(
      textEditing,
      editableDomElement,
      onDomElementSwap: _setupDomElement,
    );
    _setupDomElement();
  }

  PersistentTextEditingElement persistentTextEditingElement;
  html.Element get _textFieldElement => persistentTextEditingElement.domElement;

  void _setupDomElement() {
    // On iOS, even though the semantic text field is transparent, the cursor
    // and text highlighting are still visible. The cursor and text selection
    // are made invisible by CSS in [DomRenderer.reset].
    // But there's one more case where iOS highlights text. That's when there's
    // and autocorrect suggestion. To disable that, we have to do the following:
    _textFieldElement
      ..spellcheck = false
      ..setAttribute('spellcheck', 'false')
      ..setAttribute('autocorrect', 'off')
      ..setAttribute('autocomplete', 'off')
      ..setAttribute('data-semantics-role', 'text-field');

    _textFieldElement.style
      ..position = 'absolute'
      // `top` and `left` are intentionally set to zero here.
      //
      // The text field would live inside a `<flt-semantics>` which should
      // already be positioned using semantics.rect.
      //
      // See also:
      //
      // * [SemanticsObject.recomputePositionAndSize], which sets the position
      //   and size of the parent `<flt-semantics>` element.
      ..top = '0'
      ..left = '0'
      ..width = '${semanticsObject.rect.width}px'
      ..height = '${semanticsObject.rect.height}px';
    semanticsObject.element.append(_textFieldElement);

    switch (browserEngine) {
      case BrowserEngine.blink:
      case BrowserEngine.firefox:
      case BrowserEngine.unknown:
        _initializeForBlink();
        break;
      case BrowserEngine.webkit:
        _initializeForWebkit();
        break;
    }
  }

  /// Chrome on Android reports text field activation as a "click" event.
  ///
  /// When in browser gesture mode, the focus is forwarded to the framework as
  /// a tap to initialize editing.
  void _initializeForBlink() {
    _textFieldElement.addEventListener('focus', (html.Event event) {
      if (semanticsObject.owner.gestureMode != GestureMode.browserGestures) {
        return;
      }

      textEditing.useCustomEditableElement(persistentTextEditingElement);
      ui.window
          .onSemanticsAction(semanticsObject.id, ui.SemanticsAction.tap, null);
    });
  }

  /// Safari on iOS reports text field activation via touch events.
  ///
  /// This emulates a tap recognizer to detect the activation. Because touch
  /// events are present regardless of whether accessibility is enabled or not,
  /// this mode is always enabled.
  void _initializeForWebkit() {
    num lastTouchStartOffsetX;
    num lastTouchStartOffsetY;

    _textFieldElement.addEventListener('touchstart', (html.Event event) {
      textEditing.useCustomEditableElement(persistentTextEditingElement);
      final html.TouchEvent touchEvent = event;
      lastTouchStartOffsetX = touchEvent.changedTouches.last.client.x;
      lastTouchStartOffsetY = touchEvent.changedTouches.last.client.y;
    }, true);

    _textFieldElement.addEventListener('touchend', (html.Event event) {
      final html.TouchEvent touchEvent = event;

      if (lastTouchStartOffsetX != null) {
        assert(lastTouchStartOffsetY != null);
        final num offsetX = touchEvent.changedTouches.last.client.x;
        final num offsetY = touchEvent.changedTouches.last.client.y;

        // This should match the similar constant define in:
        //
        // lib/src/gestures/constants.dart
        //
        // The value is pre-squared so we have to do less math at runtime.
        const double kTouchSlop = 18.0 * 18.0; // Logical pixels squared

        if (offsetX * offsetX + offsetY * offsetY < kTouchSlop) {
          // Recognize it as a tap that requires a keyboard.
          ui.window.onSemanticsAction(
              semanticsObject.id, ui.SemanticsAction.tap, null);
        }
      } else {
        assert(lastTouchStartOffsetY == null);
      }

      lastTouchStartOffsetX = null;
      lastTouchStartOffsetY = null;
    }, true);
  }

  @override
  void update() {
    // The user is editing the semantic text field directly, so there's no need
    // to do any update here.
  }

  @override
  void dispose() {
    _textFieldElement.remove();
    textEditing.stopUsingCustomEditableElement();
  }
}
