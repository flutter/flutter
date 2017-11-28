// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart' hide TypeMatcher;

// This is a regression test for https://github.com/flutter/flutter/issues/5588.

class OrderSwitcher extends StatefulWidget {
  const OrderSwitcher({ Key key, this.a, this.b }) : super(key: key);

  final Widget a;
  final Widget b;

  @override
  OrderSwitcherState createState() => new OrderSwitcherState();
}

class OrderSwitcherState extends State<OrderSwitcher> {

  bool _aFirst = true;

  void switchChildren() {
    setState(() {
      _aFirst = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    if (_aFirst) {
      children.add(new KeyedSubtree(child: widget.a));
      children.add(widget.b);
    } else {
      children.add(new KeyedSubtree(child: widget.b));
      children.add(widget.a);
    }
    return new Stack(
      textDirection: TextDirection.ltr,
      children: children,
    );
  }
}

class DummyStatefulWidget extends StatefulWidget {
  const DummyStatefulWidget(Key key) : super(key: key);

  @override
  DummyStatefulWidgetState createState() => new DummyStatefulWidgetState();
}

class DummyStatefulWidgetState extends State<DummyStatefulWidget> {
  @override
  Widget build(BuildContext context) => const Text('LEAF', textDirection: TextDirection.ltr);
}

class RekeyableDummyStatefulWidgetWrapper extends StatefulWidget {
  const RekeyableDummyStatefulWidgetWrapper({ this.child, this.initialKey });
  final Widget child;
  final GlobalKey initialKey;
  @override
  RekeyableDummyStatefulWidgetWrapperState createState() => new RekeyableDummyStatefulWidgetWrapperState();
}

class RekeyableDummyStatefulWidgetWrapperState extends State<RekeyableDummyStatefulWidgetWrapper> {
  GlobalKey _key;

  @override
  void initState() {
    super.initState();
    _key = widget.initialKey;
  }

  void _setChild(GlobalKey value) {
    setState(() {
      _key = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new DummyStatefulWidget(_key);
  }
}

void main() {
  testWidgets('Handle GlobalKey reparenting in weird orders', (WidgetTester tester) async {

    // This is a bit of a weird test so let's try to explain it a bit.
    //
    // Basically what's happening here is that we have a complicated tree, and
    // in one frame, we change it to a slightly different tree with a specific
    // set of mutations:
    //
    // * The keyA subtree is regrafted to be one level higher, but later than
    //   the keyB subtree.
    // * The keyB subtree is, similarly, moved one level deeper, but earlier, than
    //   the keyA subtree.
    // * The keyD subtree is replaced by the previously earlier and shallower
    //   keyC subtree. This happens during a LayoutBuilder layout callback, so it
    //   happens long after A and B have finished their dance.
    //
    // The net result is that when keyC is moved, it has already been marked
    // dirty from being removed then reinserted into the tree (redundantly, as
    // it turns out, though this isn't known at the time), and has already been
    // visited once by the code that tries to clean nodes (though at that point
    // nothing happens since it isn't in the tree).
    //
    // This test verifies that none of the asserts go off during this dance.

    final GlobalKey<OrderSwitcherState> keyRoot = new GlobalKey(debugLabel: 'Root');
    final GlobalKey keyA = new GlobalKey(debugLabel: 'A');
    final GlobalKey keyB = new GlobalKey(debugLabel: 'B');
    final GlobalKey keyC = new GlobalKey(debugLabel: 'C');
    final GlobalKey keyD = new GlobalKey(debugLabel: 'D');
    await tester.pumpWidget(new OrderSwitcher(
      key: keyRoot,
      a: new KeyedSubtree(
        key: keyA,
        child: new RekeyableDummyStatefulWidgetWrapper(
          initialKey: keyC
        ),
      ),
      b: new KeyedSubtree(
        key: keyB,
        child: new Builder(
          builder: (BuildContext context) {
            return new Builder(
              builder: (BuildContext context) {
                return new Builder(
                  builder: (BuildContext context) {
                    return new LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        return new RekeyableDummyStatefulWidgetWrapper(
                          initialKey: keyD
                        );
                      }
                    );
                  }
                );
              }
            );
          }
        )
      ),
    ));

    expect(find.byKey(keyA), findsOneWidget);
    expect(find.byKey(keyB), findsOneWidget);
    expect(find.byKey(keyC), findsOneWidget);
    expect(find.byKey(keyD), findsOneWidget);
    expect(find.byType(RekeyableDummyStatefulWidgetWrapper), findsNWidgets(2));
    expect(find.byType(DummyStatefulWidget), findsNWidgets(2));

    keyRoot.currentState.switchChildren();
    final List<State> states = tester.stateList(find.byType(RekeyableDummyStatefulWidgetWrapper)).toList();
    final RekeyableDummyStatefulWidgetWrapperState a = states[0]; a._setChild(null);
    final RekeyableDummyStatefulWidgetWrapperState b = states[1]; b._setChild(keyC);
    await tester.pump();

    expect(find.byKey(keyA), findsOneWidget);
    expect(find.byKey(keyB), findsOneWidget);
    expect(find.byKey(keyC), findsOneWidget);
    expect(find.byKey(keyD), findsNothing);
    expect(find.byType(RekeyableDummyStatefulWidgetWrapper), findsNWidgets(2));
    expect(find.byType(DummyStatefulWidget), findsNWidgets(2));
  });
}
