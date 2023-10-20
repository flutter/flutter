// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:ui/ui.dart' as ui;

import '../browser_detection.dart';
import '../dom.dart';
import '../platform_dispatcher.dart';
import '../text_editing/text_editing.dart';
import 'semantics.dart';

/// Text editing used by accesibility mode.
///
/// [SemanticsTextEditingStrategy] assumes the caller will own the creation,
/// insertion and disposal of the DOM element. Due to this
/// [initializeElementPlacement], [initializeTextEditing] and
/// [disable] strategies are handled differently.
///
/// This class is still responsible for hooking up the DOM element with the
/// [HybridTextEditing] instance so that changes are communicated to Flutter.
class SemanticsTextEditingStrategy extends DefaultTextEditingStrategy {
  /// Creates a [SemanticsTextEditingStrategy] that eagerly instantiates
  /// [domElement] so the caller can insert it before calling
  /// [SemanticsTextEditingStrategy.enable].
  SemanticsTextEditingStrategy(super.owner);

  /// Initializes the [SemanticsTextEditingStrategy] singleton.
  ///
  /// This method must be called prior to accessing [instance].
  static SemanticsTextEditingStrategy ensureInitialized(
      HybridTextEditing owner) {
    if (_instance != null && _instance?.owner == owner) {
      return _instance!;
    }
    return _instance = SemanticsTextEditingStrategy(owner);
  }

  /// The [SemanticsTextEditingStrategy] singleton.
  static SemanticsTextEditingStrategy get instance => _instance!;
  static SemanticsTextEditingStrategy? _instance;

  /// The text field whose DOM element is currently used for editing.
  ///
  /// If this field is null, no editing takes place.
  TextField? activeTextField;

  /// Current input configuration supplied by the "flutter/textinput" channel.
  InputConfiguration? inputConfig;

  /// The semantics implementation does not operate on DOM nodes, but only
  /// remembers the config and callbacks. This is because the DOM nodes are
  /// supplied in the semantics update and enabled by [activate].
  @override
  void enable(
    InputConfiguration inputConfig, {
    required OnChangeCallback onChange,
    required OnActionCallback onAction,
  }) {
    this.inputConfig = inputConfig;
    this.onChange = onChange;
    this.onAction = onAction;
  }

  /// Attaches the DOM element owned by [textField] to the text editing
  /// strategy.
  ///
  /// This method must be called after [enable] to name sure that [inputConfig],
  /// [onChange], and [onAction] are not null.
  void activate(TextField textField) {
    assert(
      inputConfig != null && onChange != null && onAction != null,
      '"enable" should be called before "enableFromSemantics" and initialize input configuration',
    );

    if (activeTextField == textField) {
      // The specified field is already active. Skip.
      return;
    } else if (activeTextField != null) {
      // Another text field is currently active. Deactivate it before switching.
      disable();
    }

    activeTextField = textField;
    domElement = textField.editableElement;
    _syncStyle();
    super.enable(inputConfig!, onChange: onChange!, onAction: onAction!);
  }

  /// Detaches the DOM element owned by [textField] from this text editing
  /// strategy.
  ///
  /// Typically at this point the element loses focus (blurs) and stops being
  /// used for editing.
  void deactivate(TextField textField) {
    if (activeTextField == textField) {
      disable();
    }
  }

  @override
  void disable() {
    // We don't want to remove the DOM element because the caller is responsible
    // for that. However we still want to stop editing, cleanup the handlers.
    if (!isEnabled) {
      return;
    }

    isEnabled = false;
    style = null;
    geometry = null;

    for (int i = 0; i < subscriptions.length; i++) {
      subscriptions[i].cancel();
    }
    subscriptions.clear();
    lastEditingState = null;

    // If the text element still has focus, remove focus from the editable
    // element to cause the on-screen keyboard, if any, to hide (e.g. on iOS,
    // Android).
    // Otherwise, the keyboard stays on screen even when the user navigates to
    // a different screen (e.g. by hitting the "back" button).
    domElement?.blur();
    domElement = null;
    activeTextField = null;
    _queuedStyle = null;
  }

  @override
  void addEventHandlers() {
    if (inputConfiguration.autofillGroup != null) {
      subscriptions
          .addAll(inputConfiguration.autofillGroup!.addInputEventListeners());
    }

    // Subscribe to text and selection changes.
    subscriptions.add(
        DomSubscription(activeDomElement, 'input', handleChange));
    subscriptions.add(
        DomSubscription(activeDomElement, 'keydown',
            maybeSendAction));
    subscriptions.add(
        DomSubscription(domDocument, 'selectionchange',
            handleChange));
    preventDefaultForMouseEvents();
  }

  @override
  void initializeTextEditing(InputConfiguration inputConfig,
      {OnChangeCallback? onChange, OnActionCallback? onAction}) {
    isEnabled = true;
    inputConfiguration = inputConfig;
    onChange = onChange;
    onAction = onAction;
    applyConfiguration(inputConfig);
  }

  @override
  void placeElement() {
    // If this text editing element is a part of an autofill group.
    if (hasAutofillGroup) {
      placeForm();
    }
    activeDomElement.focus();
  }

