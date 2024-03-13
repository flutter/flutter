// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// Tracks the [FlutterView]s focus changes.
final class ViewFocusBinding {
  ViewFocusBinding(this._viewManager, this._onViewFocusChange);

  final FlutterViewManager _viewManager;
  final ui.ViewFocusChangeCallback _onViewFocusChange;

  int? _lastViewId;
  ui.ViewFocusDirection _viewFocusDirection = ui.ViewFocusDirection.forward;

  StreamSubscription<int>? _onViewCreatedListener;

  void init() {
    domDocument.body?.addEventListener(_keyDown, _handleKeyDown);
    domDocument.body?.addEventListener(_keyUp, _handleKeyUp);
    domDocument.body?.addEventListener(_focusin, _handleFocusin);
    domDocument.body?.addEventListener(_focusout, _handleFocusout);
    _onViewCreatedListener = _viewManager.onViewCreated.listen(_handleViewCreated);
  }

  void dispose() {
    domDocument.body?.removeEventListener(_keyDown, _handleKeyDown);
    domDocument.body?.removeEventListener(_keyUp, _handleKeyUp);
    domDocument.body?.removeEventListener(_focusin, _handleFocusin);
    domDocument.body?.removeEventListener(_focusout, _handleFocusout);
    _onViewCreatedListener?.cancel();
  }

  void changeViewFocus(int viewId, ui.ViewFocusState state) {
    final DomElement? viewElement = _viewManager[viewId]?.dom.rootElement;

    if (state == ui.ViewFocusState.focused) {
      // Only move the focus to the flutter view if nothing inside it is focused already.
      if (viewId != _viewId(domDocument.activeElement)) {
        viewElement?.focus();
      }
    } else {
      viewElement?.blur();
    }
  }

  late final DomEventListener _handleFocusin = createDomEventListener((DomEvent event) {
    event as DomFocusEvent;
    _handleFocusChange(event.target as DomElement?);
  });

  late final DomEventListener _handleFocusout = createDomEventListener((DomEvent event) {
    event as DomFocusEvent;
    _handleFocusChange(event.relatedTarget as DomElement?);
  });

  late final DomEventListener _handleKeyDown = createDomEventListener((DomEvent event) {
    event as DomKeyboardEvent;
    if (event.shiftKey) {
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
    _maybeMarkViewAsFocusable(_lastViewId, reachableByKeyboard: true);
    _maybeMarkViewAsFocusable(viewId, reachableByKeyboard: false);
    _lastViewId = viewId;
    _onViewFocusChange(event);
  }

  int? _viewId(DomElement? element) {
    final DomElement? rootElement = element?.closest(DomManager.flutterViewTagName);
    if (rootElement == null) {
      return null;
    }
    return _viewManager.viewIdForRootElement(rootElement);
  }

  void _handleViewCreated(int viewId) {
    _maybeMarkViewAsFocusable(viewId, reachableByKeyboard: true);
  }

  void _maybeMarkViewAsFocusable(
    int? viewId, {
    required bool reachableByKeyboard,
  }) {
    if (viewId == null) {
      return;
    }

    final DomElement? rootElement = _viewManager[viewId]?.dom.rootElement;
    if (EngineSemantics.instance.semanticsEnabled) {
      rootElement?.removeAttribute('tabindex');
    } else {
      // A tabindex with value zero means the DOM element can be reached by using
      // the keyboard (tab, shift + tab). When its value is -1 it is still focusable
      // but can't be focused by the result of keyboard events This is specially
      // important when the semantics tree is enabled as it puts DOM nodes inside
      // the flutter view and having it with a zero tabindex messes the focus
      // traversal order when pressing tab or shift tab.
      rootElement?.setAttribute('tabindex', reachableByKeyboard ? 0 : -1);
    }
  }

  static const String _focusin = 'focusin';
  static const String _focusout = 'focusout';
  static const String _keyDown = 'keydown';
  static const String _keyUp = 'keyup';
}
