// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'basic.dart';
import 'editable_text.dart';
import 'framework.dart';
import 'gesture_detector.dart';
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
/// [ContextMenuButtonData]s representing its children.
///
/// See also:
///
///   * [EditableTextContextMenuButtonDatasBuilder], which receives this as a
///     parameter.
typedef ToolbarButtonWidgetBuilder = Widget Function(
  BuildContext context,
  List<ContextMenuButtonData> buttonDatas,
);

// TODO(justinmc): Instead of 2 anchors, take a Rect? Or that's not enough
// info because selection is not always a Rect?
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

// TODO(justinmc): Put in own file?
/// Builds and manages a context menu at the given location.
class ContextMenuController {
  ContextMenuController._();

  // The OverlayEntry is static because only one context menu can be displayed
  // at one time.
  static OverlayEntry? _menuOverlayEntry;

  /// True iff the menu is currently being displayed.
  static bool get isShown => _menuOverlayEntry != null;

  // TODO(justinmc): Update method for efficiency of moving the menu?
  /// Shows the given context menu at the location.
  static void show({
    required WidgetBuilder buildContextMenu,
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
        return capturedThemes.wrap(buildContextMenu(context));
      },
    );
    overlayState!.insert(_menuOverlayEntry!);
  }

  /// Cause the underlying [OverlayEntry] to rebuild during the next pipeline
  /// flush.
  ///
  /// You need to call this function if the output of [buildContextMenu] has
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

/// The buttons that can appear in a context menu by default.
enum ContextMenuButtonType {
  /// A button that cuts the current text selection.
  cut,

  /// A button that copies the current text selection.
  copy,

  /// A button that pastes the clipboard contents into the focused text field.
  paste,

  /// A button that selects all the contents of the focused text field.
  selectAll,

  /// Anything other than the default button types.
  custom,
}

/// A type that returns the label string for a button.
///
/// [BuildContext] is provided to allow the use of localizations.
typedef LabelGetter = String Function (BuildContext context);

// TODO(justinmc): Make `label` a method that uses the current platform.
/// The type and callback for a context menu button.
@immutable
class ContextMenuButtonData {
  /// Creates an instance of [ContextMenuButtonData].
  const ContextMenuButtonData({
    required this.onPressed,
    this.type = ContextMenuButtonType.custom,
    this.label,
  });

  /// The callback to be called when the button is pressed.
  final VoidCallback onPressed;

  /// The type of button this represents.
  final ContextMenuButtonType type;

  /// The label to display on the button.
  ///
  /// If a [type] other than [ContextMenuButtonType.custom] is given
  /// and a label is not provided, then the default label for that type for the
  /// platform will be looked up.
  final String? label;

  /// Creates a new [ContextMenuButtonData] with the provided parameters
  /// overridden.
  ContextMenuButtonData copyWith({
    VoidCallback? onPressed,
    ContextMenuButtonType? type,
    String? label,
  }) {
    return ContextMenuButtonData(
      onPressed: onPressed ?? this.onPressed,
      type: type ?? this.type,
      label: label ?? this.label,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ContextMenuButtonData
        && other.label == label
        && other.onPressed == onPressed
        && other.type == type;
  }

  @override
  int get hashCode => Object.hash(label, onPressed, type);

  @override
  String toString() => 'ContextMenuButtonData $type, $label';
}

// TODO(justinmc): Update docs.
/// Shows and hides the context menu based on user gestures.
///
/// By default, shows the menu on right clicks, and on mobile, long presses too.
class ContextMenu extends StatefulWidget {
  /// Creates an instance of [ContextMenu].
  ContextMenu({
    super.key,
    required this.child,
    // TODO(justinmc): Rename to contextMenuBuilder.
    required this.buildContextMenu,
    bool? longPressEnabled,
    bool? secondaryTapEnabled,
  }) : longPressEnabled = longPressEnabled ?? _longPressEnabled,
       secondaryTapEnabled = secondaryTapEnabled ?? true;

  /// Builds the context menu.
  final ContextMenuBuilder buildContextMenu;

  /// The child widget that will be listened to for gestures.
  final Widget child;

  /// True if long press gestures show the menu.
  ///
  /// By default, true for mobile platforms only.
  final bool longPressEnabled;

  /// True if right click gestures show the menu.
  ///
  /// True by default.
  final bool secondaryTapEnabled;

  static bool get _longPressEnabled {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      case TargetPlatform.macOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
    }
  }

  @override
  State<ContextMenu> createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> {
  Offset? _longPressOffset;

  void _onSecondaryTapUp(TapUpDetails details) {
    _show(details.globalPosition);
  }

  void _onTap() {
    if (!ContextMenuController.isShown) {
      return;
    }
    _hide();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _longPressOffset = details.globalPosition;
  }

  void _onLongPress() {
    assert(_longPressOffset != null);
    _show(_longPressOffset!);
    _longPressOffset = null;
  }

  void _show(Offset position) {
    ContextMenuController.show(
      context: context,
      buildContextMenu: (BuildContext context) {
        return widget.buildContextMenu(context, position);
      },
    );
  }

  void _hide() {
    ContextMenuController.hide();
  }

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapUp: widget.secondaryTapEnabled ? _onSecondaryTapUp : null,
      onTap: _onTap,
      onLongPress: widget.longPressEnabled ? _onLongPress : null,
      onLongPressStart: widget.longPressEnabled ? _onLongPressStart : null,
      child: widget.child,
    );
  }
}
