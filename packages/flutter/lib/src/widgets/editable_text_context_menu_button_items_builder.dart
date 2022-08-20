// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'context_menu_button_item.dart';
import 'context_menu_controller.dart';
import 'editable_text.dart';
import 'framework.dart';
import 'text_selection.dart';
import 'ticker_provider.dart';

/// A Widget builder that is passed the [ClipboardStatus].
typedef _ClipboardStatusWidgetBuilder = Widget Function(
  BuildContext context,
  ClipboardStatus clipboardStatus,
);

/// Calls [builder] with the [ContextMenuButtonItem]s representing the
/// buttons in this platform's default text selection menu.
///
/// By default the [targetPlatform] will be [defaultTargetPlatform].
///
/// See also:
///
/// * [TextSelectionToolbarButtonsBuilder], which builds the button Widgets
///   given [ContextMenuButtonItem]s.
/// * [AdaptiveTextSelectionToolbar], which builds the toolbar itself.
/// * [SelectableRegionContextMenuButtonItemsBuilder], which is like this widget
///   but for a [SelectableRegion] instead of an [EditableText].
class EditableTextContextMenuButtonItemsBuilder extends StatefulWidget {
  /// Creates an instance of [EditableTextContextMenuButtonItemsBuilder].
  const EditableTextContextMenuButtonItemsBuilder({
    super.key,
    TargetPlatform? targetPlatform,
    required this.builder,
    required this.editableTextState,
  }) : _targetPlatform = targetPlatform;

  /// Called with a list of [ContextMenuButtonItem]s so the context menu can be
  /// built.
  final ToolbarButtonWidgetBuilder builder;

  /// The EditableTextState for the field that will display the text selection
  /// toolbar.
  final EditableTextState editableTextState;

  final TargetPlatform? _targetPlatform;

  /// The platform to base the button items on.
  TargetPlatform get targetPlatform => _targetPlatform ?? defaultTargetPlatform;

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
  static bool canPaste(EditableTextState editableTextState) {
    return !editableTextState.widget.readOnly
        && (editableTextState.clipboardStatus == null
          || editableTextState.clipboardStatus!.value == ClipboardStatus.pasteable);
  }

