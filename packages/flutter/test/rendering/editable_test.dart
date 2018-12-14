// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import '../rendering/mock_canvas.dart';
import '../rendering/recording_canvas.dart';

class FakeEditableTextState extends TextSelectionDelegate {
  @override
  TextEditingValue get textEditingValue { return const TextEditingValue(); }

  @override
  set textEditingValue(TextEditingValue value) {}

  @override
  void hideToolbar() {}

  @override
  void bringIntoView(TextPosition position) {}
}

void main() {
  test('editable intrinsics', () {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final RenderEditable editable = RenderEditable(
      text: const TextSpan(
        style: TextStyle(height: 1.0, fontSize: 10.0, fontFamily: 'Ahem'),
        text: '12345',
      ),
      textAlign: TextAlign.start,
      textDirection: TextDirection.ltr,
      locale: const Locale('ja', 'JP'),
      offset: ViewportOffset.zero(),
      textSelectionDelegate: delegate,
    );
    expect(editable.getMinIntrinsicWidth(double.infinity), 50.0);
    expect(editable.getMaxIntrinsicWidth(double.infinity), 50.0);
    expect(editable.getMinIntrinsicHeight(double.infinity), 10.0);
    expect(editable.getMaxIntrinsicHeight(double.infinity), 10.0);

    expect(
      editable.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        'RenderEditable#00000 NEEDS-LAYOUT NEEDS-PAINT DETACHED\n'
        ' │ parentData: MISSING\n'
        ' │ constraints: MISSING\n'
        ' │ size: MISSING\n'
        ' │ cursorColor: null\n'
        ' │ showCursor: ValueNotifier<bool>#00000(false)\n'
        ' │ maxLines: 1\n'
        ' │ selectionColor: null\n'
        ' │ textScaleFactor: 1.0\n'
        ' │ locale: ja_JP\n'
        ' │ selection: null\n'
        ' │ offset: _FixedViewportOffset#00000(offset: 0.0)\n'
        ' ╘═╦══ text ═══\n'
        '   ║ TextSpan:\n'
        '   ║   inherit: true\n'
        '   ║   family: Ahem\n'
        '   ║   size: 10.0\n'
        '   ║   height: 1.0x\n'
        '   ║   "12345"\n'
        '   ╚═══════════\n'
      ),
    );
  });

  // Test that clipping will be used even when the text fits within the visible
  // region if the start position of the text is offset (e.g. during scrolling
  // animation).
  test('correct clipping', () {
    final TextSelectionDelegate delegate = FakeEditableTextState();
    final RenderEditable editable = RenderEditable(
      text: const TextSpan(
        style: TextStyle(height: 1.0, fontSize: 10.0, fontFamily: 'Ahem'),
        text: 'A',
      ),
      textAlign: TextAlign.start,
      textDirection: TextDirection.ltr,
      locale: const Locale('en', 'US'),
      offset: ViewportOffset.fixed(10.0),
      textSelectionDelegate: delegate,
    );
    editable.layout(BoxConstraints.loose(const Size(1000.0, 1000.0)));
    expect(
      (Canvas canvas) => editable.paint(TestRecordingPaintingContext(canvas), Offset.zero),
      paints..clipRect(rect: Rect.fromLTRB(0.0, 0.0, 1000.0, 10.0))
    );
  });
}
