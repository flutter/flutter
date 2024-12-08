// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'editable_text.dart';
import 'framework.dart';
import 'localizations.dart';
import 'media_query.dart';
import 'text_selection_toolbar_anchors.dart';

/// Displays the system context menu on top of the Flutter view.
///
/// Currently, only supports iOS 16.0 and above and displays nothing on other
/// platforms.
///
/// The context menu is the menu that appears, for example, when doing text
/// selection. Flutter typically draws this menu itself, but this class deals
/// with the platform-rendered context menu instead.
///
/// There can only be one system context menu visible at a time. Building this
/// widget when the system context menu is already visible will hide the old one
/// and display this one. A system context menu that is hidden is informed via
/// [onSystemHide].
///
/// To check if the current device supports showing the system context menu,
/// call [isSupported].
///
/// {@tool dartpad}
/// This example shows how to create a [TextField] that uses the system context
/// menu where supported and does not show a system notification when the user
/// presses the "Paste" button.
///
/// ** See code in examples/api/lib/widgets/system_context_menu/system_context_menu.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [SystemContextMenuController], which directly controls the hiding and
///    showing of the system context menu.
class SystemContextMenu extends StatefulWidget {
  /// Creates an instance of [SystemContextMenu] that points to the given
  /// [anchor].
  const SystemContextMenu._({
    super.key,
    required this.anchor,
    this.items,
    this.onSystemHide,
  });

  /// Creates an instance of [SystemContextMenu] for the field indicated by the
  /// given [EditableTextState].
  factory SystemContextMenu.editableText({
    Key? key,
    required EditableTextState editableTextState,
    List<SystemContextMenuItem>? items,
  }) {
    final (
      startGlyphHeight: double startGlyphHeight,
      endGlyphHeight: double endGlyphHeight,
    ) = editableTextState.getGlyphHeights();
    return SystemContextMenu._(
      key: key,
      anchor: TextSelectionToolbarAnchors.getSelectionRect(
        editableTextState.renderEditable,
        startGlyphHeight,
        endGlyphHeight,
        editableTextState.renderEditable.getEndpointsForSelection(
          editableTextState.textEditingValue.selection,
        ),
      ),
      items: items,
      onSystemHide: () {
        editableTextState.hideToolbar();
      },
    );
  }

  /// The [Rect] that the context menu should point to.
  final Rect anchor;

  final List<SystemContextMenuItem>? items;

  /// Called when the system hides this context menu.
  ///
  /// For example, tapping outside of the context menu typically causes the
  /// system to hide the menu.
  ///
  /// This is not called when showing a new system context menu causes another
  /// to be hidden.
  final VoidCallback? onSystemHide;

  /// Whether the current device supports showing the system context menu.
  ///
  /// Currently, this is only supported on newer versions of iOS.
  static bool isSupported(BuildContext context) {
    return MediaQuery.maybeSupportsShowingSystemContextMenu(context) ?? false;
  }

  @override
  State<SystemContextMenu> createState() => _SystemContextMenuState();
}

class _SystemContextMenuState extends State<SystemContextMenu> {
  bool isFirstBuild = true;
  late final SystemContextMenuController _systemContextMenuController;

  /// Convert the given items to the format required to be sent over
  /// [MethodChannel.invokeMethod].
  static List<Map<String, dynamic>> _itemsToJson(List<SystemContextMenuItem> items, WidgetsLocalizations localizations) {
    // TODO(justinmc): I could cache the result for each item. Is that overoptimization or is the localization lookup expensive enough for it to matter?
    return items
        .map<Map<String, dynamic>>((SystemContextMenuItem item) => _itemToJson(item, localizations))
        .toList();
  }

  /// Convet the given single item to the format required to be sent over
  /// [MethodChannel.invokeMethod].
  static Map<String, dynamic> _itemToJson(SystemContextMenuItem item, WidgetsLocalizations localizations) {
      return <String, dynamic>{
      'type': item.type.name,
      'action': item.action.name,
      // TODO(justinmc): I guess Flutter should always pass a title for the default actions. Encode that into the backend or no?
      // TODO(justinmc): But the engine ignores the title for cut/copy/paste/selectall. See:
      // https://github.com/flutter/engine/pull/56362#issuecomment-2512589800
      'title': item.title ?? _getTitleForAction(item.action, localizations),
      'callbackId': item.hashCode, // TODO(justinmc): Effective?
    };
  }

  // Returns the localized title string for the given SystemContextMenuAction.
  static String _getTitleForAction(SystemContextMenuAction action, WidgetsLocalizations localizations) {
    return switch (action) {
      SystemContextMenuAction.copy => localizations.copyButtonLabel,
      SystemContextMenuAction.cut => localizations.cutButtonLabel,
      SystemContextMenuAction.lookUp => localizations.lookUpButtonLabel,
      SystemContextMenuAction.paste => localizations.pasteButtonLabel,
      SystemContextMenuAction.searchWeb => localizations.searchWebButtonLabel,
      SystemContextMenuAction.selectAll => localizations.selectAllButtonLabel,
      SystemContextMenuAction.share => localizations.shareButtonLabel,
      SystemContextMenuAction.custom => throw AssertionError('Custom type has no title.'),
    };
  }

  SystemContextMenuItemData _itemToData(SystemContextMenuItem item, WidgetsLocalizations localizations) {
    return switch (item.action) {
      SystemContextMenuAction.cut => const SystemContextMenuItemData.cut(),
      SystemContextMenuAction.copy => const SystemContextMenuItemData.copy(),
      SystemContextMenuAction.paste => const SystemContextMenuItemData.paste(),
      SystemContextMenuAction.selectAll => const SystemContextMenuItemData.selectAll(),
      SystemContextMenuAction.lookUp => SystemContextMenuItemData.lookUp(
        title: item.title ?? _getTitleForAction(item.action, localizations),
      ),
      SystemContextMenuAction.share => SystemContextMenuItemData.share(
        title: item.title ?? _getTitleForAction(item.action, localizations),
      ),
      SystemContextMenuAction.searchWeb => SystemContextMenuItemData.searchWeb(
        title: item.title ?? _getTitleForAction(item.action, localizations),
      ),
      SystemContextMenuAction.custom => SystemContextMenuItemData.custom(
        title: item.title!,
        onPressed: item.onPressed!,
      ),
    };
  }

  @override
  void initState() {
    super.initState();
    _systemContextMenuController = SystemContextMenuController(
      onSystemHide: widget.onSystemHide,
    );
  }

  @override
  void didUpdateWidget(SystemContextMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    // TODO(justinmc): Or if items changed.
    if (widget.anchor != oldWidget.anchor) {
      // TODO(justinmc): Deduplicate with the `show` call in the first build below.
      final WidgetsLocalizations localizations = WidgetsLocalizations.of(context);
      final Iterable<SystemContextMenuItemData>? datas =
        widget.items?.map((SystemContextMenuItem item) => _itemToData(item, localizations));
      _systemContextMenuController.show(
        widget.anchor,
        datas?.toList(),
      );
    }
  }

  @override
  void dispose() {
    _systemContextMenuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(SystemContextMenu.isSupported(context));
    if (isFirstBuild) {
      isFirstBuild = false;
      final WidgetsLocalizations localizations = WidgetsLocalizations.of(context);
      final Iterable<SystemContextMenuItemData>? datas =
        widget.items?.map((SystemContextMenuItem item) => _itemToData(item, localizations));
      _systemContextMenuController.show(
        widget.anchor,
        datas?.toList(),
      );
    }

    return const SizedBox.shrink();
  }
}
