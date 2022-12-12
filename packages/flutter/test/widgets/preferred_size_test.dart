// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PreferredSize default', (WidgetTester tester) async {
    final PreferredSize widget = PreferredSize(
      preferredSize: const Size.square(100),
      child: Container(color: const Color(0x00FF00FF))
    );
    late final Size size;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          size = widget.preferredSizeFor(context);
          return SizedBox.fromSize(size: size);
        },
      ),
    );

    expect(size, const Size.square(100));
    expect(widget.preferredSize, const Size.square(100));
  });
}
