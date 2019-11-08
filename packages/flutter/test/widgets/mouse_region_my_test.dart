import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';

void main() {
  testWidgets('detects pointer enter', (WidgetTester tester) async {
    bool hovered = false;
    StateSetter mySetState;

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(5, 5));
    addTearDown(gesture.removePointer);

    await tester.pumpWidget(
      StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
        mySetState = setState;
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            width: 100,
            height: 100,
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 10,
                  height: 10,
                  child: MouseRegion(
                    onEnter: (_) { setState(() { hovered = true; }); },
                    onExit: (_) { setState(() { hovered = false; }); },
                    child: hovered ? const Text('hover outer') : const Text('unhover outer'),
                  ),
                ),
                if (hovered) const Text('hover inner') else const Text('unhover inner'),
              ],
            ),
          ),
        );
      }),
    );

    expect(find.text('unhover outer'), findsOneWidget);
    expect(find.text('unhover inner'), findsOneWidget);

    await tester.pump();

    expect(find.text('hover outer'), findsOneWidget);
    expect(find.text('hover inner'), findsOneWidget);
  });
}
