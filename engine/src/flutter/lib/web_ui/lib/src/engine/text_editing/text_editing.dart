// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../configuration.dart';
import '../dom.dart';
import '../mouse/prevent_default.dart';
import '../platform_dispatcher.dart';
import '../semantics.dart';
import '../services.dart';
import '../text/paragraph.dart';
import '../util.dart';
import '../view_embedder/flutter_view_manager.dart';
import '../window.dart';
import 'autofill_hint.dart';
import 'composition_aware_mixin.dart';
import 'input_action.dart';
import 'input_type.dart';
import 'text_capitalization.dart';

/// Make the content editable span visible to facilitate debugging.
bool _debugVisibleTextEditing = false;

/// Set this to `true` to print when text input commands are scheduled and run.
bool _debugPrintTextInputCommands = false;

/// The `keyCode` of the "Enter" key.
const int _kReturnKeyCode = 13;

/// Offset in pixels to place an element outside of the screen.
const int offScreenOffset = -9999;

/// Blink and Webkit engines, bring an overlay on top of the text field when it
/// is autofilled.
bool browserHasAutofillOverlay() =>
    ui_web.browser.browserEngine == ui_web.BrowserEngine.blink ||
    ui_web.browser.browserEngine == ui_web.BrowserEngine.webkit;

/// `transparentTextEditing` class is configured to make the autofill overlay
/// transparent.
const String transparentTextEditingClass = 'transparentTextEditing';

void _emptyCallback(dynamic _) {}

/// These style attributes are constant throughout the life time of an input
/// element.
///
/// They are assigned once during the creation of the DOM element.
void _setStaticStyleAttributes(DomHTMLElement domElement) {
  domElement.classList.add(HybridTextEditing.textEditingClass);

  final DomCSSStyleDeclaration elementStyle = domElement.style;
  elementStyle
    // Prevent (forced-colors: active) from making our invisible text fields visible.
    // For more details, see: https://developer.mozilla.org/en-US/docs/Web/CSS/forced-color-adjust
    ..setProperty('forced-color-adjust', 'none')
    ..whiteSpace = 'pre-wrap'
    ..position = 'absolute'
    ..top = '0'
    ..left = '0'
    ..margin = '0'
    ..padding = '0'
    ..opacity = '1'
    ..color = 'transparent'
    ..backgroundColor = 'transparent'
    ..background = 'transparent'
    // This property makes the input's blinking cursor transparent.
    ..caretColor = 'transparent'
    ..outline = 'none'
    ..border = 'none'
    ..resize = 'none'
    ..textShadow = 'none'
    ..overflow = 'hidden'
    ..transformOrigin = '0 0 0';

  if (browserHasAutofillOverlay()) {
    domElement.classList.add(transparentTextEditingClass);
  }

  if (_debugVisibleTextEditing) {
    elementStyle
      ..color = 'purple'
      ..outline = '1px solid purple';
  }
}

// Password managers and browser autofill skip inputs that are effectively
// zero-sized, so the invisible autofill proxies are floored to this small but
// non-trivial size to keep them detectable. This only raises a floor and never
// shrinks a normally sized field.
const String _kAutofillFieldMinWidth = '40px';
const String _kAutofillFieldMinHeight = '20px';

/// Injected once per document so an autofilled field fires an 'animationstart'
/// event (through the ':-webkit-autofill' pseudo-class) that the autofill
/// listeners use to detect a fill on Blink/WebKit even while the field is
/// blurred. Global, so the style is added exactly once rather than once per form.
bool _autofillAnimationStyleInjected = false;

void _ensureAutofillStyleInjected() {
  if (_autofillAnimationStyleInjected) {
    return;
  }
  _autofillAnimationStyleInjected = true;
  final DomHTMLStyleElement style = createDomHTMLStyleElement(null);
  style.text = '''
@keyframes flutterAutofillStart {
  from { opacity: 0.99; }
  to { opacity: 1; }
}
input:-webkit-autofill, input:autofill {
  animation-name: flutterAutofillStart !important;
  animation-duration: 1ms !important;
}
''';
  domDocument.head?.append(style);
}

/// Sets attributes to hide autofill elements.
///
/// These style attributes are constant throughout the life time of an input
/// element.
///
/// They are assigned once during the creation of the DOM element.
void _styleAutofillElements(
  DomHTMLElement domElement, {
  bool isOffScreen = false,
  bool shouldHideElement = true,
  bool shouldDisablePointerEvents = false,
}) {
  final DomCSSStyleDeclaration elementStyle = domElement.style;
  elementStyle
    ..whiteSpace = 'pre-wrap'
    ..margin = '0'
    ..padding = '0'
    ..opacity = '1'
    ..color = 'transparent'
    ..backgroundColor = 'transparent'
    ..background = 'transparent'
    ..outline = 'none'
    ..border = 'none'
    ..resize = 'none'
    ..textShadow = 'transparent'
    ..transformOrigin = '0 0 0';

  if (isOffScreen) {
    elementStyle
      ..top = '${offScreenOffset}px'
      ..left = '${offScreenOffset}px';
  }

  if (shouldHideElement) {
    // 1px rather than 0: Safari and some password managers ignore zero-sized
    // inputs (see https://github.com/flutter/flutter/issues/71275), so even a
    // hidden proxy keeps a minimal layout box. Clear any min-width/min-height
    // floor (set by the discoverable branch below, or on the focused element)
    // first, otherwise it would override the 1px and the element would not
    // actually shrink when it is hidden.
    elementStyle
      ..setProperty('min-width', '0px')
      ..setProperty('min-height', '0px')
      ..width = '1px'
      ..height = '1px';
  } else {
    // Discoverable (but invisible) autofill fields must be big enough for
    // password managers to treat them as real fields rather than skip them as
    // effectively zero-sized. The framework editable geometry can report a 1px
    // size, so floor it with min-width/min-height. This never shrinks a
    // normally-sized field.
    elementStyle
      ..setProperty('min-width', _kAutofillFieldMinWidth)
      ..setProperty('min-height', _kAutofillFieldMinHeight);
  }

  if (shouldDisablePointerEvents) {
    elementStyle.pointerEvents = 'none';
  }

  if (browserHasAutofillOverlay()) {
    domElement.classList.add(transparentTextEditingClass);
  }

  /// This property makes the input's blinking cursor transparent.
  elementStyle.setProperty('caret-color', 'transparent');
}

void _ensureEditingElementInView(DomElement element, int viewId) {
  final bool isAlreadyAppended = element.isConnected ?? false;
  if (!isAlreadyAppended) {
    // If the element is not already appended to a view, we don't need to move
    // it anywhere.
    return;
  }

  final FlutterViewManager viewManager = EnginePlatformDispatcher.instance.viewManager;
  final EngineFlutterView? currentView = viewManager.findViewForElement(element);
  if (currentView == null) {
    // For some reason, the input element was in the DOM, but it wasn't part of
    // any Flutter view. Should we throw?
    return;
  }

  if (currentView.viewId != viewId) {
    _insertEditingElementInView(element, viewId);
  }
}

void _insertEditingElementInView(DomElement element, int viewId) {
  final FlutterViewManager viewManager = EnginePlatformDispatcher.instance.viewManager;
  final EngineFlutterView? view = viewManager[viewId];
  assert(
    view != null,
    'Could not find View with id $viewId. This should never happen, please file a bug!',
  );
  final DomElement host = view!.dom.textEditingHost;
  // Do not cause DOM disturbance unless necessary. Doing superfluous DOM operations may seem
  // harmless, but it actually causes focus changes that could break things.
  if (!host.contains(element)) {
    host.append(element);
  }
}

/// Form that contains all the fields in the same AutofillGroup.
///
/// An [EngineAutofillForm] will only be constructed when autofill is enabled
/// (the default) on the current input field. See the [fromFrameworkMessage]
/// static method.
class EngineAutofillForm {
  EngineAutofillForm({
    required this.viewId,
    required this.items,
    required this.formIdentifier,
    required this.focusedElementId,
  });

  DomHTMLFormElement? formElement;

  final elements = <String, DomHTMLElement>{};

  final Map<String, String> _lastSentAutofillText = <String, String>{};

  final Map<String, String> _lastFrameworkText = <String, String>{};

  final Map<String, FieldItem> items;

  /// Identifier for the form.
  ///
  /// It is constructed by concatenating unique ids of input elements on the
  /// form.
  ///
  /// It is used for storing the form until submission.
  /// See [dormantForms].
  final String formIdentifier;

  /// The ID of the view that this form is rendered into.
  final int viewId;

  final String focusedElementId;

  bool get _isSafariStrategy =>
      textEditing.strategy is SafariDesktopTextEditingStrategy ||
      textEditing.strategy is IOSTextEditingStrategy;

  /// Creates an [EngineAutofillForm] from the JSON representation of a Flutter
  /// framework `TextInputConfiguration` object.
  ///
  /// The `focusedElementAutofill` argument corresponds to the "autofill" field
  /// in a `TextInputConfiguration`. Not having this field indicates autofill
  /// is explicitly disabled on the text field by the developer.
  ///
  /// The `fields` argument corresponds to the "fields" field in a
  /// `TextInputConfiguration`.
  ///
  /// Returns null if autofill is disabled for the input field.
  static EngineAutofillForm? fromFrameworkMessage(
    int viewId,
    Map<String, dynamic>? focusedElementAutofill,
    List<dynamic>? fields,
  ) {
    // Autofill value will be null if the developer explicitly disables it on
    // the input field.
    if (focusedElementAutofill == null) {
      return null;
    }

    final items = <String, FieldItem>{};

    // If there is only one text field in the autofill model, `fields` will be
    // null. `focusedElementAutofill` contains the information about the one
    // text field.
    if (fields != null) {
      for (final Map<String, dynamic> field in fields.cast<Map<String, dynamic>>()) {
        final autofillInfo = AutofillInfo.fromFrameworkMessage(
          field.readJson('autofill'),
          textCapitalization: TextCapitalizationConfig.fromInputConfiguration(
            field.readString('textCapitalization'),
          ),
        );

        final EngineInputType inputType = EngineInputType.fromName(
          field.readJson('inputType').readString('name'),
        );

        items[autofillInfo.uniqueIdentifier] = FieldItem(
          inputType: inputType,
          autofillInfo: autofillInfo,
        );
      }
    } else {
      final autofillInfo = AutofillInfo.fromFrameworkMessage(focusedElementAutofill);

      // Any `inputType` is okay here since this will not be used to create the focused element
      // here. The focused element is a special case that is created outside of the
      // `EngineAutofillForm`.
      const EngineInputType inputType = EngineInputType.none;

      items[autofillInfo.uniqueIdentifier] = FieldItem(
        inputType: inputType,
        autofillInfo: autofillInfo,
      );
    }

    return EngineAutofillForm(
      viewId: viewId,
      items: items,
      formIdentifier: _getFormIdentifier(items),
      focusedElementId: focusedElementAutofill.readString('uniqueIdentifier'),
    );
  }

  static String _getFormIdentifier(Map<String, FieldItem> items) {
    final ids = <String>[];
    for (final FieldItem item in items.values) {
      ids.add(item.autofillInfo.uniqueIdentifier);
    }

    ids.sort();
    return ids.join('*');
  }

  /// Wakes up the form with the given focused element.
  ///
  /// The [focusedElement] is inserted into the form, replacing the old focused element.
  void wakeUp(DomHTMLElement focusedElement, AutofillInfo focusedAutofill) {
    // Since we're disabling pointer events on the form to fix Safari autofill,
    // we need to explicitly set pointer events on the active input element in
    // order to calculate the correct pointer event offsets.
    // See: https://github.com/flutter/flutter/issues/136006
    if (_isSafariStrategy) {
      focusedElement.style.pointerEvents = 'all';
    }

    final EngineAutofillForm? existingForm = dormantForms[formIdentifier];

    final firstWakeUp = formElement == null;

    if (firstWakeUp) {
      assert(elements.isEmpty);

      if (existingForm != null) {
        // If the form already has a dormant DOM element, let's use it instead of creating a new one.
        formElement = existingForm.formElement;
        elements.addAll(existingForm.elements);
        // Carry over the per-field tracking so the reused form remembers the
        // last value forwarded for each field. Each text input connection
        // builds a new form instance, so without this the tracking would reset
        // on every focus change and the form could not tell a programmatic
        // framework update apart from a browser autofill.
        _lastSentAutofillText.addAll(existingForm._lastSentAutofillText);
        _lastFrameworkText.addAll(existingForm._lastFrameworkText);
        // The adopted DOM elements still carry the dormant instance's
        // listeners (goDormant deliberately keeps them so a late fill on the
        // dormant form is not lost). This instance rebinds its own below in
        // attachPersistentFormListeners; cancel the old ones so listener sets
        // do not accumulate across focus cycles and, more importantly, so the
        // old instance's listener for what is now the focused field does not
        // re-forward the user's typing as an autofill. That listener was
        // bound when the field was not focused, so it forwards
        // unconditionally, and _sendAutofillEditingState collapses the
        // selection to the end of the text on every keystroke.
        existingForm._cancelFormSubscriptions();
      } else {
        formElement = _createFormElementAndFields(focusedElement, focusedAutofill);
        _insertEditingElementInView(formElement!, viewId);
      }
    }

    // There's potentially a new focused element that needs to be inserted into the existing form.
    //
    // Do not cause DOM disturbance unless necessary. Doing superfluous DOM operations may seem
    // harmless, but it actually causes focus changes that could break things.
    if (!formElement!.contains(focusedElement)) {
      // Find the matching element and replace it with the new focused element.
      final DomHTMLElement oldFocusedElement = elements[focusedAutofill.uniqueIdentifier]!;
      // Before discarding the old focused element, salvage any value the browser
      // autofilled into it while it was blurred (e.g. a mobile password manager
      // filling the field the user tapped). _updateFieldValues skips the focused
      // field and the element is about to be replaced, so this is the only
      // chance to forward that value to the framework.
      final oldDomState = EditingState.fromDomElement(oldFocusedElement);
      final String frameworkText = focusedAutofill.editingState.text;
      if (oldDomState.text.isNotEmpty &&
          oldDomState.text != frameworkText &&
          oldDomState.text != _lastSentAutofillText[focusedAutofill.uniqueIdentifier]) {
        _sendAutofillEditingState(focusedAutofill.uniqueIdentifier, oldDomState);
      }
      elements[focusedAutofill.uniqueIdentifier] = focusedElement;
      oldFocusedElement.replaceWith(focusedElement);
    }

    // Pointer events belong only on the focused element. A reused element (see
    // _reuseDormantAutofillElementOrCreate) can carry over the enabled state
    // from when it was focused, so reset the non-focused fields here to keep
    // them from intercepting taps meant for the app UI.
    for (final MapEntry<String, DomHTMLElement> entry in elements.entries) {
      final bool isFocused = entry.key == focusedAutofill.uniqueIdentifier;
      entry.value.style.pointerEvents = isFocused ? 'all' : 'none';
      // The focused field stays interactive (its tabIndex is set in
      // _reuseDormantAutofillElementOrCreate); the others are kept discoverable for
      // password managers but out of the tab order and the accessibility tree, so
      // Tab and screen readers do not land on an invisible field.
      if (isFocused) {
        entry.value.removeAttribute('aria-hidden');
      } else {
        entry.value.tabIndex = -1;
        entry.value.setAttribute('aria-hidden', 'true');
      }
    }

    _updateFieldValues();
    attachPersistentFormListeners();
    scanForAutofilledValues();
  }