  @override
  void initializeElementPlacement() {
    // Element placement is done by [TextField].
  }

  @override
  void placeForm() {
  }

  @override
  void updateElementPlacement(EditableTextGeometry textGeometry) {
    // Element placement is done by [TextField].
  }

  EditableTextStyle? _queuedStyle;

  @override
  void updateElementStyle(EditableTextStyle textStyle) {
    _queuedStyle = textStyle;
    _syncStyle();
  }

  /// Apply style to the element, if both style and element are available.
  ///
  /// Because style is supplied by the "flutter/textinput" channel and the DOM
  /// element is supplied by the semantics tree, the existence of both at the
  /// same time is not guaranteed.
  void _syncStyle() {
    if (_queuedStyle == null || domElement == null) {
      return;
    }
    super.updateElementStyle(_queuedStyle!);
  }
}

/// Manages semantics objects that represent editable text fields.
///
/// This role is implemented via a content-editable HTML element. This role does
/// not proactively switch modes depending on the current
/// [EngineSemanticsOwner.gestureMode]. However, in Chrome on Android it ignores
/// browser gestures when in pointer mode. In Safari on iOS pointer events are
/// used to detect text box invocation. This is because Safari issues touch
/// events even when Voiceover is enabled.
class TextField extends PrimaryRoleManager {
  TextField(SemanticsObject semanticsObject) : super.blank(PrimaryRole.textField, semanticsObject) {
    _setupDomElement();
  }

  /// The element used for editing, e.g. `<input>`, `<textarea>`.
  DomHTMLElement? editableElement;

  /// Same as [editableElement] but null-checked.
  DomHTMLElement get activeEditableElement {
    assert(
      editableElement != null,
      'The textField does not have an active editable element',
    );
    return editableElement!;
  }

  /// Timer that times when to set the location of the input text.
  ///
  /// This is only used for iOS. In iOS, virtual keyboard shifts the screen.
  /// There is no callback to know if the keyboard is up and how much the screen
  /// has shifted. Therefore instead of listening to the shift and passing this
  /// information to Flutter Framework, we are trying to stop the shift.
  ///
  /// In iOS, the virtual keyboard shifts the screen up if the focused input
  /// element is under the keyboard or very close to the keyboard. Before the
  /// focus is called we are positioning it offscreen. The location of the input
  /// in iOS is set to correct place, 100ms after focus. We use this timer for
  /// timing this delay.
  Timer? _positionInputElementTimer;
  static const Duration _delayBeforePlacement = Duration(milliseconds: 100);

  void _initializeEditableElement() {
    assert(editableElement == null,
        'Editable element has already been initialized');

    editableElement = semanticsObject.hasFlag(ui.SemanticsFlag.isMultiline)
        ? createDomHTMLTextAreaElement()
        : createDomHTMLInputElement();

    // On iOS, even though the semantic text field is transparent, the cursor
    // and text highlighting are still visible. The cursor and text selection
    // are made invisible by CSS in [FlutterViewEmbedder.reset].
    // But there's one more case where iOS highlights text. That's when there's
    // and autocorrect suggestion. To disable that, we have to do the following:
    activeEditableElement
      ..spellcheck = false
      ..setAttribute('autocorrect', 'off')
      ..setAttribute('autocomplete', 'off')
      ..setAttribute('data-semantics-role', 'text-field');

    activeEditableElement.style
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
      ..width = '${semanticsObject.rect!.width}px'
      ..height = '${semanticsObject.rect!.height}px';
    append(activeEditableElement);
  }

  void _setupDomElement() {
    switch (browserEngine) {
      case BrowserEngine.blink:
      case BrowserEngine.firefox:
        _initializeForBlink();
      case BrowserEngine.webkit:
        _initializeForWebkit();
    }
  }

  /// Chrome on Android reports text field activation as a "click" event.
  ///
  /// When in browser gesture mode, the focus is forwarded to the framework as
  /// a tap to initialize editing.
  void _initializeForBlink() {
    _initializeEditableElement();
    activeEditableElement.addEventListener('focus',
        createDomEventListener((DomEvent event) {
          if (semanticsObject.owner.gestureMode != GestureMode.browserGestures) {
            return;
          }

          EnginePlatformDispatcher.instance.invokeOnSemanticsAction(
              semanticsObject.id, ui.SemanticsAction.didGainAccessibilityFocus, null);
        }));
    activeEditableElement.addEventListener('blur',
        createDomEventListener((DomEvent event) {
          if (semanticsObject.owner.gestureMode != GestureMode.browserGestures) {
            return;
          }

          EnginePlatformDispatcher.instance.invokeOnSemanticsAction(
              semanticsObject.id, ui.SemanticsAction.didLoseAccessibilityFocus, null);
        }));
  }

