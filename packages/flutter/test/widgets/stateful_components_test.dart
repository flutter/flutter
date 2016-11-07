// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

class InnerWidget extends StatefulWidget {
  InnerWidget({ Key key }) : super(key: key);

  @override
  InnerWidgetState createState() => new InnerWidgetState();
}

class InnerWidgetState extends State<InnerWidget> {
  bool _didInitState = false;

  @override
  void initState() {
    super.initState();
    _didInitState = true;
  }

  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}

class OuterContainer extends StatefulWidget {
  OuterContainer({ Key key, this.child }) : super(key: key);

  final InnerWidget child;

  @override
  OuterContainerState createState() => new OuterContainerState();
}

class OuterContainerState extends State<OuterContainer> {
  @override
  Widget build(BuildContext context) {
    return config.child;
  }
}

void main() {
  testWidgets('resync stateful widget', (WidgetTester tester) async {
    Key innerKey = new Key('inner');
    Key outerKey = new Key('outer');

    InnerWidget inner1 = new InnerWidget(key: innerKey);
    InnerWidget inner2;
    OuterContainer outer1 = new OuterContainer(key: outerKey, child: inner1);
    OuterContainer outer2;

    await tester.pumpWidget(outer1);

    StatefulElement innerElement = tester.element(find.byKey(innerKey));
    InnerWidgetState innerElementState = innerElement.state;
    expect(innerElementState.config, equals(inner1));
    expect(innerElementState._didInitState, isTrue);
    expect(innerElement.renderObject.attached, isTrue);

    inner2 = new InnerWidget(key: innerKey);
    outer2 = new OuterContainer(key: outerKey, child: inner2);

    await tester.pumpWidget(outer2);

    expect(tester.element(find.byKey(innerKey)), equals(innerElement));
    expect(innerElement.state, equals(innerElementState));

    expect(innerElementState.config, equals(inner2));
    expect(innerElementState._didInitState, isTrue);
    expect(innerElement.renderObject.attached, isTrue);

    StatefulElement outerElement = tester.element(find.byKey(outerKey));
    expect(outerElement.state.config, equals(outer2));
    outerElement.markNeedsBuild();
    await tester.pump();

    expect(tester.element(find.byKey(innerKey)), equals(innerElement));
    expect(innerElement.state, equals(innerElementState));
    expect(innerElementState.config, equals(inner2));
    expect(innerElement.renderObject.attached, isTrue);
  });
}
