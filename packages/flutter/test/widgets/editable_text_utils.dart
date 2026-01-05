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

class BasicTestTextField extends StatefulWidget {
  const BasicTestTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.style,
    this.autofocus = false,
    this.contextMenuBuilder,
    this.readOnly = false,
    this.onChanged,
    this.maxLines = 1,
    this.showCursor,
    this.autofillHints = const <String>[],
    this.groupId = EditableText,
  });

  final bool autofocus;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextStyle? style;
  final EditableTextContextMenuBuilder? contextMenuBuilder;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final bool? showCursor;
  final Iterable<String>? autofillHints;
  final Object groupId;

  @override
  State<BasicTestTextField> createState() => _BasicTestTextFieldState();
}

class _BasicTestTextFieldState extends State<BasicTestTextField> {
  TextEditingController? _controller;
  TextEditingController get _effectiveController =>
      widget.controller ?? (_controller ??= TextEditingController());
  FocusNode? _focusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_focusNode ??= FocusNode());

  @override
  void dispose() {
    _focusNode?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  static const Color _red = Color(0xFFF44336); // Colors.red.

  @override
  Widget build(BuildContext context) {
    final bool cursorOpacityAnimates = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => true,
      _ => false,
    };
    return EditableText(
      autofillHints: widget.autofillHints,
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      controller: _effectiveController,
      focusNode: _effectiveFocusNode,
      style: widget.style ?? const TextStyle(),
      contextMenuBuilder: widget.contextMenuBuilder,
      cursorColor: _red, // Colors.red
      backgroundCursorColor: _red, // Colors.red
      selectionControls: basicTestTextSelectionHandleControls,
      cursorOpacityAnimates: cursorOpacityAnimates,
      showCursor: widget.showCursor,
      groupId: widget.groupId,
    );
  }
}

class BasicTestTextSelectionHandleControls extends TextSelectionControls
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

final TextSelectionControls basicTestTextSelectionHandleControls =
    BasicTestTextSelectionHandleControls();
