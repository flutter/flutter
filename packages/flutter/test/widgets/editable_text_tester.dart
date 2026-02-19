// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// A minimal wrapper around [EditableText] for use in widget tests.
///
/// This widget provides robust text selection gestures through
/// [TextSelectionGestureDetector].
///
/// This widget does not provide text selection context menus out of the box.
/// They can be added by providing [contextMenuBuilder].
///
/// This widget does not provide a concrete implementation of text selection handles
/// out of the box, and instead uses [testTextSelectionHandleControls] as a default.
/// A more robust implementation of text selection handles can be provided by
/// setting [selectionControls].
///
/// This input field manages its own internal [TextEditingController]
/// and [FocusNode] unless provided one. This field also provides defaults
/// for required [EditableText] members [EditableText.cursorColor],
/// [EditableText.backgroundCursorColor], and [EditableText.style].
class TestTextField extends StatefulWidget {
  const TestTextField({
    super.key,
    this.autofillHints = const <String>[],
    this.autofocus = false,
    this.contextMenuBuilder,
    this.cursorColor,
    this.cursorOpacityAnimates = false,
    this.focusNode,
    this.groupId = EditableText,
    this.maxLines = 1,
    this.onChanged,
    this.readOnly = false,
    this.selectionControls,
    this.showCursor,
    this.style,
    this.controller,
  });

  final Iterable<String>? autofillHints;
  final bool autofocus;
  final EditableTextContextMenuBuilder? contextMenuBuilder;
  final Color? cursorColor;
  final bool cursorOpacityAnimates;
  final FocusNode? focusNode;
  final Object groupId;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final TextSelectionControls? selectionControls;
  final bool? showCursor;
  final TextStyle? style;
  final TextEditingController? controller;

  @override
  State<TestTextField> createState() => _TestTextFieldState();
}

class _TestTextFieldState extends State<TestTextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  TextEditingController? _controller;
  TextEditingController get _effectiveController =>
      widget.controller ?? (_controller ??= TextEditingController());
  FocusNode? _focusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_focusNode ??= FocusNode());

  late _TestTextFieldSelectionGestureDetectorBuilder _selectionGestureDetectorBuilder;

  // API for TextSelectionGestureDetectorBuilderDelegate.
  @override
  bool get forcePressEnabled => false;

  @override
  final GlobalKey<EditableTextState> editableTextKey = GlobalKey<EditableTextState>();

  @override
  bool get selectionEnabled => true;
  // End of API for TextSelectionGestureDetectorBuilderDelegate.

  @override
  void initState() {
    super.initState();
    _selectionGestureDetectorBuilder = _TestTextFieldSelectionGestureDetectorBuilder(state: this);
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  static const Color _red = Color(0xFFF44336);

  @override
  Widget build(BuildContext context) {
    return _selectionGestureDetectorBuilder.buildGestureDetector(
      behavior: HitTestBehavior.translucent,
      child: EditableText(
        key: editableTextKey,
        autofillHints: widget.autofillHints,
        autofocus: widget.autofocus,
        backgroundCursorColor: _red, // required by editable text.
        contextMenuBuilder: widget.contextMenuBuilder,
        cursorColor: widget.cursorColor ?? _red, // required by editable text.
        cursorOpacityAnimates: widget.cursorOpacityAnimates,
        focusNode: _effectiveFocusNode, // required by editable text.
        groupId: widget.groupId,
        maxLines: widget.maxLines,
        onChanged: widget.onChanged,
        readOnly: widget.readOnly,
        rendererIgnoresPointer: true, // gestures are provided by text selection gesture detector.
        selectionControls: widget.selectionControls ?? testTextSelectionHandleControls,
        showCursor: widget.showCursor,
        style: widget.style ?? const TextStyle(), // required by editable text.
        controller: _effectiveController, // required by editable text.
      ),
    );
  }
}

class _TestTextFieldSelectionGestureDetectorBuilder extends TextSelectionGestureDetectorBuilder {
  _TestTextFieldSelectionGestureDetectorBuilder({required _TestTextFieldState state})
    : super(delegate: state);

  @override
  void onUserTap() {
    // TestTextField does not have an onTap callback.
  }

  @override
  bool get onUserTapAlwaysCalled => false;
}

/// A minimal set of text selection controls to make it easier to work with text
/// editing in tests.
class TestTextSelectionHandleControls extends TextSelectionControls
    with TextSelectionHandleControls {
  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) {
    return const SizedBox.shrink();
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    return Offset.zero;
  }

  @override
  Size getHandleSize(double textLineHeight) {
    return Size.zero;
  }
}

/// A minimal instance of text selection controls to make it easier to work with
/// text editing in tests.
final TextSelectionControls testTextSelectionHandleControls = TestTextSelectionHandleControls();
