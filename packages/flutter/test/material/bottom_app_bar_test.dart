// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  testWidgets('no overlap with floating action button', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: const Scaffold(
          floatingActionButton: const FloatingActionButton(
            onPressed: null,
          ),
          bottomNavigationBar: const ShapeListener(
            const BottomAppBar(
              child: const SizedBox(height: 100.0),
            )
          ),
        ),
      ),
    );

    final ShapeListenerState shapeListenerState = tester.state(find.byType(ShapeListener));
    final RenderBox renderBox = tester.renderObject(find.byType(BottomAppBar));
    final Path expectedPath = new Path()
      ..addRect(Offset.zero & renderBox.size);

    final Path actualPath = shapeListenerState.cache.value;
    expect(
      actualPath,
      coversSameAreaAs(
        expectedPath,
        areaToCompare: (Offset.zero & renderBox.size).inflate(5.0),
      )
    );
  });

  testWidgets('color defaults to Theme.bottomAppBarColor', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Builder(
          builder: (BuildContext context) {
            return new Theme(
              data: Theme.of(context).copyWith(bottomAppBarColor: const Color(0xffffff00)),
              child: const Scaffold(
                floatingActionButton: const FloatingActionButton(
                  onPressed: null,
                ),
                bottomNavigationBar: const BottomAppBar(),
              ),
            );
          }
        ),
      ),
    );

    final PhysicalShape physicalShape =
      tester.widget(find.byType(PhysicalShape).at(0));

    expect(physicalShape.color, const Color(0xffffff00));
  });

  testWidgets('color overrides theme color', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new Builder(
          builder: (BuildContext context) {
            return new Theme(
              data: Theme.of(context).copyWith(bottomAppBarColor: const Color(0xffffff00)),
              child: const Scaffold(
                floatingActionButton: const FloatingActionButton(
                  onPressed: null,
                ),
                bottomNavigationBar: const BottomAppBar(
                  color: const Color(0xff0000ff)
                ),
              ),
            );
          }
        ),
      ),
    );

    final PhysicalShape physicalShape =
      tester.widget(find.byType(PhysicalShape).at(0));

    expect(physicalShape.color, const Color(0xff0000ff));
  });

  // This is a regression test for a bug we had where toggling the notch on/off
  // will crash, as the shouldReclip method of ShapeBorderClipper or
  // _BottomAppBarClipper will try an illegal downcast.
  testWidgets('toggle hasNotch', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: const Scaffold(
          bottomNavigationBar: const BottomAppBar(
            notchComputer: const RectangularNotchComputer(),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      new MaterialApp(
        home: const Scaffold(
          bottomNavigationBar: const BottomAppBar(
            notchComputer: null,
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      new MaterialApp(
        home: const Scaffold(
          bottomNavigationBar: const BottomAppBar(
            notchComputer: const RectangularNotchComputer(),
          ),
        ),
      ),
    );
  });

  testWidgets('no notch if fab is not overlapping', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: const Scaffold(
          bottomNavigationBar: const ShapeListener(const BottomAppBar(
            notchComputer: const CircularNotchComputer(),
          )),
          floatingActionButton: const FloatingActionButton(
            onPressed: null,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );

    final ShapeListenerState shapeListenerState = tester.state(find.byType(ShapeListener));
    final RenderBox renderBox = tester.renderObject(find.byType(BottomAppBar));
    final Path expectedPath = new Path()
      ..addRect(Offset.zero & renderBox.size);

    final Path actualPath = shapeListenerState.cache.value;

    expect(
      actualPath,
      coversSameAreaAs(
        expectedPath,
        areaToCompare: (Offset.zero & renderBox.size).inflate(5.0),
      )
    );
  });

  testWidgets('no notch notch computer is null', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: const Scaffold(
          bottomNavigationBar: const ShapeListener(const BottomAppBar(
            notchComputer: null,
          )),
          floatingActionButton: const FloatingActionButton(
            onPressed: null,
            child: const Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        ),
      ),
    );

    final ShapeListenerState shapeListenerState = tester.state(find.byType(ShapeListener));
    final RenderBox renderBox = tester.renderObject(find.byType(BottomAppBar));
    final Path expectedPath = new Path()
      ..addRect(Offset.zero & renderBox.size);

    final Path actualPath = shapeListenerState.cache.value;

    expect(
      actualPath,
      coversSameAreaAs(
        expectedPath,
        areaToCompare: (Offset.zero & renderBox.size).inflate(5.0),
      )
    );
  });

  testWidgets('notch', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: const Scaffold(
          bottomNavigationBar: const ShapeListener(
            const BottomAppBar(
              child: const SizedBox(height: 100.0),
              notchComputer: const RectangularNotchComputer(),
            )
          ),
          floatingActionButton: const FloatingActionButton(
            onPressed: null,
            child: const Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        ),
      ),
    );

    final ShapeListenerState shapeListenerState = tester.state(find.byType(ShapeListener));
    final RenderBox babBox = tester.renderObject(find.byType(BottomAppBar));
    final Size babSize = babBox.size;
    final RenderBox fabBox = tester.renderObject(find.byType(FloatingActionButton));
    final Size fabSize = fabBox.size;

    final double fabLeft = (babSize.width / 2.0) - (fabSize.width / 2.0);
    final double fabRight = fabLeft + fabSize.width;
    final double fabBottom = fabSize.height / 2.0;

    final Path expectedPath = new Path()
      ..moveTo(0.0, 0.0)
      ..lineTo(fabLeft, 0.0)
      ..lineTo(fabLeft, fabBottom)
      ..lineTo(fabRight, fabBottom)
      ..lineTo(fabRight, 0.0)
      ..lineTo(babSize.width, 0.0)
      ..lineTo(babSize.width, babSize.height)
      ..lineTo(0.0, babSize.height)
      ..close();

    final Path actualPath = shapeListenerState.cache.value;

    expect(
      actualPath,
      coversSameAreaAs(
        expectedPath,
        areaToCompare: (Offset.zero & babSize).inflate(5.0),
      )
    );
  });

  testWidgets('observes safe area', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: const MediaQuery(
          data: const MediaQueryData(
            padding: const EdgeInsets.all(50.0),
          ),
          child: const Scaffold(
            bottomNavigationBar: const BottomAppBar(
              child: const Center(
                child: const Text('safe'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getBottomLeft(find.widgetWithText(Center, 'safe')),
      const Offset(50.0, 550.0),
    );
  });
}

// The bottom app bar clip path computation is only available at paint time.
// In order to examine the notch path we implement this caching painter which
// at paint time looks for for a descendant PhysicalShape and caches the
// clip path it is using.
class ClipCachePainter extends CustomPainter {
  ClipCachePainter(this.context);

  Path value;
  BuildContext context;

  @override
  void paint(Canvas canvas, Size size) {
    final RenderPhysicalShape physicalShape = findPhysicalShapeChild(context);
    value = physicalShape.clipper.getClip(size);
  }

  RenderPhysicalShape findPhysicalShapeChild(BuildContext context) {
    RenderPhysicalShape result;
    context.visitChildElements((Element e) {
      final RenderObject renderObject = e.findRenderObject();
      if (renderObject.runtimeType == RenderPhysicalShape) {
        assert(result == null);
        result = renderObject;
      } else {
        result = findPhysicalShapeChild(e);
      }
    });
    return result;
  }

  @override
  bool shouldRepaint(ClipCachePainter oldDelegate) {
    return true;
  }
}

class ShapeListener extends StatefulWidget {
  const ShapeListener(this.child);

  final Widget child;

  @override
  State createState() => new ShapeListenerState();

}

class ShapeListenerState extends State<ShapeListener> {
  @override
  Widget build(BuildContext context) {
    return new CustomPaint(
      child: widget.child,
      painter: cache
    );
  }

  ClipCachePainter cache;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cache = new ClipCachePainter(context);
  }

}

class RectangularNotchComputer implements NotchComputer{
  const RectangularNotchComputer();

  @override
  Path compute(Rect host, Rect guest, Offset start, Offset end) {
    return new Path()
      ..lineTo(guest.left, host.top)
      ..lineTo(guest.left, guest.bottom)
      ..lineTo(guest.right, guest.bottom)
      ..lineTo(guest.right, host.top)
      ..lineTo(end.dx, end.dy);
  }
}
