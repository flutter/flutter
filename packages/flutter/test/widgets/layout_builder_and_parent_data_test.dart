// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart' hide TypeMatcher;
import 'package:flutter/widgets.dart';

class SizeChanger extends StatefulWidget {
  const SizeChanger({
    Key key,
    this.child,
  }) : super(key: key);

  final Widget child;

  @override
  SizeChangerState createState() => new SizeChangerState();
}

class SizeChangerState extends State<SizeChanger> {
  bool _flag = false;

  void trigger() {
    setState(() {
      _flag = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Row(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        new SizedBox(
          height: _flag ? 50.0 : 100.0,
          width: 100.0,
          child: widget.child
        )
      ],
    );
  }
}

class Wrapper extends StatelessWidget {
  const Wrapper({
    Key key,
    this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

void main() {
  testWidgets('Applying parent data inside a LayoutBuilder', (WidgetTester tester) async {
    int frame = 1;
    await tester.pumpWidget(new SizeChanger( // when this is triggered, the child LayoutBuilder will build again
      child: new LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
        return new Column(children: <Widget>[new Expanded(
          flex: frame, // this is different after the next pump, so that the parentData has to be applied again
          child: new Container(height: 100.0),
        )]);
      })
    ));
    frame += 1;
    tester.state<SizeChangerState>(find.byType(SizeChanger)).trigger();
    await tester.pump();
  });
}