  /// True while a password manager holds focus to fill the form. During that
  /// window the focused field and the non-focused proxies are held at their
  /// current positions instead of tracking the browser's scroll/relayout, so
  /// repositioning them does not churn the DOM under the manager's own overlay
  /// UI. Some extension overlays race their own DOM insertion when the page
  /// mutates the tree mid-fill, so holding still avoids interfering with them.
  /// The filled values still arrive through the input/animationstart listeners.
  bool _fillWindowActive = false;

  /// Whether this form instance has been deactivated ([goDormant]) and its
  /// focused field no longer has a live connection. While dormant, the
  /// persistent listeners forward the focused field's events too; while live,
  /// the focused field is delivered by
  /// [DefaultTextEditingStrategy.handleChange] instead.
  bool _isDormant = false;

  /// Whether a password manager currently holds focus to fill the form, during
  /// which the proxy geometry is held still. See [beginFillWindow].
  bool get fillWindowActive => _fillWindowActive;

  /// Opens the fill window when a password manager takes focus to fill the form.
  /// While it is open the proxy geometry is held still (see [fillWindowActive]).
  /// It is closed by [endFillWindow] the moment focus returns to the field or
  /// the page, which is when the manager has finished and placement can resume
  /// -- an event boundary rather than a fixed timeout.
  void beginFillWindow() {
    _fillWindowActive = true;
  }

  /// Closes the fill window opened by [beginFillWindow], so proxy placement
  /// resumes. Called when the password manager hands focus back (the field or
  /// window regains focus) or when the form is deactivated.
  void endFillWindow() {
    _fillWindowActive = false;
  }

  /// Positions the non-focused proxies right next to the focused field.
  ///
  /// Only the focused field receives an on-screen geometry (transform) from the
  /// framework; without help the other proxies sit at the form origin, far away.
  /// Some password managers then fail to associate the far-away field and fill
  /// only the focused one (observed with Bitwarden). Stacking the siblings just
  /// under the focused field presents a coherent, adjacent username-above-
  /// password login form so they fill every field. (Proton Pass filled the whole
  /// form either way.)
  ///
  /// Called after the geometry transform has been applied to [focusedElement].
  void clusterNonFocusedFieldsAt(DomHTMLElement focusedElement) {
    // Held still during an active password-manager fill; see beginFillWindow.
    if (_fillWindowActive) {
      return;
    }
    final DomRect rect = focusedElement.getBoundingClientRect();
    final double w = rect.width;
    final double h = rect.height;
    // Not laid out / positioned yet -- nothing reliable to anchor to.
    if (w == 0 || h == 0) {
      return;
    }
    // Stack each non-focused proxy directly below the focused field, at the same
    // width, so the manager sees an adjacent, coherent username-above-password
    // login form (viewport coordinates, so position:fixed). Without this the
    // non-focused proxies sit at the form origin, far from the focused field,
    // and some managers fill only the focused one.
    var top = rect.top + h;
    for (final DomHTMLElement element in elements.values) {
      if (identical(element, focusedElement)) {
        continue;
      }
      element.style
        ..position = 'fixed'
        ..left = '${rect.left}px'
        ..top = '${top}px'
        ..width = '${w}px'
        ..height = '${h}px'
        ..transform = 'none';
      top += h;
    }
  }

  /// Makes the form dormant.
  ///
  /// A dormant form stays in the DOM and does not interact with the framework until it's woken up.
  ///
  /// The form is kept in the DOM to:
  /// 1. Allow the browser to autofill it.
  /// 2. Allow submitting the form later.
  void goDormant() {
    assert(formElement != null);

    // The form is deactivated; end any open fill window so it never stays frozen.
    endFillWindow();
    _isDormant = true;
    dormantForms[formIdentifier] = this;
    _styleAutofillElements(formElement!, isOffScreen: true);
  }

  DomHTMLFormElement _createFormElementAndFields(
    DomHTMLElement focusedElement,
    AutofillInfo focusedAutofill,
  ) {
    assert(this.formElement == null);
    assert(elements.isEmpty);

    final DomHTMLFormElement formElement = createDomHTMLFormElement();
    // Validation is in the framework side.
    formElement.noValidate = true;
    formElement.method = 'post';
    formElement.action = '#';
    formElement.addEventListener('submit', preventDefaultListener);

    // We need to explicitly disable pointer events on the form in Safari Desktop and iOS,
    // so that we don't have pointer event collisions if users hover over or click
    // into the invisible autofill elements within the form.
    _styleAutofillElements(formElement, shouldDisablePointerEvents: _isSafariStrategy);

    for (final FieldItem field in items.values) {
      final DomHTMLElement htmlElement;
      if (field.autofillInfo.uniqueIdentifier == focusedAutofill.uniqueIdentifier) {
        // Do not create the focused element here since it is created already. Use the provided one.
        htmlElement = focusedElement;
      } else {
        htmlElement = field.inputType.createDomElement();
        field.autofillInfo.applyToDomElement(htmlElement);

        // Keep the non-focused autofill fields sized and placed on the DOM (not
        // hidden), only visually transparent, and disable pointer events on
        // them. Safari and password-manager extensions ignore zero-size or
        // hidden inputs, which breaks a paired username+password autofill.
        // Making the elements discoverable but invisible lets those tools fill
        // the whole form.
        // (ref: https://github.com/flutter/flutter/issues/71275)
        _styleAutofillElements(
          htmlElement,
          shouldHideElement: false,
          shouldDisablePointerEvents: true,
        );
        // Keep the proxy discoverable to password managers (which scan the DOM)
        // but out of the tab order and the accessibility tree, so keyboard Tab
        // and screen readers do not land on this invisible field.
        htmlElement.tabIndex = -1;
        htmlElement.setAttribute('aria-hidden', 'true');
      }

      elements[field.autofillInfo.uniqueIdentifier] = htmlElement;
      formElement.append(htmlElement);
    }

    // In order to submit the form when Framework sends a `TextInput.commit`
    // message, we add a submit button to the form.
    // The -1 tab index value makes this element not reachable by keyboard.
    final DomHTMLInputElement submitButton = createDomHTMLInputElement()..tabIndex = -1;
    _styleAutofillElements(submitButton, isOffScreen: true);
    submitButton.className = 'submitBtn';
    submitButton.type = 'submit';
    formElement.append(submitButton);

    return formElement;
  }

  /// Updates the field values in this form.
  void _updateFieldValues() {
    for (final String key in elements.keys) {
      final DomHTMLElement element = elements[key]!;
      final AutofillInfo autofill = items[key]!.autofillInfo;

      // A field's DOM value and the framework's stored value can diverge in two
      // ways. When the browser autofills the field, the DOM holds a value the
      // framework has not seen yet, so it must be forwarded and kept. Otherwise
      // the framework is the source of truth, either it just changed (a
      // programmatic update) or it is already in sync. The last framework value
      // per field tells them apart: an autofill is an unchanged framework value
      // next to a changed DOM value.
      //
      // This runs for the focused field too. On mobile a password manager fills
      // the field the user tapped (the focused field) while it is blurred, and
      // that value would otherwise never be forwarded: the focused field has no
      // other recovery path.
      final domEditingState = EditingState.fromDomElement(element);
      final String frameworkText = autofill.editingState.text;
      final String lastFrameworkText =
          _lastFrameworkText[autofill.uniqueIdentifier] ?? frameworkText;
      _lastFrameworkText[autofill.uniqueIdentifier] = frameworkText;
      final bool frameworkUnchanged = frameworkText == lastFrameworkText;
      if (frameworkUnchanged &&
          domEditingState.text.isNotEmpty &&
          domEditingState.text != frameworkText) {
        // The browser autofilled this field (the framework's own value is
        // unchanged next to a different DOM value). Forward it and keep it
        // instead of clearing it.
        if (domEditingState.text != _lastSentAutofillText[autofill.uniqueIdentifier]) {
          _sendAutofillEditingState(autofill.uniqueIdentifier, domEditingState);
        }
        continue;
      }
      // The framework wins: it changed (a programmatic update) or is in sync.
      // Only push the framework value onto non-focused elements; the focused
      // element's selection/cursor is owned by the active connection, and
      // applying selection on non-focused elements may cause them to gain focus
      // unexpectedly.
      if (key != focusedElementId) {
        autofill.editingState.applyTextToDomElement(element);
      }
    }
  }

  /// Records the framework's own value for [fieldId] so a later
  /// [scanForAutofilledValues] or [_updateFieldValues] does not mistake it for a
  /// browser autofill and echo it straight back. The field's *current* framework
  /// value must be compared against, not the stale config-time
  /// [AutofillInfo.editingState].
  void noteFrameworkEditingState(String fieldId, EditingState editingState) {
    _lastSentAutofillText[fieldId] = editingState.text;
  }

  /// Scans every field for a value the browser autofilled but the framework has
  /// not seen yet, and forwards it. Unlike [_updateFieldValues] this never
  /// pushes framework values back onto the DOM, so it is safe to call repeatedly
  /// (e.g. when the window regains focus or the page becomes visible) to pick up
  /// an autofill that arrived without an input event and without the user
  /// refocusing the field. Skips a value already in [_lastSentAutofillText].
  void scanForAutofilledValues() {
    if (elements.isEmpty) {
      return;
    }
    // Keep the non-focused proxies clustered under the focused field. Done here
    // (not in updateElementPlacement, which does not fire for this flow) because
    // the scan runs after the field has been laid out and positioned.
    final DomHTMLElement? focused = elements[focusedElementId];
    if (focused != null) {
      clusterNonFocusedFieldsAt(focused);
    }
    for (final String key in elements.keys) {
      final DomHTMLElement element = elements[key]!;
      final AutofillInfo autofill = items[key]!.autofillInfo;
      final domState = EditingState.fromDomElement(element);
      final String? lastSent = _lastSentAutofillText[autofill.uniqueIdentifier];

      // Only forward a value the browser autofilled, i.e. one that differs from
      // both what was last forwarded and the framework's own value. Without the
      // second check the framework's value (applied to the DOM via
      // setEditingState) would be echoed straight back as a fake autofill.
      if (domState.text.isNotEmpty &&
          domState.text != lastSent &&
          domState.text != autofill.editingState.text) {
        _sendAutofillEditingState(autofill.uniqueIdentifier, domState);
      }
    }
  }

  final List<DomSubscription> _formSubscriptions = <DomSubscription>[];

  void _cancelFormSubscriptions() {
    for (final DomSubscription subscription in _formSubscriptions) {
      subscription.cancel();
    }
    _formSubscriptions.clear();
  }

  /// The DOM events that can carry a browser autofill. A password manager fills
  /// a (possibly blurred) field by setting its value and dispatching
  /// 'input'/'change'; Blink and WebKit additionally fire 'animationstart'
  /// through the ':-webkit-autofill' hook injected by
  /// [_ensureAutofillStyleInjected].
  static const List<String> _autofillEventTypes = <String>[
    'input',
    'change',
    'animationstart',
    'webkitAnimationStart',
  ];

  /// Forwards the element's current value to the framework when the browser has
  /// autofilled it: a non-empty value that differs from what was last forwarded
  /// for the field.
  void _forwardAutofillIfChanged(DomHTMLElement element, AutofillInfo autofillInfo) {
    final domState = EditingState.fromDomElement(element);
    if (domState.text.isNotEmpty &&
        domState.text != _lastSentAutofillText[autofillInfo.uniqueIdentifier]) {
      _sendAutofillEditingState(autofillInfo.uniqueIdentifier, domState);
    }
  }

  /// Binds autofill listeners to the non-focused fields for the lifetime of the
  /// (re)woken form, replacing any previous set.
  ///
  /// Unlike [addInputEventListeners] (used by the semantics strategy, whose
  /// subscriptions are owned by [DefaultTextEditingStrategy.subscriptions]),
  /// this owns its subscriptions in [_formSubscriptions] so they can be rebound
  /// each time the form wakes. The focused field is observed only after its
  /// connection has closed (see the guard in the listener); while it is live its
  /// edits and autofills are delivered by [handleChange].
  void attachPersistentFormListeners() {
    _ensureAutofillStyleInjected();
    _cancelFormSubscriptions();

    for (final String key in elements.keys) {
      final DomHTMLElement element = elements[key]!;
      final FieldItem? fieldItem = items[key];
      if (fieldItem == null) {
        continue;
      }
      final bool isFocusedField = key == focusedElementId;
      final AutofillInfo autofillInfo = fieldItem.autofillInfo;
      for (final String type in _autofillEventTypes) {
        _formSubscriptions.add(
          DomSubscription(
            element,
            type,
            createDomEventListener((DomEvent _) {
              // While the form is live the focused field's edits and autofills
              // are delivered by handleChange; observing it here too would
              // re-forward the user's own typing as a browser autofill. Once
              // the form went dormant (its connection closed) forward from
              // here, so a manager filling the focused field after it lost
              // focus still reaches the framework (routed via the last
              // connection on the framework side). Dormancy is tracked on the
              // form itself rather than through textEditing.isEditing: the
              // form belongs to one HybridTextEditing instance and must not
              // consult the shared singleton's state.
              if (isFocusedField && !_isDormant) {
                return;
              }
              _forwardAutofillIfChanged(element, autofillInfo);
            }),
          ),
        );
      }
    }
  }

  /// Attaches autofill listeners to every field of the form and returns the
  /// subscriptions so the caller can cancel them.
  ///
  /// Used by the semantics text-editing strategy, whose fields already exist
  /// when its handlers are attached. [DefaultTextEditingStrategy] instead builds
  /// its form lazily and (re)binds these listeners from [wakeUp] through
  /// [attachPersistentFormListeners].
  List<DomSubscription> addInputEventListeners() {
    _ensureAutofillStyleInjected();
    final Iterable<String> keys = elements.keys;
    final subscriptions = <DomSubscription>[];

    void addSubscriptionForKey(String key) {
      final DomHTMLElement element = elements[key]!;
      final FieldItem? fieldItem = items[key];
      if (fieldItem == null) {
        throw StateError('AutofillInfo must have a valid uniqueIdentifier.');
      }
      final AutofillInfo autofillInfo = fieldItem.autofillInfo;
      for (final String type in _autofillEventTypes) {
        subscriptions.add(
          DomSubscription(
            element,
            type,
            createDomEventListener((DomEvent _) => _forwardAutofillIfChanged(element, autofillInfo)),
          ),
        );
      }
    }

    keys.forEach(addSubscriptionForKey);
    return subscriptions;
  }

