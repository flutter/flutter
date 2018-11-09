// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class Leaf extends StatefulWidget {
  const Leaf({ Key key, this.child }) : super(key: key);
  final Widget child;
  @override
  _LeafState createState() => _LeafState();
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
        _handle = KeepAliveHandle();
        KeepAliveNotification(_handle).dispatch(context);
      }
    } else {
      _handle?.release();
      _handle = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_keepAlive && _handle == null) {
      _handle = KeepAliveHandle();
      KeepAliveNotification(_handle).dispatch(context);
    }
    return widget.child;
  }
}

List<Widget> generateList(Widget child, { @required bool impliedMode }) {
  return List<Widget>.generate(
    100,
    (int index) {
      final Widget result = Leaf(
        key: GlobalObjectKey<_LeafState>(index),
        child: child,
      );
      if (impliedMode)
        return result;
      return AutomaticKeepAlive(child: result);
    },
    growable: false,
  );
}

void tests({ @required bool impliedMode }) {
  testWidgets('AutomaticKeepAlive with ListView with itemExtent', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          addAutomaticKeepAlives: impliedMode,
          addRepaintBoundaries: impliedMode,
          addSemanticIndexes: false,
          itemExtent: 12.3, // about 50 widgets visible
          cacheExtent: 0.0,
          children: generateList(const Placeholder(), impliedMode: impliedMode),
        ),
      ),
    );
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0.0, -300.0)); // about 25 widgets' worth
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
    const GlobalObjectKey<_LeafState>(60).currentState.setKeepAlive(true);
    await tester.drag(find.byType(ListView), const Offset(0.0, 300.0)); // back to top
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
    const GlobalObjectKey<_LeafState>(60).currentState.setKeepAlive(false);
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
  });

  testWidgets('AutomaticKeepAlive with ListView without itemExtent', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          addAutomaticKeepAlives: impliedMode,
          addRepaintBoundaries: impliedMode,
          addSemanticIndexes: false,
          cacheExtent: 0.0,
          children: generateList(
            Container(height: 12.3, child: const Placeholder()), // about 50 widgets visible
            impliedMode: impliedMode,
          ),
        ),
      ),
    );
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0.0, -300.0)); // about 25 widgets' worth
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
    const GlobalObjectKey<_LeafState>(60).currentState.setKeepAlive(true);
    await tester.drag(find.byType(ListView), const Offset(0.0, 300.0)); // back to top
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
    const GlobalObjectKey<_LeafState>(60).currentState.setKeepAlive(false);
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
  });

  testWidgets('AutomaticKeepAlive with GridView', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView.count(
          addAutomaticKeepAlives: impliedMode,
          addRepaintBoundaries: impliedMode,
          addSemanticIndexes: false,
          crossAxisCount: 2,
          childAspectRatio: 400.0 / 24.6, // about 50 widgets visible
          cacheExtent: 0.0,
          children: generateList(
            Container(child: const Placeholder()),
            impliedMode: impliedMode,
          ),
        ),
      ),
    );
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
    await tester.drag(find.byType(GridView), const Offset(0.0, -300.0)); // about 25 widgets' worth
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
    const GlobalObjectKey<_LeafState>(60).currentState.setKeepAlive(true);
    await tester.drag(find.byType(GridView), const Offset(0.0, 300.0)); // back to top
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
    const GlobalObjectKey<_LeafState>(60).currentState.setKeepAlive(false);
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(30)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(59), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(60), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(61), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(90), skipOffstage: false), findsNothing);
  });
}

