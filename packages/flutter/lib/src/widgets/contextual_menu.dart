import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

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

/// A function that builds a widget to use as a contextual menu.
///
/// See also:
///
///  * [TextSelectionToolbarBuilder], which is a specific case of this for
///    building text selection toolbars.
typedef ContextualMenuBuilder = Widget Function(
  BuildContext,
  ContextualMenuController,
  Offset,
  Offset?,
);

/// Designates a part of the Widget tree to use the contextual menu given by
/// [buildMenu].
class InheritedContextualMenu extends InheritedWidget {
  /// Creates an instance of [InheritedContextualMenu].
  InheritedContextualMenu({
    Key? key,
    // TODO(justinmc): Make all names the same (buildMenu vs. buildContextualMenu).
    required ContextualMenuBuilder buildMenu,
    required Widget child,
  }) : assert(buildMenu != null),
       assert(child != null),
       _contextualMenuController = ContextualMenuController(
         buildMenu: buildMenu,
       ),
       super(key: key, child: child);

  final ContextualMenuController _contextualMenuController;

  /// Returns the nearest [ContextualMenuController] for the given
  /// [BuildContext], if any.
  static ContextualMenuController? of(BuildContext context) {
    final InheritedContextualMenu? inheritedContextualMenu =
        context.dependOnInheritedWidgetOfExactType<InheritedContextualMenu>();
    return inheritedContextualMenu?._contextualMenuController;
  }

  @override
  bool updateShouldNotify(InheritedContextualMenu oldWidget) {
    return _contextualMenuController != oldWidget._contextualMenuController;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ContextualMenuBuilder>('buildMenu', _contextualMenuController.buildMenu));
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
/// See also:
///
/// * [TextSelectionToolbarButtonsBuilder], which builds the button Widgets
///   given [ContextualMenuButtonData]s.
/// * [DefaultTextSelectionToolbar], which builds the toolbar itself.
class TextSelectionToolbarButtonDatasBuilder extends StatefulWidget {
  /// Creates an instance of [TextSelectionToolbarButtonDatasBuilder].
  const TextSelectionToolbarButtonDatasBuilder({
    Key? key,
    required this.builder,
    required this.editableTextState,
  }) : super(key: key);

  /// Called with a list of [ContextualMenuButtonData]s so the contextual menu
  /// can be built.
  final ToolbarButtonWidgetBuilder builder;
  final EditableTextState editableTextState;

  @override
  State<TextSelectionToolbarButtonDatasBuilder> createState() => _TextSelectionToolbarButtonDatasBuilderState();
}

class _TextSelectionToolbarButtonDatasBuilderState extends State<TextSelectionToolbarButtonDatasBuilder> with TickerProviderStateMixin {
  ClipboardStatusNotifier? get _clipboardStatus =>
      widget.editableTextState.clipboardStatus;

  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  bool get _cutEnabled {
    return !widget.editableTextState.widget.readOnly
        && !widget.editableTextState.widget.obscureText
        && !widget.editableTextState.textEditingValue.selection.isCollapsed;
  }

  bool get _copyEnabled {
    return !widget.editableTextState.widget.obscureText
        && !widget.editableTextState.textEditingValue.selection.isCollapsed;
  }

  bool get _pasteEnabled {
    return !widget.editableTextState.widget.readOnly;
  }

  bool get _selectAllEnabled {
    if (!widget.editableTextState.widget.enableInteractiveSelection
        || (widget.editableTextState.widget.readOnly
            && widget.editableTextState.widget.obscureText)) {
      return false;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return widget.editableTextState.textEditingValue.text.isNotEmpty
            && widget.editableTextState.textEditingValue.selection.isCollapsed;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return true;
    }
  }

  void _handleCut() {
    widget.editableTextState.cutSelection(SelectionChangedCause.toolbar);
  }

  void _handleCopy() {
    widget.editableTextState.copySelection(SelectionChangedCause.toolbar);
  }

  void _handlePaste() {
    widget.editableTextState.pasteText(SelectionChangedCause.toolbar);
  }

  void _handleSelectAll() {
    widget.editableTextState.selectAll(SelectionChangedCause.toolbar);
    widget.editableTextState.bringIntoView(
      widget.editableTextState.textEditingValue.selection.extent,
    );

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        break;
      case TargetPlatform.macOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        widget.editableTextState.hideToolbar();
    }
  }

  @override
  void initState() {
    super.initState();
    _clipboardStatus?.addListener(_onChangedClipboardStatus);
  }

  @override
  void didUpdateWidget(TextSelectionToolbarButtonDatasBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_clipboardStatus != oldWidget.editableTextState.clipboardStatus) {
      _clipboardStatus?.addListener(_onChangedClipboardStatus);
      oldWidget.editableTextState.clipboardStatus?.removeListener(
        _onChangedClipboardStatus,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    _clipboardStatus?.removeListener(_onChangedClipboardStatus);
  }

  @override
  Widget build(BuildContext context) {
    // If there are no buttons to be shown, don't render anything.
    if (!_cutEnabled && !_copyEnabled && !_pasteEnabled && !_selectAllEnabled) {
      return const SizedBox.shrink();
    }
    // If the paste button is enabled, don't render anything until the state of
    // the clipboard is known, since it's used to determine if paste is shown.
    if (_pasteEnabled && _clipboardStatus?.value == ClipboardStatus.unknown) {
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
      if (_pasteEnabled
          && _clipboardStatus?.value == ClipboardStatus.pasteable)
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
  }
}

/// Shows and hides the contextual menu based on user gestures.
///
/// By default, shows the menu on right clicks, and on mobile, long presses too.
class ContextualMenuGestureDetector extends StatefulWidget {
  /// Creates an instance of [ContextualMenuGestureDetector].
  ContextualMenuGestureDetector({
    required this.child,
    bool? longPressEnabled,
    bool? secondaryTapEnabled,
    Key? key,
  }) : longPressEnabled = longPressEnabled ?? _longPressEnabled,
       secondaryTapEnabled = secondaryTapEnabled ?? true,
       super(key: key);

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
  State<ContextualMenuGestureDetector> createState() => _ContextualMenuGestureDetectorState();
}

class _ContextualMenuGestureDetectorState extends State<ContextualMenuGestureDetector> {
  ContextualMenuController get _contextualMenuController {
    final ContextualMenuController? state = InheritedContextualMenu.of(context);
    assert(state != null, 'No ContextualMenuArea found above in the Widget tree.');
    return state!;
  }

  Offset? _longPressOffset;

  void _onSecondaryTapUp(TapUpDetails details) {
    _contextualMenuController.show(context, details.globalPosition);
  }

  void _onTap() {
    if (!_contextualMenuController.isVisible) {
      return;
    }
    _contextualMenuController.hide();
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
    _contextualMenuController.show(context, position);
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
