// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';

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

  /// How long a blur that landed on nothing is given to turn out to be a focus
  /// change inside the view after all. See [_handleFocusout].
  ///
  /// This waits on a pair of browser events, not on anything a user does. The
  /// browser dispatches the `focusout` and the `focusin` that follows it in
  /// adjacent tasks, about a millisecond apart when something steps between two
  /// fields of a form, and the wait only has to outlast that. The rest is
  /// headroom for a busy main thread: any value between a few milliseconds and
  /// a tenth of a second behaves identically, so the exact number is not
  /// load-bearing. It is deliberately not derived from a frame budget, which
  /// depends on the display and has nothing to do with the task scheduling this
  /// waits on.
  ///
  /// It cannot be zero: a zero timer is queued before the task carrying the
  /// next focus, so it would fire first and defeat the point.
  ///
  /// Nothing waits on a password manager here. If focus never comes back, the
  /// view is reported unfocused this much later than it once was.
  static const Duration _unfocusGracePeriod = Duration(milliseconds: 32);
  Timer? _pendingUnfocus;

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
    _pendingUnfocus?.cancel();
    _pendingUnfocus = null;
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
    // Focus returned before the pending report went out, so the view never lost
    // it. See [_handleFocusout].
    _pendingUnfocus?.cancel();
    _pendingUnfocus = null;
    event as DomFocusEvent;
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
    final DomElement? willGainFocus = event.relatedTarget as DomElement?;

    // A field of an autofill form blurring to nothing is not yet a view losing
    // focus. A password manager fills a login form one field at a time, blurring
    // each as it finishes before focusing the next, and reporting the view
    // unfocused in between makes the framework drop its focus, which tears the
    // text connection down and builds it back up between every field. Managers
    // that give up when the form churns under them then fill only the first
    // field. Wait a moment: a focus landing back in the view cancels the report.
    //
    // Only these fields defer. Anything else losing focus is reported at once,
    // as before.
    if (_isAutofillFormField(event.target as DomElement?)) {
      _pendingUnfocus?.cancel();
      _pendingUnfocus = Timer(_unfocusGracePeriod, () {
        _pendingUnfocus = null;
        _handleFocusChange(willGainFocus);
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