void main() {
  group('Explicit automatic keep-alive', () { tests(impliedMode: false); });
  group('Implied automatic keep-alive', () { tests(impliedMode: true); });

  testWidgets('AutomaticKeepAlive double', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          addSemanticIndexes: false,
          cacheExtent: 0.0,
          children: <Widget>[
            AutomaticKeepAlive(
              child: Container(
                height: 400.0,
                child: Stack(children: const <Widget>[
                  Leaf(key: GlobalObjectKey<_LeafState>(0), child: Placeholder()),
                  Leaf(key: GlobalObjectKey<_LeafState>(1), child: Placeholder()),
                ]),
              ),
            ),
            AutomaticKeepAlive(
              child: Container(
                key: const GlobalObjectKey<_LeafState>(2),
                height: 400.0,
              ),
            ),
            AutomaticKeepAlive(
              child: Container(
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
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3), skipOffstage: false), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0.0, -1000.0)); // move to bottom
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0.0, 1000.0)); // move to top
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3), skipOffstage: false), findsNothing);
    const GlobalObjectKey<_LeafState>(0).currentState.setKeepAlive(true);
    await tester.drag(find.byType(ListView), const Offset(0.0, -1000.0)); // move to bottom
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    const GlobalObjectKey<_LeafState>(1).currentState.setKeepAlive(true);
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    const GlobalObjectKey<_LeafState>(0).currentState.setKeepAlive(false);
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    const GlobalObjectKey<_LeafState>(1).currentState.setKeepAlive(false);
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
  });

  testWidgets('AutomaticKeepAlive double 2', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          addSemanticIndexes: false,
          cacheExtent: 0.0,
          children: <Widget>[
            AutomaticKeepAlive(
              child: Container(
                height: 400.0,
                child: Stack(children: const <Widget>[
                  Leaf(key: GlobalObjectKey<_LeafState>(0), child: Placeholder()),
                  Leaf(key: GlobalObjectKey<_LeafState>(1), child: Placeholder()),
                ]),
              ),
            ),
            AutomaticKeepAlive(
              child: Container(
                height: 400.0,
                child: Stack(children: const <Widget>[
                  Leaf(key: GlobalObjectKey<_LeafState>(2), child: Placeholder()),
                  Leaf(key: GlobalObjectKey<_LeafState>(3), child: Placeholder()),
                ]),
              ),
            ),
            AutomaticKeepAlive(
              child: Container(
                height: 400.0,
                child: Stack(children: const <Widget>[
                  Leaf(key: GlobalObjectKey<_LeafState>(4), child: Placeholder()),
                  Leaf(key: GlobalObjectKey<_LeafState>(5), child: Placeholder()),
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
    expect(find.byKey(const GlobalObjectKey<_LeafState>(4), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(5), skipOffstage: false), findsNothing);
    const GlobalObjectKey<_LeafState>(0).currentState.setKeepAlive(true);
    await tester.drag(find.byType(ListView), const Offset(0.0, -1000.0)); // move to bottom
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(4)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(5)), findsOneWidget);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListView(
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        addSemanticIndexes: false,
        cacheExtent: 0.0,
        children: <Widget>[
          AutomaticKeepAlive(
            child: Container(
              height: 400.0,
              child: Stack(children: const <Widget>[
                Leaf(key: GlobalObjectKey<_LeafState>(1), child: Placeholder()),
              ]),
            ),
          ),
          AutomaticKeepAlive(
            child: Container(
              height: 400.0,
              child: Stack(children: const <Widget>[
                Leaf(key: GlobalObjectKey<_LeafState>(2), child: Placeholder()),
                Leaf(key: GlobalObjectKey<_LeafState>(3), child: Placeholder()),
              ]),
            ),
          ),
          AutomaticKeepAlive(
            child: Container(
              height: 400.0,
              child: Stack(children: const <Widget>[
                Leaf(key: GlobalObjectKey<_LeafState>(4), child: Placeholder()),
                Leaf(key: GlobalObjectKey<_LeafState>(5), child: Placeholder()),
                Leaf(key: GlobalObjectKey<_LeafState>(0), child: Placeholder()),
              ]),
            ),
          ),
        ],
      ),
    ));
    await tester.pump(); // Sometimes AutomaticKeepAlive needs an extra pump to clean things up.
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1), skipOffstage: false), findsNothing);
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
    expect(find.byKey(const GlobalObjectKey<_LeafState>(4), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(5), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(4)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(5)), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0)), findsNothing);
    const GlobalObjectKey<_LeafState>(0).currentState.setKeepAlive(false);
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(4), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(5), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0), skipOffstage: false), findsNothing);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListView(
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        addSemanticIndexes: false,
        cacheExtent: 0.0,
        children: <Widget>[
          AutomaticKeepAlive(
            child: Container(
              height: 400.0,
              child: Stack(children: const <Widget>[
                Leaf(key: GlobalObjectKey<_LeafState>(1), child: Placeholder()),
                Leaf(key: GlobalObjectKey<_LeafState>(2), child: Placeholder()),
              ]),
            ),
          ),
          AutomaticKeepAlive(
            child: Container(
              height: 400.0,
              child: Stack(children: const <Widget>[
              ]),
            ),
          ),
          AutomaticKeepAlive(
            child: Container(
              height: 400.0,
              child: Stack(children: const <Widget>[
                Leaf(key: GlobalObjectKey<_LeafState>(3), child: Placeholder()),
                Leaf(key: GlobalObjectKey<_LeafState>(4), child: Placeholder()),
                Leaf(key: GlobalObjectKey<_LeafState>(5), child: Placeholder()),
                Leaf(key: GlobalObjectKey<_LeafState>(0), child: Placeholder()),
              ]),
            ),
          ),
        ],
      ),
    ));
    await tester.pump(); // Sometimes AutomaticKeepAlive needs an extra pump to clean things up.
    expect(find.byKey(const GlobalObjectKey<_LeafState>(1)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(2)), findsOneWidget);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(3), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(4), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(5), skipOffstage: false), findsNothing);
    expect(find.byKey(const GlobalObjectKey<_LeafState>(0), skipOffstage: false), findsNothing);
  });

  testWidgets('AutomaticKeepAlive with keepAlive set to true before initState', (WidgetTester tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListView.builder(
        addSemanticIndexes: false,
        itemCount: 50,
        itemBuilder: (BuildContext context, int index){
          if (index == 0){
            return const _AlwaysKeepAlive(
              key: GlobalObjectKey<_AlwaysKeepAliveState>(0),
            );
          }
          return Container(
            height: 44.0,
            child: Text('FooBar $index'),
          );
        },
      ),
    ));

    expect(find.text('keep me alive'), findsOneWidget);
    expect(find.text('FooBar 1'), findsOneWidget);
    expect(find.text('FooBar 2'), findsOneWidget);

    expect(find.byKey(const GlobalObjectKey<_AlwaysKeepAliveState>(0)), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0.0, -1000.0)); // move to bottom
    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_AlwaysKeepAliveState>(0), skipOffstage: false), findsOneWidget);

    expect(find.text('keep me alive', skipOffstage: false), findsOneWidget);
    expect(find.text('FooBar 1'), findsNothing);
    expect(find.text('FooBar 2'), findsNothing);
  });

  testWidgets('AutomaticKeepAlive with keepAlive set to true before initState and widget goes out of scope', (WidgetTester tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListView.builder(
        addSemanticIndexes: false,
        itemCount: 250,
        itemBuilder: (BuildContext context, int index){
          if (index % 2 == 0){
            return _AlwaysKeepAlive(
              key: GlobalObjectKey<_AlwaysKeepAliveState>(index),
            );
          }
          return Container(
            height: 44.0,
            child: Text('FooBar $index'),
          );
        },
      ),
    ));

    expect(find.text('keep me alive'), findsNWidgets(7));
    expect(find.text('FooBar 1'), findsOneWidget);
    expect(find.text('FooBar 3'), findsOneWidget);

    expect(find.byKey(const GlobalObjectKey<_AlwaysKeepAliveState>(0)), findsOneWidget);

    final ScrollableState state = tester.state(find.byType(Scrollable));
    final ScrollPosition position = state.position;
    position.jumpTo(3025.0);

    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_AlwaysKeepAliveState>(0), skipOffstage: false), findsOneWidget);

    expect(find.text('keep me alive', skipOffstage: false), findsNWidgets(23));
    expect(find.text('FooBar 1'), findsNothing);
    expect(find.text('FooBar 3'), findsNothing);
    expect(find.text('FooBar 73'), findsOneWidget);
  });

  testWidgets('AutomaticKeepAlive with SliverKeepAliveWidget', (WidgetTester tester) async {
    RenderSliverAlternativeToMultiBoxAdaptor r = RenderSliverAlternativeToMultiBoxAdaptor();



    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListView.builder(
        addSemanticIndexes: false,
        itemCount: 250,
        itemBuilder: (BuildContext context, int index){
          if (index % 2 == 0){
            return _AlwaysKeepAlive(
              key: GlobalObjectKey<_AlwaysKeepAliveState>(index),
            );
          }
          return Container(
            height: 44.0,
            child: Text('FooBar $index'),
          );
        },
      ),
    ));

    expect(find.text('keep me alive'), findsNWidgets(7));
    expect(find.text('FooBar 1'), findsOneWidget);
    expect(find.text('FooBar 3'), findsOneWidget);

    expect(find.byKey(const GlobalObjectKey<_AlwaysKeepAliveState>(0)), findsOneWidget);

    final ScrollableState state = tester.state(find.byType(Scrollable));
    final ScrollPosition position = state.position;
    position.jumpTo(3025.0);

    await tester.pump();
    expect(find.byKey(const GlobalObjectKey<_AlwaysKeepAliveState>(0), skipOffstage: false), findsOneWidget);

    expect(find.text('keep me alive', skipOffstage: false), findsNWidgets(23));
    expect(find.text('FooBar 1'), findsNothing);
    expect(find.text('FooBar 3'), findsNothing);
    expect(find.text('FooBar 73'), findsOneWidget);
  });
}

