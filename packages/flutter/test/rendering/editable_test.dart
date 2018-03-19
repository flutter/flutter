// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('editable intrinsics', () {
    final RenderEditable editable = new RenderEditable(
      text: const TextSpan(
        style: const TextStyle(height: 1.0, fontSize: 10.0, fontFamily: 'Ahem'),
        text: '12345',
      ),
      textAlign: TextAlign.start,
      textDirection: TextDirection.ltr,
      offset: new ViewportOffset.zero(),
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
}