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
import 'modal_barrier.dart';
import 'navigator.dart';
import 'overlay.dart';
import 'text_selection.dart';
import 'ticker_provider.dart';

// TODO(justinmc): Rename this file. context_menu.dart? There is already cupertino/context_menu.dart.

// TODO(justinmc): Remove ContextualMenuController et. al.
/// A function that builds a widget to use as a contextual menu.
///
/// See also:
///
///  * [EditableTextToolbarBuilder], which is a specific case of this for
///    building text selection toolbars.
typedef ContextualMenuBuilder = Widget Function(
  BuildContext,
  ContextualMenuController,
  Offset,
  Offset?,
);

// TODO(justinmc): Better docs.
/// Builds a context menu.
typedef ContextMenuBuilder = Widget Function(
  BuildContext,
  Offset,
  [Offset?]
);

// TODO(justinmc): Instead of 2 anchors, take a Rect? Or that's not enough
// info because selection is not always a Rect?
/// A function that builds a widget to use as the text selection toolbar for
/// editable text.
///
/// See also:
///
///  * [ContextualMenuBuilder], which is the generic type for any contextual
///    menu builder, not just for the editable text selection toolbar.
typedef EditableTextToolbarBuilder = Widget Function(
  BuildContext,
  EditableTextState,
  Offset,
  [Offset?]
);

// TODO(justinmc): Is the ephemeral approach with just dipose right? Consumers
// that get passed a controller call dispose on it, then it's done for.
/// Builds and manages a conext menu at the given location.
class ContextMenuController {
  ContextMenuController._();

  // The OverlayEntry is static because only one contextual menu can be
  // displayed at one time.
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

// TODO(justinmc): Put in own file?
/// A contextual menu that can be shown and hidden.
class ContextualMenuController {
  // TODO(justinmc): Update method for efficiency of moving the menu?
  /// Creates an instance of [ContextualMenuController].
  ContextualMenuController({
    // TODO(justinmc): Accept these or just BuildContext?
    required this.buildMenu,
    this.debugRequiredFor,
  });

  /// The function that returns the contextual menu for this part of the widget
  /// tree.
  final ContextualMenuBuilder buildMenu;

  /// Debugging information for explaining why the [Overlay] is required.
  ///
  /// See also:
  ///
  /// * [Overlay.of], which uses this parameter.
  final Widget? debugRequiredFor;

  // The OverlayEntry is static because only one contextual menu can be
  // displayed at one time.
  static OverlayEntry? _menuOverlayEntry;

  /// True iff the contextual menu is currently being displayed.
  bool get isVisible => _menuOverlayEntry != null;

  /// Insert the Widget given by [buildMenu] into the root [Overlay].
  ///
  /// Will first remove the previously shown menu, if one exists.
  void show(BuildContext context, Offset primaryAnchor, [Offset? secondaryAnchor]) {
    hide();
    final OverlayState? overlayState = Overlay.of(
      context,
      rootOverlay: true,
      debugRequiredFor: debugRequiredFor,
    );
    final CapturedThemes capturedThemes = InheritedTheme.capture(
      from: context,
      to: Navigator.of(context).context,
    );

    _menuOverlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return Stack(
          children: <Widget>[
            ModalBarrier(
              onDismiss: hide,
            ),
            capturedThemes.wrap(buildMenu(context, this, primaryAnchor, secondaryAnchor)),
          ],
        );
      },
    );
    overlayState!.insert(_menuOverlayEntry!);
  }

  /// Remove the contextual menu from the [Overlay].
  void hide() {
    _menuOverlayEntry?.remove();
    _menuOverlayEntry = null;
  }
}

// TODO(justinmc): Now that it contains "custom" and isn't all default, rename?
// TODO(justinmc): How does the user create a buttondata when they can't create
// a type?
/// The buttons that can appear in a contextual menu by default.
enum DefaultContextualMenuButtonType {
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
/// The type and callback for the available default contextual menu buttons.
@immutable
class ContextualMenuButtonData {
  /// Creates an instance of [ContextualMenuButtonData].
  const ContextualMenuButtonData({
    required this.onPressed,
    this.type = DefaultContextualMenuButtonType.custom,
    this.label,
  });

  /// The callback to be called when the button is pressed.
  final VoidCallback onPressed;

  /// The type of button this represents.
  final DefaultContextualMenuButtonType type;

