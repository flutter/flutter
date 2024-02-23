// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'adaptive_text_selection_toolbar.dart';

// TODO(justinmc): Really this and a Cupertino version? Or is there a way with less API surface?
/// The default context menu for text selection for the current platform, or
/// the system-drawn context menu if available.
///
/// Must be used with an [EditableText], whose [EditableTextState] is passed as
/// a parameter. The system menu depends on the existence of active text input.
/// Flutter-drawn context menus can be created independently from text fields,
/// for example with [AdaptiveTextSelectionToolbar].
class AdaptiveAndSystemTextSelectionToolbar extends StatelessWidget {
  /// Creates an instance of [AdaptiveAndSystemTextSelectionToolbar] for the
  /// given [EditableTextState].
  const AdaptiveAndSystemTextSelectionToolbar.editableText({
    super.key,
    this.buttonItems,
    required this.editableTextState,
  });

  /// The [ContextMenuButtonItem]s that will be turned into buttons in the menu.
  ///
  /// In Flutter-drawn menus, buttonItems are turned into button widgets that
  /// are styled to match the current platform. In system menus, the buttons are
  /// drawn by the system and not by Flutter.
  ///
  /// If null, the default buttons will be used.
  final List<ContextMenuButtonItem>? buttonItems;

  /// Indicates the field whose text selection is operated on by this toolbar.
  ///
  /// This widget is always paired with a text field because the system context
  /// menu must operate on an active text input session. Flutter-drawn context
  /// menus can be created independently from text fields, for example with
  /// [AdaptiveTextSelectionToolbar].
  final EditableTextState editableTextState;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        (MediaQuery.maybeSupportsShowingSystemContextMenu(context) ?? false)) {
      return SystemContextMenu.editableText(
        editableTextState: editableTextState,
      );
    }
    if (buttonItems != null) {
      return AdaptiveTextSelectionToolbar.buttonItems(
        buttonItems: buttonItems,
        anchors: editableTextState.contextMenuAnchors,
      );
    }
    return AdaptiveTextSelectionToolbar.editableText(
      editableTextState: editableTextState,
    );
  }
}
