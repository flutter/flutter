// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

// A simple "flat" InheritedModel: the data model is just 3 integer
// valued fields: a, b, c.
class ABCModel extends InheritedModel<String> {
  ABCModel({
    Key key,
    this.a,
    this.b,
    this.c,
    Widget child,
  }) : super(key: key, child: child);

  final int a;
  final int b;
  final int c;

  @override
  bool updateShouldNotify(ABCModel old) {
    return a != old.a || b != old.b || c != old.c;
  }

  @override
  bool updateShouldNotifyDependent(ABCModel old, Set<String> dependencies) {
    return (a != old.a && dependencies.contains('a'))
        || (b != old.b && dependencies.contains('b'))
        || (c != old.c && dependencies.contains('c'));
  }

  static ABCModel of(BuildContext context, { String fieldName }) {
    return InheritedModel.inheritFrom<ABCModel>(context, aspect: fieldName);
  }
}

class ShowABCField extends StatefulWidget {
  ShowABCField({ Key key, this.fieldName }) : super(key: key);

  final String fieldName;

  _ShowABCFieldState createState() => new _ShowABCFieldState();
}

class _ShowABCFieldState extends State<ShowABCField> {
  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    final ABCModel abc = ABCModel.of(context, fieldName: widget.fieldName);
    final int value = widget.fieldName == 'a' ? abc.a : (widget.fieldName == 'b' ? abc.b : abc.c);
    return new Text('${widget.fieldName}: $value [${_buildCount++}]');
  }
}

class ABCPage extends StatefulWidget {
  @override
  _ABCPageState createState() => new _ABCPageState();
}

class _ABCPageState extends State<ABCPage> {
  int _a = 0;
  int _b = 1;
  int _c = 2;

  @override
  Widget build(BuildContext context) {
    final Widget showA = new ShowABCField(fieldName: 'a');
    final Widget showB = new ShowABCField(fieldName: 'b');
    final Widget showC = new ShowABCField(fieldName: 'c');

    // Unconditionally depends on the ABCModel: rebuilt when any
    // aspect of the model changes.
    final Widget showABC = new Builder(
      builder: (BuildContext context) {
        final ABCModel abc = ABCModel.of(context);
        return new Text('a: ${abc.a} b: ${abc.b} c: ${abc.c}');
      }
    );

    return new Scaffold(
      body: new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return new ABCModel(
            a: _a,
            b: _b,
            c: _c,
            child: new Center(
              child: new Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  showA,
                  showB,
                  showC,
                  showABC,
                  new RaisedButton(
                    child: const Text('Increment a'),
                    onPressed: () {
                      // Rebuilds the ABCModel which triggers a rebuild
                      // of showA because showA depends on the 'a' aspect
                      // of the ABCModel.
                      setState(() { _a += 1; });
                    },
                  ),
                  new RaisedButton(
                    child: const Text('Increment b'),
                    onPressed: () {
                      // Rebuilds the ABCModel which triggers a rebuild
                      // of showB because showB depends on the 'b' aspect
                      // of the ABCModel.
                      setState(() { _b += 1; });
                    },
                  ),
                  new RaisedButton(
                    child: const Text('Increment c'),
                    onPressed: () {
                      // Rebuilds the ABCModel which triggers a rebuild
                      // of showC because showC depends on the 'c' aspect
                      // of the ABCModel.
                      setState(() { _c += 1; });
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


void main() {
  testWidgets('InheritedModel flat ABCModel', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(home: new ABCPage()));

    expect(find.text('a: 0 [0]'), findsOneWidget);
    expect(find.text('b: 1 [0]'), findsOneWidget);
    expect(find.text('c: 2 [0]'), findsOneWidget);
    expect(find.text('a: 0 b: 1 c: 2'), findsOneWidget);

    await tester.tap(find.text('Increment a'));
    await tester.pumpAndSettle();
    // Verify that field 'a' was incremented, but only the showA
    // and showABC widgets were rebuilt.
    expect(find.text('a: 1 [1]'), findsOneWidget);
    expect(find.text('b: 1 [0]'), findsOneWidget);
    expect(find.text('c: 2 [0]'), findsOneWidget);
    expect(find.text('a: 1 b: 1 c: 2'), findsOneWidget);

    // Verify that field 'a' was incremented, but only the showA
    // and showABC widgets were rebuilt.
    await tester.tap(find.text('Increment a'));
    await tester.pumpAndSettle();
    expect(find.text('a: 2 [2]'), findsOneWidget);
    expect(find.text('b: 1 [0]'), findsOneWidget);
    expect(find.text('c: 2 [0]'), findsOneWidget);
    expect(find.text('a: 2 b: 1 c: 2'), findsOneWidget);

    // Verify that field 'b' was incremented, but only the showB
    // and showABC widgets were rebuilt.
    await tester.tap(find.text('Increment b'));
    await tester.pumpAndSettle();
    expect(find.text('a: 2 [2]'), findsOneWidget);
    expect(find.text('b: 2 [1]'), findsOneWidget);
    expect(find.text('c: 2 [0]'), findsOneWidget);
    expect(find.text('a: 2 b: 2 c: 2'), findsOneWidget);

    // Verify that field 'c' was incremented, but only the showC
    // and showABC widgets were rebuilt.
    await tester.tap(find.text('Increment c'));
    await tester.pumpAndSettle();
    expect(find.text('a: 2 [2]'), findsOneWidget);
    expect(find.text('b: 2 [1]'), findsOneWidget);
    expect(find.text('c: 3 [1]'), findsOneWidget);
    expect(find.text('a: 2 b: 2 c: 3'), findsOneWidget);
  });
}
