// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

class TestSliverChildListDelegate extends SliverChildListDelegate {
  TestSliverChildListDelegate(List<Widget> children) : super(children);

  final List<String> log = <String>[];

  @override
  void didFinishLayout(int firstIndex, int lastIndex) {
    log.add('didFinishLayout firstIndex=$firstIndex lastIndex=$lastIndex');
  }
}

void main() {
  testWidgets('ListView default control', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new ListView(itemExtent: 100.0),
        ),
      ),
    );
  });

  testWidgets('ListView itemExtent control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          itemExtent: 200.0,
          children: new List<Widget>.generate(20, (int i) {
            return new Container(
              child: new Text('$i'),
            );
          }),
        ),
      ),
    );

    final RenderBox box = tester.renderObject<RenderBox>(find.byType(Container).first);
    expect(box.size.height, equals(200.0));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0.0, -250.0));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsNothing);
    expect(find.text('6'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0.0, 200.0));
    await tester.pump();

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('ListView large scroll jump', (WidgetTester tester) async {
    final List<int> log = <int>[];

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          itemExtent: 200.0,
          children: new List<Widget>.generate(20, (int i) {
            return new Builder(
              builder: (BuildContext context) {
                log.add(i);
                return new Container(
                  child: new Text('$i'),
                );
              }
            );
          }),
        ),
      ),
    );

    expect(log, equals(<int>[0, 1, 2]));
    log.clear();

    final ScrollableState state = tester.state(find.byType(Scrollable));
    final ScrollPosition position = state.position;
    position.jumpTo(2025.0);

    expect(log, isEmpty);
    await tester.pump();

    expect(log, equals(<int>[10, 11, 12, 13]));
    log.clear();

    position.jumpTo(975.0);

    expect(log, isEmpty);
    await tester.pump();

    expect(log, equals(<int>[4, 5, 6, 7]));
    log.clear();
  });

  testWidgets('ListView can build out of underflow', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          itemExtent: 100.0,
        ),
      ),
    );

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          itemExtent: 100.0,
          children: new List<Widget>.generate(2, (int i) {
            return new Container(
              child: new Text('$i'),
            );
          }),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          itemExtent: 100.0,
          children: new List<Widget>.generate(5, (int i) {
            return new Container(
              child: new Text('$i'),
            );
          }),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('ListView can build out of overflow padding', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new SizedBox(
            width: 0.0,
            height: 0.0,
            child: new ListView(
              padding: const EdgeInsets.all(8.0),
              children: const <Widget>[
                const Text('padded', textDirection: TextDirection.ltr),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('padded'), findsOneWidget);
  });

  testWidgets('ListView with itemExtent in unbounded context', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new SingleChildScrollView(
          child: new ListView(
            itemExtent: 100.0,
            shrinkWrap: true,
            children: new List<Widget>.generate(20, (int i) {
              return new Container(
                child: new Text('$i'),
              );
            }),
          ),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);
    expect(find.text('19'), findsOneWidget);
  });

  testWidgets('didFinishLayout has correct indices', (WidgetTester tester) async {
    final TestSliverChildListDelegate delegate = new TestSliverChildListDelegate(
      new List<Widget>.generate(20, (int i) {
        return new Container(
          child: new Text('$i', textDirection: TextDirection.ltr),
        );
      })
    );

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView.custom(
          itemExtent: 110.0,
          childrenDelegate: delegate,
        ),
      ),
    );

    expect(delegate.log, equals(<String>['didFinishLayout firstIndex=0 lastIndex=5']));
    delegate.log.clear();

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView.custom(
          itemExtent: 210.0,
          childrenDelegate: delegate,
        ),
      ),
    );

    expect(delegate.log, equals(<String>['didFinishLayout firstIndex=0 lastIndex=2']));
    delegate.log.clear();

    await tester.drag(find.byType(ListView), const Offset(0.0, -600.0));

    expect(delegate.log, isEmpty);

    await tester.pump();

    expect(delegate.log, equals(<String>['didFinishLayout firstIndex=2 lastIndex=5']));
    delegate.log.clear();
  });

  testWidgets('ListView automatically pad MediaQuery on axis', (WidgetTester tester) async {
    EdgeInsets innerMediaQueryPadding;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new MediaQuery(
          data: const MediaQueryData(
            padding: const EdgeInsets.all(30.0),
          ),
          child: new ListView(
            children: <Widget>[
              const Text('top', textDirection: TextDirection.ltr),
              new Builder(builder: (BuildContext context) {
                innerMediaQueryPadding = MediaQuery.of(context).padding;
                return new Container();
              }),
            ],
          ),
        ),
      ),
    );
    // Automatically apply the top/bottom padding into sliver.
    expect(tester.getTopLeft(find.text('top')).dy, 30.0);
    // Leave left/right padding as is for children.
    expect(innerMediaQueryPadding, const EdgeInsets.symmetric(horizontal: 30.0));
  });
}