  /// Sends the 'TextInputClient.updateEditingStateWithTag' message to the framework.
  void _sendAutofillEditingState(String tag, EditingState editingState) {
    // Collapse selection to end of text for autofilled values so Chrome's
    // DOM selection highlight doesn't leave the field text selected in Flutter.
    final cleanEditingState = EditingState(
      text: editingState.text,
      baseOffset: editingState.text.length,
      extentOffset: editingState.text.length,
    );
    _lastSentAutofillText[tag] = cleanEditingState.text;
    EnginePlatformDispatcher.instance.invokeOnPlatformMessage(
      'flutter/textinput',
      const JSONMethodCodec().encodeMethodCall(
        MethodCall('TextInputClient.updateEditingStateWithTag', <dynamic>[
          0,
          <String, dynamic>{tag: cleanEditingState.toFlutter()},
        ]),
      ),
      _emptyCallback,
    );
    EnginePlatformDispatcher.instance.scheduleFrame();
  }
}

/// Holds information about a single field in an autofill group.
class FieldItem {
  FieldItem({required this.inputType, required this.autofillInfo});

  /// The input type of the field.
  final EngineInputType inputType;

  /// The autofill information for the field.
  final AutofillInfo autofillInfo;
}

/// Autofill related values.
///
/// These values are to be used when a text field have autofill enabled.
@visibleForTesting
class AutofillInfo {
  AutofillInfo({
    required this.editingState,
    required this.uniqueIdentifier,
    required this.autofillHint,
    required this.textCapitalization,
    this.placeholder,
  });

  factory AutofillInfo.fromFrameworkMessage(
    Map<String, dynamic> autofill, {
    TextCapitalizationConfig textCapitalization =
        const TextCapitalizationConfig.defaultCapitalization(),
  }) {
    final String uniqueIdentifier = autofill.readString('uniqueIdentifier');
    final List<dynamic>? hintsList = autofill.tryList('hints');
    final String? firstHint = (hintsList == null || hintsList.isEmpty)
        ? null
        : hintsList.first as String;
    final editingState = EditingState.fromFrameworkMessage(autofill.readJson('editingValue'));
    return AutofillInfo(
      uniqueIdentifier: uniqueIdentifier,
      autofillHint: (firstHint != null)
          ? BrowserAutofillHints.instance.flutterToEngine(firstHint)
          : null,
      editingState: editingState,
      placeholder: autofill.tryString('hintText'),
      textCapitalization: textCapitalization,
    );
  }

  /// The current text and selection state of a text field.
  final EditingState editingState;

  /// Unique value set by the developer or generated by the framework.
  ///
  /// Used as id of the text field.
  ///
  /// An example an id generated by the framework: `EditableText-285283643`.
  final String uniqueIdentifier;

  /// Information on how should autofilled text capitalized.
  ///
  /// For example for [TextCapitalization.characters] each letter is converted
  /// to upper case.
  ///
  /// This value is not necessary for autofilling the focused element since
  /// [DefaultTextEditingStrategy.inputConfiguration] already has this
  /// information.
  ///
  /// On the other hand for the multi element forms, for the input elements
  /// other the focused field, we need to use this information.
  final TextCapitalizationConfig textCapitalization;

  /// The type of information expected in the field, specified by the developer.
  ///
  /// Used as a guidance to the browser as to the type of information expected
  /// in the field.
  /// See: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete
  final String? autofillHint;

  /// The optional hint text placed on the view that typically suggests what
  /// sort of input the field accepts, for example "enter your password here".
  ///
  /// If the developer does not specify any [autofillHints], the [placeholder]
  /// can be a useful indication to the platform autofill service as to what
  /// information is expected in this field.
  final String? placeholder;

  void applyToDomElement(DomHTMLElement domElement, {bool focusedElement = false}) {
    final String? autofillHint = this.autofillHint;
    final String? placeholder = this.placeholder;
    if (domElement.isA<DomHTMLInputElement>()) {
      final element = domElement as DomHTMLInputElement;
      if (placeholder != null) {
        element.placeholder = placeholder;
      }
      if (autofillHint != null) {
        element.name = autofillHint;
        element.id = autofillHint;
        if (autofillHint.contains('password')) {
          element.type = 'password';
        } else {
          element.type = 'text';
        }
      }
      element.autocomplete = autofillHint ?? 'on';
    } else if (domElement.isA<DomHTMLTextAreaElement>()) {
      final element = domElement as DomHTMLTextAreaElement;
      if (placeholder != null) {
        element.placeholder = placeholder;
      }
      if (autofillHint != null) {
        element.name = autofillHint;
        element.id = autofillHint;
      }
      element.setAttribute('autocomplete', autofillHint ?? 'on');
    }
  }
}

/// Replaces a range of text in the original string with the text given in the
/// replacement string.
String _replace(String originalText, String replacementText, ui.TextRange replacedRange) {
  assert(replacedRange.isValid);
  assert(replacedRange.start <= originalText.length && replacedRange.end <= originalText.length);

  final normalizedRange = ui.TextRange(
    start: math.min(replacedRange.start, replacedRange.end),
    end: math.max(replacedRange.start, replacedRange.end),
  );

  return normalizedRange.textBefore(originalText) +
      replacementText +
      normalizedRange.textAfter(originalText);
}

/// The change between the last editing state and the current editing state
/// of a text field.
///
/// This is packaged into a JSON and sent to the framework
/// to be processed into a concrete [TextEditingDelta].
class TextEditingDeltaState {
  TextEditingDeltaState({
    this.oldText = '',
    this.deltaText = '',
    this.deltaStart = -1,
    this.deltaEnd = -1,
    this.baseOffset,
    this.extentOffset,
    this.composingOffset,
    this.composingExtent,
  });

  /// Infers the correct delta values based on information from the new editing state
  /// and the last editing state.
  ///
  /// For a deletion, the length and the direction of the deletion (backward or forward)
  /// are calculated by comparing the new and last editing states.
  /// If the deletion is backward, the length is susbtracted from the [deltaEnd]
  /// that we set when beforeinput was fired to determine the [deltaStart].
  /// If the deletion is forward, [deltaStart] is set to the new editing state baseOffset
  /// and [deltaEnd] is set to [deltaStart] incremented by the length of the deletion.
  ///
  /// For a replacement at a selection we set the [deltaStart] to be the beginning of the selection
  /// from the last editing state.
  ///
  /// For the composing region we check if a composing range was captured by the compositionupdate event,
  /// we have a non empty [deltaText], and that we did not have an active selection. An active selection
  /// would mean we are not composing.
  ///
  /// We then verify that the delta we collected results in the text contained within the new editing state
  /// when applied to the last editing state. If it is not then we use our new editing state as the source of truth,
  /// and use regex to find the correct [deltaStart] and [deltaEnd].
  static TextEditingDeltaState inferDeltaState(
    EditingState newEditingState,
    EditingState? lastEditingState,
    TextEditingDeltaState lastTextEditingDeltaState,
  ) {
    final TextEditingDeltaState newTextEditingDeltaState = lastTextEditingDeltaState.copyWith();
    final previousSelectionWasCollapsed =
        lastEditingState?.baseOffset == lastEditingState?.extentOffset;
    final bool isTextBeingRemoved =
        newTextEditingDeltaState.deltaText.isEmpty && newTextEditingDeltaState.deltaEnd != -1;
    final bool isTextBeingChangedAtActiveSelection =
        newTextEditingDeltaState.deltaText.isNotEmpty && !previousSelectionWasCollapsed;

    if (isTextBeingRemoved) {
      // When text is deleted outside of the composing region or is cut using the native toolbar,
      // we calculate the length of the deleted text by comparing the new and old editing state lengths.
      // If the deletion is backward, the length is subtracted from the [deltaEnd]
      // that we set when beforeinput was fired to determine the [deltaStart].
      // If the deletion is forward, [deltaStart] is set to the new editing state baseOffset
      // and [deltaEnd] is set to [deltaStart] incremented by the length of the deletion.
      final int deletedLength =
          newTextEditingDeltaState.oldText.length - newEditingState.text.length;
      final backwardDeletion = newEditingState.baseOffset != lastEditingState?.baseOffset;
      if (backwardDeletion) {
        newTextEditingDeltaState.deltaStart = newTextEditingDeltaState.deltaEnd - deletedLength;
      } else {
        // Forward deletion
        newTextEditingDeltaState.deltaStart = newEditingState.baseOffset;
        newTextEditingDeltaState.deltaEnd = newTextEditingDeltaState.deltaStart + deletedLength;
      }
    } else if (isTextBeingChangedAtActiveSelection) {
      final bool isPreviousSelectionInverted =
          lastEditingState!.baseOffset > lastEditingState.extentOffset;
      // When a selection of text is replaced by a copy/paste operation we set the starting range
      // of the delta to be the beginning of the selection of the previous editing state.
      newTextEditingDeltaState.deltaStart = isPreviousSelectionInverted
          ? lastEditingState.extentOffset
          : lastEditingState.baseOffset;
    }

    // If we are composing then set the delta range to the composing region we
    // captured in compositionupdate.
    final bool isCurrentlyComposing =
        newTextEditingDeltaState.composingOffset != null &&
        newTextEditingDeltaState.composingOffset != newTextEditingDeltaState.composingExtent;
    if (newTextEditingDeltaState.deltaText.isNotEmpty &&
        previousSelectionWasCollapsed &&
        isCurrentlyComposing) {
      newTextEditingDeltaState.deltaStart = newTextEditingDeltaState.composingOffset!;
    }

    final bool isDeltaRangeEmpty =
        newTextEditingDeltaState.deltaStart == -1 &&
        newTextEditingDeltaState.deltaStart == newTextEditingDeltaState.deltaEnd;
    if (!isDeltaRangeEmpty) {
      // To verify the range of our delta we should compare the newEditingState's
      // text with the delta applied to the oldText. If they differ then capture
      // the correct delta range from the newEditingState's text value.
      //
      // We can assume the deltaText for additions and replacements to the text value
      // are accurate. What may not be accurate is the range of the delta.
      //
      // We can think of the newEditingState as our source of truth.
      //
      // This verification is needed for cases such as the insertion of a period
      // after a double space, and the insertion of an accented character through
      // a native composing menu.
      final replacementRange = ui.TextRange(
        start: newTextEditingDeltaState.deltaStart,
        end: newTextEditingDeltaState.deltaEnd,
      );
      final String textAfterDelta = _replace(
        newTextEditingDeltaState.oldText,
        newTextEditingDeltaState.deltaText,
        replacementRange,
      );
      final isDeltaVerified = textAfterDelta == newEditingState.text;

      if (!isDeltaVerified) {
        // 1. Find all matches for deltaText.
        // 2. Apply matches/replacement to oldText until oldText matches the
        // new editing state's text value.
        final bool isPeriodInsertion = newTextEditingDeltaState.deltaText.contains('.');
        final deltaTextPattern = RegExp(RegExp.escape(newTextEditingDeltaState.deltaText));
        for (final Match match in deltaTextPattern.allMatches(newEditingState.text)) {
          String textAfterMatch;
          int actualEnd;
          final bool isMatchWithinOldTextBounds =
              match.start >= 0 && match.end <= newTextEditingDeltaState.oldText.length;
          if (!isMatchWithinOldTextBounds) {
            actualEnd = match.start + newTextEditingDeltaState.deltaText.length - 1;
            textAfterMatch = _replace(
              newTextEditingDeltaState.oldText,
              newTextEditingDeltaState.deltaText,
              ui.TextRange(start: match.start, end: actualEnd),
            );
          } else {
            actualEnd = actualEnd = isPeriodInsertion ? match.end - 1 : match.end;
            textAfterMatch = _replace(
              newTextEditingDeltaState.oldText,
              newTextEditingDeltaState.deltaText,
              ui.TextRange(start: match.start, end: actualEnd),
            );
          }

          if (textAfterMatch == newEditingState.text) {
            newTextEditingDeltaState.deltaStart = match.start;
            newTextEditingDeltaState.deltaEnd = actualEnd;
            break;
          }
        }
      }
    }

    // Update selection of the delta using information from the new editing state.
    newTextEditingDeltaState.baseOffset = newEditingState.baseOffset;
    newTextEditingDeltaState.extentOffset = newEditingState.extentOffset;

    return newTextEditingDeltaState;
  }

  /// The text before the text field was updated.
  String oldText;

  /// The text that is being inserted/replaced into the text field.
  /// This will be an empty string for deletions and non text updates
  /// such as selection updates.
  String deltaText;

  /// The position in the text field where the change begins.
  ///
  /// Has a default value of -1 to signify an empty range.
  int deltaStart;

  /// The position in the text field where the change ends.
  ///
  /// Has a default value of -1 to signify an empty range.
  int deltaEnd;

  /// The updated starting position of the selection in the text field.
  int? baseOffset;

  /// The updated terminating position of the selection in the text field.
  int? extentOffset;

  /// The starting position of the composing region.
  int? composingOffset;

  /// The terminating position of the composing region.
  int? composingExtent;

  Map<String, dynamic> toFlutter() => <String, dynamic>{
    'deltas': <Map<String, dynamic>>[
      <String, dynamic>{
        'oldText': oldText,
        'deltaText': deltaText,
        'deltaStart': deltaStart,
        'deltaEnd': deltaEnd,
        'selectionBase': baseOffset,
        'selectionExtent': extentOffset,
        'composingBase': composingOffset,
        'composingExtent': composingExtent,
      },
    ],
  };

  TextEditingDeltaState copyWith({
    String? oldText,
    String? deltaText,
    int? deltaStart,
    int? deltaEnd,
    int? baseOffset,
    int? extentOffset,
    int? composingOffset,
    int? composingExtent,
  }) {
    return TextEditingDeltaState(
      oldText: oldText ?? this.oldText,
      deltaText: deltaText ?? this.deltaText,
      deltaStart: deltaStart ?? this.deltaStart,
      deltaEnd: deltaEnd ?? this.deltaEnd,
      baseOffset: baseOffset ?? this.baseOffset,
      extentOffset: extentOffset ?? this.extentOffset,
      composingOffset: composingOffset ?? this.composingOffset,
      composingExtent: composingExtent ?? this.composingExtent,
    );
  }
}

/// The current text and selection state of a text field.
class EditingState {
  EditingState({
    required this.text,
    required int baseOffset,
    required int extentOffset,
    this.composingBaseOffset = -1,
    this.composingExtentOffset = -1,
  }) : // Don't allow negative numbers.
       baseOffset = math.max(0, baseOffset),
       // Don't allow negative numbers.
       extentOffset = math.max(0, extentOffset);

