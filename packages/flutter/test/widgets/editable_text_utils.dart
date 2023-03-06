// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// On web, the context menu (aka toolbar) is provided by the browser.
const bool isContextMenuProvidedByPlatform = isBrowser;

// Returns the first RenderEditable.
RenderEditable findRenderEditable(WidgetTester tester) {
  final RenderObject root = tester.renderObject(find.byType(EditableText));
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
    return TextSelectionPoint(
      box.localToGlobal(point.point),
      point.direction,
    );
  }).toList();
}

Offset textOffsetToPosition(WidgetTester tester, int offset) {
  final RenderEditable renderEditable = findRenderEditable(tester);
  final List<TextSelectionPoint> endpoints = globalize(
    renderEditable.getEndpointsForSelection(
      TextSelection.collapsed(offset: offset),
    ),
    renderEditable,
  );
  expect(endpoints.length, 1);
  return endpoints[0].point + const Offset(kIsWeb? 1.0 : 0.0, -2.0);
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
        WidgetSpan(
          child: Container(
            color: Colors.redAccent,
            height: 100.0,
          ),
        ),
      ],
    );
  }
}
