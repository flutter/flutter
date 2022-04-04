import 'dart:collection' show LinkedHashMap;
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
import 'navigator.dart';
import 'overlay.dart';
import 'text_selection.dart';
import 'ticker_provider.dart';

/// A function that builds a widget to use as a contextual menu.
typedef ContextualMenuBuilder = Widget Function(BuildContext, Offset, Offset?);

// TODO(justinmc): Figure out all the platforms and nested packages.
// Should a CupertinoTextField on Android show the iOS toolbar?? It seems to now
// before this PR.
/*
class ContextualMenuConfiguration extends InheritedWidget {
  const ContextualMenuConfiguration({
    Key? key,
    required this.buildMenu,
    required Widget child,
  }) : super(key: key, child: child);

  final ContextualMenuBuilder buildMenu;

  /// Get the [ContextualMenuConfiguration] that applies to the given
  /// [BuildContext].
  static ContextualMenuConfiguration of(BuildContext context) {
    final ContextualMenuConfiguration? result = context.dependOnInheritedWidgetOfExactType<ContextualMenuConfiguration>();
    assert(result != null, 'No ContextualMenuConfiguration found in context.');
    return result!;
  }

  @override
  bool updateShouldNotify(ContextualMenuConfiguration old) => buildMenu != old.buildMenu;
}
*/

/// Designates a part of the Widget tree to use the contextual menu given by
/// [buildMenu].
class InheritedContextualMenu extends InheritedWidget {
  /// Creates an instance of [InheritedContextualMenu].
  InheritedContextualMenu({
    Key? key,
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

  OverlayEntry? _menuOverlayEntry;

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
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: hide,
          onSecondaryTap: hide,
          // TODO(justinmc): I'm using this to block taps on the menu from being
          // received by the above barrier. Is there a less weird way?
          child: GestureDetector(
            onTap: () {},
            onSecondaryTap: () {},
            child: capturedThemes.wrap(buildMenu(context, primaryAnchor, secondaryAnchor)),
          ),
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
}

/// The type and callback for the available default contextual menu buttons.
@immutable
class ContextualMenuButtonData {
  /// Creates an instance of [ContextualMenuButtonData].
  const ContextualMenuButtonData({
    required this.onPressed,
    required this.type,
  });

  /// The callback to be called when the button is pressed.
  final VoidCallback onPressed;

  /// The type of button this represents.
  final DefaultContextualMenuButtonType type;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ContextualMenuButtonData
        && other.onPressed == onPressed
        && other.type == type;
  }

  @override
  int get hashCode => Object.hash(onPressed, type);
}

/// A builder function that builds a toolbar given the default [buttonDatas].
///
/// See also:
///
///   * [TextSelectionToolbarButtons], which receives this as a parameter.
typedef ToolbarButtonWidgetBuilder = Widget Function(
  BuildContext context,
  LinkedHashMap<DefaultContextualMenuButtonType, ContextualMenuButtonData> buttonDatas,
);

// TODO(justinmc): Move this to its own file once the name is finalized.
// TODO(justinmc): What about the general contextualmenu case?
/// The default buttons for [TextSelectionToolbar].
class TextSelectionToolbarButtons extends StatefulWidget {
  /// Creates an instance of [TextSelectionToolbarButtons].
  const TextSelectionToolbarButtons({
    Key? key,
    required this.builder,
    required this.editableTextState,
  }) : super(key: key);

  /// Called with a list of [ContextualMenuButtonData]s so the contextual menu
  /// can be built.
  final ToolbarButtonWidgetBuilder builder;
  final EditableTextState editableTextState;

  @override
  _TextSelectionToolbarButtonsState createState() => _TextSelectionToolbarButtonsState();
}

class _TextSelectionToolbarButtonsState extends State<TextSelectionToolbarButtons> with TickerProviderStateMixin {
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
  void didUpdateWidget(TextSelectionToolbarButtons oldWidget) {
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
    final LinkedHashMap<DefaultContextualMenuButtonType, ContextualMenuButtonData> buttonDatas =
        LinkedHashMap<DefaultContextualMenuButtonType, ContextualMenuButtonData>.of(
            <DefaultContextualMenuButtonType, ContextualMenuButtonData>{
              if (_cutEnabled)
                DefaultContextualMenuButtonType.cut: ContextualMenuButtonData(
                  onPressed: _handleCut,
                  type: DefaultContextualMenuButtonType.cut,
                ),
              if (_copyEnabled)
                DefaultContextualMenuButtonType.copy: ContextualMenuButtonData(
                  onPressed: _handleCopy,
                  type: DefaultContextualMenuButtonType.copy,
                ),
              if (_pasteEnabled
                  && _clipboardStatus?.value == ClipboardStatus.pasteable)
                DefaultContextualMenuButtonType.paste: ContextualMenuButtonData(
                  onPressed: _handlePaste,
                  type: DefaultContextualMenuButtonType.paste,
                ),
              if (_selectAllEnabled)
                DefaultContextualMenuButtonType.selectAll: ContextualMenuButtonData(
                  onPressed: _handleSelectAll,
                  type: DefaultContextualMenuButtonType.selectAll,
                ),
            });

    // If there is no option available, build an empty widget.
    if (buttonDatas.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    return widget.builder(context, buttonDatas);
  }
}