  /// Creates an [EditingState] instance using values from an editing state Map
  /// coming from Flutter.
  ///
  /// The `editingState` Map has the following structure:
  /// ```json
  /// {
  ///   "text": "The text here",
  ///   "selectionBase": 0,
  ///   "selectionExtent": 0,
  ///   "selectionAffinity": "TextAffinity.upstream",
  ///   "selectionIsDirectional": false,
  ///   "composingBase": -1,
  ///   "composingExtent": -1
  /// }
  /// ```
  ///
  /// Flutter Framework can send the [selectionBase] and [selectionExtent] as
  /// -1, if so 0 assigned to the [baseOffset] and [extentOffset]. -1 is not a
  /// valid selection range for input DOM elements.
  factory EditingState.fromFrameworkMessage(Map<String, dynamic> flutterEditingState) {
    final String text = flutterEditingState.readString('text');
    final int selectionBase = flutterEditingState.readInt('selectionBase');
    final int selectionExtent = flutterEditingState.readInt('selectionExtent');
    final int composingBase = flutterEditingState.readInt('composingBase');
    final int composingExtent = flutterEditingState.readInt('composingExtent');

    return EditingState(
      text: text,
      baseOffset: selectionBase,
      extentOffset: selectionExtent,
      composingBaseOffset: composingBase,
      composingExtentOffset: composingExtent,
    );
  }

  /// Creates an [EditingState] instance using values from the editing element
  /// in the DOM.
  ///
  /// [domElement] can be a [InputElement] or a [TextAreaElement] depending on
  /// the [InputType] of the text field.
  factory EditingState.fromDomElement(DomHTMLElement domElement) {
    if (domElement.isA<DomHTMLInputElement>()) {
      final element = domElement as DomHTMLInputElement;
      final int selectionEnd = element.selectionEnd?.toInt() ?? 0;
      final int selectionStart = element.selectionStart?.toInt() ?? 0;
      if (element.selectionDirection == 'backward') {
        return EditingState(
          text: element.value,
          baseOffset: selectionEnd,
          extentOffset: selectionStart,
        );
      } else {
        return EditingState(
          text: element.value,
          baseOffset: selectionStart,
          extentOffset: selectionEnd,
        );
      }
    } else if (domElement.isA<DomHTMLTextAreaElement>()) {
      final element = domElement as DomHTMLTextAreaElement;
      final int selectionEnd = element.selectionEnd?.toInt() ?? 0;
      final int selectionStart = element.selectionStart?.toInt() ?? 0;
      if (element.selectionDirection == 'backward') {
        return EditingState(
          text: element.value,
          baseOffset: selectionEnd,
          extentOffset: selectionStart,
        );
      } else {
        return EditingState(
          text: element.value,
          baseOffset: selectionStart,
          extentOffset: selectionEnd,
        );
      }
    } else {
      throw UnsupportedError('Initialized with unsupported input type');
    }
  }

  // Pick the smallest selection index for base.
  int get minOffset => math.min(baseOffset, extentOffset);
  // Pick the greatest selection index for extent.
  int get maxOffset => math.max(baseOffset, extentOffset);

  EditingState copyWith({
    String? text,
    int? baseOffset,
    int? extentOffset,
    int? composingBaseOffset,
    int? composingExtentOffset,
  }) {
    return EditingState(
      text: text ?? this.text,
      baseOffset: baseOffset ?? this.baseOffset,
      extentOffset: extentOffset ?? this.extentOffset,
      composingBaseOffset: composingBaseOffset ?? this.composingBaseOffset,
      composingExtentOffset: composingExtentOffset ?? this.composingExtentOffset,
    );
  }

  /// The counterpart of [EditingState.fromFrameworkMessage]. It generates a Map that
  /// can be sent to Flutter.
  // TODO(mdebbar): Should we get `selectionAffinity` and other properties from flutter's editing state?
  Map<String, dynamic> toFlutter() => <String, dynamic>{
    'text': text,
    'selectionBase': baseOffset,
    'selectionExtent': extentOffset,
    'composingBase': composingBaseOffset,
    'composingExtent': composingExtentOffset,
  };

  /// The current text being edited.
  final String text;

  /// The offset at which the text selection originates.
  final int baseOffset;

  /// The offset at which the text selection terminates.
  final int extentOffset;

  /// The offset at which [CompositionAwareMixin.composingText] begins, if any.
  final int composingBaseOffset;

  /// The offset at which [CompositionAwareMixin.composingText] terminates, if any.
  final int composingExtentOffset;

  /// Whether the current editing state is valid or not.
  bool get isValid => baseOffset >= 0 && extentOffset >= 0;

  @override
  int get hashCode =>
      Object.hash(text, baseOffset, extentOffset, composingBaseOffset, composingExtentOffset);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return other is EditingState &&
        other.text == text &&
        other.minOffset == minOffset &&
        other.maxOffset == maxOffset &&
        other.composingBaseOffset == composingBaseOffset &&
        other.composingExtentOffset == composingExtentOffset;
  }

  @override
  String toString() {
    var result = super.toString();
    assert(() {
      result =
          'EditingState("$text", base:$baseOffset, extent:$extentOffset, composingBase:$composingBaseOffset, composingExtent:$composingExtentOffset)';
      return true;
    }());
    return result;
  }

  /// Sets the selection values of a DOM element using this [EditingState].
  ///
  /// [domElement] can be a [InputElement] or a [TextAreaElement] depending on
  /// the [InputType] of the text field.
  ///
  /// This should only be used by focused elements only, because only focused
  /// elements can have their text selection range set. Attempting to set
  /// selection range on a non-focused element will cause it to request focus.
  ///
  /// See also:
  ///
  ///  * [applyTextToDomElement], which is used for non-focused elements.
  void applyToDomElement(DomHTMLElement? domElement) {
    if (domElement != null && domElement.isA<DomHTMLInputElement>()) {
      final element = domElement as DomHTMLInputElement;
      element.value = text;
      element.setSelectionRange(minOffset, maxOffset);
    } else if (domElement != null && domElement.isA<DomHTMLTextAreaElement>()) {
      final element = domElement as DomHTMLTextAreaElement;
      element.value = text;
      element.setSelectionRange(minOffset, maxOffset);
    } else {
      throw UnsupportedError(
        'Unsupported DOM element type: <${domElement?.tagName}> (${domElement.runtimeType})',
      );
    }
  }

  /// Applies the [text] to the [domElement].
  ///
  /// This is used by non-focused elements.
  ///
  /// See also:
  ///
  ///  * [applyToDomElement], which is used for focused elements.
  void applyTextToDomElement(DomHTMLElement? domElement) {
    if (domElement != null && domElement.isA<DomHTMLInputElement>()) {
      final element = domElement as DomHTMLInputElement;
      element.value = text;
    } else if (domElement != null && domElement.isA<DomHTMLTextAreaElement>()) {
      final element = domElement as DomHTMLTextAreaElement;
      element.value = text;
    } else {
      throw UnsupportedError('Unsupported DOM element type');
    }
  }
}

/// Controls the appearance of the input control being edited.
///
/// For example, [inputType] determines whether we should use `<input>` or
/// `<textarea>` as a backing DOM element.
///
/// This corresponds to Flutter's [TextInputConfiguration].
class InputConfiguration {
  InputConfiguration({
    required this.viewId,
    this.inputType = EngineInputType.text,
    this.inputAction = 'TextInputAction.done',
    this.obscureText = false,
    this.readOnly = false,
    this.autocorrect = true,
    this.textCapitalization = const TextCapitalizationConfig.defaultCapitalization(),
    this.autofill,
    this.autofillGroup,
    this.enableDeltaModel = false,
    this.enableInteractiveSelection = true,
  });

  InputConfiguration.fromFrameworkMessage(Map<String, dynamic> flutterInputConfiguration)
    : viewId = flutterInputConfiguration.tryInt('viewId') ?? kImplicitViewId,
      inputType = EngineInputType.fromName(
        flutterInputConfiguration.readJson('inputType').readString('name'),
        isDecimal: flutterInputConfiguration.readJson('inputType').tryBool('decimal') ?? false,
        isMultiline:
            flutterInputConfiguration.readJson('inputType').tryBool('isMultiline') ?? false,
      ),
      inputAction = flutterInputConfiguration.tryString('inputAction') ?? 'TextInputAction.done',
      obscureText = flutterInputConfiguration.tryBool('obscureText') ?? false,
      readOnly = flutterInputConfiguration.tryBool('readOnly') ?? false,
      autocorrect = flutterInputConfiguration.tryBool('autocorrect') ?? true,
      textCapitalization = TextCapitalizationConfig.fromInputConfiguration(
        flutterInputConfiguration.readString('textCapitalization'),
      ),
      autofill = flutterInputConfiguration.containsKey('autofill')
          ? AutofillInfo.fromFrameworkMessage(flutterInputConfiguration.readJson('autofill'))
          : null,
      autofillGroup = EngineAutofillForm.fromFrameworkMessage(
        flutterInputConfiguration.tryInt('viewId') ?? kImplicitViewId,
        flutterInputConfiguration.tryJson('autofill'),
        flutterInputConfiguration.tryList('fields'),
      ),
      enableDeltaModel = flutterInputConfiguration.tryBool('enableDeltaModel') ?? false,
      enableInteractiveSelection =
          flutterInputConfiguration.tryBool('enableInteractiveSelection') ?? true;

  /// The ID of the view that contains the text field.
  final int viewId;

  /// The type of information being edited in the input control.
  final EngineInputType inputType;

  /// The default action for the input field.
  final String inputAction;

  /// Whether the text field can be edited or not.
  ///
  /// Defaults to false.
  final bool readOnly;

  /// Whether to hide the text being edited.
  final bool obscureText;

  /// Whether to enable autocorrection.
  ///
  /// Definition of autocorrect can be found in:
  /// https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  ///
  /// For future manual tests, note that autocorrect is an attribute only
  /// supported by Safari.
  final bool autocorrect;

  final bool enableDeltaModel;

  /// Autofill information for the focused text field.
  final AutofillInfo? autofill;

  final EngineAutofillForm? autofillGroup;

  final TextCapitalizationConfig textCapitalization;

  /// Whether the user can change the text selection.
  ///
  /// When this is false, the text selection cannot be adjusted by
  /// the user, text cannot be copied, and the user cannot paste into
  /// the text field from the clipboard.
  final bool enableInteractiveSelection;
}

typedef OnChangeCallback =
    void Function(EditingState? editingState, TextEditingDeltaState? editingDeltaState);
typedef OnActionCallback = void Function(String? inputAction);

/// Provides HTML DOM functionality for editable text.
///
/// A concrete implementation is picked at runtime based on the current
/// operating system, web browser, and accessibility mode.
abstract class TextEditingStrategy {
  void initializeTextEditing(
    InputConfiguration inputConfig, {
    required OnChangeCallback onChange,
    required OnActionCallback onAction,
  });

  /// Sets the initial placement of the DOM element on the UI.
  ///
  /// The element must be located exactly in the same place with the editable
  /// widget. However, its contents and cursor will be invisible.
  ///
  /// Users can interact with the element and use the functionality of the
  /// right-click menu, such as copy, paste, cut, select, translate, etc.
  void initializeElementPlacement();

  /// Register event listeners to the DOM element.
  ///
  /// These event listener will be removed in [disable].
  void addEventHandlers();

  /// Update the element's position.
  ///
  /// The position will be updated everytime Flutter Framework sends
  /// 'TextInput.setEditableSizeAndTransform' message.
  void updateElementPlacement(EditableTextGeometry geometry);

  /// Set editing state of the element.
  ///
  /// This includes text and selection relelated states. The editing state will
  /// be updated everytime Flutter Framework sends 'TextInput.setEditingState'
  /// message.
  void setEditingState(EditingState editingState);

  /// Set style to the native DOM element used for text editing.
  void updateElementStyle(EditableTextStyle style);

  /// Disables the element so it's no longer used for text editing.
  ///
  /// Calling [disable] also removes any registered event listeners.
  void disable();
}

/// A [TextEditingStrategy] that places its [domElement] assuming no
/// prior transform or sizing is applied to it.
///
/// This implementation is used by text editables when semantics is not
/// enabled. With semantics enabled the placement is provided by the semantics
/// tree.
class GloballyPositionedTextEditingStrategy extends DefaultTextEditingStrategy {
  GloballyPositionedTextEditingStrategy(super.owner);

  @override
  void placeElement() {
    geometry?.applyToDomElement(activeDomElement);
    // Set the last editing state if it exists, this is critical for a
    // users ongoing work to continue uninterrupted when there is an update to
    // the transform.
    lastEditingState?.applyToDomElement(domElement);
    if (hasAutofillGroup) {
      placeForm();
      // On Chrome, when a form is focused, it opens an autofill menu
      // immediately.
      // Flutter framework sends `setEditableSizeAndTransform` for informing
      // the engine about the location of the text field. This call will
      // arrive after `show` call.
      // Therefore on Chrome we place the element when
      //  `setEditableSizeAndTransform` method is called and focus on the form
      // only after placing it to the correct position. Hence autofill menu
      // does not appear on top-left of the page.
      // Refocus on the elements after applying the geometry.
      // placeForm() involves DOM manipulation which can trigger synchronous
      // events (like blur). These events might invalidate the current
      // inputConfiguration or disable the strategy before placeForm() returns.
      // Therefore, we must defensively check if the element is still valid/present.
      focusedFormElement?.focusWithoutScroll();
      moveFocusToActiveDomElement();
    }
  }
}

/// A [TextEditingStrategy] for Safari Desktop Browser.
///
/// It places its [domElement] assuming no prior transform or sizing is applied
/// to it.
///
/// In case of an autofill enabled form, it does not append the form element
/// to the DOM, until the geometry information is updated.
///
/// This implementation is used by text editables when semantics is not
/// enabled. With semantics enabled the placement is provided by the semantics
/// tree.
class SafariDesktopTextEditingStrategy extends DefaultTextEditingStrategy {
  SafariDesktopTextEditingStrategy(super.owner);

  /// Appending an element on the DOM for Safari Desktop Browser.
  ///
  /// This method is only called when geometry information is updated by
  /// 'TextInput.setEditableSizeAndTransform' message.
  ///
  /// This method is similar to the [GloballyPositionedTextEditingStrategy].
  /// The only part different: this method does not call `super.placeElement()`,
  /// which in current state calls `domElement.focusWithoutScroll()`.
  ///
  /// Making an extra `focus` request causes flickering in Safari.
  @override
  void placeElement() {
    geometry?.applyToDomElement(activeDomElement);
    if (hasAutofillGroup) {
      placeForm();
      // If domElement is not focused cursor location will not be correct.
      moveFocusToActiveDomElement();
    }
    // Set the last editing state if it exists, this is critical for a
    // users ongoing work to continue uninterrupted when there is an update to
    // the transform.
    lastEditingState?.applyToDomElement(activeDomElement);
  }

