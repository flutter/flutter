// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/layout_builder.dart';
import 'package:flutter_test/flutter_test.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({
    Key key,
    @required this.child
  }) : assert(child != null),
       super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

void main() {
  testWidgets('Moving a global key from another LayoutBuilder at layout time', (WidgetTester tester) async {
    final GlobalKey victimKey = GlobalKey();

    await tester.pumpWidget(Row(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Wrapper(
          child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
            return const SizedBox();
          }),
        ),
        Wrapper(
          child: Wrapper(
            child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
              return Wrapper(
                child: SizedBox(key: victimKey)
              );
            })
          )
        ),
      ],
    ));

    await tester.pumpWidget(Row(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Wrapper(
          child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
            return Wrapper(
              child: SizedBox(key: victimKey)
            );
          })
        ),
        Wrapper(
          child: Wrapper(
            child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
              return const SizedBox();
            })
          )
        ),
      ],
    ));
  });
}
