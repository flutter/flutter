// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// Overrides `domDocument.hasFocus()` in [ViewFocusBinding] for tests, so the
/// iOS caret-drag deferral tests do not depend on the headless browser
/// reporting the test document as focused. Mirrors
/// `DefaultTextEditingStrategy.debugDocumentHasFocusOverride`.
bool? debugViewFocusDocumentHasFocusOverride;

/// Tracks the [FlutterView]s focus changes.
final class ViewFocusBinding {
  ViewFocusBinding(this._viewManager, this._onViewFocusChange);

  final FlutterViewManager _viewManager;
  final ui.ViewFocusChangeCallback _onViewFocusChange;

  int? _lastViewId;
  ui.ViewFocusDirection _viewFocusDirection = ui.ViewFocusDirection.forward;

  StreamSubscription<int>? _onViewCreatedListener;

  /// A deferred report of a `focusout` that named no element to gain focus.
  ///
  /// Two transient blurs look like a view losing focus and are not. A native
  /// iOS caret or selection drag blurs the focused input to <body> and WebKit
  /// refocuses it a frame later. A password manager filling an autofill form
  /// blurs each field to <body> as it finishes with it and focuses the next a
  /// moment later. Deferring the report lets the focus that follows cancel it,
  /// so the view is never reported unfocused in between. See [_handleFocusout].
  /// See also: https://github.com/flutter/flutter/issues/189744
  Timer? _pendingFocusoutTimer;

  /// Whether the document itself still has focus.
  ///
  /// Reads [debugViewFocusDocumentHasFocusOverride] when set, so tests do not
  /// depend on the headless browser reporting the test document as focused.
  /// Mirrors `DefaultTextEditingStrategy._documentHasFocus`.
  bool get _documentHasFocus => debugViewFocusDocumentHasFocusOverride ?? domDocument.hasFocus();

  void init() {
    // We need a global listener here to know if the user was pressing "shift"
    // when the Flutter view receives focus, to move the Flutter focus to the
    // *last* focusable element.
    domDocument.body?.addEventListener(_keyDown, _handleKeyDown);
    domDocument.body?.addEventListener(_keyUp, _handleKeyUp);

    // If so, update `_handleViewCreated` and add a `_handleViewDisposed` to attach
    // and remove the focus/blur listener.
    _onViewCreatedListener = _viewManager.onViewCreated.listen(_handleViewCreated);
  }

  void dispose() {
    domDocument.body?.removeEventListener(_keyDown, _handleKeyDown);
    domDocument.body?.removeEventListener(_keyUp, _handleKeyUp);
    _onViewCreatedListener?.cancel();
    _pendingFocusoutTimer?.cancel();
    _pendingFocusoutTimer = null;
  }

  void changeViewFocus(int viewId, ui.ViewFocusState state) {
    final DomElement? viewElement = _viewManager[viewId]?.dom.rootElement;

    switch (state) {
      case ui.ViewFocusState.focused:
        // Only move the focus to the flutter view if nothing inside it is focused already.
        if (viewId != _viewId(domDocument.activeElement)) {
          viewElement?.focusWithoutScroll();
        }
      case ui.ViewFocusState.unfocused:
        viewElement?.blur();
    }
  }

  late final DomEventListener _handleFocusin = createDomEventListener((DomEvent event) {
    event as DomFocusEvent;
    // Focus returned, so a deferred `focusout` was a transient blur; drop it.
    // See [_handleFocusout].
    _pendingFocusoutTimer?.cancel();
    _pendingFocusoutTimer = null;
    _handleFocusChange(event.target as DomElement?);
  });

  late final DomEventListener _handleFocusout = createDomEventListener((DomEvent event) {
    // During focusout processing, activeElement typically points to <body />.
    // However, if an element is focused during a blur event, activeElement points to that focused element.
    // We leverage this behavior to ignore focusout events where the document has focus but activeElement is not <body />.
    //
    // Refer to https://github.com/flutter/engine/pull/54965 for more info.
    final bool wasFocusInvoked = _documentHasFocus && domDocument.activeElement != domDocument.body;
    if (wasFocusInvoked) {
      return;
    }

    event as DomFocusEvent;
    final willGainFocus = event.relatedTarget as DomElement?;
    final target = event.target as DomElement?;

    // A blur to nothing is not always a view losing focus, and reporting it as
    // one makes the framework drop its focus, which tears the text connection
    // down and builds it back up when focus returns. Two cases wait instead,
    // and a focus landing back in the view cancels the report:
    //
    // - A field of an autofill form. A password manager fills a login form one
    //   field at a time, blurring each as it finishes before focusing the next.
    //   Reporting the view unfocused in between churns the connection between
    //   every field, and managers that give up when the form churns under them
    //   then fill only the first field.
    // - On iOS, Flutter's active text-editing element while the document keeps
    //   focus. A native caret or selection drag blurs it to <body> and WebKit
    //   refocuses it a frame later; reporting the view unfocused on that blink
    //   tears the text connection down and drops the keyboard.
    //   https://github.com/flutter/flutter/issues/189744
    //
    // The wait is [kTransientBlurSettleDelay], the same window the text editing
    // strategy gives the matching `blur`. It only has to outlast the task gap
    // between a `focusout` and the `focusin` that follows it; nothing here waits
    // on a user or on a password manager. If focus never comes back, the view
    // is reported unfocused this much later than it once was. Anything else
    // losing focus, including a blur to a known element outside the view, is
    // reported at once.
    if (willGainFocus == null &&
        (_isAutofillFormField(target) ||
            (isIosSafari && _documentHasFocus && textEditing.isActiveTextEditingElement(target)))) {
      _pendingFocusoutTimer?.cancel();
      _pendingFocusoutTimer = Timer(kTransientBlurSettleDelay, () {
        _pendingFocusoutTimer = null;
        // Re-derive from the live focus so a refocus that fired no `focusin` is
        // still a no-op. Once the document itself has lost focus (a window, tab
        // or app switch, or browser chrome taking it) the active element is
        // stale, it still names the blurred field, and the view is unfocused.
        _handleFocusChange(_documentHasFocus ? domDocument.activeElement : null);
      });
      return;
    }

    _handleFocusChange(willGainFocus);
  });

