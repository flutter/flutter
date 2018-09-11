// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import '../rendering/mock_canvas.dart';

class TestSliverChildListDelegate extends SliverChildListDelegate {
  TestSliverChildListDelegate(List<Widget> children) : super(children);

  final List<String> log = <String>[];

  @override
  void didFinishLayout(int firstIndex, int lastIndex) {
    log.add('didFinishLayout firstIndex=$firstIndex lastIndex=$lastIndex');
  }
}

class Alive extends StatefulWidget {
  const Alive(this.alive, this.index);
  final bool alive;
  final int index;

  @override
  AliveState createState() => new AliveState();

  @override
  String toString({DiagnosticLevel minLevel}) => '$index $alive';
}

class AliveState extends State<Alive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.alive;

  @override
  Widget build(BuildContext context) =>
     new Text('${widget.index}:$wantKeepAlive');
}

typedef WhetherToKeepAlive = bool Function(int);
class _StatefulListView extends StatefulWidget {
  const _StatefulListView(this.aliveCallback);

  final WhetherToKeepAlive aliveCallback;
  @override
  _StatefulListViewState createState() => new _StatefulListViewState();
}

class _StatefulListViewState extends State<_StatefulListView> {
  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      // force a rebuild - the test(s) using this are verifying that the list is
      // still correct after rebuild
      onTap: () => setState,
      child: new Directionality(
        textDirection: TextDirection.ltr,
        child: new ListView(
          children: new List<Widget>.generate(200, (int i) {
            return new Builder(
              builder: (BuildContext context) {
                return new Container(
                  child: new Alive(widget.aliveCallback(i), i),
                );
              },
            );
          }),
        ),
      ),
    );
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
              },
            );
          }),
        ),
      ),
    );

    expect(log, equals(<int>[0, 1, 2, 3, 4]));
    log.clear();

    final ScrollableState state = tester.state(find.byType(Scrollable));
    final ScrollPosition position = state.position;
    position.jumpTo(2025.0);

    expect(log, isEmpty);
    await tester.pump();

    expect(log, equals(<int>[8, 9, 10, 11, 12, 13, 14]));
    log.clear();

    position.jumpTo(975.0);

    expect(log, isEmpty);
    await tester.pump();

    expect(log, equals(<int>[7, 6, 5, 4, 3]));
    log.clear();
  });

  testWidgets('ListView large scroll jump and keepAlive first child not keepAlive', (WidgetTester tester) async {
    Future<Null> checkAndScroll([String zero = '0:false']) async {
      expect(find.text(zero), findsOneWidget);
      expect(find.text('1:false'), findsOneWidget);
      expect(find.text('2:false'), findsOneWidget);
      expect(find.text('3:true'), findsOneWidget);
      expect(find.text('116:false'), findsNothing);
      final ScrollableState state = tester.state(find.byType(Scrollable));
      final ScrollPosition position = state.position;
      position.jumpTo(1025.0);

      await tester.pump();

      expect(find.text(zero), findsNothing);
      expect(find.text('1:false'), findsNothing);
      expect(find.text('2:false'), findsNothing);
      expect(find.text('3:true', skipOffstage: false), findsOneWidget);
      expect(find.text('116:false'), findsOneWidget);

      await tester.tapAt(const Offset(100.0, 100.0));
      position.jumpTo(0.0);
      await tester.pump();
      await tester.pump();

      expect(find.text(zero), findsOneWidget);
      expect(find.text('1:false'), findsOneWidget);
      expect(find.text('2:false'), findsOneWidget);
      expect(find.text('3:true'), findsOneWidget);
    }

    await tester.pumpWidget(new _StatefulListView((int i) => i > 2 && i % 3 == 0));
    await checkAndScroll();

    await tester.pumpWidget(new _StatefulListView((int i) => i % 3 == 0));
    await checkAndScroll('0:true');
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
                Text('padded', textDirection: TextDirection.ltr),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('padded', skipOffstage: false), findsOneWidget);
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
      new List<Widget>.generate(
        20,
        (int i) {
          return new Container(
            child: new Text('$i', textDirection: TextDirection.ltr),
          );
        },
      )
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

    expect(delegate.log, equals(<String>['didFinishLayout firstIndex=0 lastIndex=7']));
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

    expect(delegate.log, equals(<String>['didFinishLayout firstIndex=0 lastIndex=4']));
    delegate.log.clear();

    await tester.drag(find.byType(ListView), const Offset(0.0, -600.0));

    expect(delegate.log, isEmpty);

    await tester.pump();

    expect(delegate.log, equals(<String>['didFinishLayout firstIndex=1 lastIndex=6']));
    delegate.log.clear();
  });

  testWidgets('ListView automatically pad MediaQuery on axis', (WidgetTester tester) async {
    EdgeInsets innerMediaQueryPadding;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.all(30.0),
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

  testWidgets('ListView clips if overflow is smaller than cacheExtent', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/17426.

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new Container(
            height: 200.0,
            child: new ListView(
              cacheExtent: 500.0,
              children: <Widget>[
                new Container(
                  height: 90.0,
                ),
                new Container(
                  height: 110.0,
                ),
                new Container(
                  height: 80.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Viewport), paints..clipRect());
  });

  testWidgets('ListView does not clips if no overflow', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new Container(
            height: 200.0,
            child: new ListView(
              cacheExtent: 500.0,
              children: <Widget>[
                new Container(
                  height: 100.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Viewport), isNot(paints..clipRect()));
  });

  testWidgets('ListView (fixed extent) clips if overflow is smaller than cacheExtent', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/17426.

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new Container(
            height: 200.0,
            child: new ListView(
              itemExtent: 100.0,
              cacheExtent: 500.0,
              children: <Widget>[
                new Container(
                  height: 100.0,
                ),
                new Container(
                  height: 100.0,
                ),
                new Container(
                  height: 100.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Viewport), paints..clipRect());
  });

  testWidgets('ListView (fixed extent) does not clips if no overflow', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new Container(
            height: 200.0,
            child: new ListView(
              itemExtent: 100.0,
              cacheExtent: 500.0,
              children: <Widget>[
                new Container(
                  height: 100.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Viewport), isNot(paints..clipRect()));
  });
}
