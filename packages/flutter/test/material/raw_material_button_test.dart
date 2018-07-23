import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('materialTapTargetSize.padded expands hit test area', (WidgetTester tester) async {
    int pressed = 0;

    await tester.pumpWidget(new RawMaterialButton(
      onPressed: () {
        pressed++;
      },
      constraints: new BoxConstraints.tight(const Size(10.0, 10.0)),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      child: const Text('+', textDirection: TextDirection.ltr),
    ));

    await tester.tapAt(const Offset(40.0, 400.0));

    expect(pressed, 1);
  });

  testWidgets('materialTapTargetSize.padded expands semantics area', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await tester.pumpWidget(
      new Center(
        child: new RawMaterialButton(
          onPressed: () {},
          constraints: new BoxConstraints.tight(const Size(10.0, 10.0)),
          materialTapTargetSize: MaterialTapTargetSize.padded,
          child: const Text('+', textDirection: TextDirection.ltr),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
        new TestSemantics(
          id: 1,
          flags: <SemanticsFlag>[
            SemanticsFlag.isButton,
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.isEnabled,
          ],
          actions: <SemanticsAction>[
            SemanticsAction.tap,
          ],
          label: '+',
          textDirection: TextDirection.ltr,
          rect: Rect.fromLTRB(0.0, 0.0, 48.0, 48.0),
          children: <TestSemantics>[],
        ),
      ]
    ), ignoreTransform: true));

    semantics.dispose();
  });

  testWidgets('Ink splash from center tap originates in correct location', (WidgetTester tester) async {
    const Color highlightColor = Color(0xAAFF0000);
    const Color splashColor = Color(0xAA0000FF);
    const Color fillColor = Color(0xFFEF5350);

    await tester.pumpWidget(
      new Center(
        child: new RawMaterialButton(
          materialTapTargetSize: MaterialTapTargetSize.padded,
          onPressed: () {},
          fillColor: fillColor,
          highlightColor: highlightColor,
          splashColor: splashColor,
          child: const SizedBox(),
        ),
      ),
    );

    final Offset center = tester.getCenter(find.byType(InkWell));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // start gesture
    await tester.pump(const Duration(milliseconds: 200)); // wait for splash to be well under way

    final RenderBox box = Material.of(tester.element(find.byType(InkWell))) as dynamic;
    // centered in material button.
    expect(box, paints..circle(x: 44.0, y: 18.0, color: splashColor));
    await gesture.up();
  });

  testWidgets('Ink splash from tap above material originates in correct location', (WidgetTester tester) async {
    const Color highlightColor = Color(0xAAFF0000);
    const Color splashColor = Color(0xAA0000FF);
    const Color fillColor = Color(0xFFEF5350);

    await tester.pumpWidget(
      new Center(
        child: new RawMaterialButton(
          materialTapTargetSize: MaterialTapTargetSize.padded,
          onPressed: () {},
          fillColor: fillColor,
          highlightColor: highlightColor,
          splashColor: splashColor,
          child: const SizedBox(),
        ),
      ),
    );

    final Offset top = tester.getRect(find.byType(InkWell)).topCenter;
    final TestGesture gesture = await tester.startGesture(top);
    await tester.pump(); // start gesture
    await tester.pump(const Duration(milliseconds: 200)); // wait for splash to be well under way
    final RenderBox box = Material.of(tester.element(find.byType(InkWell))) as dynamic;
    // paints above above material
    expect(box, paints..circle(x: 44.0, y: 0.0, color: splashColor));
    await gesture.up();
  });

  testWidgets('off-center child is hit testable', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            new RawMaterialButton(
            materialTapTargetSize: MaterialTapTargetSize.padded,
            onPressed: () {},
            child: new Container(
              width: 400.0,
              height: 400.0,
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const <Widget>[
                  SizedBox(
                    height: 50.0,
                    width: 400.0,
                    child: Text('Material'),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
    expect(find.text('Material').hitTestable(), findsOneWidget);
  });

  testWidgets('smaller child is hit testable', (WidgetTester tester) async {
    const Key key = Key('test');
    await tester.pumpWidget(
      new MaterialApp(
        home: new Column(
          children: <Widget>[
            new RawMaterialButton(
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onPressed: () {},
              child: new SizedBox(
                key: key,
                width: 8.0,
                height: 8.0,
                child: new Container(
                  color: const Color(0xFFAABBCC),
                ),
              ),
            ),
        ]),
      ),
    );
    expect(find.byKey(key).hitTestable(), findsOneWidget);
  });

  testWidgets('RawMaterialButton can be expanded by parent constraints', (WidgetTester tester) async {
    const Key key = Key('test');
    await tester.pumpWidget(
      new MaterialApp(
        home: new Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new RawMaterialButton(
              key: key,
              onPressed: () {},
              child: const SizedBox(),
            )
          ],
        ),
      ),
    );

    expect(tester.getSize(find.byKey(key)), const Size(800.0, 48.0));
  });
}