  /// Returns true if the given [EditableTextState] supports select all.
  ///
  /// If [targetPlatform] is not provided, [defaultTargetPlatform] will be used.
  static bool canSelectAll(EditableTextState editableTextState, [TargetPlatform? targetPlatform]) {
    if (!editableTextState.widget.enableInteractiveSelection
        || (editableTextState.widget.readOnly
            && editableTextState.widget.obscureText)) {
      return false;
    }

    switch (targetPlatform ?? defaultTargetPlatform) {
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

  /// Returns the [ContextMenuButtonItem]s for the given [ToolbarOptions].
  @Deprecated(
    'Use `contextMenuBuilder` instead of `toolbarOptions`. '
    'This feature was deprecated after v2.12.0-4.1.pre.',
  )
  static List<ContextMenuButtonItem>? buttonItemsForToolbarOptions(EditableTextState editableTextState, [TargetPlatform? targetPlatform]) {
    final ToolbarOptions toolbarOptions = editableTextState.widget.toolbarOptions;
    if (toolbarOptions == ToolbarOptions.empty) {
      return null;
    }
    return <ContextMenuButtonItem>[
      if (toolbarOptions.cut
          && EditableTextContextMenuButtonItemsBuilder.canCut(editableTextState))
        ContextMenuButtonItem(
          onPressed: () {
            editableTextState.selectAll(SelectionChangedCause.toolbar);
          },
          type: ContextMenuButtonType.selectAll,
        ),
      if (toolbarOptions.copy
          && EditableTextContextMenuButtonItemsBuilder.canCopy(editableTextState))
        ContextMenuButtonItem(
          onPressed: () {
            editableTextState.copySelection(SelectionChangedCause.toolbar);
          },
          type: ContextMenuButtonType.copy,
        ),
      if (toolbarOptions.paste && editableTextState.clipboardStatus != null
          && EditableTextContextMenuButtonItemsBuilder.canPaste(editableTextState))
        ContextMenuButtonItem(
          onPressed: () {
            editableTextState.pasteText(SelectionChangedCause.toolbar);
          },
          type: ContextMenuButtonType.paste,
        ),
      if (toolbarOptions.selectAll
          && EditableTextContextMenuButtonItemsBuilder.canSelectAll(editableTextState, targetPlatform))
        ContextMenuButtonItem(
          onPressed: () {
            editableTextState.selectAll(SelectionChangedCause.toolbar);
          },
          type: ContextMenuButtonType.selectAll,
        ),
    ];
  }

  @override
  State<EditableTextContextMenuButtonItemsBuilder> createState() => _EditableTextContextMenuButtonItemsBuilderState();
}

class _EditableTextContextMenuButtonItemsBuilderState extends State<EditableTextContextMenuButtonItemsBuilder> with TickerProviderStateMixin {
  bool get _canCut => EditableTextContextMenuButtonItemsBuilder.canCut(widget.editableTextState);

  bool get _canCopy => EditableTextContextMenuButtonItemsBuilder.canCopy(widget.editableTextState);

  bool get _canSelectAll => EditableTextContextMenuButtonItemsBuilder.canSelectAll(widget.editableTextState, widget.targetPlatform);

  void _handleCut() {
    return widget.editableTextState.cutSelection(SelectionChangedCause.toolbar);
  }

  void _handleCopy() {
    return widget.editableTextState.copySelection(SelectionChangedCause.toolbar);
  }

  Future<void> _handlePaste() {
    return widget.editableTextState.pasteText(SelectionChangedCause.toolbar);
  }

  void _handleSelectAll() {
    return widget.editableTextState.selectAll(SelectionChangedCause.toolbar);
  }

  @override
  Widget build(BuildContext context) {
    return _ClipboardStatusBuilder(
      clipboardStatusNotifier: widget.editableTextState.clipboardStatus,
      builder: (BuildContext context, ClipboardStatus clipboardStatus) {
        final bool canPaste = EditableTextContextMenuButtonItemsBuilder.canPaste(
          widget.editableTextState,
        );
        // If there are no buttons to be shown, don't render anything.
        if (!_canCut && !_canCopy && !canPaste && !_canSelectAll) {
          return const SizedBox.shrink();
        }
        // If the paste button is enabled, don't render anything until the state
        // of the clipboard is known, since it's used to determine if paste is
        // shown.
        if (canPaste && clipboardStatus == ClipboardStatus.unknown) {
          return const SizedBox.shrink();
        }

        // Determine which buttons will appear so that the order and total number is
        // known. A button's position in the menu can slightly affect its
        // appearance.
        final List<ContextMenuButtonItem> buttonItems = <ContextMenuButtonItem>[
          if (_canCut)
            ContextMenuButtonItem(
              onPressed: _handleCut,
              type: ContextMenuButtonType.cut,
            ),
          if (_canCopy)
            ContextMenuButtonItem(
              onPressed: _handleCopy,
              type: ContextMenuButtonType.copy,
            ),
          if (canPaste && clipboardStatus == ClipboardStatus.pasteable)
            ContextMenuButtonItem(
              onPressed: _handlePaste,
              type: ContextMenuButtonType.paste,
            ),
          if (_canSelectAll)
            ContextMenuButtonItem(
              onPressed: _handleSelectAll,
              type: ContextMenuButtonType.selectAll,
            ),
        ];

        // If there is no option available, build an empty widget.
        if (buttonItems.isEmpty) {
          return const SizedBox(width: 0.0, height: 0.0);
        }

        return widget.builder(context, buttonItems);
      },
    );
  }
}

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
