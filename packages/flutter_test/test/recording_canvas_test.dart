// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data' show Float32List, Int32List;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late final ui.Image image;
  setUpAll(() async {
    image = await createTestImage(width: 8, height: 8);
  });

  testWidgets('paints.circle is not affected by mutated colors', (WidgetTester tester) async {
    final Key customPaintKey = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CustomPaint(
              key: customPaintKey,
              painter: _MutantPainter(
                painter: (Canvas canvas, Paint paint) {
                  canvas.drawCircle(Offset.zero, 10.0, paint);
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byKey(customPaintKey))),
      paints..circle(color: _MutantPainter.startColor),
    );
  });

  testWidgets('paints.rect is not affected by mutated colors', (WidgetTester tester) async {
    final Key customPaintKey = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CustomPaint(
              key: customPaintKey,
              painter: _MutantPainter(
                painter: (Canvas canvas, Paint paint) {
                  canvas.drawRect(const Rect.fromLTRB(0.0, 0.0, 100.0, 100.0), paint);
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byKey(customPaintKey))),
      paints..rect(color: _MutantPainter.startColor),
    );
  });

  testWidgets('paints.drawRRect is not affected by mutated colors', (WidgetTester tester) async {
    final Key customPaintKey = UniqueKey();
    const Rect rect = Rect.fromLTRB(0.0, 0.0, 100.0, 100.0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CustomPaint(
              key: customPaintKey,
              painter: _MutantPainter(
                painter: (Canvas canvas, Paint paint) {
                  canvas.drawRRect(RRect.fromRectXY(rect, 4.0, 4.0), paint);
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byKey(customPaintKey))),
      paints..rrect(color: _MutantPainter.startColor),
    );
  });

  testWidgets('paints.drawDRRect is not affected by mutated colors', (WidgetTester tester) async {
    final Key customPaintKey = UniqueKey();
    const Rect rect = Rect.fromLTRB(0.0, 0.0, 100.0, 100.0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CustomPaint(
              key: customPaintKey,
              painter: _MutantPainter(
                painter: (Canvas canvas, Paint paint) {
                  final RRect rRect = RRect.fromRectXY(rect, 4.0, 4.0);
                  final RRect innerRRect = RRect.fromRectXY(
                    const Rect.fromLTRB(10.0, 10.0, 80.0, 80.0),
                    4.0,
                    4.0,
                  );
                  canvas.drawDRRect(rRect, innerRRect, paint);
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byKey(customPaintKey))),
      paints..drrect(color: _MutantPainter.startColor),
    );
  });

  testWidgets('paints.drawPath is not affected by mutated colors', (WidgetTester tester) async {
    final Key customPaintKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CustomPaint(
              key: customPaintKey,
              painter: _MutantPainter(
                painter: (Canvas canvas, Paint paint) {
                  canvas.drawPath(Path(), paint);
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byKey(customPaintKey))),
      paints..path(color: _MutantPainter.startColor),
    );
  });

  testWidgets('paints.drawLine is not affected by mutated colors', (WidgetTester tester) async {
    final Key customPaintKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CustomPaint(
              key: customPaintKey,
              painter: _MutantPainter(
                painter: (Canvas canvas, Paint paint) {
                  canvas.drawLine(Offset.zero, const Offset(10.0, 10.0), paint);
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byKey(customPaintKey))),
      paints..line(color: _MutantPainter.startColor),
    );
  });

  testWidgets('paints.drawArc is not affected by mutated colors', (WidgetTester tester) async {
    final Key customPaintKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CustomPaint(
              key: customPaintKey,
              painter: _MutantPainter(
                painter: (Canvas canvas, Paint paint) {
                  const Rect rect = Rect.fromLTRB(0.0, 0.0, 100.0, 100.0);
                  canvas.drawArc(rect, 10.0, 10.0, true, paint);
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byKey(customPaintKey))),
      paints..arc(color: _MutantPainter.startColor),
    );
  });

  testWidgets('paints.drawPaint is not affected by mutated colors', (WidgetTester tester) async {
    final Key customPaintKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CustomPaint(
              key: customPaintKey,
              painter: _MutantPainter(
                painter: (Canvas canvas, Paint paint) {
                  canvas.drawPaint(paint);
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byKey(customPaintKey))),
      paints..something((Symbol methodName, List<dynamic> arguments) {
        if (methodName != #drawPaint) {
          return false;
        }
        return (arguments[0] as Paint).color == _MutantPainter.startColor;
      }),
    );
  });

  testWidgets('paints.drawRSuperellipse is not affected by mutated colors', (
    WidgetTester tester,
  ) async {
    final Key customPaintKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CustomPaint(
              key: customPaintKey,
              painter: _MutantPainter(
                painter: (Canvas canvas, Paint paint) {
                  canvas.drawRSuperellipse(
                    RSuperellipse.fromLTRBR(0.0, 0.0, 100.0, 100.0, const Radius.circular(10.0)),
                    paint,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byKey(customPaintKey))),
      paints..rsuperellipse(color: _MutantPainter.startColor),
    );
  });

  testWidgets('paints.drawOval is not affected by mutated colors', (WidgetTester tester) async {
    final Key customPaintKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CustomPaint(
              key: customPaintKey,
              painter: _MutantPainter(
                painter: (Canvas canvas, Paint paint) {
                  const Rect rect = Rect.fromLTRB(0.0, 0.0, 100.0, 100.0);
                  canvas.drawOval(rect, paint);
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byKey(customPaintKey))),
      paints..something((Symbol methodName, List<dynamic> arguments) {
        if (methodName != #drawOval) {
          return false;
        }
        return (arguments[1] as Paint).color == _MutantPainter.startColor;
      }),
    );
  });

  testWidgets('paints.image is not affected by mutated colors', (WidgetTester tester) async {
    final Key customPaintKey = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CustomPaint(
              key: customPaintKey,
              painter: _MutantPainter(
                painter: (Canvas canvas, Paint paint) {
                  canvas.drawImage(image, Offset.zero, paint);
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byKey(customPaintKey))),
      paints..something((Symbol methodName, List<dynamic> arguments) {
        if (methodName != #drawImage) {
          return false;
        }
        return (arguments[2] as Paint).color == _MutantPainter.startColor;
      }),
    );
  });

  testWidgets('paints.drawImageRect is not affected by mutated colors', (
    WidgetTester tester,
  ) async {
    final Key customPaintKey = UniqueKey();
    const Rect rect = Rect.fromLTRB(0.0, 0.0, 100.0, 100.0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CustomPaint(
              key: customPaintKey,
              painter: _MutantPainter(
                painter: (Canvas canvas, Paint paint) {
                  canvas.drawImageRect(image, rect, rect, paint);
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byKey(customPaintKey))),
      paints..drawImageRect(color: _MutantPainter.startColor),
    );
  });

  testWidgets('paints.drawImageNine is not affected by mutated colors', (
    WidgetTester tester,
  ) async {
    final Key customPaintKey = UniqueKey();
    const Rect rect = Rect.fromLTRB(0.0, 0.0, 100.0, 100.0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CustomPaint(
              key: customPaintKey,
              painter: _MutantPainter(
                painter: (Canvas canvas, Paint paint) {
                  canvas.drawImageNine(image, rect, rect, paint);
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byKey(customPaintKey))),
      paints..something((Symbol methodName, List<dynamic> arguments) {
        if (methodName != #drawImageNine) {
          return false;
        }
        return (arguments[3] as Paint).color == _MutantPainter.startColor;
      }),
    );
  });

  testWidgets('paints.drawPoints is not affected by mutated colors', (WidgetTester tester) async {
    final Key customPaintKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CustomPaint(
              key: customPaintKey,
              painter: _MutantPainter(
                painter: (Canvas canvas, Paint paint) {
                  canvas.drawPoints(ui.PointMode.lines, <Offset>[
                    Offset.zero,
                    const Offset(10.0, 10.0),
                  ], paint);
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byKey(customPaintKey))),
      paints..something((Symbol methodName, List<dynamic> arguments) {
        if (methodName != #drawPoints) {
          return false;
        }
        return (arguments[2] as Paint).color == _MutantPainter.startColor;
      }),
    );
  });

  testWidgets('paints.drawRawPoints is not affected by mutated colors', (
    WidgetTester tester,
  ) async {
    final Key customPaintKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CustomPaint(
              key: customPaintKey,
              painter: _MutantPainter(
                painter: (Canvas canvas, Paint paint) {
                  canvas.drawRawPoints(
                    ui.PointMode.lines,
                    Float32List.fromList(<double>[0.0, 0.0, 10.0, 10.0]),
                    paint,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byKey(customPaintKey))),
      paints..something((Symbol methodName, List<dynamic> arguments) {
        if (methodName != #drawRawPoints) {
          return false;
        }
        return (arguments[2] as Paint).color == _MutantPainter.startColor;
      }),
    );
  });

  testWidgets('paints.drawVertices is not affected by mutated colors', (WidgetTester tester) async {
    final Key customPaintKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CustomPaint(
              key: customPaintKey,
              painter: _MutantPainter(
                painter: (Canvas canvas, Paint paint) {
                  canvas.drawVertices(
                    ui.Vertices(ui.VertexMode.triangles, <Offset>[
                      Offset.zero,
                      const Offset(0.0, 10.0),
                      const Offset(10.0, 10.0),
                    ]),
                    BlendMode.src,
                    paint,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byKey(customPaintKey))),
      paints..something((Symbol methodName, List<dynamic> arguments) {
        if (methodName != #drawVertices) {
          return false;
        }
        return (arguments[2] as Paint).color == _MutantPainter.startColor;
      }),
    );
  });

  testWidgets('paints.drawAtlas is not affected by mutated colors', (WidgetTester tester) async {
    final Key customPaintKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CustomPaint(
              key: customPaintKey,
              painter: _MutantPainter(
                painter: (Canvas canvas, Paint paint) {
                  canvas.drawAtlas(
                    image,
                    <RSTransform>[],
                    <Rect>[],
                    <Color>[],
                    BlendMode.src,
                    const Rect.fromLTRB(0.0, 0.0, 100.0, 100.0),
                    paint,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byKey(customPaintKey))),
      paints..something((Symbol methodName, List<dynamic> arguments) {
        if (methodName != #drawAtlas) {
          return false;
        }
        return (arguments[6] as Paint).color == _MutantPainter.startColor;
      }),
    );
  });

  testWidgets('paints.drawRawAtlas is not affected by mutated colors', (WidgetTester tester) async {
    final Key customPaintKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CustomPaint(
              key: customPaintKey,
              painter: _MutantPainter(
                painter: (Canvas canvas, Paint paint) {
                  canvas.drawRawAtlas(
                    image,
                    Float32List.fromList(<double>[]),
                    Float32List.fromList(<double>[]),
                    Int32List.fromList(<int>[]),
                    BlendMode.src,
                    const Rect.fromLTRB(0.0, 0.0, 100.0, 100.0),
                    paint,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byKey(customPaintKey))),
      paints..something((Symbol methodName, List<dynamic> arguments) {
        if (methodName != #drawRawAtlas) {
          return false;
        }
        return (arguments[6] as Paint).color == _MutantPainter.startColor;
      }),
    );
  });
}

typedef _Painter = void Function(Canvas canvas, Paint paint);

/// A painter that mutates its Paint color after painting.
class _MutantPainter extends ChangeNotifier implements CustomPainter {
  _MutantPainter({required this.painter});

  final _Painter painter;

  static const ui.Color startColor = ui.Color(0xff00ff00);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = startColor;

    painter(canvas, paint);

    // Mutate paint after drawing.
    paint.color = Colors.blue;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  @override
  bool? hitTest(Offset position) => null;

  @override
  SemanticsBuilderCallback? get semanticsBuilder => null;

  @override
  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) => true;
}