class _AlwaysKeepAlive extends StatefulWidget {
  const _AlwaysKeepAlive({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AlwaysKeepAliveState();
}

class _AlwaysKeepAliveState extends State<_AlwaysKeepAlive> with AutomaticKeepAliveClientMixin<_AlwaysKeepAlive> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      height: 48.0,
      child: const Text('keep me alive'),
    );
  }
}
/// Theses classes are here to make sure that [KeepAlive] is dissociate from [RenderSliverMultiBoxAdaptor].
class _SliverAlternativeToMultiBoxAdaptorWidget extends SliverWithKeepAliveWidget {

  @override
  _SliverAlternativeToMultiBoxAdaptorElement createElement() =>
      _SliverAlternativeToMultiBoxAdaptorElement(this);

  @override
  RenderSliverAlternativeToMultiBoxAdaptor createRenderObject(BuildContext context) => RenderSliverAlternativeToMultiBoxAdaptor();
}

class _SliverAlternativeToMultiBoxAdaptorElement extends RenderObjectElement{
  _SliverAlternativeToMultiBoxAdaptorElement(_SliverAlternativeToMultiBoxAdaptorWidget widget)
      : super(widget);

  @override
  _SliverAlternativeToMultiBoxAdaptorWidget get widget => super.widget;

  @override
  RenderSliverAlternativeToMultiBoxAdaptor get renderObject => super.renderObject;

