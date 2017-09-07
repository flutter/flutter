// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

int countSemanticsChildren(RenderObject object) {
  int count = 0;
  object.visitChildrenForSemantics((RenderObject child) {
    count += 1;
  });
  return count;
}
    
void main() {
  test('RenderOpacity and children and semantics', () {
    final RenderOpacity box = new RenderOpacity(
      child: new RenderParagraph(
        const TextSpan(),
        textDirection: TextDirection.ltr,
      ),
    );
    expect(countSemanticsChildren(box), 1);
    box.opacity = 0.5;
    expect(countSemanticsChildren(box), 1);
    box.opacity = 0.25;
    expect(countSemanticsChildren(box), 1);
    box.opacity = 0.125;
    expect(countSemanticsChildren(box), 1);
    box.opacity = 0.0;
    expect(countSemanticsChildren(box), 0);
    box.opacity = 0.125;
    expect(countSemanticsChildren(box), 1);
    box.opacity = 0.0;
    expect(countSemanticsChildren(box), 0);
  });
}
