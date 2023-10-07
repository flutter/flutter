// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WidgetSpan codeUnitAt', () {
    const InlineSpan span = WidgetSpan(child: SizedBox());
    expect(span.codeUnitAt(-1), isNull);
    expect(span.codeUnitAt(0), PlaceholderSpan.placeholderCodeUnit);
    expect(span.codeUnitAt(1), isNull);
    expect(span.codeUnitAt(2), isNull);

    const InlineSpan nestedSpan = TextSpan(
      text: 'AAA',
      children: <InlineSpan>[span, span],
    );
    expect(nestedSpan.codeUnitAt(-1), isNull);
    expect(nestedSpan.codeUnitAt(0), 65);
    expect(nestedSpan.codeUnitAt(1), 65);
    expect(nestedSpan.codeUnitAt(2), 65);
    expect(nestedSpan.codeUnitAt(3), PlaceholderSpan.placeholderCodeUnit);
    expect(nestedSpan.codeUnitAt(4), PlaceholderSpan.placeholderCodeUnit);
    expect(nestedSpan.codeUnitAt(5), isNull);
  });
}