  @override
  void forgetChild(Element child) {
  }

  @override
  void insertChildRenderObject(RenderObject child, int slot) {
    renderObject.
  }

  @override
  void moveChildRenderObject(RenderObject child, int slot) {
  }

  @override
  void removeChildRenderObject(RenderObject child) {
  }
}

class RenderSliverAlternativeToMultiBoxAdaptor extends RenderSliver
    with RenderSliverWithKeepAliveMixin,
         RenderSliverHelpers {
  @override
  void performLayout() {
    // Perform a layout where children are not laid out in the same order
    // as they are defined.
  }
}

class _Theatre extends RenderObjectWidget {
  _Theatre({
    this.onstage,
    @required this.offstage,
  }) : assert(offstage != null),
        assert(!offstage.any((Widget child) => child == null));

  final Stack onstage;

  final List<Widget> offstage;

//  @override
//   createElement() =>

  @override
  _TheatreElement createRenderObject(BuildContext context) => _TheatreElement(this);
}

class _TheatreElement extends RenderObjectElement {
  _TheatreElement(_Theatre widget)
      : assert(!debugChildrenHaveDuplicateKeys(widget, widget.offstage)),
        super(widget);

  @override
  _Theatre get widget => super.widget;

  @override
  _RenderTheatre get renderObject => super.renderObject;

  Element _onstage;
  static final Object _onstageSlot = Object();

  List<Element> _offstage;
  final Set<Element> _forgottenOffstageChildren = HashSet<Element>();

  @override
  void insertChildRenderObject(RenderBox child, dynamic slot) {
    assert(renderObject.debugValidateChild(child));
    if (slot == _onstageSlot) {
      assert(child is RenderStack);
      renderObject.child = child;
    } else {
      assert(slot == null || slot is Element);
      renderObject.insert(child, after: slot?.renderObject);
    }
  }

  @override
  void moveChildRenderObject(RenderBox child, dynamic slot) {
    if (slot == _onstageSlot) {
      renderObject.remove(child);
      assert(child is RenderStack);
      renderObject.child = child;
    } else {
      assert(slot == null || slot is Element);
      if (renderObject.child == child) {
        renderObject.child = null;
        renderObject.insert(child, after: slot?.renderObject);
      } else {
        renderObject.move(child, after: slot?.renderObject);
      }
    }
  }

  @override
  void removeChildRenderObject(RenderBox child) {
    if (renderObject.child == child) {
      renderObject.child = null;
    } else {
      renderObject.remove(child);
    }
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_onstage != null)
      visitor(_onstage);
    for (Element child in _offstage) {
      if (!_forgottenOffstageChildren.contains(child))
        visitor(child);
    }
  }

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    if (_onstage != null)
      visitor(_onstage);
  }

  @override
  bool forgetChild(Element child) {
    if (child == _onstage) {
      _onstage = null;
    } else {
      assert(_offstage.contains(child));
      assert(!_forgottenOffstageChildren.contains(child));
      _forgottenOffstageChildren.add(child);
    }
    return true;
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _onstage = updateChild(_onstage, widget.onstage, _onstageSlot);
    _offstage = List<Element>(widget.offstage.length);
    Element previousChild;
    for (int i = 0; i < _offstage.length; i += 1) {
      final Element newChild = inflateWidget(widget.offstage[i], previousChild);
      _offstage[i] = newChild;
      previousChild = newChild;
    }
  }

  @override
  void update(_Theatre newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _onstage = updateChild(_onstage, widget.onstage, _onstageSlot);
    _offstage = updateChildren(_offstage, widget.offstage, forgottenChildren: _forgottenOffstageChildren);
    _forgottenOffstageChildren.clear();
  }
}
