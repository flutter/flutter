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

  Widget mouseRegionInner({bool hovered, void Function(bool) setHovered}) {
    return Container(
      width: 10,
      height: 10,
      child: MouseRegion(
        onEnter: (_) { setHovered(true); },
        onExit: (_) { setHovered(false); },
        child: hovered ? const Text('hover inner') : const Text('unhover inner'),
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
  });

  testWidgets('detach', (WidgetTester tester) async {
    bool hovered = true;

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(5, 5));
    addTearDown(gesture.removePointer);

    await tester.pumpWidget(
      StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
        return scaffold(children: <Widget>[
          mouseRegionInner(
            hovered: hovered,
            setHovered: (bool value) { print(value); setState(() { hovered = value; }); }
          ),
          outerText(hovered: hovered),
        ]);
      }),
    );

    expect(find.text('hover outer'), findsOneWidget);
    expect(find.text('hover inner'), findsOneWidget);

    // Throws
    await tester.pumpWidget(
      StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
        return scaffold(children: <Widget>[
          outerText(hovered: hovered),
        ]);
      }),
    );

    // expect(find.text('hover outer'), findsOneWidget);

    // await tester.pump();

    // expect(find.text('unhover outer'), findsOneWidget);
  });
}
