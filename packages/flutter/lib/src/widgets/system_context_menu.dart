// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
library;

import 'package:flutter/foundation.dart';
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
/// Pass [items] to specify the buttons that will appear in the menu. Any items
/// without a title will be given a default title from [WidgetsLocalizations].
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
    _systemContextMenuController.show(widget.anchor, widget.items, localizations);

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
///  * [IOSSystemContextMenuItem], which performs a similar role but at the
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

  String get _jsonType;

  String? _getJsonTitle(WidgetsLocalizations? localizations) => null;

  /// Returns json for use in method channel calls, specifically
  /// `ContextMenu.showSystemContextMenu`.
  Map<String, dynamic> _toJson(WidgetsLocalizations? localizations) {
    final String? jsonTitle = title ?? _getJsonTitle(localizations);

    return <String, dynamic>{
      'callbackId': hashCode,
      if (jsonTitle != null) 'title': jsonTitle,
      'type': _jsonType,
    };
  }

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
///  * [IOSSystemContextMenuItemCut], which specifies the data to be sent to
///    the platform for this same button.
class IOSSystemContextMenuItemCut extends IOSSystemContextMenuItem {
  /// Creates an instance of [IOSSystemContextMenuItemCut].
  const IOSSystemContextMenuItemCut();

  @override
  String get _jsonType => 'cut';
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
///  * [IOSSystemContextMenuItemCopy], which specifies the data to be sent to
///    the platform for this same button.
class IOSSystemContextMenuItemCopy extends IOSSystemContextMenuItem {
  /// Creates an instance of [IOSSystemContextMenuItemCopy].
  const IOSSystemContextMenuItemCopy();

  @override
  String get _jsonType => 'copy';
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
///  * [IOSSystemContextMenuItemPaste], which specifies the data to be sent
///     to the platform for this same button.
class IOSSystemContextMenuItemPaste extends IOSSystemContextMenuItem {
  /// Creates an instance of [IOSSystemContextMenuItemPaste].
  const IOSSystemContextMenuItemPaste();

  @override
  String get _jsonType => 'paste';
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
///  * [IOSSystemContextMenuItemSelectAll], which specifies the data to be
///     sent to the platform for this same button.
class IOSSystemContextMenuItemSelectAll extends IOSSystemContextMenuItem {
  /// Creates an instance of [IOSSystemContextMenuItemSelectAll].
  const IOSSystemContextMenuItemSelectAll();

  @override
  String get _jsonType => 'selectAll';
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
///  * [IOSSystemContextMenuItemLookUp], which specifies the data to be sent
///    to the platform for this same button.
class IOSSystemContextMenuItemLookUp extends IOSSystemContextMenuItem {
  /// Creates an instance of [IOSSystemContextMenuItemLookUp].
  const IOSSystemContextMenuItemLookUp({this.title});

  @override
  final String? title;

  @override
  String get _jsonType => 'lookUp';

  @override
  String _getJsonTitle(WidgetsLocalizations? localizations) {
    return localizations!.lookUpButtonLabel;
  }

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
///  * [IOSSystemContextMenuItemSearchWeb], which specifies the data to be
///    sent to the platform for this same button.
class IOSSystemContextMenuItemSearchWeb extends IOSSystemContextMenuItem {
  /// Creates an instance of [IOSSystemContextMenuItemSearchWeb].
  const IOSSystemContextMenuItemSearchWeb({this.title});

  @override
  final String? title;

  @override
  String get _jsonType => 'searchWeb';

  @override
  String _getJsonTitle(WidgetsLocalizations? localizations) {
    return localizations!.searchWebButtonLabel;
  }

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
///  * [IOSSystemContextMenuItemShare], which specifies the data to be sent
///    to the platform for this same button.
class IOSSystemContextMenuItemShare extends IOSSystemContextMenuItem {
  /// Creates an instance of [IOSSystemContextMenuItemShare].
  const IOSSystemContextMenuItemShare({this.title});

  @override
  final String? title;

  @override
  String get _jsonType => 'share';

