// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// Tracks the [FlutterView]s focus changes.
final class ViewFocusBinding {
  /// Creates a [ViewFocusBinding] instance.
  ViewFocusBinding._();

  /// The [ViewFocusBinding] singleton.
  static final ViewFocusBinding instance = ViewFocusBinding._();

  final List<ui.ViewFocusChangeCallback> _listeners = <ui.ViewFocusChangeCallback>[];

  /// Subscribes the [listener] to [ui.ViewFocusEvent] events.
  void addListener(ui.ViewFocusChangeCallback listener) {
    if (_listeners.isEmpty) {
      domDocument.body?.addEventListener(_focusin, _handleFocusin, true);
      domDocument.body?.addEventListener(_focusout, _handleFocusout, true);
    }
    _listeners.add(listener);
  }

  /// Removes the [listener] from the [ui.ViewFocusEvent] events subscription.
  void removeListener(ui.ViewFocusChangeCallback listener) {
    _listeners.remove(listener);
    if (_listeners.isEmpty) {
      domDocument.body?.removeEventListener(_focusin, _handleFocusin, true);
      domDocument.body?.removeEventListener(_focusout, _handleFocusout, true);
    }
  }

  void _notify(ui.ViewFocusEvent event) {
    for (final ui.ViewFocusChangeCallback listener in _listeners) {
      listener(event);
    }
  }

  late final DomEventListener _handleFocusin = createDomEventListener(
    (DomEvent event) => _handleFocusChange(event.target as DomElement?),
  );

  late final DomEventListener _handleFocusout = createDomEventListener(
    (DomEvent event) => _handleFocusChange((event as DomFocusEvent).relatedTarget as DomElement?),
  );

  int? _lastViewId;
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
        direction: ui.ViewFocusDirection.forward,
      );
    }
    _lastViewId = viewId;
    _notify(event);
  }

  static int? _viewId(DomElement? element) {
    final DomElement? viewElement = element?.closest(
      DomManager.flutterViewTagName,
    );
    final String? viewIdAttribute = viewElement?.getAttribute(
      GlobalHtmlAttributes.flutterViewIdAttributeName,
    );
    return viewIdAttribute == null ? null : int.tryParse(viewIdAttribute);
  }

  static const String _focusin = 'focusin';
  static const String _focusout = 'focusout';
}
