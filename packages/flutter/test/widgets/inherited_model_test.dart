// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

// See ShowABCField, ABCModel
enum ShowABCFieldMode {
  useOf, // Lookup the value to be displayed with ABCModel.of()
  useValueOf, // Lookup the value to be displayed with ABCModel.valueOf()
}

// A simple "flat" InheritedModel: the data model is just 3 integer
// valued fields: a, b, c.
class ABCModel extends InheritedModel<String> {
  const ABCModel({
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

  // Returns the value of fieldName in the first ABCModel ancestor
  // for which fieldName's value is non-null. Creates a dependency on
  // on that ancestor: when the ancestor is rebuilt the given context
  // will also be rebuit.
  static int valueOf(BuildContext context, String fieldName) {
    int value;
    InheritedModel.inheritFrom<ABCModel>(
      context,
      aspect: fieldName,
      visitor: (ABCModel widget) {
        value = fieldName == 'a' ? widget.a : (fieldName == 'b' ? widget.b : widget.c);
        return value == null;
      }
    );
    return value;
  }
}

class ShowABCField extends StatefulWidget {
  const ShowABCField({ Key key, this.fieldName, this.mode = ShowABCFieldMode.useOf }) : super(key: key);

  final String fieldName;
  final ShowABCFieldMode mode;

  @override
  _ShowABCFieldState createState() => new _ShowABCFieldState();
}

class _ShowABCFieldState extends State<ShowABCField> {
  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    int value;
    switch (widget.mode) {
      case ShowABCFieldMode.useOf:
        final ABCModel abc = ABCModel.of(context, fieldName: widget.fieldName);
        value = widget.fieldName == 'a' ? abc.a : (widget.fieldName == 'b' ? abc.b : abc.c);
        break;
      case ShowABCFieldMode.useValueOf:
        value = ABCModel.valueOf(context, widget.fieldName);
      break;
    }
    return new Text('${widget.fieldName}: $value [${_buildCount++}]');
  }
}

void main() {
  testWidgets('InheritedModel flat ABCModel', (WidgetTester tester) async {
    int _a = 0;
    int _b = 1;
    int _c = 2;

    final Widget abcPage = new StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        const Widget showA = ShowABCField(fieldName: 'a');
        const Widget showB = ShowABCField(fieldName: 'b');
        const Widget showC = ShowABCField(fieldName: 'c');

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
      },
    );

    await tester.pumpWidget(new MaterialApp(home: abcPage));

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

  testWidgets('InheritedModel flat ABCModel with shadowing', (WidgetTester tester) async {
    int _a = 0;
    int _b = 1;
    int _c = 2;

    // Same as in abcPage in the "InheritedModel flat ABCModel" test
    // except:
    // - ABCModel.valueOf() is used to look up the values for the showA, showB,
    // and showC widgets (but not showABC which uses ABCModel.of()).
    // - There are two ABCModels and the inner model's "a" property
    // shadows (overrides) the outer model.
    final Widget abcPage = new StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        const Widget showA = ShowABCField(fieldName: 'a', mode: ShowABCFieldMode.useValueOf);
        const Widget showB = ShowABCField(fieldName: 'b', mode: ShowABCFieldMode.useValueOf);
        const Widget showC = ShowABCField(fieldName: 'c', mode: ShowABCFieldMode.useValueOf);

        // Unconditionally depends on the closest ABCModel ancestor.
        // Which is the inner model, for which b,c are null.
        final Widget showABC = new Builder(
          builder: (BuildContext context) {
            final ABCModel abc = ABCModel.of(context);
            return new Text('a: ${abc.a} b: ${abc.b} c: ${abc.c}', style: Theme.of(context).textTheme.title);
          }
        );

        return new Scaffold(
          body: new StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return new ABCModel( // The "outer" model
                a: _a,
                b: _b,
                c: _c,
                child: new ABCModel( // The "inner" model
                  a: 100 + _a, // Override the value of a
                  b: null, // but not b, c
                  c: null,
                  child: new Center(
                    child: new Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        showA,
                        showB,
                        showC,
                        const SizedBox(height: 24.0),
                        showABC,
                        const SizedBox(height: 24.0),
                        new RaisedButton(
                          child: const Text('Increment a'),
                          onPressed: () {
                            setState(() { _a += 1; });
                          },
                        ),
                        new RaisedButton(
                          child: const Text('Increment b'),
                          onPressed: () {
                            setState(() { _b += 1; });
                          },
                        ),
                        new RaisedButton(
                          child: const Text('Increment c'),
                          onPressed: () {
                            setState(() { _c += 1; });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    await tester.pumpWidget(new MaterialApp(home: abcPage));
    expect(find.text('a: 100 [0]'), findsOneWidget);
    expect(find.text('b: 1 [0]'), findsOneWidget);
    expect(find.text('c: 2 [0]'), findsOneWidget);
    expect(find.text('a: 100 b: null c: null'), findsOneWidget);

    await tester.tap(find.text('Increment a'));
    await tester.pumpAndSettle();
    // Verify that field 'a' was incremented, but only the showA
    // and showABC widgets were rebuilt.
    expect(find.text('a: 101 [1]'), findsOneWidget);
    expect(find.text('b: 1 [0]'), findsOneWidget);
    expect(find.text('c: 2 [0]'), findsOneWidget);
    expect(find.text('a: 101 b: null c: null'), findsOneWidget);

    await tester.tap(find.text('Increment a'));
    await tester.pumpAndSettle();
    // Verify that field 'a' was incremented, but only the showA
    // and showABC widgets were rebuilt.
    expect(find.text('a: 102 [2]'), findsOneWidget);
    expect(find.text('b: 1 [0]'), findsOneWidget);
    expect(find.text('c: 2 [0]'), findsOneWidget);
    expect(find.text('a: 102 b: null c: null'), findsOneWidget);

    // Verify that field 'b' was incremented, but only the showB
    // and showABC widgets were rebuilt.
    await tester.tap(find.text('Increment b'));
    await tester.pumpAndSettle();
    expect(find.text('a: 102 [2]'), findsOneWidget);
    expect(find.text('b: 2 [1]'), findsOneWidget);
    expect(find.text('c: 2 [0]'), findsOneWidget);
    expect(find.text('a: 102 b: null c: null'), findsOneWidget);

    // Verify that field 'c' was incremented, but only the showC
    // and showABC widgets were rebuilt.
    await tester.tap(find.text('Increment c'));
    await tester.pumpAndSettle();
    expect(find.text('a: 102 [2]'), findsOneWidget);
    expect(find.text('b: 2 [1]'), findsOneWidget);
    expect(find.text('c: 3 [1]'), findsOneWidget);
    expect(find.text('a: 102 b: null c: null'), findsOneWidget);
  });
}
