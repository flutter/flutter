// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/layout_builder.dart';
import 'package:flutter_test/flutter_test.dart' hide TypeMatcher;

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
    final GlobalKey victimKey = new GlobalKey();

    await tester.pumpWidget(new Row(children: <Widget>[
      new Wrapper(
        child: new LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
          return const SizedBox();
        }),
      ),
      new Wrapper(
        child: new Wrapper(
          child: new LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
            return new Wrapper(
              child: new SizedBox(key: victimKey)
            );
          })
        )
      ),
    ]));

    await tester.pumpWidget(new Row(children: <Widget>[
      new Wrapper(
        child: new LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
          return new Wrapper(
            child: new SizedBox(key: victimKey)
          );
        })
      ),
      new Wrapper(
        child: new Wrapper(
          child: new LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
            return const SizedBox();
          })
        )
      ),
    ]));
  });
}