  late final DomEventListener _handleKeyDown = createDomEventListener((DomEvent event) {
    // The right event type needs to be checked because Chrome seems to be firing
    // `Event` events instead of `KeyboardEvent` events when autofilling is used.
    // See https://github.com/flutter/flutter/issues/149968 for more info.
    if (event.isA<DomKeyboardEvent>() && ((event as DomKeyboardEvent).shiftKey ?? false)) {
      _viewFocusDirection = ui.ViewFocusDirection.backward;
    }
  });

  late final DomEventListener _handleKeyUp = createDomEventListener((DomEvent event) {
    _viewFocusDirection = ui.ViewFocusDirection.forward;
  });

  /// Whether [element] is one of the text fields the engine synthesises for an
  /// autofill group, which are the only elements a password manager moves the
  /// focus between. They are the engine's own inputs, so they always sit in a
  /// `<form>` it created.
  bool _isAutofillFormField(DomElement? element) {
    if (element == null) {
      return false;
    }
    final String tag = element.tagName.toLowerCase();
    if (tag != 'input' && tag != 'textarea') {
      return false;
    }
    return element.closest('form') != null;
  }

  void _handleFocusChange(DomElement? focusedElement) {
    final int? viewId = _viewId(focusedElement);
    if (viewId == _lastViewId) {
      return;
    }

    final ui.ViewFocusEvent event;
    if (viewId == null) {
      event = ui.ViewFocusEvent(
        viewId: _lastViewId!,
        state: ui.ViewFocusState.unfocused,
        direction: ui.ViewFocusDirection.undefined,
      );
    } else {
      event = ui.ViewFocusEvent(
        viewId: viewId,
        state: ui.ViewFocusState.focused,
        direction: _isViewRoot(viewId, focusedElement)
            ? _viewFocusDirection
            : ui.ViewFocusDirection.undefined,
      );
    }
    _updateViewKeyboardReachability(_lastViewId, reachable: true);
    _updateViewKeyboardReachability(viewId, reachable: false);
    _lastViewId = viewId;
    _onViewFocusChange(event);
  }

  int? _viewId(DomElement? element) {
    final FlutterViewManager viewManager = EnginePlatformDispatcher.instance.viewManager;
    return viewManager.findViewForElement(element)?.viewId;
  }

  bool _isViewRoot(int viewId, DomElement? element) {
    final DomElement? rootElement = _viewManager[viewId]?.dom.rootElement;
    return element != null && element == rootElement;
  }

  void _handleViewCreated(int viewId) {
    final DomElement? rootElement = _viewManager[viewId]?.dom.rootElement;

    rootElement?.addEventListener(_focusin, _handleFocusin);
    rootElement?.addEventListener(_focusout, _handleFocusout);

    _updateViewKeyboardReachability(viewId, reachable: true);
  }

  // Controls whether the Flutter view identified by [viewId] is reachable by
  // keyboard.
  void _updateViewKeyboardReachability(int? viewId, {required bool reachable}) {
    if (viewId == null) {
      return;
    }

    final DomElement? rootElement = _viewManager[viewId]?.dom.rootElement;
    // A tabindex with value zero means the DOM element can be reached using the
    // keyboard (tab, shift + tab). When its value is -1 it is still focusable
    // but can't be focused as the result of keyboard events. This is specially
    // important when the semantics tree is enabled as it puts DOM nodes inside
    // the flutter view and having it with a zero tabindex messes the focus
    // traversal order when pressing tab or shift tab.
    rootElement?.setAttribute('tabindex', reachable ? 0 : -1);
  }

  static const String _focusin = 'focusin';
  static const String _focusout = 'focusout';
  static const String _keyDown = 'keydown';
  static const String _keyUp = 'keyup';
}