  /// The label to display on the button.
  ///
  /// If a [type] other than [DefaultContextualMenuButtonType.custom] is given
  /// and a label is not provided, then the default label for that type for the
  /// platform will be looked up.
  final String? label;

  /// Creates a new [ContextualMenuButtonData] with the provided parameters
  /// overridden.
  ContextualMenuButtonData copyWith({
    VoidCallback? onPressed,
    DefaultContextualMenuButtonType? type,
    String? label,
  }) {
    return ContextualMenuButtonData(
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
    return other is ContextualMenuButtonData
        && other.label == label
        && other.onPressed == onPressed
        && other.type == type;
  }

  @override
  int get hashCode => Object.hash(label, onPressed, type);

  @override
  String toString() => 'ContextualMenuButtonData $type, $label';
}

/// A builder function that builds a contextual menu given a list of
/// [ContextualMenuButtonData]s representing its children.
///
/// See also:
///
///   * [TextSelectionToolbarButtonDatasBuilder], which receives this as a
///     parameter.
typedef ToolbarButtonWidgetBuilder = Widget Function(
  BuildContext context,
  List<ContextualMenuButtonData> buttonDatas,
);


/// Calls [builder] with the [ContextualMenuButtonData]s representing the
/// button in this platform's default text selection menu.
///
/// The platform is determined by [defaultTargetPlatform].
///
/// See also:
///
/// * [TextSelectionToolbarButtonsBuilder], which builds the button Widgets
///   given [ContextualMenuButtonData]s.
/// * [DefaultTextSelectionToolbar], which builds the toolbar itself.
class TextSelectionToolbarButtonDatasBuilder extends StatefulWidget {
  /// Creates an instance of [TextSelectionToolbarButtonDatasBuilder].
  const TextSelectionToolbarButtonDatasBuilder({
    super.key,
    required this.builder,
    required this.editableTextState,
  });

  /// Called with a list of [ContextualMenuButtonData]s so the contextual menu
  /// can be built.
  final ToolbarButtonWidgetBuilder builder;

  /// The EditableTextState for the field that will display the text selection
  /// toolbar.
  final EditableTextState editableTextState;

  /// Returns true if the given [EditableTextState] supports cut.
  static bool canCut(EditableTextState editableTextState) {
    return !editableTextState.widget.readOnly
        && !editableTextState.widget.obscureText
        && !editableTextState.textEditingValue.selection.isCollapsed;
  }

  /// Returns true if the given [EditableTextState] supports copy.
  static bool canCopy(EditableTextState editableTextState) {
    return !editableTextState.widget.obscureText
        && !editableTextState.textEditingValue.selection.isCollapsed;
  }

  /// Returns true if the given [EditableTextState] supports paste.
  static bool canPaste(EditableTextState editableTextState, ClipboardStatus clipboardStatus) {
    return !editableTextState.widget.readOnly
        && clipboardStatus == ClipboardStatus.pasteable;
  }

  /// Returns true if the given [EditableTextState] supports select all.
  static bool canSelectAll(EditableTextState editableTextState) {
    if (!editableTextState.widget.enableInteractiveSelection
        || (editableTextState.widget.readOnly
            && editableTextState.widget.obscureText)) {
      return false;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
        return false;
      case TargetPlatform.iOS:
        return editableTextState.textEditingValue.text.isNotEmpty
            && editableTextState.textEditingValue.selection.isCollapsed;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return editableTextState.textEditingValue.text.isNotEmpty
           && !(editableTextState.textEditingValue.selection.start == 0
               && editableTextState.textEditingValue.selection.end == editableTextState.textEditingValue.text.length);
    }
  }

  // TODO(justinmc): Document.
  static void handleCut(EditableTextState editableTextState) {
    editableTextState.cutSelection(SelectionChangedCause.toolbar);
  }

  static void handleCopy(EditableTextState editableTextState) {
    editableTextState.copySelection(SelectionChangedCause.toolbar);
  }

  static void handlePaste(EditableTextState editableTextState) {
    editableTextState.pasteText(SelectionChangedCause.toolbar);
  }

  // TODO(justinmc): Really though, why isn't this in EditableTextState?
  static void handleSelectAll(EditableTextState editableTextState) {
    editableTextState.selectAll(SelectionChangedCause.toolbar);
    editableTextState.bringIntoView(
      editableTextState.textEditingValue.selection.extent,
    );

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        break;
      case TargetPlatform.macOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        editableTextState.hideToolbar();
    }
  }

