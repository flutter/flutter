import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';

void main() {

  Widget scaffold({List<Widget> children}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: 100,
        height: 100,
        alignment: Alignment.topLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget mouseRegionInner({
    bool hovered,
    @required void Function(bool) setHovered,
    VoidCallback onDispose,
  }) {
    return Container(
      width: 10,
      height: 10,
      child: MouseRegion(
        onEnter: (_) { setHovered(true); },
        onExit: (_) { setHovered(false); },
        child: hovered ? const Text('hover inner') : const Text('unhover inner'),
        onExitOrDispose: (bool disposed, _) {
          if (disposed && onDispose != null)
            onDispose();
        },
      ),
    );
  }

  Widget outerText({bool hovered}) {
    return hovered ? const Text('hover outer') : const Text('unhover outer');
  }

  testWidgets('startup', (WidgetTester tester) async {
    bool hovered = false;

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(5, 5));
    addTearDown(gesture.removePointer);

    await tester.pumpWidget(
      StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
        return scaffold(children: <Widget>[
          mouseRegionInner(
            hovered: hovered,
            setHovered: (bool value) { setState(() { hovered = value; }); }
          ),
          outerText(hovered: hovered),
        ]);
      }),
    );

    expect(find.text('unhover outer'), findsOneWidget);
    expect(find.text('unhover inner'), findsOneWidget);

    await tester.pump();

    expect(find.text('hover outer'), findsOneWidget);
    expect(find.text('hover inner'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('attach', (WidgetTester tester) async {
    bool hovered = false;

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(5, 5));
    addTearDown(gesture.removePointer);

    await tester.pumpWidget(
      StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
        return scaffold(children: <Widget>[
          outerText(hovered: hovered),
        ]);
      }),
    );

    expect(find.text('unhover outer'), findsOneWidget);

    await tester.pumpWidget(
      StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
        return scaffold(children: <Widget>[
          mouseRegionInner(
            hovered: hovered,
            setHovered: (bool value) { setState(() { hovered = value; }); }
          ),
          outerText(hovered: hovered),
        ]);
      }),
    );

    expect(find.text('unhover outer'), findsOneWidget);
    expect(find.text('unhover inner'), findsOneWidget);

    await tester.pump();

    expect(find.text('hover outer'), findsOneWidget);
    expect(find.text('hover inner'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('detaching widget should not throw', (WidgetTester tester) async {
    bool hovered = true;

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(5, 5));
    addTearDown(gesture.removePointer);

    await tester.pumpWidget(
      StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
        return scaffold(children: <Widget>[
          mouseRegionInner(
            hovered: hovered,
            setHovered: (bool value) { print('setHovered $value'); setState(() { hovered = value; }); },
            onDispose: () { print('onDispose'); setState(() { hovered = false; }); },
          ),
          outerText(hovered: hovered),
        ]);
      }),
    );

    expect(find.text('hover outer'), findsOneWidget);
    expect(find.text('hover inner'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pump();
    expect(find.text('hover outer'), findsOneWidget);
    expect(find.text('hover inner'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(
      StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
        return scaffold(children: <Widget>[
          outerText(hovered: hovered),
        ]);
      }),
    );

    expect(find.text('hover outer'), findsOneWidget);

    await tester.pump();

    expect(find.text('unhover outer'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('move', (WidgetTester tester) async {
    bool hovered = false;
    bool moved = false;
    StateSetter mySetState;

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(5, 5));
    addTearDown(gesture.removePointer);

    await tester.pumpWidget(
      StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
        mySetState = setState;
        return scaffold(children: <Widget>[
          Container(
            height: 100,
            width: 10,
            alignment: moved ? Alignment.topLeft : Alignment.bottomLeft,
            child: mouseRegionInner(
              hovered: hovered,
              setHovered: (bool value) { setState(() { hovered = value; }); }
            ),
          ),
          outerText(hovered: hovered),
        ]);
      }),
    );

    expect(find.text('unhover inner'), findsOneWidget);
    expect(find.text('unhover outer'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);

    mySetState(() { moved = true; });
    await tester.pump();
    expect(find.text('unhover inner'), findsOneWidget);
    expect(find.text('unhover outer'), findsOneWidget);

    await tester.pump();
    expect(find.text('hover inner'), findsOneWidget);
    expect(find.text('hover outer'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