  @override
  void initializeElementPlacement() {
    if (geometry != null) {
      placeElement();
    }
    moveFocusToActiveDomElement();
  }
}

/// Class implementing the default editing strategies for text editing.
///
/// This class uses a DOM element to provide text editing capabilities.
///
/// The backing DOM element could be one of:
///
/// 1. `<input>`.
/// 2. `<textarea>`.
/// 3. `<span contenteditable="true">`.
///
/// This class includes all the default behaviour for an editing element as
/// well as the common properties such as [domElement].
///
/// Strategies written for different form factors and browsers should extend
/// this class instead of extending the interface [TextEditingStrategy]. In
/// particular, a concrete implementation is expected to override
/// [placeElement] that places the DOM element accordingly. The default
/// implementation of [placeElement] does not position the element.
///
/// Unless a formfactor/browser requires specific implementation for a specific
/// strategy the methods in this class should be used.
abstract class DefaultTextEditingStrategy
    with CompositionAwareMixin
    implements TextEditingStrategy {
  DefaultTextEditingStrategy(this.owner);

  final HybridTextEditing owner;

  bool isEnabled = false;

  /// The DOM element used for editing, if any.
  DomHTMLElement? domElement;

  /// Same as [domElement] but null-checked.
  ///
  /// This must only be called in places that know for sure that a DOM element
  /// is currently available for editing.
  DomHTMLElement get activeDomElement {
    assert(
      domElement != null,
      'The DOM element of this text editing strategy is not currently active.',
    );
    return domElement!;
  }

  /// The [FlutterView] in which [activeDomElement] is contained.
  EngineFlutterView? get activeDomElementView => _viewForElement(activeDomElement);

  EngineFlutterView? _viewForElement(DomElement element) =>
      EnginePlatformDispatcher.instance.viewManager.findViewForElement(element);

  late InputConfiguration inputConfiguration;
  EditingState? lastEditingState;

  TextEditingDeltaState? _editingDeltaState;
  TextEditingDeltaState get editingDeltaState {
    _editingDeltaState ??= TextEditingDeltaState(oldText: lastEditingState!.text);
    return _editingDeltaState!;
  }

  /// Styles associated with the editable text.
  EditableTextStyle? style;

  /// Size and transform of the editable text on the page.
  EditableTextGeometry? geometry;

  /// The scroll top of the editable text on the page.
  final Map<String, double> _preservedScrollTops = <String, double>{};

  OnChangeCallback? onChange;
  OnActionCallback? onAction;

  final List<DomSubscription> subscriptions = <DomSubscription>[];
  Timer? _pendingBlurConnectionCloseTimer;

  /// Rescans the autofill form for filled values when an autofill session is
  /// blurred (a password-manager dialog is open) and the dialog hands control
  /// back: the window regains focus, or the page becomes visible again. Both
  /// fire when the dialog closes after filling, so the filled values reach the
  /// framework without the user having to refocus the field. The per-field
  /// input/change/animationstart listeners cover fills that do fire an event;
  /// these two events cover fills that arrive while the field is blurred.
  DomSubscription? _autofillScanFocusSub;
  DomSubscription? _autofillScanVisibilitySub;

  void _startAutofillScan() {
    if (!hasAutofillGroup) {
      return;
    }
    // Scan immediately, then again whenever the dialog hands control back.
    inputConfiguration.autofillGroup?.scanForAutofilledValues();

    _autofillScanFocusSub?.cancel();
    _autofillScanFocusSub = DomSubscription(
      domWindow,
      'focus',
      createDomEventListener((DomEvent _) {
        // The window regained focus: the manager's dialog closed, so the fill
        // window ends and placement can resume.
        inputConfiguration.autofillGroup?.endFillWindow();
        inputConfiguration.autofillGroup?.scanForAutofilledValues();
      }),
    );
    _autofillScanVisibilitySub?.cancel();
    _autofillScanVisibilitySub = DomSubscription(
      domDocument,
      'visibilitychange',
      createDomEventListener((DomEvent _) {
        if (_documentVisibilityState == 'visible') {
          inputConfiguration.autofillGroup?.endFillWindow();
          inputConfiguration.autofillGroup?.scanForAutofilledValues();
        }
      }),
    );
  }

  void _stopAutofillScan() {
    _autofillScanFocusSub?.cancel();
    _autofillScanFocusSub = null;
    _autofillScanVisibilitySub?.cancel();
    _autofillScanVisibilitySub = null;
  }

  /// Overrides the result of [domDocument.hasFocus] for testing.
  @visibleForTesting
  bool? debugDocumentHasFocusOverride;

  /// Overrides the result of [domDocument.visibilityState] for testing.
  @visibleForTesting
  String? debugDocumentVisibilityStateOverride;

  bool get _documentHasFocus => debugDocumentHasFocusOverride ?? domDocument.hasFocus();

  String get _documentVisibilityState =>
      debugDocumentVisibilityStateOverride ?? domDocument.visibilityState;

  bool get hasAutofillGroup => inputConfiguration.autofillGroup != null;

  /// Whether the focused input element is part of a form.
  bool get appendedToForm => _appendedToForm;
  bool _appendedToForm = false;

  DomHTMLFormElement? get focusedFormElement => inputConfiguration.autofillGroup?.formElement;

  /// Scrolls the active DOM element into view if running inside an iframe
  /// or in multi-view mode.
  ///
  /// This handles two cases where iOS browsers don't automatically scroll
  /// text fields into view when the keyboard appears:
  /// 1. Flutter embedded in an iframe
  /// 2. Flutter in multi-view mode (embedded as a component)
  ///
  /// See: https://github.com/flutter/flutter/issues/178743
  void scrollIntoViewIfEmbedded() {
    if (isEmbeddedInIframe() || configuration.multiViewEnabled) {
      activeDomElement.scrollIntoView(<String, dynamic>{'block': 'center', 'inline': 'nearest'});
    }
  }

  /// Returns the DOM element to use as the active editing element.
  ///
  /// If a dormant autofill form already holds an element for the field about to
  /// be edited, that element is reused instead of creating a new one. Password
  /// managers and browser autofill hold a reference to the specific input they
  /// detected and rely on it keeping a stable identity and position; creating a
  /// fresh element on every focus (and replacing the dormant one in
  /// [EngineAutofillForm.wakeUp]) makes the login form churn, which breaks
  /// detection in extensions like Bitwarden. Reusing keeps the element -- and
  /// its geometry -- stable across focus changes.
  DomHTMLElement _reuseDormantAutofillElementOrCreate(InputConfiguration inputConfig) {
    final EngineAutofillForm? autofillGroup = inputConfig.autofillGroup;
    final AutofillInfo? autofill = inputConfig.autofill;
    // The focused field is the element tagged tabindex="-1", and in testing it
    // was the one field password managers would not fill. Keeping autofill
    // fields in the tab order (tabindex=0) makes them fillable; non-autofill
    // fields keep -1 so the invisible proxy does not steal keyboard focus.
    final double tabIndex = autofillGroup != null ? 0 : -1;
    final DomHTMLElement freshElement = inputConfig.inputType.createDomElement()
      ..tabIndex = tabIndex;
    if (autofillGroup != null && autofill != null) {
      final EngineAutofillForm? dormant = dormantForms[autofillGroup.formIdentifier];
      final DomHTMLElement? reused = dormant?.elements[autofill.uniqueIdentifier];
      // Only reuse the dormant element when it is the same kind of element (for
      // example not an <input> when the field now needs a <textarea>); reusing a
      // mismatched element would give the field the wrong DOM type.
      if (reused != null && reused.tagName == freshElement.tagName) {
        reused.tabIndex = tabIndex;
        // Pointer events (disabled while it was a non-focused field) are
        // re-enabled for the focused element in wakeUp.
        return reused;
      }
    }
    return freshElement;
  }

  @override
  void initializeTextEditing(
    InputConfiguration inputConfig, {
    required OnChangeCallback onChange,
    required OnActionCallback onAction,
  }) {
    assert(!isEnabled);
    _pendingBlurConnectionCloseTimer?.cancel();
    _pendingBlurConnectionCloseTimer = null;
    _stopAutofillScan();

    // The -1 tab index value makes this element not reachable by keyboard.
    domElement = _reuseDormantAutofillElementOrCreate(inputConfig);
    applyConfiguration(inputConfig);

    _setStaticStyleAttributes(activeDomElement);
    style?.applyToDomElement(activeDomElement);

    if (hasAutofillGroup) {
      // Floor the focused element's size so password managers can detect it too.
      // The editable geometry can be as small as 1px, which is below the size at
      // which Proton Pass/Bitwarden consider an input a real field. min-* only
      // acts as a floor and never shrinks a normally-sized field. Because the
      // focused element is reused as a non-focused field on the next focus
      // change, this also keeps the sibling fields discoverable.
      activeDomElement.style
        ..setProperty('min-width', _kAutofillFieldMinWidth)
        ..setProperty('min-height', _kAutofillFieldMinHeight);
    }

    if (!hasAutofillGroup) {
      // If there is an Autofill Group the `FormElement`, it will be appended to the
      // DOM later, when the first location information arrived.
      // Otherwise, on Blink based Desktop browsers, the autofill menu appears
      // on top left of the screen.
      _insertEditingElementInView(activeDomElement, inputConfig.viewId);
      _appendedToForm = false;
    }

    initializeElementPlacement();

    isEnabled = true;
    this.onChange = onChange;
    this.onAction = onAction;

    if (hasAutofillGroup) {
      _startAutofillScan();
    }
  }

  void applyConfiguration(InputConfiguration config) {
    inputConfiguration = config;

    if (config.readOnly) {
      activeDomElement.setAttribute('readonly', 'readonly');
    } else {
      activeDomElement.removeAttribute('readonly');
    }

    if (config.obscureText) {
      activeDomElement.setAttribute('type', 'password');
    }

    if (config.inputType.inputmodeAttribute == 'none') {
      activeDomElement.setAttribute('inputmode', 'none');
    }

    final EngineInputAction action = EngineInputAction.fromName(config.inputAction);
    action.configureInputAction(activeDomElement);

    final AutofillInfo? autofill = config.autofill;
    if (autofill != null) {
      autofill.applyToDomElement(activeDomElement, focusedElement: true);
    } else {
      activeDomElement.setAttribute('autocomplete', 'off');
      // When the new input configuration contains a different view ID, we need
      // to move the input element to the new view.
      _ensureEditingElementInView(activeDomElement, inputConfiguration.viewId);
    }

    final autocorrectValue = config.autocorrect ? 'on' : 'off';
    activeDomElement.setAttribute('autocorrect', autocorrectValue);
    config.textCapitalization.setAutocapitalizeAttribute(activeDomElement);
  }

  @override
  void initializeElementPlacement() {
    placeElement();
  }

  @override
  void addEventHandlers() {
    // Subscribe to text and selection changes.
    subscriptions.add(
      DomSubscription(activeDomElement, 'input', createDomEventListener(handleChange)),
    );

    subscriptions.add(
      DomSubscription(activeDomElement, 'keydown', createDomEventListener(maybeSendAction)),
    );

    subscriptions.add(
      DomSubscription(domDocument, 'selectionchange', createDomEventListener(handleChange)),
    );

    subscriptions.add(
      DomSubscription(activeDomElement, 'beforeinput', createDomEventListener(handleBeforeInput)),
    );

    if (this is! SafariDesktopTextEditingStrategy) {
      // handleBlur causes Safari to reopen autofill dialogs after autofill,
      // so we don't attach the listener there.
      subscriptions.add(
        DomSubscription(activeDomElement, 'blur', createDomEventListener(handleBlur)),
      );
      // Pairs with handleBlur: a re-focus cancels a pending blur-triggered
      // connection close (e.g. when a browser autofill popup hands focus back).
      subscriptions.add(
        DomSubscription(activeDomElement, 'focus', createDomEventListener(handleFocus)),
      );
    }

    subscriptions.add(
      DomSubscription(activeDomElement, 'copy', createDomEventListener(handleClipboardEvent)),
    );

    subscriptions.add(
      DomSubscription(activeDomElement, 'paste', createDomEventListener(handleClipboardEvent)),
    );

    addCompositionEventHandlers(activeDomElement);

    preventDefaultForMouseEvents();
  }

  @override
  void updateElementPlacement(EditableTextGeometry textGeometry) {
    geometry = textGeometry;
    if (isEnabled) {
      // A password manager is filling the form: hold the field where it is (see
      // EngineAutofillForm.beginFillWindow). Re-applying the transform as the
      // browser scrolls the field under the opening menu churns the DOM under
      // the manager's overlay UI, which can break its fill. The stored geometry
      // is applied by the next placement once the window thaws.
      // (inputConfiguration is a late field, so it is only read once enabled.)
      if (inputConfiguration.autofillGroup?.fillWindowActive ?? false) {
        return;
      }
      // On updates, we shouldn't go through the entire placeElement() flow if
      // we are in the middle of IME composition, otherwise we risk interrupting it.
      // Geometry updates occur when a multiline input expands or contracts. If
      // we are in the middle of composition, we should just update the geometry.
      // See: https://github.com/flutter/flutter/issues/98817
      if (composingText != null) {
        geometry?.applyToDomElement(activeDomElement);
      } else {
        placeElement();
      }
      // The focused element now has its on-screen transform. Move the non-focused
      // autofill proxies next to it so proximity-based password managers see a
      // coherent login form and fill every field, not just the focused one.
      inputConfiguration.autofillGroup?.clusterNonFocusedFieldsAt(activeDomElement);
    }
  }

  @override
  void updateElementStyle(EditableTextStyle textStyle) {
    style = textStyle;
    if (isEnabled) {
      textStyle.applyToDomElement(activeDomElement);
    }
  }

  @override
  void disable() {
    assert(isEnabled);
    _pendingBlurConnectionCloseTimer?.cancel();
    _pendingBlurConnectionCloseTimer = null;
    // Editing has genuinely stopped (a transient password-manager blur keeps the
    // connection open instead of disabling, see handleBlur), so stop polling for
    // autofill. Leaving the periodic scan running here would poll forever and,
    // in tests, leak platform messages into later cases.
    _stopAutofillScan();

    // Preserve the internal scroll position.
    if (geometry != null && lastEditingState != null) {
      final key = '${geometry!.hashCode}_${lastEditingState!.text.hashCode}';
      _preservedScrollTops[key] = activeDomElement.scrollTop;
    }

    isEnabled = false;
    lastEditingState = null;
    _editingDeltaState = null;
    style = null;
    geometry = null;

    for (var i = 0; i < subscriptions.length; i++) {
      subscriptions[i].cancel();
    }
    subscriptions.clear();
    removeCompositionEventHandlers(activeDomElement);

    // If focused element is a part of a form, it needs to stay on the DOM
    // until the autofill context of the form is finalized.
    // More details on `TextInput.finishAutofillContext` call.
    if (_appendedToForm && inputConfiguration.autofillGroup?.formElement != null) {
      _styleAutofillElements(activeDomElement, isOffScreen: true);
      inputConfiguration.autofillGroup?.goDormant();
      EnginePlatformDispatcher.instance.viewManager.safeBlur(activeDomElement);
    } else {
      EnginePlatformDispatcher.instance.viewManager.safeRemove(activeDomElement);
    }
    domElement = null;
  }

  @override
  void setEditingState(EditingState? editingState) {
    lastEditingState = editingState;
    if (!isEnabled || !editingState!.isValid) {
      return;
    }
    lastEditingState!.applyToDomElement(domElement);
    // Record the framework's value so a later autofill rescan does not mistake this
    // programmatic update for a browser autofill and echo it back (which would
    // collapse the cursor to the end). See EngineAutofillForm.noteFrameworkEditingState.
    inputConfiguration.autofillGroup?.noteFrameworkEditingState(
      inputConfiguration.autofill!.uniqueIdentifier,
      lastEditingState!,
    );
  }

  void placeElement() {
    moveFocusToActiveDomElement();
  }

  void placeForm() {
    // Record the framework's current value for the focused field before the form
    // wakes and scans, so the scan does not mistake the framework's own value for
    // a browser autofill and echo it back. (Recording it from setEditingState is
    // too late: the wake-up scan can run first.)
    final EditingState? currentState = lastEditingState;
    if (currentState != null) {
      inputConfiguration.autofillGroup!.noteFrameworkEditingState(
        inputConfiguration.autofill!.uniqueIdentifier,
        currentState,
      );
    }
    inputConfiguration.autofillGroup!.wakeUp(activeDomElement, inputConfiguration.autofill!);
    _appendedToForm = true;
  }

  void handleChange(DomEvent event) {
    assert(isEnabled);

    var newEditingState = EditingState.fromDomElement(activeDomElement);
    newEditingState = suppressInteractiveSelectionIfNeeded(newEditingState);
    newEditingState = determineCompositionState(newEditingState);

    TextEditingDeltaState? newTextEditingDeltaState;
    if (inputConfiguration.enableDeltaModel) {
      editingDeltaState.composingOffset = newEditingState.composingBaseOffset;
      editingDeltaState.composingExtent = newEditingState.composingExtentOffset;
      newTextEditingDeltaState = TextEditingDeltaState.inferDeltaState(
        newEditingState,
        lastEditingState,
        editingDeltaState,
      );
    }

    if (newEditingState != lastEditingState) {
      // Focusing an untouched empty field produces a null -> empty transition
      // that the framework already knows about. Record it but do not forward it,
      // to avoid pushing a redundant editing state on focus.
      final bool isInitialEmpty = lastEditingState == null && newEditingState.text.isEmpty;
      lastEditingState = newEditingState;
      if (!isInitialEmpty) {
        _editingDeltaState = newTextEditingDeltaState;
        onChange!(lastEditingState, _editingDeltaState);
        // The user's own edit was just delivered above; record it so the autofill
        // listeners do not re-forward the same value as a browser autofill.
        inputConfiguration.autofillGroup?.noteFrameworkEditingState(
          inputConfiguration.autofill!.uniqueIdentifier,
          lastEditingState!,
        );
      }
    }
    // Flush delta state.
    _editingDeltaState = null;
  }

  EditingState suppressInteractiveSelectionIfNeeded(EditingState editingState) {
    if (inputConfiguration.enableInteractiveSelection) {
      return editingState;
    }

    if (editingState.baseOffset == editingState.extentOffset) {
      return editingState;
    }

    // If interactive selection is disabled, collapse the selection to the end.
    final EditingState newEditingState = editingState.copyWith(
      baseOffset: editingState.extentOffset,
      extentOffset: editingState.extentOffset,
    );
    newEditingState.applyToDomElement(activeDomElement);
    return newEditingState;
  }

  void handleBeforeInput(DomEvent event) {
    // In some cases the beforeinput event is not fired such as when the selection
    // of a text field is updated. In this case only the oninput event is fired.
    // We still want a delta generated in these cases so we can properly update
    // the selection. We begin to set the deltaStart and deltaEnd in beforeinput
    // because a change in the selection will not have a delta range, it will only
    // have a baseOffset and extentOffset. If these are set inside of inferDeltaState
    // then the method will incorrectly report a deltaStart and deltaEnd for a non
    // text update delta.
    final String? eventData = (event['data'] as JSString?)?.toDart;
    final String? inputType = (event['inputType'] as JSString?)?.toDart;

    if (inputType != null) {
      final bool isSelectionInverted =
          lastEditingState!.baseOffset > lastEditingState!.extentOffset;
      final int deltaOffset = isSelectionInverted
          ? lastEditingState!.baseOffset
          : lastEditingState!.extentOffset;
      if (inputType.contains('delete')) {
        // The deltaStart is set in handleChange because there is where we get access
        // to the new selection baseOffset which is our new deltaStart.
        editingDeltaState.deltaText = '';
        editingDeltaState.deltaEnd = deltaOffset;
      } else if (inputType == 'insertLineBreak') {
        // event.data is null on a line break, so we manually set deltaText as a line break by setting it to '\n'.
        editingDeltaState.deltaText = '\n';
        editingDeltaState.deltaStart = deltaOffset;
        editingDeltaState.deltaEnd = deltaOffset;
      } else if (eventData != null) {
        // When event.data is not null we will begin by considering this delta as an insertion
        // at the selection extentOffset. This may change due to logic in handleChange to handle
        // composition and other IME behaviors.
        editingDeltaState.deltaText = eventData;
        editingDeltaState.deltaStart = deltaOffset;
        editingDeltaState.deltaEnd = deltaOffset;
      }
    }
  }

  void handleBlur(DomEvent event) {
    event as DomFocusEvent;

    final willGainFocusElement = event.relatedTarget as DomElement?;
    if (willGainFocusElement == null) {
      // Focus left to something that is not a DOM element: either the window or
      // iframe that Flutter runs in is losing focus (tab or app switch), or a
      // piece of browser/OS chrome such as an autofill / password-manager
      // dialog took focus while it is open.
      //
      // When an autofill group is active, begin scanning for the values the
      // dialog is about to fill and hold the proxy geometry still for a short
      // window so the DOM does not churn under the dialog's overlay mid-fill;
      // see EngineAutofillForm.beginFillWindow. isEnabled is checked first so
      // `inputConfiguration` (a late field) is only read once the strategy is
      // enabled.
      final bool autofillSession = isEnabled && hasAutofillGroup && textEditing.isEditing;
      if (autofillSession) {
        _startAutofillScan();
        inputConfiguration.autofillGroup?.beginFillWindow();
      }

      if (!_documentHasFocus) {
        // The window/iframe that Flutter runs in is losing focus. Defer the
        // close: when a browser tab is backgrounded the input blur arrives
        // before visibilitychange, and focus may also return immediately. Keep
        // the connection alive on a tab background or a quick refocus, and
        // otherwise close it. This is fixing
        // https://github.com/flutter/flutter/issues/155265.
        _pendingBlurConnectionCloseTimer?.cancel();
        _pendingBlurConnectionCloseTimer = Timer(const Duration(milliseconds: 100), () {
          _pendingBlurConnectionCloseTimer = null;
          if (_documentVisibilityState == 'hidden' || _documentHasFocus) {
            return;
          }
          // A field participating in autofill lost focus while the page moved
          // to the background, for example a mobile OS autofill sheet that
          // takes system focus away from the page while it fills the form and
          // then returns. Keep the connection alive so the value it is about to
          // fill still reaches the framework.
          // https://github.com/flutter/flutter/issues/174773
          if (isEnabled && hasAutofillGroup && textEditing.isEditing) {
            return;
          }
          textEditing.sendTextConnectionClosedToFrameworkIfAny();
        });
        return;
      }

      // The document still has focus, yet the editing element blurred to
      // nowhere. For an autofill session this is a password-manager / browser
      // autofill dialog that steals the element's focus while the page keeps
      // focus -- on mobile that can be several seconds -- and then fills the
      // fields and hands focus back. Closing the connection now would tear down
      // the field listeners and drop the value the dialog is about to fill,
      // which is exactly the "autofill never reaches the Flutter field" bug
      // (https://github.com/flutter/flutter/issues/174773). Keep the connection
      // open: the fill dispatches 'input' events that the still-attached
      // listeners forward to the framework, and the connection is closed
      // normally when the framework unfocuses the field (widget disposed, or
      // focus moved elsewhere in the widget tree).
      if (autofillSession) {
        return;
      }

      // Ordinary field: focus genuinely left the input while the page kept
      // focus (the user clicked an empty area of the page), so close the
      // connection.
      textEditing.sendTextConnectionClosedToFrameworkIfAny();
    } else if (_viewForElement(willGainFocusElement) == activeDomElementView) {
      // If the focus stays within the same FlutterView, ensure the focus stays
      // on the input element.

      // TODO(yjbanov): Make text input less grabby. See: https://github.com/flutter/flutter/issues/166857
      // The motivation/reasoning behind this remains murky.
      // It's unclear why, if the browser wants to remove focus from the input,
      // we must insist that it stays on the element. This could lead to
      // different elements/widgets fighting over who gets the focus, or resist
      // to user's request to move focus elsewhere, which can be super-annoying
      // UX. We should reevaluate what it is we're trying to do here. Perhaps
      // there's a better way.
      //
      // Exception: do not grab focus back when it is moving to another field of
      // the same autofill form. Password managers focus each field of the login
      // form in turn as they fill it; fighting that movement tears the text
      // connection down and recreates it repeatedly, and strict managers (e.g.
      // Bitwarden) detect that churn as page interference and disable autofill.
      // Let the manager walk the fields -- the field listeners still forward the
      // values it fills.
      final DomHTMLFormElement? autofillForm = inputConfiguration.autofillGroup?.formElement;
      final bool movingWithinAutofillForm =
          autofillForm != null && autofillForm.contains(willGainFocusElement);
      if (!movingWithinAutofillForm) {
        moveFocusToActiveDomElement();
      }
    }
  }

  /// Cancels a pending blur-triggered connection close.
  ///
  /// A blur may be transient: browser chrome such as an autofill or
  /// password-manager popup can take focus and then hand it back to the editing
  /// element. When that happens the element fires a `focus` event, which tells
  /// us the blur was not the user leaving the field, so we keep the connection.
  void handleFocus(DomEvent event) {
    _pendingBlurConnectionCloseTimer?.cancel();
    _pendingBlurConnectionCloseTimer = null;
    // A re-focus cancels the pending close above. For an autofill field, also
    // sync the current value and scan: a password manager may fill the field
    // while it is blurred and then hand focus back. Non-autofill fields need
    // nothing here (their edits arrive through input events), and running
    // handleChange for them would push a redundant editing state on every focus.
    // isEnabled is checked first so the late `inputConfiguration` is only read
    // once the strategy is enabled.
    if (isEnabled && hasAutofillGroup) {
      // Focus returned to the field: the manager finished, so end the fill
      // window and let placement resume.
      inputConfiguration.autofillGroup?.endFillWindow();
      handleChange(event);
      inputConfiguration.autofillGroup?.scanForAutofilledValues();
    }
  }

  void handleClipboardEvent(DomEvent event) {
    // Prevent clipboard copy/paste if interactive selection is disabled.
    if (!inputConfiguration.enableInteractiveSelection) {
      event.preventDefault();
    }
  }

  void maybeSendAction(DomEvent e) {
    if (e.isA<DomKeyboardEvent>()) {
      final event = e as DomKeyboardEvent;
      if (event.keyCode == _kReturnKeyCode) {
        onAction!(inputConfiguration.inputAction);
        if (inputConfiguration.inputType is MultilineInputType &&
            inputConfiguration.inputAction == 'TextInputAction.newline') {
          return;
        }
        // Prevent the browser from inserting a new line.
        event.preventDefault();
      }
    }
  }

  /// Enables the element so it can be used to edit text.
  ///
  /// Register [callback] so that it gets invoked whenever any change occurs in
  /// the text editing element.
  ///
  /// Changes could be:
  /// - Text changes, or
  /// - Selection changes.
  void enable(
    InputConfiguration inputConfig, {
    required OnChangeCallback onChange,
    required OnActionCallback onAction,
  }) {
    assert(!isEnabled);

    initializeTextEditing(inputConfig, onChange: onChange, onAction: onAction);

    addEventHandlers();

    if (lastEditingState != null) {
      setEditingState(lastEditingState);
    }

    // Re-focuses after setting editing state.
    moveFocusToActiveDomElement();

    // Restore the internal scroll position.
    if (geometry != null && lastEditingState != null) {
      final key = '${geometry!.hashCode}_${lastEditingState!.text.hashCode}';
      activeDomElement.scrollTop = _preservedScrollTops.remove(key) ?? 0.0;
    }
  }

  /// Prevent default behavior for mouse down, up and move.
  ///
  /// When normal mouse events are not prevented, mouse selection
  /// conflicts with selection sent from the framework, which creates
  /// flickering during selection by mouse.
  ///
  /// On mobile browsers, mouse events are sent after a touch event,
  /// see: https://bugs.chromium.org/p/chromium/issues/detail?id=119216#c11.
  void preventDefaultForMouseEvents() {
    subscriptions.add(
      DomSubscription(
        activeDomElement,
        'mousedown',
        createDomEventListener((DomEvent event) {
          event.preventDefault();
        }),
      ),
    );

    subscriptions.add(
      DomSubscription(
        activeDomElement,
        'mouseup',
        createDomEventListener((DomEvent event) {
          event.preventDefault();
        }),
      ),
    );

    subscriptions.add(
      DomSubscription(
        activeDomElement,
        'mousemove',
        createDomEventListener((DomEvent event) {
          event.preventDefault();
        }),
      ),
    );
  }

  /// Moves the focus to the [activeDomElement].
  void moveFocusToActiveDomElement() {
    activeDomElement.focusWithoutScroll();
  }
}

