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
  SystemContextMenu._({super.key, required this.anchor, this.items, this.onSystemHide})
    : assert(items == null || !_containsDuplicates(items));

  /// Creates an instance of [SystemContextMenu] for the field indicated by the
  /// given [EditableTextState].
  factory SystemContextMenu.editableText({
    Key? key,
    required EditableTextState editableTextState,
    List<IOSSystemContextMenuItem>? items,
  }) {
    final (startGlyphHeight: double startGlyphHeight, endGlyphHeight: double endGlyphHeight) =
        editableTextState.getGlyphHeights();

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
      onSystemHide: editableTextState.hideToolbar,
    );
  }

  /// The [Rect] that the context menu should point to.
  final Rect anchor;

  /// A list of the items to be displayed in the system context menu.
  ///
  /// If none are given, the items will be inferred by the platform based on the
  /// current [TextInputConnection].
  ///
  /// Built-in items will only be shown when relevant. For example, if
  /// [IOSSystemContextMenuItemCopy] is passed, the copy button will only be
  /// shown when there is a non-empty selection and not when the selection is
  /// collapsed. It's not necessary to manually add and remove these items based
  /// on the state of the field.
  final List<IOSSystemContextMenuItem>? items;

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

  /// Returns true only if the given list contains at least one pair of
  /// identical IOSSystemContextMenuItems.
  static bool _containsDuplicates(List<IOSSystemContextMenuItem> items) {
    final Set<IOSSystemContextMenuItem> uniqueItems = <IOSSystemContextMenuItem>{};

    for (final IOSSystemContextMenuItem item in items) {
      if (uniqueItems.contains(item)) {
        return true;
      }
      uniqueItems.add(item);
    }

    return false;
  }

  @override
  State<SystemContextMenu> createState() => _SystemContextMenuState();
}

class _SystemContextMenuState extends State<SystemContextMenu> {
  late final SystemContextMenuController _systemContextMenuController;

  /// Return the IOSSystemContextMenuItemData for the given
  /// IOSSystemContextMenuItem.
  ///
  /// IOSSystemContextMenuItem is a format that is designed to be consumed as
  /// SystemContextMenu.items, where users might want a default localized title
  /// to be set for them.
  ///
  /// IOSSystemContextMenuItemData is a format that is meant to be consumed by
  /// SystemContextMenuController.show, where there is no expectation that
  /// localizations can be used under the hood.
  IOSSystemContextMenuItemData _itemToData(
    IOSSystemContextMenuItem item,
    WidgetsLocalizations localizations,
  ) {
    return switch (item) {
      IOSSystemContextMenuItemCut() => const IOSSystemContextMenuItemDataCut(),
      IOSSystemContextMenuItemCopy() => const IOSSystemContextMenuItemDataCopy(),
      IOSSystemContextMenuItemPaste() => const IOSSystemContextMenuItemDataPaste(),
      IOSSystemContextMenuItemSelectAll() => const IOSSystemContextMenuItemDataSelectAll(),
      IOSSystemContextMenuItemLookUp() => IOSSystemContextMenuItemDataLookUp(
        title: item.title ?? localizations.lookUpButtonLabel,
      ),
      IOSSystemContextMenuItemSearchWeb() => IOSSystemContextMenuItemDataSearchWeb(
        title: item.title ?? localizations.searchWebButtonLabel,
      ),
      IOSSystemContextMenuItemShare() => IOSSystemContextMenuItemDataShare(
        title: item.title ?? localizations.shareButtonLabel,
      ),
      IOSSystemContextMenuItemCustom() => IOSSystemContextMenuItemDataCustom(
        title: item.title!,
        onPressed: item.onPressed!,
      ),
    };
  }

  @override
  void initState() {
    super.initState();
    _systemContextMenuController = SystemContextMenuController(onSystemHide: widget.onSystemHide);
  }