  /// Safari on iOS reports text field activation via pointer events.
  ///
  /// This emulates a tap recognizer to detect the activation. Because pointer
  /// events are present regardless of whether accessibility is enabled or not,
  /// this mode is always enabled.
  ///
  /// In iOS, the virtual keyboard shifts the screen up if the focused input
  /// element is under the keyboard or very close to the keyboard. To avoid the shift,
  /// the creation of the editable element is delayed until a tap is detected.
  ///
  /// In the absence of an editable DOM element, role of 'textbox' is assigned to the
  /// semanticsObject.element to communicate to the assistive technologies that
  /// the user can start editing by tapping on the element. Once a tap is detected,
  /// the editable element gets created and the role of textbox is removed from
  /// semanicsObject.element to avoid confusing VoiceOver.
  void _initializeForWebkit() {
    // Safari for desktop is also initialized as the other browsers.
    if (operatingSystem == OperatingSystem.macOs) {
      _initializeForBlink();
      return;
    }

    setAttribute('role', 'textbox');
    setAttribute('contenteditable', 'false');
    setAttribute('tabindex', '0');

    num? lastPointerDownOffsetX;
    num? lastPointerDownOffsetY;

    addEventListener('pointerdown',
        createDomEventListener((DomEvent event) {
          final DomPointerEvent pointerEvent = event as DomPointerEvent;
          lastPointerDownOffsetX = pointerEvent.clientX;
          lastPointerDownOffsetY = pointerEvent.clientY;
        }), true);

    addEventListener('pointerup',
        createDomEventListener((DomEvent event) {
      final DomPointerEvent pointerEvent = event as DomPointerEvent;

      if (lastPointerDownOffsetX != null) {
        assert(lastPointerDownOffsetY != null);
        final num deltaX = pointerEvent.clientX - lastPointerDownOffsetX!;
        final num deltaY = pointerEvent.clientY - lastPointerDownOffsetY!;

        // This should match the similar constant defined in:
        //
        // lib/src/gestures/constants.dart
        //
        // The value is pre-squared so we have to do less math at runtime.
        const double kTouchSlop = 18.0 * 18.0; // Logical pixels squared

        if (deltaX * deltaX + deltaY * deltaY < kTouchSlop) {
          // Recognize it as a tap that requires a keyboard.
          EnginePlatformDispatcher.instance.invokeOnSemanticsAction(
              semanticsObject.id, ui.SemanticsAction.tap, null);
          _invokeIosWorkaround();
        }
      } else {
        assert(lastPointerDownOffsetY == null);
      }

      lastPointerDownOffsetX = null;
      lastPointerDownOffsetY = null;
    }), true);
  }

  void _invokeIosWorkaround() {
    if (editableElement != null) {
      return;
    }

    _initializeEditableElement();
    activeEditableElement.style.transform = 'translate(${offScreenOffset}px, ${offScreenOffset}px)';
    _positionInputElementTimer?.cancel();
    _positionInputElementTimer = Timer(_delayBeforePlacement, () {
      editableElement?.style.transform = '';
      _positionInputElementTimer = null;
    });

    // Can not have both activeEditableElement and semanticsObject.element
    // represent the same text field. It will confuse VoiceOver, so `role` needs to
    // be assigned and removed, based on whether or not editableElement exists.
    activeEditableElement.focus();
    removeAttribute('role');

    activeEditableElement.addEventListener('blur',
        createDomEventListener((DomEvent event) {
      setAttribute('role', 'textbox');
      activeEditableElement.remove();
      SemanticsTextEditingStrategy._instance?.deactivate(this);

      // Focus on semantics element before removing the editable element, so that
      // the user can continue navigating the page with the assistive technology.
      element.focus();
      editableElement = null;
    }));
  }

  @override
  void update() {
    super.update();

    // Ignore the update if editableElement has not been created yet.
    // On iOS Safari, when the user dismisses the keyboard using the 'done' button,
    // we recieve a `blur` event from the browswer and a semantic update with
    // [hasFocus] set to true from the framework. In this case, we ignore the update
    // and wait for a tap event before invoking the iOS workaround and creating
    // the editable element.
    if (editableElement != null) {
      activeEditableElement.style
        ..width = '${semanticsObject.rect!.width}px'
        ..height = '${semanticsObject.rect!.height}px';

      if (semanticsObject.hasFocus) {
        if (domDocument.activeElement !=
            activeEditableElement) {
          semanticsObject.owner.addOneTimePostUpdateCallback(() {
            activeEditableElement.focus();
          });
        }
        SemanticsTextEditingStrategy._instance?.activate(this);
      } else if (domDocument.activeElement ==
          activeEditableElement) {
        if (!isIosSafari) {
          SemanticsTextEditingStrategy._instance?.deactivate(this);
          // Only apply text, because this node is not focused.
        }
        activeEditableElement.blur();
      }
    }

    final DomElement element = editableElement ?? this.element;
    if (semanticsObject.hasLabel) {
      element.setAttribute(
        'aria-label',
        semanticsObject.label!,
      );
    } else {
      element.removeAttribute('aria-label');
    }
  }

  @override
  void dispose() {
    super.dispose();
    _positionInputElementTimer?.cancel();
    _positionInputElementTimer = null;
    // on iOS, the `blur` event listener callback will remove the element.
    if (!isIosSafari) {
      editableElement?.remove();
    }
    SemanticsTextEditingStrategy._instance?.deactivate(this);
  }
}