/// IOS/Safari behaviour for text editing.
///
/// In iOS, the virtual keyboard might shifts the screen up to make input
/// visible depending on the location of the focused input element.
///
/// Due to this [initializeElementPlacement] and [updateElementPlacement]
/// strategies are different.
///
/// [disable] is also different since the [_positionInputElementTimer]
/// also needs to be cleaned.
///
/// inputmodeAttribute needs to be set for mobile devices. Due to this
/// [initializeTextEditing] is different.
class IOSTextEditingStrategy extends GloballyPositionedTextEditingStrategy {
  IOSTextEditingStrategy(super.owner);

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

  /// Whether or not the input element can be positioned at this point in time.
  ///
  /// This is currently only used in iOS. It's set to false before focusing the
  /// input field, and set back to true after a short timer. We do this because
  /// if the input field is positioned before focus, it could be pushed to an
  /// incorrect position by the virtual keyboard.
  ///
  /// See:
  ///
  /// * [_delayBeforePlacement] which controls how long to wait before
  ///   positioning the input field.
  bool _canPosition = true;

  @override
  void initializeTextEditing(
    InputConfiguration inputConfig, {
    required OnChangeCallback onChange,
    required OnActionCallback onAction,
  }) {
    super.initializeTextEditing(inputConfig, onChange: onChange, onAction: onAction);
    inputConfig.inputType.configureInputMode(activeDomElement);
    if (hasAutofillGroup) {
      placeForm();
    }
  }