  @override
  void dispose() {
    _systemContextMenuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(SystemContextMenu.isSupported(context));
    final WidgetsLocalizations localizations = WidgetsLocalizations.of(context);
    final Iterable<IOSSystemContextMenuItemData>? datas = widget.items?.map(
      (IOSSystemContextMenuItem item) => _itemToData(item, localizations),
    );
    _systemContextMenuController.show(widget.anchor, datas?.toList());

    return const SizedBox.shrink();
  }
}

/// Describes a context menu button that will be rendered in the system context
/// menu and not by Flutter itself.
///
/// See also:
///
///  * [SystemContextMenu], a widget that can be used to display the system
///    context menu.
///  * [IOSSystemContextMenuItemData], which performs a similar role but at the
///    method channel level and mirrors the requirements of the method channel
///    API.
///  * [ContextMenuButtonItem], which performs a similar role for Flutter-drawn
///    context menus.
@immutable
sealed class IOSSystemContextMenuItem {
  const IOSSystemContextMenuItem();

  /// The text to display to the user.
  ///
  /// Not exposed for some built-in menu items whose title is always set by the
  /// platform.
  String? get title => null;

  /// The callback to be called when the menu item is pressed.
  ///
  /// Not exposed for built-in menu items, which handle their own action when
  /// pressed.
  VoidCallback? get onPressed => null;

  @override
  int get hashCode => Object.hash(title, onPressed);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is IOSSystemContextMenuItem &&
        other.title == title &&
        other.onPressed == onPressed;
  }
}

/// Creates an instance of [IOSSystemContextMenuItem] for the system's built-in
/// cut button.
///
/// Should only appear when there is a selection that can be cut.
///
/// The title and action are both handled by the platform.
///
/// See also:
///
///  * [SystemContextMenu], a widget that can be used to display the system
///    context menu.
///  * [IOSSystemContextMenuItemDataCut], which specifies the data to be sent to
///    the platform for this same button.
class IOSSystemContextMenuItemCut extends IOSSystemContextMenuItem {
  /// Creates an instance of [IOSSystemContextMenuItemCut].
  const IOSSystemContextMenuItemCut();
}

/// Creates an instance of [IOSSystemContextMenuItem] for the system's built-in
/// copy button.
///
/// Should only appear when there is a selection that can be copied.
///
/// The title and action are both handled by the platform.
///
/// See also:
///
///  * [SystemContextMenu], a widget that can be used to display the system
///    context menu.
///  * [IOSSystemContextMenuItemDataCopy], which specifies the data to be sent to
///    the platform for this same button.
class IOSSystemContextMenuItemCopy extends IOSSystemContextMenuItem {
  /// Creates an instance of [IOSSystemContextMenuItemCopy].
  const IOSSystemContextMenuItemCopy();
}

/// Creates an instance of [IOSSystemContextMenuItem] for the system's built-in
/// paste button.
///
/// Should only appear when the field can receive pasted content.
///
/// The title and action are both handled by the platform.
///
/// See also:
///
///  * [SystemContextMenu], a widget that can be used to display the system
///    context menu.
///  * [IOSSystemContextMenuItemDataPaste], which specifies the data to be sent
///     to the platform for this same button.
class IOSSystemContextMenuItemPaste extends IOSSystemContextMenuItem {
  /// Creates an instance of [IOSSystemContextMenuItemPaste].
  const IOSSystemContextMenuItemPaste();
}

/// Creates an instance of [IOSSystemContextMenuItem] for the system's built-in
/// select all button.
///
/// Should only appear when the field can have its selection changed.
///
/// The title and action are both handled by the platform.
///
/// See also:
///
///  * [SystemContextMenu], a widget that can be used to display the system
///    context menu.
///  * [IOSSystemContextMenuItemDataSelectAll], which specifies the data to be
///     sent to the platform for this same button.
class IOSSystemContextMenuItemSelectAll extends IOSSystemContextMenuItem {
  /// Creates an instance of [IOSSystemContextMenuItemSelectAll].
  const IOSSystemContextMenuItemSelectAll();
}

