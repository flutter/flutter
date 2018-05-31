// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Shared state updates state only when changed and handles null value.', (WidgetTester tester) async {
    final List<int> log = <int>[];

    final Builder builder = new Builder(builder: (BuildContext context) {
      final int current = SharedState.getSharedState<int>(context);
      log.add(current);
      return new FlatButton(
        onPressed: () {
          SharedState.setSharedState<int>(context, (current ?? 0) + 1);
        },
        child: new Container(width: 20.0, height: 20.0),
      );
    });

    await tester.pumpWidget(new SharedStateTester(builder));

    expect(log, equals(<int>[null]));
    await tester.tap(find.byType(FlatButton));
    await tester.pumpAndSettle();
    expect(log, equals(<int>[null, 1]));
    await tester.pumpAndSettle();
    expect(log, equals(<int>[null, 1]));
    await tester.tap(find.byType(FlatButton));
    await tester.pumpAndSettle();
    expect(log, equals(<int>[null, 1, 2]));
  });
}

class SharedStateTester extends StatefulWidget {
  const SharedStateTester(this.builder);

  final Widget builder;

  @override
  _SharedStateTesterState createState() {
    return new _SharedStateTesterState();
  }
}

class _SharedStateTesterState extends State<SharedStateTester> {
  int state;

  @override
  Widget build(BuildContext context) {
    return new SharedState<int>(
      value: state,
      valueChanged: (int newState) {
        setState(() {
          state = newState;
        });
      },
      child: widget.builder,
    );
  }
}