  @override
  String _getJsonTitle(WidgetsLocalizations? localizations) {
    return localizations!.shareButtonLabel;
  }

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
///  * [IOSSystemContextMenuItemCustom], which specifies the data to be sent
///    to the platform for this same button.
class IOSSystemContextMenuItemCustom extends IOSSystemContextMenuItem {
  /// Creates an instance of [IOSSystemContextMenuItemCustom].
  const IOSSystemContextMenuItemCustom({required String this.title, required this.onPressed});

  @override
  final String? title;

  @override
  final VoidCallback onPressed;

  @override
  String get _jsonType => 'custom';

  @override
  String toString() {
    return 'IOSSystemContextMenuItemCustom(title: $title, onPressed: $onPressed)';
  }
}

// TODO(justinmc): Could this be in its own file?
/// Allows access to the system context menu.
///
/// The context menu is the menu that appears, for example, when doing text
/// selection. Flutter typically draws this menu itself, but this class deals
/// with the platform-rendered context menu.
///
/// Only one instance can be visible at a time. Calling [show] while the system
/// context menu is already visible will hide it and show it again at the new
/// [Rect]. An instance that is hidden is informed via [onSystemHide].
///
/// Currently this system context menu is bound to text input. The buttons that
/// are shown and the actions they perform are dependent on the currently
/// active [TextInputConnection]. Using this without an active
/// [TextInputConnection] is a noop.
///
/// Call [dispose] when no longer needed.
///
/// See also:
///
///  * [ContextMenuController], which controls Flutter-drawn context menus.
///  * [SystemContextMenu], which wraps this functionality in a widget.
///  * [MediaQuery.maybeSupportsShowingSystemContextMenu], which indicates
///    whether the system context menu is supported.
class SystemContextMenuController with SystemContextMenuClient {
  /// Creates an instance of [SystemContextMenuController].
  ///
  /// Not shown until [show] is called.
  SystemContextMenuController({this.onSystemHide}) {
    ServicesBinding.systemContextMenuClient = this;
  }

  /// Called when the system has hidden the context menu.
  ///
  /// For example, tapping outside of the context menu typically causes the
  /// system to hide it directly. Flutter is made aware that the context menu is
  /// no longer visible through this callback.
  ///
  /// This is not called when [show]ing a new system context menu causes another
  /// to be hidden.
  final VoidCallback? onSystemHide;

  static const MethodChannel _channel = SystemChannels.platform;

  static SystemContextMenuController? _lastShown;

  /// The target [Rect] that was last given to [show].
  ///
  /// Null if [show] has not been called.
  Rect? _lastTargetRect;

  /// The [IOSSystemContextMenuItem]s that were last given to [show].
  ///
  /// Null if [show] has not been called.
  List<IOSSystemContextMenuItem>? _lastItems;

  /// True when the instance most recently [show]n has been hidden by the
  /// system.
  bool _hiddenBySystem = false;

  /// Indicates whether the system context menu managed by this controller is
  /// currently being displayed to the user.
  bool get isVisible => this == _lastShown && !_hiddenBySystem;

  /// After calling [dispose], this instance can no longer be used.
  bool _isDisposed = false;

  final Map<int, VoidCallback> _buttonCallbacks = <int, VoidCallback>{};

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

  // Begin SystemContextMenuClient.

  @override
  void handleSystemHide() {
    assert(!_isDisposed);
    assert(isVisible);
    if (_isDisposed || !isVisible) {
      return;
    }
    if (_lastShown == this) {
      _lastShown = null;
    }
    _hiddenBySystem = true;
    onSystemHide?.call();
  }

  @override
  void handleTapCustomActionItem(int callbackId) {
    assert(!_isDisposed);
    assert(isVisible);
    if (_isDisposed || !isVisible) {
      return;
    }
    final VoidCallback? callback = _buttonCallbacks[callbackId];
    if (callback == null) {
      assert(false, 'Tap received for non-existent item with id $callbackId.');
      return;
    }
    callback();
  }

  // End SystemContextMenuClient.

