// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({
    Key key,
    this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class StatefulWrapper extends StatefulWidget {
  const StatefulWrapper({
    Key key,
    this.child,
  }) : super(key: key);

  final Widget child;

  @override
  StatefulWrapperState createState() => StatefulWrapperState();
}

class StatefulWrapperState extends State<StatefulWrapper> {

  void trigger() {
    setState(() { /* for test purposes */ });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void main() {
  testWidgets('Moving global key inside a LayoutBuilder', (WidgetTester tester) async {
    final GlobalKey<StatefulWrapperState> key = GlobalKey<StatefulWrapperState>();
    await tester.pumpWidget(
      LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
        return Wrapper(
          child: StatefulWrapper(key: key, child: Container(height: 100.0)),
        );
      }),
    );
    await tester.pumpWidget(
      LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
        key.currentState.trigger();
        return StatefulWrapper(key: key, child: Container(height: 100.0));
      }),
    );
  });
}