  @override
  void initializeElementPlacement() {
    /// Position the element outside of the page before focusing on it. This is
    /// useful for not triggering a scroll when iOS virtual keyboard is
    /// coming up.
    activeDomElement.style.transform = 'translate(${offScreenOffset}px, ${offScreenOffset}px)';

    _canPosition = false;
  }

  @override
  void addEventHandlers() {
    // Subscribe to text and selection changes.
    subscriptions.add(
      DomSubscription(activeDomElement, 'input', createDomEventListener(handleChange)),
    );

    subscriptions.add(
      DomSubscription(activeDomElement, 'keydown', createDomEventListener(maybeSendAction)),
    );

    subscriptions.add(
      DomSubscription(domDocument, 'selectionchange', createDomEventListener(handleChange)),
    );

    subscriptions.add(
      DomSubscription(activeDomElement, 'beforeinput', createDomEventListener(handleBeforeInput)),
    );

    subscriptions.add(
      DomSubscription(activeDomElement, 'blur', createDomEventListener(handleBlur)),
    );

    subscriptions.add(
      DomSubscription(activeDomElement, 'copy', createDomEventListener(handleClipboardEvent)),
    );

    subscriptions.add(
      DomSubscription(activeDomElement, 'paste', createDomEventListener(handleClipboardEvent)),
    );

    addCompositionEventHandlers(activeDomElement);

    // Position the DOM element after it is focused.
    subscriptions.add(
      DomSubscription(
        activeDomElement,
        'focus',
        createDomEventListener((DomEvent event) {
          // A re-focus cancels a pending blur-triggered connection close.
          handleFocus(event);
          // Cancel previous timer if exists.
          _schedulePlacement();
        }),
      ),
    );

    _addTapListener();
  }

  @override
  void updateElementPlacement(EditableTextGeometry textGeometry) {
    geometry = textGeometry;
    if (isEnabled && _canPosition) {
      placeElement();
    }
  }

  @override
  void disable() {
    super.disable();
    _positionInputElementTimer?.cancel();
    _positionInputElementTimer = null;
  }

  /// On iOS long press works differently than a single tap.
  ///
  /// On a normal tap the virtual keyboard comes up and users can enter text
  /// using the keyboard.
  ///
  /// The long press on the other hand focuses on the element without bringing
  /// up the virtual keyboard. It allows the users to modify the field by using
  /// copy/cut/select/paste etc.
  ///
  /// After a long press [domElement] is positioned to the correct place. If the
  /// user later single-tap on the [domElement] the virtual keyboard will come
  /// and might shift the page up.
  ///
  /// In order to prevent this shift, on a `click` event the position of the
  /// element is again set somewhere outside of the page and
  /// [_positionInputElementTimer] timer is restarted. The element will be
  /// placed to its correct position after [_delayBeforePlacement].
  void _addTapListener() {
    subscriptions.add(
      DomSubscription(
        activeDomElement,
        'click',
        createDomEventListener((DomEvent _) {
          // Check if the element is already positioned. If not this does not fall
          // under `The user was using the long press, now they want to enter text
          // via keyboard` journey.
          if (_canPosition) {
            // Re-place the element somewhere outside of the screen.
            initializeElementPlacement();

            // Re-configure the timer to place the element.
            _schedulePlacement();
          }
        }),
      ),
    );
  }

  void _schedulePlacement() {
    _positionInputElementTimer?.cancel();
    _positionInputElementTimer = Timer(_delayBeforePlacement, () {
      _canPosition = true;
      placeElement();
    });
  }

  @override
  void placeElement() {
    moveFocusToActiveDomElement();
    geometry?.applyToDomElement(activeDomElement);
    scrollIntoViewIfEmbedded();
  }
}

/// Android behaviour for text editing.
///
/// inputmodeAttribute needs to be set for mobile devices. Due to this
/// [initializeTextEditing] is different.
///
/// Keyboard acts differently than other devices. [addEventHandlers] handles
/// this case as an extra.
class AndroidTextEditingStrategy extends GloballyPositionedTextEditingStrategy {
  AndroidTextEditingStrategy(super.owner);

  @override
  void initializeTextEditing(
    InputConfiguration inputConfig, {
    required OnChangeCallback onChange,
    required OnActionCallback onAction,
  }) {
    super.initializeTextEditing(inputConfig, onChange: onChange, onAction: onAction);
    inputConfig.inputType.configureInputMode(activeDomElement);
    if (hasAutofillGroup) {
      placeForm();
    } else {
      _insertEditingElementInView(activeDomElement, inputConfig.viewId);
    }
  }

  @override
  void addEventHandlers() {
    // Subscribe to text and selection changes.
    subscriptions.add(
      DomSubscription(activeDomElement, 'input', createDomEventListener(handleChange)),
    );

    subscriptions.add(
      DomSubscription(activeDomElement, 'keydown', createDomEventListener(maybeSendAction)),
    );

    subscriptions.add(
      DomSubscription(domDocument, 'selectionchange', createDomEventListener(handleChange)),
    );

    subscriptions.add(
      DomSubscription(activeDomElement, 'beforeinput', createDomEventListener(handleBeforeInput)),
    );

    subscriptions.add(
      DomSubscription(activeDomElement, 'blur', createDomEventListener(handleBlur)),
    );

    // Pairs with handleBlur: a re-focus cancels a pending blur-triggered
    // connection close (e.g. when a browser autofill popup hands focus back).
    subscriptions.add(
      DomSubscription(activeDomElement, 'focus', createDomEventListener(handleFocus)),
    );

    subscriptions.add(
      DomSubscription(activeDomElement, 'copy', createDomEventListener(handleClipboardEvent)),
    );

    subscriptions.add(
      DomSubscription(activeDomElement, 'paste', createDomEventListener(handleClipboardEvent)),
    );

    addCompositionEventHandlers(activeDomElement);

    preventDefaultForMouseEvents();
  }

  @override
  void placeElement() {
    moveFocusToActiveDomElement();
    geometry?.applyToDomElement(activeDomElement);
  }
}

/// Firefox behaviour for text editing.
///
/// Selections are different in Firefox. [addEventHandlers] strategy is
/// impelemented diefferently in Firefox.
class FirefoxTextEditingStrategy extends GloballyPositionedTextEditingStrategy {
  FirefoxTextEditingStrategy(super.owner);

  @override
  void initializeTextEditing(
    InputConfiguration inputConfig, {
    required OnChangeCallback onChange,
    required OnActionCallback onAction,
  }) {
    super.initializeTextEditing(inputConfig, onChange: onChange, onAction: onAction);
    if (hasAutofillGroup) {
      placeForm();
    }
  }

  @override
  void addEventHandlers() {
    // Subscribe to text and selection changes.
    subscriptions.add(
      DomSubscription(activeDomElement, 'input', createDomEventListener(handleChange)),
    );

    subscriptions.add(
      DomSubscription(activeDomElement, 'keydown', createDomEventListener(maybeSendAction)),
    );

    subscriptions.add(
      DomSubscription(activeDomElement, 'beforeinput', createDomEventListener(handleBeforeInput)),
    );

    addCompositionEventHandlers(activeDomElement);

    // Detects changes in text selection.
    //
    // In Firefox, when cursor moves, neither selectionChange nor onInput
    // events are triggered. We are listening to keyup event. Selection start,
    // end values are used to decide if the text cursor moved.
    //
    // Specific keycodes are not checked since users/applications can bind
    // their own keys to move the text cursor.
    // Decides if the selection has changed (cursor moved) compared to the
    // previous values.
    //
    // After each keyup, the start/end values of the selection is compared to
    // the previously saved editing state.
    subscriptions.add(
      DomSubscription(
        activeDomElement,
        'keyup',
        createDomEventListener((DomEvent event) {
          handleChange(event);
        }),
      ),
    );

    // In Firefox the context menu item "Select All" does not work without
    // listening to onSelect. On the other browsers onSelectionChange is
    // enough for covering "Select All" functionality.
    subscriptions.add(
      DomSubscription(activeDomElement, 'select', createDomEventListener(handleChange)),
    );

    subscriptions.add(
      DomSubscription(activeDomElement, 'blur', createDomEventListener(handleBlur)),
    );

    // Pairs with handleBlur: a re-focus cancels a pending blur-triggered
    // connection close (e.g. when a browser autofill popup hands focus back).
    subscriptions.add(
      DomSubscription(activeDomElement, 'focus', createDomEventListener(handleFocus)),
    );

    subscriptions.add(
      DomSubscription(activeDomElement, 'copy', createDomEventListener(handleClipboardEvent)),
    );

    subscriptions.add(
      DomSubscription(activeDomElement, 'paste', createDomEventListener(handleClipboardEvent)),
    );

    preventDefaultForMouseEvents();
  }

  @override
  void placeElement() {
    moveFocusToActiveDomElement();
    geometry?.applyToDomElement(activeDomElement);
    // Set the last editing state if it exists, this is critical for a
    // users ongoing work to continue uninterrupted when there is an update to
    // the transform.
    lastEditingState?.applyToDomElement(activeDomElement);
  }
}

/// Base class for all `TextInput` commands sent through the `flutter/textinput`
/// channel.
@immutable
abstract class TextInputCommand {
  const TextInputCommand();

  /// Executes the logic for this command.
  void run(HybridTextEditing textEditing);
}

/// Responds to the 'TextInput.setClient' message.
class TextInputSetClient extends TextInputCommand {
  const TextInputSetClient({required this.clientId, required this.configuration});

  final int clientId;
  final InputConfiguration configuration;

  @override
  void run(HybridTextEditing textEditing) {
    final bool clientIdChanged = textEditing._clientId != null && textEditing._clientId != clientId;
    if (clientIdChanged && textEditing.isEditing) {
      // We're connecting a new client. Any pending command for the previous client
      // are irrelevant at this point.
      textEditing.stopEditing();
    }
    textEditing._clientId = clientId;
    textEditing.configuration = configuration;
  }
}

/// Creates the text editing strategy used in non-a11y mode.
DefaultTextEditingStrategy createDefaultTextEditingStrategy(HybridTextEditing textEditing) {
  DefaultTextEditingStrategy strategy;

  if (ui_web.browser.operatingSystem == ui_web.OperatingSystem.iOs) {
    strategy = IOSTextEditingStrategy(textEditing);
  } else if (ui_web.browser.operatingSystem == ui_web.OperatingSystem.android) {
    strategy = AndroidTextEditingStrategy(textEditing);
  } else if (ui_web.browser.browserEngine == ui_web.BrowserEngine.webkit) {
    strategy = SafariDesktopTextEditingStrategy(textEditing);
  } else if (ui_web.browser.browserEngine == ui_web.BrowserEngine.firefox) {
    strategy = FirefoxTextEditingStrategy(textEditing);
  } else {
    strategy = GloballyPositionedTextEditingStrategy(textEditing);
  }

  return strategy;
}

/// Responds to the 'TextInput.updateConfig' message.
class TextInputUpdateConfig extends TextInputCommand {
  const TextInputUpdateConfig();

  @override
  void run(HybridTextEditing textEditing) {
    textEditing.strategy.applyConfiguration(textEditing.configuration!);
  }
}

/// Responds to the 'TextInput.setEditingState' message.
class TextInputSetEditingState extends TextInputCommand {
  const TextInputSetEditingState({required this.state});

  final EditingState state;

  @override
  void run(HybridTextEditing textEditing) {
    textEditing.strategy.setEditingState(state);
  }
}

/// Responds to the 'TextInput.show' message.
class TextInputShow extends TextInputCommand {
  const TextInputShow();

  @override
  void run(HybridTextEditing textEditing) {
    if (!textEditing.isEditing) {
      textEditing._startEditing();
    }
  }
}

/// Responds to the 'TextInput.setEditableSizeAndTransform' message.
class TextInputSetEditableSizeAndTransform extends TextInputCommand {
  const TextInputSetEditableSizeAndTransform({required this.geometry});

  final EditableTextGeometry geometry;

  @override
  void run(HybridTextEditing textEditing) {
    textEditing.strategy.updateElementPlacement(geometry);
  }
}

/// Responds to the 'TextInput.setStyle' message.
class TextInputSetStyle extends TextInputCommand {
  const TextInputSetStyle({required this.style});

  final EditableTextStyle style;

  @override
  void run(HybridTextEditing textEditing) {
    textEditing.strategy.updateElementStyle(style);
  }
}

/// Responds to the 'TextInput.clearClient' message.
class TextInputClearClient extends TextInputCommand {
  const TextInputClearClient();

  @override
  void run(HybridTextEditing textEditing) {
    if (textEditing.isEditing) {
      textEditing.stopEditing();
    }
  }
}

/// Responds to the 'TextInput.hide' message.
class TextInputHide extends TextInputCommand {
  const TextInputHide();

  @override
  void run(HybridTextEditing textEditing) {
    if (textEditing.isEditing) {
      textEditing.stopEditing();
    }
  }
}

class TextInputSetMarkedTextRect extends TextInputCommand {
  const TextInputSetMarkedTextRect();

  @override
  void run(HybridTextEditing textEditing) {
    // No-op: this message is currently only used on iOS to implement
    // UITextInput.firstRecForRange.
  }
}

class TextInputSetCaretRect extends TextInputCommand {
  const TextInputSetCaretRect();

  @override
  void run(HybridTextEditing textEditing) {
    // No-op: not supported on this platform.
  }
}

class TextInputRequestAutofill extends TextInputCommand {
  const TextInputRequestAutofill();

  @override
  void run(HybridTextEditing textEditing) {
    // No-op: not supported on this platform.
  }
}

class TextInputFinishAutofillContext extends TextInputCommand {
  const TextInputFinishAutofillContext({required this.saveForm});

  final bool saveForm;

  @override
  void run(HybridTextEditing textEditing) {
    // Close the text editing connection. Form is finalizing.
    textEditing.sendTextConnectionClosedToFrameworkIfAny();
    if (saveForm) {
      saveForms();
    }
    // Clean the forms from DOM after submitting them.
    cleanForms();
  }
}