  // TODO(justinmc): The system shouldn't infer items, need to change this and
  // update these docs.
  /// Shows the system context menu anchored on the given [Rect].
  ///
  /// Currently only supported on iOS 16.0 and later. Check
  /// [MediaQuery.maybeSupportsShowingSystemContextMenu] before calling this.
  ///
  /// The [Rect] represents what the context menu is pointing to. For example,
  /// for some text selection, this would be the selection [Rect].
  ///
  /// Optionally, `items` can be provided to specify the menu items. If none are
  /// given, then the platform will infer which menu items should be visible
  /// based on the state of the current [TextInputConnection]. Any `items` that
  /// have no title will be passed a default title from the given
  /// [WidgetsLocalizations].
  ///
  /// Currently this system context menu is bound to text input. Using this
  /// without an active [TextInputConnection] will be a noop, even when
  /// specifying custom `items`.
  ///
  /// Built-in menu items will only be shown when relevant. For example, if
  /// [IOSSystemContextMenuItemCopy] is passed, the copy button will only be
  /// shown when there is something to copy (a non-empty selection). It's not
  /// necessary to manually add and remove these items based on the state of the
  /// field.
  ///
  /// There can only be one system context menu visible at a time. Calling this
  /// while another system context menu is already visible will remove the old
  /// menu before showing the new menu.
  ///
  /// See also:
  ///
  ///  * [hide], which hides the menu shown by this method.
  ///  * [MediaQuery.supportsShowingSystemContextMenu], which indicates whether
  ///    this method is supported on the current platform.
  Future<void> show(
    Rect targetRect, [
    List<IOSSystemContextMenuItem>? items,
    WidgetsLocalizations? localizations,
  ]) {
    assert(!_isDisposed);
    assert(items == null || !_containsDuplicates(items));

    // Don't show the same thing that's already being shown.
    if (_lastShown != null &&
        _lastShown!.isVisible &&
        _lastShown!._lastTargetRect == targetRect &&
        listEquals(_lastShown!._lastItems, items)) {
      return Future<void>.value();
    }

    assert(
      _lastShown == null || _lastShown == this || !_lastShown!.isVisible,
      'Attempted to show while another instance was still visible.',
    );

    _buttonCallbacks.clear();

    if (items != null) {
      for (final IOSSystemContextMenuItem item in items) {
        if (item is IOSSystemContextMenuItemCustom) {
          _buttonCallbacks[item.hashCode] = item.onPressed;
        }
      }
    }

    ServicesBinding.systemContextMenuClient = this;

    final List<Map<String, dynamic>>? itemsJson =
        items
            ?.map<Map<String, dynamic>>(
              (IOSSystemContextMenuItem item) => item._toJson(localizations),
            )
            .toList();
    _lastTargetRect = targetRect;
    _lastItems = items;
    _lastShown = this;
    _hiddenBySystem = false;
    return _channel.invokeMethod('ContextMenu.showSystemContextMenu', <String, dynamic>{
      'targetRect': <String, double>{
        'x': targetRect.left,
        'y': targetRect.top,
        'width': targetRect.width,
        'height': targetRect.height,
      },
      if (items != null) 'items': itemsJson,
    });
  }

  /// Hides this system context menu.
  ///
  /// If this hasn't been shown, or if another instance has hidden this menu,
  /// does nothing.
  ///
  /// Currently this is only supported on iOS 16.0 and later.
  ///
  /// See also:
  ///
  ///  * [show], which shows the menu hidden by this method.
  ///  * [MediaQuery.supportsShowingSystemContextMenu], which indicates whether
  ///    the system context menu is supported on the current platform.
  Future<void> hide() async {
    assert(!_isDisposed);
    // This check prevents the instance from accidentally hiding some other
    // instance, since only one can be visible at a time.
    if (this != _lastShown) {
      return;
    }
    _lastShown = null;
    _buttonCallbacks.clear();
    ServicesBinding.systemContextMenuClient = null;
    // This may be called unnecessarily in the case where the user has already
    // hidden the menu (for example by tapping the screen).
    return _channel.invokeMethod<void>('ContextMenu.hideSystemContextMenu');
  }

  @override
  String toString() {
    return 'SystemContextMenuController(onSystemHide=$onSystemHide, _hiddenBySystem=$_hiddenBySystem, _isVisible=$isVisible, _isDisposed=$_isDisposed)';
  }

  /// Used to release resources when this instance will never be used again.
  void dispose() {
    assert(!_isDisposed);
    hide();
    _isDisposed = true;
  }
}