/// Creates an instance of [IOSSystemContextMenuItem] for the
/// system's built-in look up button.
///
/// Should only appear when content is selected.
///
/// The [title] is optional, but it must be specified before being sent to the
/// platform. Typically it should be set to
/// [WidgetsLocalizations.lookUpButtonLabel].
///
/// The action is handled by the platform.
///
/// See also:
///
///  * [SystemContextMenu], a widget that can be used to display the system
///    context menu.
///  * [IOSSystemContextMenuItemDataLookUp], which specifies the data to be sent
///    to the platform for this same button.
class IOSSystemContextMenuItemLookUp extends IOSSystemContextMenuItem {
  /// Creates an instance of [IOSSystemContextMenuItemLookUp].
  const IOSSystemContextMenuItemLookUp({this.title});

  @override
  final String? title;

  @override
  String toString() {
    return 'IOSSystemContextMenuItemLookUp(title: $title)';
  }
}

/// Creates an instance of [IOSSystemContextMenuItem] for the
/// system's built-in search web button.
///
/// Should only appear when content is selected.
///
/// The [title] is optional, but it must be specified before being sent to the
/// platform. Typically it should be set to
/// [WidgetsLocalizations.searchWebButtonLabel].
///
/// The action is handled by the platform.
///
/// See also:
///
///  * [SystemContextMenu], a widget that can be used to display the system
///    context menu.
///  * [IOSSystemContextMenuItemDataSearchWeb], which specifies the data to be
///    sent to the platform for this same button.
class IOSSystemContextMenuItemSearchWeb extends IOSSystemContextMenuItem {
  /// Creates an instance of [IOSSystemContextMenuItemSearchWeb].
  const IOSSystemContextMenuItemSearchWeb({this.title});

  @override
  final String? title;

  @override
  String toString() {
    return 'IOSSystemContextMenuItemSearchWeb(title: $title)';
  }
}

/// Creates an instance of [IOSSystemContextMenuItem] for the
/// system's built-in share button.
///
/// Opens the system share dialog.
///
/// Should only appear when shareable content is selected.
///
/// The [title] is optional, but it must be specified before being sent to the
/// platform. Typically it should be set to
/// [WidgetsLocalizations.shareButtonLabel].
///
/// See also:
///
///  * [SystemContextMenu], a widget that can be used to display the system
///    context menu.
///  * [IOSSystemContextMenuItemDataShare], which specifies the data to be sent
///    to the platform for this same button.
class IOSSystemContextMenuItemShare extends IOSSystemContextMenuItem {
  /// Creates an instance of [IOSSystemContextMenuItemShare].
  const IOSSystemContextMenuItemShare({this.title});

  @override
  final String? title;

  @override
  String toString() {
    return 'IOSSystemContextMenuItemShare(title: $title)';
  }
}

// TODO(justinmc): Support the "custom" type.
// https://github.com/flutter/flutter/issues/103163
/// Creates an instance of [IOSSystemContextMenuItem] for a custom menu item
/// whose [title] and [onPressed] are as specified.
///
/// See also:
///
///  * [SystemContextMenu], a widget that can be used to display the system
///    context menu.
///  * [IOSSystemContextMenuItemDataCustom], which specifies the data to be sent
///    to the platform for this same button.
class IOSSystemContextMenuItemCustom extends IOSSystemContextMenuItem {
  /// Creates an instance of [IOSSystemContextMenuItemCustom].
  const IOSSystemContextMenuItemCustom({
    required String this.title,
    required VoidCallback this.onPressed,
  });

  @override
  final String? title;

  @override
  final VoidCallback? onPressed;

  @override
  String toString() {
    return 'IOSSystemContextMenuItemCustom(title: $title, onPressed: $onPressed)';
  }
}
