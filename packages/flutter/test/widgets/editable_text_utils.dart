// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// On web, the context menu (aka toolbar) is provided by the browser.
const bool isContextMenuProvidedByPlatform = isBrowser;

// Returns the RenderEditable at the given index, or the first if not given.
RenderEditable findRenderEditable(WidgetTester tester, {int index = 0}) {
  final RenderObject root = tester.renderObject(find.byType(EditableText).at(index));
  expect(root, isNotNull);

  late RenderEditable renderEditable;
  void recursiveFinder(RenderObject child) {
    if (child is RenderEditable) {
      renderEditable = child;
      return;
    }
    child.visitChildren(recursiveFinder);
  }

  root.visitChildren(recursiveFinder);
  expect(renderEditable, isNotNull);
  return renderEditable;
}

List<TextSelectionPoint> globalize(Iterable<TextSelectionPoint> points, RenderBox box) {
  return points.map<TextSelectionPoint>((TextSelectionPoint point) {
    return TextSelectionPoint(box.localToGlobal(point.point), point.direction);
  }).toList();
}

Offset textOffsetToPosition(WidgetTester tester, int offset, {int index = 0}) {
  final RenderEditable renderEditable = findRenderEditable(tester, index: index);
  final List<TextSelectionPoint> endpoints = globalize(
    renderEditable.getEndpointsForSelection(TextSelection.collapsed(offset: offset)),
    renderEditable,
  );
  expect(endpoints.length, 1);
  return endpoints[0].point + const Offset(kIsWeb ? 1.0 : 0.0, -2.0);
}

/// Mimic key press events by sending key down and key up events via the [tester].
Future<void> sendKeys(
  WidgetTester tester,
  List<LogicalKeyboardKey> keys, {
  bool shift = false,
  bool wordModifier = false,
  bool lineModifier = false,
  bool shortcutModifier = false,
  required TargetPlatform targetPlatform,
}) async {
  final targetPlatformString = targetPlatform.toString();
  final String platform = targetPlatformString
      .substring(targetPlatformString.indexOf('.') + 1)
      .toLowerCase();
  if (shift) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft, platform: platform);
  }
  if (shortcutModifier) {
    await tester.sendKeyDownEvent(
      platform == 'macos' || platform == 'ios'
          ? LogicalKeyboardKey.metaLeft
          : LogicalKeyboardKey.controlLeft,
      platform: platform,
    );
  }
  if (wordModifier) {
    await tester.sendKeyDownEvent(
      platform == 'macos' || platform == 'ios'
          ? LogicalKeyboardKey.altLeft
          : LogicalKeyboardKey.controlLeft,
      platform: platform,
    );
  }
  if (lineModifier) {
    await tester.sendKeyDownEvent(
      platform == 'macos' || platform == 'ios'
          ? LogicalKeyboardKey.metaLeft
          : LogicalKeyboardKey.altLeft,
      platform: platform,
    );
  }
  for (final key in keys) {
    await tester.sendKeyEvent(key, platform: platform);
    await tester.pump();
  }
  if (lineModifier) {
    await tester.sendKeyUpEvent(
      platform == 'macos' || platform == 'ios'
          ? LogicalKeyboardKey.metaLeft
          : LogicalKeyboardKey.altLeft,
      platform: platform,
    );
  }
  if (wordModifier) {
    await tester.sendKeyUpEvent(
      platform == 'macos' || platform == 'ios'
          ? LogicalKeyboardKey.altLeft
          : LogicalKeyboardKey.controlLeft,
      platform: platform,
    );
  }
  if (shortcutModifier) {
    await tester.sendKeyUpEvent(
      platform == 'macos' || platform == 'ios'
          ? LogicalKeyboardKey.metaLeft
          : LogicalKeyboardKey.controlLeft,
      platform: platform,
    );
  }
  if (shift) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft, platform: platform);
  }
  if (shift || wordModifier || lineModifier) {
    await tester.pump();
  }
}

// Simple controller that builds a WidgetSpan with 100 height.
class OverflowWidgetTextEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return TextSpan(
      style: style,
      children: <InlineSpan>[
        const TextSpan(text: 'Hi'),
        WidgetSpan(child: Container(color: const Color(0xffff0000), height: 100.0)),
      ],
    );
  }
}

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

  static const Color _red = Color.fromARGB(0xFF, 0xFF, 0x00, 0x00);

  @override
  Widget build(BuildContext context) {
    return _selectionGestureDetectorBuilder.buildGestureDetector(
      behavior: HitTestBehavior.translucent,
      child: EditableText(
        key: editableTextKey,
        autofillHints: widget.autofillHints,
        autofocus: widget.autofocus,
        backgroundCursorColor: _red, // Colors.red, required by editable text.
        contextMenuBuilder: widget.contextMenuBuilder,
        cursorColor: widget.cursorColor ?? _red, // Colors.red, required by editable text.
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
    // BasicTestTextField does not have an onTap callback.
  }

  @override
  bool get onUserTapAlwaysCalled => false;
}

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

final TextSelectionControls testTextSelectionHandleControls = TestTextSelectionHandleControls();