/// Submits the forms currently attached to the DOM.
///
/// Browser will save the information entered to the form.
///
/// Called when the form is finalized with save option `true`.
/// See: https://github.com/flutter/flutter/blob/bf9f3a3dcfea3022f9cf2dfc3ab10b120b48b19d/packages/flutter/lib/src/services/text_input.dart#L1277
void saveForms() {
  dormantForms.forEach((String identifier, EngineAutofillForm form) {
    final submitBtn = form.formElement!.getElementsByClassName('submitBtn').first as DomElement;
    submitBtn.click();
  });
}

/// Removes the forms from the DOM.
///
/// Called when the form is finalized.
void cleanForms() {
  for (final EngineAutofillForm form in dormantForms.values) {
    form.formElement?.remove();
  }
  dormantForms.clear();
}

/// Translates the message-based communication between the framework and the
/// engine [implementation].
///
/// This class is meant to be used as a singleton.
class TextEditingChannel {
  TextEditingChannel(this.implementation);

  /// Supplies the implementation that responds to the channel messages.
  final HybridTextEditing implementation;

  /// Handles "flutter/textinput" platform messages received from the framework.
  void handleTextInput(ByteData? data, ui.PlatformMessageResponseCallback? callback) {
    const codec = JSONMethodCodec();
    final MethodCall call = codec.decodeMethodCall(data);
    final TextInputCommand command;
    switch (call.method) {
      case 'TextInput.setClient':
        final args = call.arguments! as List<Object?>;
        command = TextInputSetClient(
          clientId: args[0]! as int,
          configuration: InputConfiguration.fromFrameworkMessage(args[1]! as Map<String, Object?>),
        );

      case 'TextInput.updateConfig':
        // Set configuration eagerly because it contains data about the text
        // field used to flush the command queue. However, delay applying the
        // configuration because the strategy may not be available yet.
        implementation.configuration = InputConfiguration.fromFrameworkMessage(
          call.arguments as Map<String, dynamic>,
        );
        command = const TextInputUpdateConfig();

      case 'TextInput.setEditingState':
        command = TextInputSetEditingState(
          state: EditingState.fromFrameworkMessage(call.arguments as Map<String, dynamic>),
        );

      case 'TextInput.show':
        command = const TextInputShow();

      case 'TextInput.setEditableSizeAndTransform':
        command = TextInputSetEditableSizeAndTransform(
          geometry: EditableTextGeometry.fromFrameworkMessage(
            call.arguments as Map<String, dynamic>,
          ),
        );

      case 'TextInput.setStyle':
        command = TextInputSetStyle(
          style: EditableTextStyle.fromFrameworkMessage(call.arguments as Map<String, dynamic>),
        );

      case 'TextInput.clearClient':
        command = const TextInputClearClient();

      case 'TextInput.hide':
        command = const TextInputHide();

      case 'TextInput.requestAutofill':
        // There's no API to request autofill on the web. Instead we let the
        // browser show autofill options automatically, if available. We
        // therefore simply ignore this message.
        command = const TextInputRequestAutofill();

      case 'TextInput.finishAutofillContext':
        command = TextInputFinishAutofillContext(saveForm: call.arguments as bool);

      case 'TextInput.setMarkedTextRect':
        command = const TextInputSetMarkedTextRect();

      case 'TextInput.setCaretRect':
        command = const TextInputSetCaretRect();

      default:
        if (_debugPrintTextInputCommands) {
          print('Received unknown command on flutter/textinput channel: ${call.method}');
        }
        EnginePlatformDispatcher.instance.replyToPlatformMessage(callback, null);
        return;
    }

    implementation.acceptCommand(command, () {
      EnginePlatformDispatcher.instance.replyToPlatformMessage(
        callback,
        codec.encodeSuccessEnvelope(true),
      );
    });
  }

  /// Sends the 'TextInputClient.updateEditingState' message to the framework.
  void updateEditingState(int? clientId, EditingState? editingState) {
    EnginePlatformDispatcher.instance.invokeOnPlatformMessage(
      'flutter/textinput',
      const JSONMethodCodec().encodeMethodCall(
        MethodCall('TextInputClient.updateEditingState', <dynamic>[
          clientId,
          editingState!.toFlutter(),
        ]),
      ),
      _emptyCallback,
    );
  }

  /// Sends the 'TextInputClient.updateEditingStateWithDeltas' message to the framework.
  void updateEditingStateWithDelta(int? clientId, TextEditingDeltaState? editingDeltaState) {
    EnginePlatformDispatcher.instance.invokeOnPlatformMessage(
      'flutter/textinput',
      const JSONMethodCodec().encodeMethodCall(
        MethodCall('TextInputClient.updateEditingStateWithDeltas', <dynamic>[
          clientId,
          editingDeltaState!.toFlutter(),
        ]),
      ),
      _emptyCallback,
    );
  }

  /// Sends the 'TextInputClient.performAction' message to the framework.
  void performAction(int? clientId, String? inputAction) {
    EnginePlatformDispatcher.instance.invokeOnPlatformMessage(
      'flutter/textinput',
      const JSONMethodCodec().encodeMethodCall(
        MethodCall('TextInputClient.performAction', <dynamic>[clientId, inputAction]),
      ),
      _emptyCallback,
    );
  }

  /// Sends the 'TextInputClient.onConnectionClosed' message to the framework.
  void onConnectionClosed(int? clientId) {
    EnginePlatformDispatcher.instance.invokeOnPlatformMessage(
      'flutter/textinput',
      const JSONMethodCodec().encodeMethodCall(
        MethodCall('TextInputClient.onConnectionClosed', <dynamic>[clientId]),
      ),
      _emptyCallback,
    );
  }

  /// Sends the 'TextInputClient.onFocusReceived' message to the framework.
  void onFocusReceived(int? clientId) {
    EnginePlatformDispatcher.instance.invokeOnPlatformMessage(
      'flutter/textinput',
      const JSONMethodCodec().encodeMethodCall(
        MethodCall('TextInputClient.onFocusReceived', <dynamic>[clientId]),
      ),
      (ByteData? data) {
        if (data == null) {
          return;
        }
        final result = const JSONMethodCodec().decodeEnvelope(data) as bool;
        if (!result) {
          printWarning('Text input client did not acquire focus after platform focus received.');
        }
      },
    );
  }
}

/// Text editing singleton.
final HybridTextEditing textEditing = HybridTextEditing();

/// Map for storing forms left attached on the DOM.
///
/// Used for keeping the form elements on the DOM until user confirms to
/// save or cancel them.
///
/// See: https://github.com/flutter/flutter/blob/bf9f3a3dcfea3022f9cf2dfc3ab10b120b48b19d/packages/flutter/lib/src/services/text_input.dart#L1277
final dormantForms = <String, EngineAutofillForm>{};

/// Should be used as a singleton to provide support for text editing in
/// Flutter Web.
///
/// The approach is "hybrid" because it relies on Flutter for
/// displaying, and HTML for user interactions:
///
/// - HTML's contentEditable feature handles typing and text changes.
/// - HTML's selection API handles selection changes and cursor movements.
class HybridTextEditing {
  /// Private constructor so this class can be a singleton.
  ///
  /// The constructor also decides which text editing strategy to use depending
  /// on the operating system and browser engine.
  HybridTextEditing() {
    if (ui_web.browser.operatingSystem == ui_web.OperatingSystem.iOs) {
      // In iOS 26, the text field is blurred right before autofill occurs. We need to keep listening
      // for focus events in order to re-establish the connection with the framework when the text
      // field is focused again for autofill.
      for (final EngineFlutterView view in EnginePlatformDispatcher.instance.views) {
        _addFocusReceivedListenerToView(view.viewId);
      }
      EnginePlatformDispatcher.instance.viewManager.onViewCreated.listen(
        _addFocusReceivedListenerToView,
      );
    }
  }

  late final TextEditingChannel channel = TextEditingChannel(this);

  /// A CSS class name used to identify all elements used for text editing.
  @visibleForTesting
  static const String textEditingClass = 'flt-text-editing';

  int? _clientId;

  /// Flag which shows if there is an ongoing editing.
  ///
  /// Also used to define if a keyboard is needed.
  bool isEditing = false;

  InputConfiguration? configuration;

  DefaultTextEditingStrategy? debugTextEditingStrategyOverride;

  /// Supplies the DOM element used for editing.
  late final DefaultTextEditingStrategy strategy =
      debugTextEditingStrategyOverride ??
      (EngineSemantics.instance.semanticsEnabled
          ? SemanticsTextEditingStrategy.ensureInitialized(this)
          : createDefaultTextEditingStrategy(this));

  void acceptCommand(TextInputCommand command, ui.VoidCallback callback) {
    if (_debugPrintTextInputCommands) {
      print('flutter/textinput channel command: ${command.runtimeType}');
    }
    command.run(this);
    callback();
  }

  void _startEditing() {
    assert(!isEditing);
    isEditing = true;
    strategy.enable(
      configuration!,
      onChange: (EditingState? editingState, TextEditingDeltaState? editingDeltaState) {
        if (configuration!.enableDeltaModel) {
          channel.updateEditingStateWithDelta(_clientId, editingDeltaState);
        } else {
          channel.updateEditingState(_clientId, editingState);
        }
      },
      onAction: (String? inputAction) {
        channel.performAction(_clientId, inputAction);
      },
    );
  }

  void stopEditing() {
    assert(isEditing);
    isEditing = false;
    strategy.disable();
  }

  void sendTextConnectionClosedToFrameworkIfAny() {
    if (isEditing) {
      stopEditing();
      channel.onConnectionClosed(_clientId);
    }
  }

  void _addFocusReceivedListenerToView(int viewId) {
    final EngineFlutterView? view = EnginePlatformDispatcher.instance.viewManager[viewId];
    view!.dom.textEditingHost.addEventListener(
      'focusin',
      createDomEventListener(_handleFocusReceived),
    );
  }

  void _handleFocusReceived(DomEvent event) {
    if (isEditing) {
      return;
    }
    final target = event.target as DomElement?;
    if (target == null) {
      return;
    }
    if (target.classList.contains(HybridTextEditing.textEditingClass)) {
      channel.onFocusReceived(_clientId);
    }
  }
}

/// Information on the font and alignment of a text editing element.
///
/// This information is received via TextInput.setStyle message.
class EditableTextStyle {
  EditableTextStyle({
    required this.textDirection,
    required this.fontSize,
    required this.textAlign,
    required this.fontFamily,
    required this.fontWeight,
    required this.letterSpacing,
    required this.wordSpacing,
    required this.lineHeight,
  });

  factory EditableTextStyle.fromFrameworkMessage(Map<String, dynamic> flutterStyle) {
    assert(flutterStyle.containsKey('fontSize'));
    assert(flutterStyle.containsKey('fontFamily'));
    assert(flutterStyle.containsKey('textAlignIndex'));
    assert(flutterStyle.containsKey('textDirectionIndex'));

    final textAlignIndex = flutterStyle['textAlignIndex'] as int;
    final textDirectionIndex = flutterStyle['textDirectionIndex'] as int;
    final fontWeightIndex = flutterStyle['fontWeightIndex'] as int?;

    // Convert [fontWeightIndex] to its CSS equivalent value.
    final String fontWeight = fontWeightIndex != null
        ? fontWeightIndexToCss(fontWeightIndex: fontWeightIndex)
        : 'normal';

    // Also convert [textAlignIndex] and [textDirectionIndex] to their
    // corresponding enum values in [ui.TextAlign] and [ui.TextDirection]
    // respectively.
    return EditableTextStyle(
      fontSize: flutterStyle.tryDouble('fontSize'),
      fontFamily: flutterStyle.tryString('fontFamily'),
      textAlign: ui.TextAlign.values[textAlignIndex],
      textDirection: ui.TextDirection.values[textDirectionIndex],
      fontWeight: fontWeight,
      letterSpacing: flutterStyle.tryDouble('letterSpacing'),
      wordSpacing: flutterStyle.tryDouble('wordSpacing'),
      lineHeight: flutterStyle.tryDouble('lineHeight'),
    );
  }

  /// This information will be used for changing the style of the hidden input
  /// element, which will match it's size to the size of the editable widget.
  final double? fontSize;
  final String fontWeight;
  final String? fontFamily;
  final ui.TextAlign textAlign;
  final ui.TextDirection textDirection;
  final double? letterSpacing;
  final double? wordSpacing;
  final double? lineHeight;

  String? get align => textAlignToCssValue(textAlign, textDirection);

  String get cssFont => '$fontWeight ${fontSize}px ${canonicalizeFontFamily(fontFamily)}';

  void applyToDomElement(DomHTMLElement domElement) {
    domElement.style
      ..textAlign = align!
      ..font = cssFont
      ..letterSpacing = letterSpacing != null ? '${letterSpacing}px' : ''
      ..wordSpacing = wordSpacing != null ? '${wordSpacing}px' : ''
      ..lineHeight = lineHeight != null ? '${lineHeight}px' : 'normal';
  }
}

/// Describes the location and size of the editing element on the screen.
///
/// This information is received via "TextInput.setEditableSizeAndTransform"
/// message from the framework.
@immutable
class EditableTextGeometry {
  const EditableTextGeometry({
    required this.width,
    required this.height,
    required this.globalTransform,
  });

  /// Parses the geometry from a message sent by the framework.
  factory EditableTextGeometry.fromFrameworkMessage(Map<String, dynamic> encodedGeometry) {
    assert(encodedGeometry.containsKey('width'));
    assert(encodedGeometry.containsKey('height'));
    assert(encodedGeometry.containsKey('transform'));

    final transformList = List<double>.from(
      encodedGeometry.readList('transform').map((dynamic e) => (e as num).toDouble()),
    );
    return EditableTextGeometry(
      width: encodedGeometry.readDouble('width'),
      height: encodedGeometry.readDouble('height'),
      globalTransform: Float32List.fromList(transformList),
    );
  }

  /// The width of the editable in local coordinates, i.e. before applying [globalTransform].
  final double width;

  /// The height of the editable in local coordinates, i.e. before applying [globalTransform].
  final double height;

  /// The aggregate transform rooted at the global (screen) coordinate system
  /// that places and sizes the editable.
  ///
  /// For correct sizing this transform must be applied to the [width] and
  /// [height] fields.
  final Float32List globalTransform;

  /// Applies this geometry to the DOM element.
  ///
  /// This assumes that the parent of the [domElement] has identity transform
  /// applied to it (i.e. the default). If the parent has a non-identity
  /// transform applied, this method will misplace the [domElement]. For
  /// example, if the editable DOM element is nested inside the semantics
  /// tree the semantics tree provides the placement parameters, in which
  /// case this method should not be used.
  void applyToDomElement(DomHTMLElement domElement) {
    final String cssTransform = float64ListToCssTransform(globalTransform);
    domElement.style
      ..width = '${width}px'
      ..height = '${height}px'
      ..transform = cssTransform;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is EditableTextGeometry &&
        other.width == width &&
        other.height == height &&
        listEquals<double>(other.globalTransform, globalTransform);
  }

  @override
  int get hashCode => Object.hash(width, height, Object.hashAll(globalTransform));
}
