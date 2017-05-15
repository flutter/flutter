// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

void main() {
  test('editable intrinsics', () {
    final RenderEditable editable = new RenderEditable(
      text: const TextSpan(
        style: const TextStyle(height: 1.0, fontSize: 10.0, fontFamily: 'Ahem'),
        text: '12345',
      ),
      offset: new ViewportOffset.zero(),
    );
    expect(editable.getMinIntrinsicWidth(double.INFINITY), 50.0);
    expect(editable.getMaxIntrinsicWidth(double.INFINITY), 50.0);
    expect(editable.getMinIntrinsicHeight(double.INFINITY), 10.0);
    expect(editable.getMaxIntrinsicHeight(double.INFINITY), 10.0);
  });
}