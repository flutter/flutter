// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class Leaf extends StatefulWidget {
  const Leaf({ Key key, this.child }) : super(key: key);
  final Widget child;
  @override
  _LeafState createState() => new _LeafState();
}

class _LeafState extends State<Leaf> {
  bool _keepAlive = false;
  KeepAliveHandle _handle;

  @override
  void deactivate() {
    _handle?.release();
    _handle = null;
    super.deactivate();
  }

  void setKeepAlive(bool value) {
    _keepAlive = value;
    if (_keepAlive) {
      if (_handle == null) {
        _handle = new KeepAliveHandle();
        new KeepAliveNotification(_handle).dispatch(context);
      }
    } else {
      _handle?.release();
      _handle = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_keepAlive && _handle == null) {
      _handle = new KeepAliveHandle();
      new KeepAliveNotification(_handle).dispatch(context);
    }
    return widget.child;
  }
}

List<Widget> generateList(Widget child, { @required bool impliedMode }) {
  return new List<Widget>.generate(
    100,
    (int index) {
      final Widget result = new Leaf(
        key: new GlobalObjectKey<_LeafState>(index),
        child: child,
      );
      if (impliedMode)
        return result;
      return new AutomaticKeepAlive(child: result);
    },
    growable: false,
  );
}

void tests({ @required bool impliedMode }) {
  testWidgets('AutomaticKeepAlive with ListView with itemExtent', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          addAutomaticKeepAlives: impliedMode,
          addRepaintBoundaries: impliedMode,
          itemExtent: 12.3, // about 50 widgets visible
          children: generateList(const Placeholder(), impliedMode: impliedMode),
        ),
      ),
    );
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90)), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0.0, -300.0)); // about 25 widgets' worth
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90)), findsNothing);
    const GlobalObjectKey<_LeafState>(60).currentState.setKeepAlive(true);
    await tester.drag(find.byType(ListView), const Offset(0.0, 300.0)); // back to top
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90)), findsNothing);
    const GlobalObjectKey<_LeafState>(60).currentState.setKeepAlive(false);
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90)), findsNothing);
  });

  testWidgets('AutomaticKeepAlive with ListView without itemExtent', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          addAutomaticKeepAlives: impliedMode,
          addRepaintBoundaries: impliedMode,
          children: generateList(
            new Container(height: 12.3, child: const Placeholder()), // about 50 widgets visible
            impliedMode: impliedMode,
          ),
        ),
      ),
    );
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90)), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0.0, -300.0)); // about 25 widgets' worth
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90)), findsNothing);
    const GlobalObjectKey<_LeafState>(60).currentState.setKeepAlive(true);
    await tester.drag(find.byType(ListView), const Offset(0.0, 300.0)); // back to top
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90)), findsNothing);
    const GlobalObjectKey<_LeafState>(60).currentState.setKeepAlive(false);
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90)), findsNothing);
  });

  testWidgets('AutomaticKeepAlive with GridView', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new GridView.count(
          addAutomaticKeepAlives: impliedMode,
          addRepaintBoundaries: impliedMode,
          crossAxisCount: 2,
          childAspectRatio: 400.0 / 24.6, // about 50 widgets visible
          children: generateList(
            new Container(child: const Placeholder()),
            impliedMode: impliedMode,
          ),
        ),
      ),
    );
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90)), findsNothing);
    await tester.drag(find.byType(GridView), const Offset(0.0, -300.0)); // about 25 widgets' worth
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90)), findsNothing);
    const GlobalObjectKey<_LeafState>(60).currentState.setKeepAlive(true);
    await tester.drag(find.byType(GridView), const Offset(0.0, 300.0)); // back to top
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90)), findsNothing);
    const GlobalObjectKey<_LeafState>(60).currentState.setKeepAlive(false);
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90)), findsNothing);
  });
}