  /// Returns the [ContextualMenuButtonData]s for the given [ToolbarOptions].
  @Deprecated(
    'Use `buildContextMenu` instead of `toolbarOptions`. '
    'This feature was deprecated after v2.12.0-4.1.pre.',
  )
  static List<ContextualMenuButtonData>? buttonDatasForToolbarOptions(ToolbarOptions? toolbarOptions, EditableTextState editableTextState) {
    return toolbarOptions == null ? null : <ContextualMenuButtonData>[
      if (toolbarOptions.cut
          && TextSelectionToolbarButtonDatasBuilder.canCut(editableTextState))
        ContextualMenuButtonData(
          onPressed: () {
            TextSelectionToolbarButtonDatasBuilder.handleSelectAll(editableTextState);
          },
          type: DefaultContextualMenuButtonType.selectAll,
        ),
      if (toolbarOptions.copy
          && TextSelectionToolbarButtonDatasBuilder.canCopy(editableTextState))
        ContextualMenuButtonData(
          onPressed: () {
            TextSelectionToolbarButtonDatasBuilder.handleCopy(editableTextState);
          },
          type: DefaultContextualMenuButtonType.copy,
        ),
      if (toolbarOptions.paste && editableTextState.clipboardStatus != null
          && TextSelectionToolbarButtonDatasBuilder.canPaste(editableTextState, editableTextState.clipboardStatus!.value))
        ContextualMenuButtonData(
          onPressed: () {
            TextSelectionToolbarButtonDatasBuilder.handlePaste(editableTextState);
          },
          type: DefaultContextualMenuButtonType.paste,
        ),
      if (toolbarOptions.selectAll
          && TextSelectionToolbarButtonDatasBuilder.canSelectAll(editableTextState))
        ContextualMenuButtonData(
          onPressed: () {
            TextSelectionToolbarButtonDatasBuilder.handleSelectAll(editableTextState);
          },
          type: DefaultContextualMenuButtonType.selectAll,
        ),
    ];
  }

  @override
  State<TextSelectionToolbarButtonDatasBuilder> createState() => _TextSelectionToolbarButtonDatasBuilderState();
}

class _TextSelectionToolbarButtonDatasBuilderState extends State<TextSelectionToolbarButtonDatasBuilder> with TickerProviderStateMixin {
  bool get _cutEnabled => TextSelectionToolbarButtonDatasBuilder.canCut(widget.editableTextState);

  bool get _copyEnabled => TextSelectionToolbarButtonDatasBuilder.canCopy(widget.editableTextState);

  bool get _selectAllEnabled => TextSelectionToolbarButtonDatasBuilder.canSelectAll(widget.editableTextState);

  void _handleCut() {
    return TextSelectionToolbarButtonDatasBuilder.handleCut(widget.editableTextState);
  }

  void _handleCopy() {
    return TextSelectionToolbarButtonDatasBuilder.handleCopy(widget.editableTextState);
  }

  void _handlePaste() {
    return TextSelectionToolbarButtonDatasBuilder.handlePaste(widget.editableTextState);
  }

  void _handleSelectAll() {
    return TextSelectionToolbarButtonDatasBuilder.handleSelectAll(widget.editableTextState);
  }

