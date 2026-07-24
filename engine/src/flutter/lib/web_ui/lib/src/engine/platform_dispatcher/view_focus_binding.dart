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
  /// A native iOS caret/selection drag transiently blurs the focused input to
  /// <body> and WebKit refocuses it a frame later. Deferring the report lets
  /// that refocus cancel it, so the view is not briefly reported unfocused.
  /// See: https://github.com/flutter/flutter/issues/189744
  Timer? _pendingFocusoutTimer;

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
    final bool wasFocusInvoked =
        domDocument.hasFocus() && domDocument.activeElement != domDocument.body;
    if (wasFocusInvoked) {
      return;
    }

    event as DomFocusEvent;
    final willGainFocus = event.relatedTarget as DomElement?;
    final target = event.target as DomElement?;

    // On iOS, a native caret/selection drag transiently blurs Flutter's active
    // text-editing element to <body> (relatedTarget == null) while the document
    // still has focus, and WebKit refocuses it a frame later. Reporting the view
    // unfocused on that blink tears the text connection down and drops the
    // keyboard. Defer only that precise case, re-deriving from the live focus so
    // an immediate refocus is a no-op ([_handleFocusin] cancels the timer).
    // Anything else, a non-editing element, a genuine focus loss, or the page
    // itself losing focus, reports immediately.
    // https://github.com/flutter/flutter/issues/189744
    if (isIosSafari &&
        willGainFocus == null &&
        (debugViewFocusDocumentHasFocusOverride ?? domDocument.hasFocus()) &&
        (target?.classList.contains(HybridTextEditing.textEditingClass) ?? false)) {
      _pendingFocusoutTimer?.cancel();
      _pendingFocusoutTimer = Timer(const Duration(milliseconds: 100), () {
        _pendingFocusoutTimer = null;
        _handleFocusChange(domDocument.activeElement);
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
        direction: _viewFocusDirection,
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