void main() {
  group('Explicit automatic keep-alive', () { tests(impliedMode: false); });
  group('Implied automatic keep-alive', () { tests(impliedMode: true); });

  testWidgets('AutomaticKeepAlive double', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          children: <Widget>[
            new AutomaticKeepAlive(
              child: new Container(
                height: 400.0,
                child: new Stack(children: const <Widget>[
                  const Leaf(key: const GlobalObjectKey<_LeafState>(0), child: const Placeholder()),
                  const Leaf(key: const GlobalObjectKey<_LeafState>(1), child: const Placeholder()),
                ]),
              ),
            ),
            new AutomaticKeepAlive(
              child: new Container(
                key: const GlobalObjectKey<_LeafState>(2),
                height: 400.0,
              ),
            ),
            new AutomaticKeepAlive(
              child: new Container(
                key: const GlobalObjectKey<_LeafState>(3),
                height: 400.0,
              ),
            ),
          ],
        ),
      ),
    );
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0.0, -1000.0)); // move to bottom
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0.0, 1000.0)); // move to top
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsNothing);
    const GlobalObjectKey<_LeafState>(0).currentState.setKeepAlive(true);
    await tester.drag(find.byType(ListView), const Offset(0.0, -1000.0)); // move to bottom
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    const GlobalObjectKey<_LeafState>(1).currentState.setKeepAlive(true);
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    const GlobalObjectKey<_LeafState>(0).currentState.setKeepAlive(false);
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    const GlobalObjectKey<_LeafState>(1).currentState.setKeepAlive(false);
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
  });

  testWidgets('AutomaticKeepAlive double', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          children: <Widget>[
            new AutomaticKeepAlive(
              child: new Container(
                height: 400.0,
                child: new Stack(children: const <Widget>[
                  const Leaf(key: const GlobalObjectKey<_LeafState>(0), child: const Placeholder()),
                  const Leaf(key: const GlobalObjectKey<_LeafState>(1), child: const Placeholder()),
                ]),
              ),
            ),
            new AutomaticKeepAlive(
              child: new Container(
                height: 400.0,
                child: new Stack(children: const <Widget>[
                  const Leaf(key: const GlobalObjectKey<_LeafState>(2), child: const Placeholder()),
                  const Leaf(key: const GlobalObjectKey<_LeafState>(3), child: const Placeholder()),
                ]),
              ),
            ),
            new AutomaticKeepAlive(
              child: new Container(
                height: 400.0,
                child: new Stack(children: const <Widget>[
                  const Leaf(key: const GlobalObjectKey<_LeafState>(4), child: const Placeholder()),
                  const Leaf(key: const GlobalObjectKey<_LeafState>(5), child: const Placeholder()),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(4)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(5)), findsNothing);
    const GlobalObjectKey<_LeafState>(0).currentState.setKeepAlive(true);
    await tester.drag(find.byType(ListView), const Offset(0.0, -1000.0)); // move to bottom
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(4)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(5)), findsOneWidget);
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new ListView(
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        children: <Widget>[
          new AutomaticKeepAlive(
            child: new Container(
              height: 400.0,
              child: new Stack(children: const <Widget>[
                const Leaf(key: const GlobalObjectKey<_LeafState>(1), child: const Placeholder()),
              ]),
            ),
          ),
          new AutomaticKeepAlive(
            child: new Container(
              height: 400.0,
              child: new Stack(children: const <Widget>[
                const Leaf(key: const GlobalObjectKey<_LeafState>(2), child: const Placeholder()),
                const Leaf(key: const GlobalObjectKey<_LeafState>(3), child: const Placeholder()),
              ]),
            ),
          ),
          new AutomaticKeepAlive(
            child: new Container(
              height: 400.0,
              child: new Stack(children: const <Widget>[
                const Leaf(key: const GlobalObjectKey<_LeafState>(4), child: const Placeholder()),
                const Leaf(key: const GlobalObjectKey<_LeafState>(5), child: const Placeholder()),
                const Leaf(key: const GlobalObjectKey<_LeafState>(0), child: const Placeholder()),
              ]),
            ),
          ),
        ],
      ),
    ));
    await tester.pump(); // Sometimes AutomaticKeepAlive needs an extra pump to clean things up.
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(4)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(5)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0)), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0.0, 1000.0)); // move to top
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(4)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(5)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0)), findsOneWidget);
    const GlobalObjectKey<_LeafState>(0).currentState.setKeepAlive(false);
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(4)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(5)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0)), findsNothing);
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new ListView(
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        children: <Widget>[
          new AutomaticKeepAlive(
            child: new Container(
              height: 400.0,
              child: new Stack(children: const <Widget>[
                const Leaf(key: const GlobalObjectKey<_LeafState>(1), child: const Placeholder()),
                const Leaf(key: const GlobalObjectKey<_LeafState>(2), child: const Placeholder()),
              ]),
            ),
          ),
          new AutomaticKeepAlive(
            child: new Container(
              height: 400.0,
              child: new Stack(children: const <Widget>[
              ]),
            ),
          ),
          new AutomaticKeepAlive(
            child: new Container(
              height: 400.0,
              child: new Stack(children: const <Widget>[
                const Leaf(key: const GlobalObjectKey<_LeafState>(3), child: const Placeholder()),
                const Leaf(key: const GlobalObjectKey<_LeafState>(4), child: const Placeholder()),
                const Leaf(key: const GlobalObjectKey<_LeafState>(5), child: const Placeholder()),
                const Leaf(key: const GlobalObjectKey<_LeafState>(0), child: const Placeholder()),
              ]),
            ),
          ),
        ],
      ),
    ));
    await tester.pump(); // Sometimes AutomaticKeepAlive needs an extra pump to clean things up.
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(4)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(5)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0)), findsNothing);
  });
}