  @override
  Widget build(BuildContext context) {
    return _ClipboardStatusBuilder(
      clipboardStatusNotifier: widget.editableTextState.clipboardStatus,
      builder: (BuildContext context, ClipboardStatus clipboardStatus) {
        final bool pasteEnabled = TextSelectionToolbarButtonDatasBuilder.canPaste(
          widget.editableTextState,
          clipboardStatus,
        );
        // If there are no buttons to be shown, don't render anything.
        if (!_cutEnabled && !_copyEnabled && !pasteEnabled && !_selectAllEnabled) {
          return const SizedBox.shrink();
        }
        // If the paste button is enabled, don't render anything until the state of
        // the clipboard is known, since it's used to determine if paste is shown.
        if (pasteEnabled && clipboardStatus == ClipboardStatus.unknown) {
          return const SizedBox.shrink();
        }

        // Determine which buttons will appear so that the order and total number is
        // known. A button's position in the menu can slightly affect its
        // appearance.
        final List<ContextualMenuButtonData> buttonDatas = <ContextualMenuButtonData>[
          if (_cutEnabled)
            ContextualMenuButtonData(
              onPressed: _handleCut,
              type: DefaultContextualMenuButtonType.cut,
            ),
          if (_copyEnabled)
            ContextualMenuButtonData(
              onPressed: _handleCopy,
              type: DefaultContextualMenuButtonType.copy,
            ),
          if (pasteEnabled
              && clipboardStatus == ClipboardStatus.pasteable)
            ContextualMenuButtonData(
              onPressed: _handlePaste,
              type: DefaultContextualMenuButtonType.paste,
            ),
          if (_selectAllEnabled)
            ContextualMenuButtonData(
              onPressed: _handleSelectAll,
              type: DefaultContextualMenuButtonType.selectAll,
            ),
        ];

        // If there is no option available, build an empty widget.
        if (buttonDatas.isEmpty) {
          return const SizedBox(width: 0.0, height: 0.0);
        }

        return widget.builder(context, buttonDatas);
      },
    );
  }
}

/// A Widget builder that is passed the [ClipboardStatus].
typedef _ClipboardStatusWidgetBuilder = Widget Function(
  BuildContext context,
  ClipboardStatus clipboardStatus,
);

// TODO(justinmc): Should this be public? Currently it might be a little bit too
/// tied into EditableText's nullable clipboardStatus. Maybe that can be moved?
/// A widget builder wrapper of [ClipboardStatusNotifier].
///
/// Runs the given [builder] with the current [ClipboardStatus]. If the
/// [ClipboardStatus] changes, the builder will be called again.
///
/// If a null [clipboardStatusNotifier] is given, then the [ClipboardStatus]
/// passed to the builder will be [ClipboardStatus.unknown]. No
/// [ClipboardStatusNotifier] will be created internally.
///
/// This widget does not own the [ClipboardStatusNotifier] and will not dispose
/// of it.
class _ClipboardStatusBuilder extends StatefulWidget {
  /// Creates an instance of [_ClipboardStatusBuilder].
  const _ClipboardStatusBuilder({
    required this.builder,
    required this.clipboardStatusNotifier,
  });

  /// Called with the current [ClipboardStatus].
  final _ClipboardStatusWidgetBuilder builder;

  /// Used to determine the [ClipboardStatus] to pass into [builder] and to
  /// listen for changes to decide when to rebuild.
  final ClipboardStatusNotifier? clipboardStatusNotifier;

  @override
  State<_ClipboardStatusBuilder> createState() => _ClipboardStatusBuilderState();
}

class _ClipboardStatusBuilderState extends State<_ClipboardStatusBuilder> with TickerProviderStateMixin {
  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  @override
  void initState() {
    super.initState();
    widget.clipboardStatusNotifier?.addListener(_onChangedClipboardStatus);
  }

  @override
  void didUpdateWidget(_ClipboardStatusBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clipboardStatusNotifier != oldWidget.clipboardStatusNotifier) {
      widget.clipboardStatusNotifier?.addListener(_onChangedClipboardStatus);
      oldWidget.clipboardStatusNotifier?.removeListener(
        _onChangedClipboardStatus,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.clipboardStatusNotifier?.removeListener(_onChangedClipboardStatus);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      widget.clipboardStatusNotifier?.value ?? ClipboardStatus.unknown,
    );
  }
}

// TODO(justinmc): Update docs.
/// Shows and hides the contextual menu based on user gestures.
///
/// By default, shows the menu on right clicks, and on mobile, long presses too.
class ContextMenu extends StatefulWidget {
  /// Creates an instance of [ContextMenu].
  ContextMenu({
    super.key,
    required this.child,
    required this.buildContextMenu,
    bool? longPressEnabled,
    bool? secondaryTapEnabled,
  }) : longPressEnabled = longPressEnabled ?? _longPressEnabled,
       secondaryTapEnabled = secondaryTapEnabled ?? true;

  /// Builds the context menu.
  final ContextMenuBuilder buildContextMenu;

  /// The child widget that will be listened to for gestures.
  final Widget child;

  /// True iff long press gestures show the menu.
  ///
  /// By default, true for mobile platforms only.
  final bool longPressEnabled;

  /// True iff right click gestures show the menu.
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
      // TODO(justinmc): Secondary tapping when the menu is open should fade out
      // and then fade in to show again at the new location on Mac. On Linux, it
      // should hide the menu and not change the selection.
      onSecondaryTapUp: widget.secondaryTapEnabled ? _onSecondaryTapUp : null,
      onTap: _onTap,
      onLongPress: widget.longPressEnabled ? _onLongPress : null,
      onLongPressStart: widget.longPressEnabled ? _onLongPressStart : null,
      child: widget.child,
    );
  }
}
