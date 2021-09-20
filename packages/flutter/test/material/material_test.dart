// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/test_border.dart' show TestBorder;

class NotifyMaterial extends StatelessWidget {
  const NotifyMaterial({ Key? key }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    LayoutChangedNotification().dispatch(context);
    return Container();
  }
}

Widget buildMaterial({
  double elevation = 0.0,
  Color shadowColor = const Color(0xFF00FF00),
  Color color = const Color(0xFF0000FF),
}) {
  return Center(
    child: SizedBox(
      height: 100.0,
      width: 100.0,
      child: Material(
        color: color,
        shadowColor: shadowColor,
        elevation: elevation,
        shape: const CircleBorder(),
      ),
    ),
  );
}

RenderPhysicalShape getModel(WidgetTester tester) {
  return tester.renderObject(find.byType(PhysicalShape));
}

class PaintRecorder extends CustomPainter {
  PaintRecorder(this.log);

  final List<Size> log;

  @override
  void paint(Canvas canvas, Size size) {
    log.add(size);
    final Paint paint = Paint()..color = const Color(0xFF0000FF);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(PaintRecorder oldDelegate) => false;
}

class ElevationColor {
  const ElevationColor(this.elevation, this.color);
  final double elevation;
  final Color color;
}

void main() {
  // Regression test for https://github.com/flutter/flutter/issues/81504
  testWidgets('MaterialApp.home nullable and update test', (WidgetTester tester) async {
    // _WidgetsAppState._usesNavigator == true
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    // _WidgetsAppState._usesNavigator == false
    await tester.pumpWidget(const MaterialApp()); // Do not crash!

    // _WidgetsAppState._usesNavigator == true
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink())); // Do not crash!

    expect(tester.takeException(), null);
  });

  testWidgets('default Material debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const Material().debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>['type: canvas']);
  });

  testWidgets('Material implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const Material(
      type: MaterialType.canvas,
      color: Color(0xFFFFFFFF),
      shadowColor: Color(0xffff0000),
      textStyle: TextStyle(color: Color(0xff00ff00)),
      borderRadius: BorderRadiusDirectional.all(Radius.circular(10)),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[
      'type: canvas',
      'color: Color(0xffffffff)',
      'shadowColor: Color(0xffff0000)',
      'textStyle.inherit: true',
      'textStyle.color: Color(0xff00ff00)',
      'borderRadius: BorderRadiusDirectional.circular(10.0)',
    ]);
  });

  testWidgets('LayoutChangedNotification test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Material(
        child: NotifyMaterial(),
      ),
    );
  });

  testWidgets('ListView scroll does not repaint', (WidgetTester tester) async {
    final List<Size> log = <Size>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            SizedBox(
              width: 150.0,
              height: 150.0,
              child: CustomPaint(
                painter: PaintRecorder(log),
              ),
            ),
            Expanded(
              child: Material(
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: ListView(
                        children: <Widget>[
                          Container(
                            height: 2000.0,
                            color: const Color(0xFF00FF00),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 100.0,
                      height: 100.0,
                      child: CustomPaint(
                        painter: PaintRecorder(log),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // We paint twice because we have two CustomPaint widgets in the tree above
    // to test repainting both inside and outside the Material widget.
    expect(log, equals(<Size>[
      const Size(150.0, 150.0),
      const Size(100.0, 100.0),
    ]));
    log.clear();

    await tester.drag(find.byType(ListView), const Offset(0.0, -300.0));
    await tester.pump();

    expect(log, isEmpty);
  });

  testWidgets('Shadows animate smoothly', (WidgetTester tester) async {
    // This code verifies that the PhysicalModel's elevation animates over
    // a kThemeChangeDuration time interval.

    await tester.pumpWidget(buildMaterial(elevation: 0.0));
    final RenderPhysicalShape modelA = getModel(tester);
    expect(modelA.elevation, equals(0.0));

    await tester.pumpWidget(buildMaterial(elevation: 9.0));
    final RenderPhysicalShape modelB = getModel(tester);
    expect(modelB.elevation, equals(0.0));

    await tester.pump(const Duration(milliseconds: 1));
    final RenderPhysicalShape modelC = getModel(tester);
    expect(modelC.elevation, moreOrLessEquals(0.0, epsilon: 0.001));

    await tester.pump(kThemeChangeDuration ~/ 2);
    final RenderPhysicalShape modelD = getModel(tester);
    expect(modelD.elevation, isNot(moreOrLessEquals(0.0, epsilon: 0.001)));

    await tester.pump(kThemeChangeDuration);
    final RenderPhysicalShape modelE = getModel(tester);
    expect(modelE.elevation, equals(9.0));
  });

  testWidgets('Shadow colors animate smoothly', (WidgetTester tester) async {
    // This code verifies that the PhysicalModel's shadowColor animates over
    // a kThemeChangeDuration time interval.

    await tester.pumpWidget(buildMaterial(shadowColor: const Color(0xFF00FF00)));
    final RenderPhysicalShape modelA = getModel(tester);
    expect(modelA.shadowColor, equals(const Color(0xFF00FF00)));

    await tester.pumpWidget(buildMaterial(shadowColor: const Color(0xFFFF0000)));
    final RenderPhysicalShape modelB = getModel(tester);
    expect(modelB.shadowColor, equals(const Color(0xFF00FF00)));

    await tester.pump(const Duration(milliseconds: 1));
    final RenderPhysicalShape modelC = getModel(tester);
    expect(modelC.shadowColor, within<Color>(distance: 1, from: const Color(0xFF00FF00)));

    await tester.pump(kThemeChangeDuration ~/ 2);
    final RenderPhysicalShape modelD = getModel(tester);
    expect(modelD.shadowColor, isNot(within<Color>(distance: 1, from: const Color(0xFF00FF00))));

    await tester.pump(kThemeChangeDuration);
    final RenderPhysicalShape modelE = getModel(tester);
    expect(modelE.shadowColor, equals(const Color(0xFFFF0000)));
  });

  testWidgets('Transparent material widget does not absorb hit test', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/58665.
    bool pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  pressed = true;
                },
                child: null,
              ),
              const Material(
                type: MaterialType.transparency,
                child: SizedBox(
                  width: 400.0,
                  height: 500.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    expect(pressed, isTrue);
  });

  group('Elevation Overlay', () {

    testWidgets('applyElevationOverlayColor set to false does not change surface color', (WidgetTester tester) async {
      const Color surfaceColor = Color(0xFF121212);
      await tester.pumpWidget(Theme(
          data: ThemeData(
            applyElevationOverlayColor: false,
            colorScheme: const ColorScheme.dark().copyWith(surface: surfaceColor),
          ),
          child: buildMaterial(color: surfaceColor, elevation: 8.0),
      ));
      final RenderPhysicalShape model = getModel(tester);
      expect(model.color, equals(surfaceColor));
    });

    testWidgets('applyElevationOverlayColor set to true applies a semi-transparent onSurface color to the surface color', (WidgetTester tester) async {
      const Color surfaceColor = Color(0xFF121212);
      const Color onSurfaceColor = Colors.greenAccent;

      // The colors we should get with a base surface color of 0xFF121212 for
      // and a given elevation
      const List<ElevationColor> elevationColors = <ElevationColor>[
        ElevationColor(0.0, Color(0xFF121212)),
        ElevationColor(1.0, Color(0xFF161D19)),
        ElevationColor(2.0, Color(0xFF18211D)),
        ElevationColor(3.0, Color(0xFF19241E)),
        ElevationColor(4.0, Color(0xFF1A2620)),
        ElevationColor(6.0, Color(0xFF1B2922)),
        ElevationColor(8.0, Color(0xFF1C2C24)),
        ElevationColor(12.0, Color(0xFF1D3027)),
        ElevationColor(16.0, Color(0xFF1E3329)),
        ElevationColor(24.0, Color(0xFF20362B)),
      ];

      for (final ElevationColor test in elevationColors) {
        await tester.pumpWidget(
            Theme(
              data: ThemeData(
                applyElevationOverlayColor: true,
                colorScheme: const ColorScheme.dark().copyWith(
                  surface: surfaceColor,
                  onSurface: onSurfaceColor,
                ),
              ),
              child: buildMaterial(
                color: surfaceColor,
                elevation: test.elevation,
              ),
            ),
        );
        await tester.pumpAndSettle(); // wait for the elevation animation to finish
        final RenderPhysicalShape model = getModel(tester);
        expect(model.color, equals(test.color));
      }
    });

    testWidgets('overlay will not apply to materials using a non-surface color', (WidgetTester tester) async {
      await tester.pumpWidget(
        Theme(
          data: ThemeData(
            applyElevationOverlayColor: true,
            colorScheme: const ColorScheme.dark(),
          ),
          child: buildMaterial(
            color: Colors.cyan,
            elevation: 8.0,
          ),
        ),
      );
      final RenderPhysicalShape model = getModel(tester);
      // Shouldn't change, as it is not using a ColorScheme.surface color
      expect(model.color, equals(Colors.cyan));
    });

    testWidgets('overlay will not apply to materials using a light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
          Theme(
            data: ThemeData(
              applyElevationOverlayColor: true,
              colorScheme: const ColorScheme.light(),
            ),
            child: buildMaterial(
              color: Colors.cyan,
              elevation: 8.0,
            ),
          ),
      );
      final RenderPhysicalShape model = getModel(tester);
      // Shouldn't change, as it was under a light color scheme.
      expect(model.color, equals(Colors.cyan));
    });

    testWidgets('overlay will apply to materials with a non-opaque surface color', (WidgetTester tester) async {
      const Color surfaceColor = Color(0xFF121212);
      const Color surfaceColorWithOverlay = Color(0xC6353535);

      await tester.pumpWidget(
        Theme(
          data: ThemeData(
            applyElevationOverlayColor: true,
            colorScheme: const ColorScheme.dark(surface: surfaceColor),
          ),
          child: buildMaterial(
            color: surfaceColor.withOpacity(.75),
            elevation: 8.0,
          ),
        ),
      );

      final RenderPhysicalShape model = getModel(tester);
      expect(model.color, equals(surfaceColorWithOverlay));
      expect(model.color, isNot(equals(surfaceColor)));
    });

    testWidgets('Expected overlay color can be computed using colorWithOverlay', (WidgetTester tester) async {
      const Color surfaceColor = Color(0xFF123456);
      const Color onSurfaceColor = Color(0xFF654321);
      const double elevation = 8.0;

      final Color surfaceColorWithOverlay =
        ElevationOverlay.colorWithOverlay(surfaceColor, onSurfaceColor, elevation);

      await tester.pumpWidget(
        Theme(
          data: ThemeData(
            applyElevationOverlayColor: true,
            colorScheme: const ColorScheme.dark(
              surface: surfaceColor,
              onSurface: onSurfaceColor,
            ),
          ),
          child: buildMaterial(
            color: surfaceColor,
            elevation: elevation,
          ),
        ),
      );

      final RenderPhysicalShape model = getModel(tester);
      expect(model.color, equals(surfaceColorWithOverlay));
      expect(model.color, isNot(equals(surfaceColor)));
    });
  });

  group('Transparency clipping', () {
    testWidgets('No clip by default', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
          Material(
            key: materialKey,
            type: MaterialType.transparency,
            child: const SizedBox(width: 100.0, height: 100.0),
          ),
      );

      expect(find.byKey(materialKey), hasNoImmediateClip);
    });

    testWidgets('clips to bounding rect by default given Clip.antiAlias', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.transparency,
          clipBehavior: Clip.antiAlias,
          child: const SizedBox(width: 100.0, height: 100.0),
        ),
      );

      expect(find.byKey(materialKey), clipsWithBoundingRect);
    });

    testWidgets('clips to rounded rect when borderRadius provided given Clip.antiAlias', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.transparency,
          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
          clipBehavior: Clip.antiAlias,
          child: const SizedBox(width: 100.0, height: 100.0),
        ),
      );

      expect(
        find.byKey(materialKey),
        clipsWithBoundingRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
        ),
      );
    });

    testWidgets('clips to shape when provided given Clip.antiAlias', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.transparency,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: const SizedBox(width: 100.0, height: 100.0),
        ),
      );

      expect(
        find.byKey(materialKey),
        clipsWithShapeBorder(
          shape: const StadiumBorder(),
        ),
      );
    });

    testWidgets('supports directional clips', (WidgetTester tester) async {
      final List<String> logs = <String>[];
      final ShapeBorder shape = TestBorder((String message) { logs.add(message); });
      Widget buildMaterial() {
        return Material(
          type: MaterialType.transparency,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: const SizedBox(width: 100.0, height: 100.0),
        );
      }
      final Widget material = buildMaterial();
      // verify that a regular clip works as one would expect
      logs.add('--0');
      await tester.pumpWidget(material);
      // verify that pumping again doesn't recompute the clip
      // even though the widget itself is new (the shape doesn't change identity)
      logs.add('--1');
      await tester.pumpWidget(buildMaterial());
      // verify that Material passes the TextDirection on to its shape when it's transparent
      logs.add('--2');
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: material,
      ));
      // verify that changing the text direction from LTR to RTL has an effect
      // even though the widget itself is identical
      logs.add('--3');
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.rtl,
        child: material,
      ));
      // verify that pumping again with a text direction has no effect
      logs.add('--4');
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.rtl,
        child: buildMaterial(),
      ));
      logs.add('--5');
      // verify that changing the text direction and the widget at the same time
      // works as expected
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: material,
      ));
      expect(logs, <String>[
        '--0',
        'getOuterPath Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) null',
        'paint Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) null',
        '--1',
        '--2',
        'getOuterPath Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.ltr',
        'paint Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.ltr',
        '--3',
        'getOuterPath Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.rtl',
        'paint Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.rtl',
        '--4',
        '--5',
        'getOuterPath Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.ltr',
        'paint Rect.fromLTRB(0.0, 0.0, 800.0, 600.0) TextDirection.ltr',
      ]);
    });
  });

  group('PhysicalModels', () {
    testWidgets('canvas', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.canvas,
          child: const SizedBox(width: 100.0, height: 100.0),
        ),
      );

      expect(find.byKey(materialKey), rendersOnPhysicalModel(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.zero,
          elevation: 0.0,
      ));
    });

    testWidgets('canvas with borderRadius and elevation', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.canvas,
          borderRadius: const BorderRadius.all(Radius.circular(5.0)),
          elevation: 1.0,
          child: const SizedBox(width: 100.0, height: 100.0),
        ),
      );

      expect(find.byKey(materialKey), rendersOnPhysicalModel(
          shape: BoxShape.rectangle,
          borderRadius: const BorderRadius.all(Radius.circular(5.0)),
          elevation: 1.0,
      ));
    });

    testWidgets('canvas with shape and elevation', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.canvas,
          shape: const StadiumBorder(),
          elevation: 1.0,
          child: const SizedBox(width: 100.0, height: 100.0),
        ),
      );

      expect(find.byKey(materialKey), rendersOnPhysicalShape(
          shape: const StadiumBorder(),
          elevation: 1.0,
      ));
    });

    testWidgets('card', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.card,
          child: const SizedBox(width: 100.0, height: 100.0),
        ),
      );

      expect(find.byKey(materialKey), rendersOnPhysicalModel(
          shape: BoxShape.rectangle,
          borderRadius: const BorderRadius.all(Radius.circular(2.0)),
          elevation: 0.0,
      ));
    });

    testWidgets('card with borderRadius and elevation', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.card,
          borderRadius: const BorderRadius.all(Radius.circular(5.0)),
          elevation: 5.0,
          child: const SizedBox(width: 100.0, height: 100.0),
        ),
      );

      expect(find.byKey(materialKey), rendersOnPhysicalModel(
          shape: BoxShape.rectangle,
          borderRadius: const BorderRadius.all(Radius.circular(5.0)),
          elevation: 5.0,
      ));
    });

    testWidgets('card with shape and elevation', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.card,
          shape: const StadiumBorder(),
          elevation: 5.0,
          child: const SizedBox(width: 100.0, height: 100.0),
        ),
      );

      expect(find.byKey(materialKey), rendersOnPhysicalShape(
          shape: const StadiumBorder(),
          elevation: 5.0,
      ));
    });

    testWidgets('circle', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.circle,
          color: const Color(0xFF0000FF),
          child: const SizedBox(width: 100.0, height: 100.0),
        ),
      );

      expect(find.byKey(materialKey), rendersOnPhysicalModel(
          shape: BoxShape.circle,
          elevation: 0.0,
      ));
    });

    testWidgets('button', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.button,
          color: const Color(0xFF0000FF),
          child: const SizedBox(width: 100.0, height: 100.0),
        ),
      );

      expect(find.byKey(materialKey), rendersOnPhysicalModel(
          shape: BoxShape.rectangle,
          borderRadius: const BorderRadius.all(Radius.circular(2.0)),
          elevation: 0.0,
      ));
    });

    testWidgets('button with elevation and borderRadius', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.button,
          color: const Color(0xFF0000FF),
          borderRadius: const BorderRadius.all(Radius.circular(6.0)),
          elevation: 4.0,
          child: const SizedBox(width: 100.0, height: 100.0),
        ),
      );

      expect(find.byKey(materialKey), rendersOnPhysicalModel(
          shape: BoxShape.rectangle,
          borderRadius: const BorderRadius.all(Radius.circular(6.0)),
          elevation: 4.0,
      ));
    });

    testWidgets('button with elevation and shape', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.button,
          color: const Color(0xFF0000FF),
          shape: const StadiumBorder(),
          elevation: 4.0,
          child: const SizedBox(width: 100.0, height: 100.0),
        ),
      );

      expect(find.byKey(materialKey), rendersOnPhysicalShape(
          shape: const StadiumBorder(),
          elevation: 4.0,
      ));
    });
  });

  group('Border painting', () {
    testWidgets('border is painted on physical layers', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.button,
          color: const Color(0xFF0000FF),
          shape: const CircleBorder(
            side: BorderSide(
              width: 2.0,
              color: Color(0xFF0000FF),
            ),
          ),
          child: const SizedBox(width: 100.0, height: 100.0),
        ),
      );

      final RenderBox box = tester.renderObject(find.byKey(materialKey));
      expect(box, paints..circle());
    });

    testWidgets('border is painted for transparent material', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.transparency,
          shape: const CircleBorder(
            side: BorderSide(
              width: 2.0,
              color: Color(0xFF0000FF),
            ),
          ),
          child: const SizedBox(width: 100.0, height: 100.0),
        ),
      );

      final RenderBox box = tester.renderObject(find.byKey(materialKey));
      expect(box, paints..circle());
    });

    testWidgets('border is not painted for when border side is none', (WidgetTester tester) async {
      final GlobalKey materialKey = GlobalKey();
      await tester.pumpWidget(
        Material(
          key: materialKey,
          type: MaterialType.transparency,
          shape: const CircleBorder(),
          child: const SizedBox(width: 100.0, height: 100.0),
        ),
      );

      final RenderBox box = tester.renderObject(find.byKey(materialKey));
      expect(box, isNot(paints..circle()));
    });

    testWidgets('border is painted above child by default', (WidgetTester tester) async {
      final Key painterKey = UniqueKey();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: painterKey,
            child: Card(
              child: SizedBox(
                width: 200,
                height: 300,
                child: Material(
                  clipBehavior: Clip.hardEdge,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey, width: 6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: <Widget>[
                      Container(
                        color: Colors.green,
                        height: 150,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ));

      await expectLater(
        find.byKey(painterKey),
        matchesGoldenFile('material.border_paint_above.png'),
      );
    });

    testWidgets('border is painted below child when specified', (WidgetTester tester) async {
      final Key painterKey = UniqueKey();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: painterKey,
            child: Card(
              child: SizedBox(
                width: 200,
                height: 300,
                child: Material(
                  clipBehavior: Clip.hardEdge,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey, width: 6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  borderOnForeground: false,
                  child: Column(
                    children: <Widget>[
                      Container(
                        color: Colors.green,
                        height: 150,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ));

      await expectLater(
        find.byKey(painterKey),
        matchesGoldenFile('material.border_paint_below.png'),
      );
    });
  });
}
