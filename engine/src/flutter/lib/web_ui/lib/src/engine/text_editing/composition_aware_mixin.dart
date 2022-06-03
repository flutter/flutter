// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'text_editing.dart';

/// Provides default functionality for listening to HTML composition events.
///
/// A class with this mixin generally calls [determineCompositionState] in order to update
/// an [EditingState] with new composition values; namely, [EditingState.composingBaseOffset]
/// and [EditingState.composingExtentOffset].
///
/// A class with this mixin should call [addCompositionEventHandlers] on initalization, and
/// [removeCompositionEventHandlers] on deinitalization.
///
/// See also:
///
/// * [EditingState], the state of a text field that [CompositionAwareMixin] updates.
/// * [DefaultTextEditingStrategy], the primary implementer of [CompositionAwareMixin].
mixin CompositionAwareMixin {
  /// The name of the HTML composition event type that triggers on starting a composition.
  static const String _kCompositionStart = 'compositionstart';

  /// The name of the browser composition event type that triggers on updating a composition.
  static const String _kCompositionUpdate = 'compositionupdate';

  /// The name of the browser composition event type that triggers on ending a composition.
  static const String _kCompositionEnd = 'compositionend';

  late final html.EventListener _compositionStartListener = _handleCompositionStart;
  late final html.EventListener _compositionUpdateListener = _handleCompositionUpdate;
  late final html.EventListener _compositionEndListener = _handleCompositionEnd;

  /// The currently composing text in the `domElement`.
  ///
  /// Will be null if composing just started, ended, or no composing is being done.
  /// This member is kept up to date provided compositionEventHandlers are in place,
  /// so it is safe to reference it to get the current composingText.
  String? composingText;

  void addCompositionEventHandlers(html.HtmlElement domElement) {
    domElement.addEventListener(_kCompositionStart, _compositionStartListener);
    domElement.addEventListener(_kCompositionUpdate, _compositionUpdateListener);
    domElement.addEventListener(_kCompositionEnd, _compositionEndListener);
  }

  void removeCompositionEventHandlers(html.HtmlElement domElement) {
    domElement.removeEventListener(_kCompositionStart, _compositionStartListener);
    domElement.removeEventListener(_kCompositionUpdate, _compositionUpdateListener);
    domElement.removeEventListener(_kCompositionEnd, _compositionEndListener);
  }

  void _handleCompositionStart(html.Event event) {
    composingText = null;
  }

  void _handleCompositionUpdate(html.Event event) {
    if (event is html.CompositionEvent) {
      composingText = event.data;
    }
  }

  void _handleCompositionEnd(html.Event event) {
    composingText = null;
  }

  EditingState determineCompositionState(EditingState editingState) {
    if (editingState.baseOffset == null || composingText == null || editingState.text == null) {
      return editingState;
    }

    final int composingBase = editingState.baseOffset! - composingText!.length;

    if (composingBase < 0) {
      return editingState;
    }

    return editingState.copyWith(
      composingBaseOffset: composingBase,
      composingExtentOffset: composingBase + composingText!.length,
    );
  }
}
