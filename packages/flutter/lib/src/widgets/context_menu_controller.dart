// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'context_menu_button_item.dart';
import 'editable_text.dart';
import 'framework.dart';
import 'inherited_theme.dart';
import 'navigator.dart';
import 'overlay.dart';

/// Builds a context menu at [primaryAnchor] if possible, otherwise at
/// [secondaryAnchor].
typedef ContextMenuBuilder = Widget Function(
  BuildContext context,
  Offset primaryAnchor,
  [Offset? secondaryAnchor]
);

/// A builder function that builds a context menu given a list of
/// [ContextMenuButtonItem]s representing its children.
///
/// See also:
///
///   * [EditableTextContextMenuButtonItemsBuilder], which receives this as a
///     parameter.
typedef ToolbarButtonWidgetBuilder = Widget Function(
  BuildContext context,
  List<ContextMenuButtonItem> buttonItems,
);

/// A function that builds a widget to use as the text selection toolbar for
/// [EditableText].
///
/// See also:
///
///  * [ContextMenuBuilder], which is the generic type for any context menu
///    builder, not just for the editable text selection toolbar.
typedef EditableTextToolbarBuilder = Widget Function(
  BuildContext,
  EditableTextState,
  Offset,
  [Offset?]
);

/// Builds and manages a context menu at the given location.
class ContextMenuController {
  ContextMenuController._();

  // The OverlayEntry is static because only one context menu can be displayed
  // at one time.
  static OverlayEntry? _menuOverlayEntry;

  /// True iff the menu is currently being displayed.
  static bool get isShown => _menuOverlayEntry != null;

  /// Shows the given context menu at the location.
  static void show({
    required WidgetBuilder contextMenuBuilder,
    required BuildContext context,
    Widget? debugRequiredFor,
  }) {
    hide();
    final OverlayState? overlayState = Overlay.of(
      context,
      rootOverlay: true,
      debugRequiredFor: debugRequiredFor,
    );
    final CapturedThemes capturedThemes = InheritedTheme.capture(
      from: context,
      to: Navigator.maybeOf(context)?.context,
    );

    _menuOverlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return capturedThemes.wrap(contextMenuBuilder(context));
      },
    );
    overlayState!.insert(_menuOverlayEntry!);
  }

  /// Cause the underlying [OverlayEntry] to rebuild during the next pipeline
  /// flush.
  ///
  /// You need to call this function if the output of [contextMenuBuilder] has
  /// changed.
  ///
  /// If the context menu is not currently shown, does nothing.
  ///
  /// See also:
  ///
  ///  * [OverlayEntry.markNeedsBuild]
  static void markNeedsBuild() {
    _menuOverlayEntry?.markNeedsBuild();
  }

  /// Remove the menu.
  static void hide() {
    _menuOverlayEntry?.remove();
    _menuOverlayEntry = null;
  }
}
