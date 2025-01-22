// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'editable_text.dart';
import 'localizations.dart';
import 'media_query.dart';

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

  // End SystemContextMenuClient.

  /// Shows the system context menu anchored on the given [Rect].
  ///
  /// Currently only supported on iOS 16.0 and later. Check
  /// [MediaQuery.maybeSupportsShowingSystemContextMenu] before calling this.
  ///
  /// The [Rect] represents what the context menu is pointing to. For example,
  /// for some text selection, this would be the selection [Rect].
  ///
  /// `items` specifies the buttons that appear in the menu. Any `items` that
  /// have no title will be passed a default title from the given
  /// [WidgetsLocalizations]. The buttons that appear in the menu will be
  /// exactly as given and will not automatically udpate based on the state of
  /// the input field. See [SystemContextMenu.getDefaultItems] for the default
  /// items for a given [EditableTextState].
  ///
  /// Currently this system context menu is bound to text input. Using this
  /// without an active [TextInputConnection] will be a noop.
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
    Rect targetRect,
    List<IOSSystemContextMenuItem> items,
    WidgetsLocalizations localizations,
  ) {
    assert(!_isDisposed);
    assert(items.isNotEmpty);

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

    ServicesBinding.systemContextMenuClient = this;

    final List<Map<String, dynamic>> itemsJson =
        items
            .map<Map<String, dynamic>>(
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
      'items': itemsJson,
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
