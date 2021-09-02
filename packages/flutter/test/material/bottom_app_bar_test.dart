// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('no overlap with floating action button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: null,
          ),
          bottomNavigationBar: ShapeListener(
            BottomAppBar(
              child: SizedBox(height: 100.0),
            ),
          ),
        ),
      ),
    );

    final ShapeListenerState shapeListenerState = tester.state(find.byType(ShapeListener));
    final RenderBox renderBox = tester.renderObject(find.byType(BottomAppBar));
    final Path expectedPath = Path()
      ..addRect(Offset.zero & renderBox.size);

    final Path actualPath = shapeListenerState.cache.value;
    expect(
      actualPath,
      coversSameAreaAs(
        expectedPath,
        areaToCompare: (Offset.zero & renderBox.size).inflate(5.0),
      ),
    );
  });

  testWidgets('custom shape', (WidgetTester tester) async {
    final Key key = UniqueKey();
    Future<void> pump(FloatingActionButtonLocation location) async {
      await tester.pumpWidget(
        SizedBox(
          width: 200,
          height: 200,
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
              home: Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: () { },
                ),
                floatingActionButtonLocation: location,
                bottomNavigationBar: BottomAppBar(
                  shape: AutomaticNotchedShape(
                    BeveledRectangleBorder(borderRadius: BorderRadius.circular(50.0)),
                    ContinuousRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                  ),
                  notchMargin: 10.0,
                  color: Colors.green,
                  child: const SizedBox(height: 100.0),
                ),
              ),
            ),
          ),
        ),
      );
    }
    await pump(FloatingActionButtonLocation.endDocked);
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('bottom_app_bar.custom_shape.1.png'),
    );
    await pump(FloatingActionButtonLocation.centerDocked);
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('bottom_app_bar.custom_shape.2.png'),
    );
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/44572

  testWidgets('color defaults to Theme.bottomAppBarColor', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Theme(
              data: Theme.of(context).copyWith(bottomAppBarColor: const Color(0xffffff00)),
              child: const Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: null,
                ),
                bottomNavigationBar: BottomAppBar(),
              ),
            );
          },
        ),
      ),
    );

    final PhysicalShape physicalShape =
      tester.widget(find.byType(PhysicalShape).at(0));

    expect(physicalShape.color, const Color(0xffffff00));
  });

  testWidgets('color overrides theme color', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Theme(
              data: Theme.of(context).copyWith(bottomAppBarColor: const Color(0xffffff00)),
              child: const Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: null,
                ),
                bottomNavigationBar: BottomAppBar(
                  color: Color(0xff0000ff),
                ),
              ),
            );
          },
        ),
      ),
    );

    final PhysicalShape physicalShape =
      tester.widget(find.byType(PhysicalShape).at(0));

    expect(physicalShape.color, const Color(0xff0000ff));
  });

  testWidgets('dark theme applies an elevation overlay color', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: const ColorScheme.dark()),
        home: Scaffold(
          bottomNavigationBar: BottomAppBar(
            color: const ColorScheme.dark().surface,
          ),
        ),
      ),
    );

    final PhysicalShape physicalShape = tester.widget(find.byType(PhysicalShape).at(0));

    // For the default dark theme the overlay color for elevation 8 is 0xFF2D2D2D
    expect(physicalShape.color, const Color(0xFF2D2D2D));
  });

  // This is a regression test for a bug we had where toggling the notch on/off
  // would crash, as the shouldReclip method of ShapeBorderClipper or
  // _BottomAppBarClipper would try an illegal downcast.
  testWidgets('toggle shape to null', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomAppBar(
            shape: RectangularNotch(),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomAppBar(
            shape: null,
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomAppBar(
            shape: RectangularNotch(),
          ),
        ),
      ),
    );
  });

  testWidgets('no notch when notch param is null', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ShapeListener(BottomAppBar(
            shape: null,
          )),
          floatingActionButton: FloatingActionButton(
            onPressed: null,
            child: Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        ),
      ),
    );

    final ShapeListenerState shapeListenerState = tester.state(find.byType(ShapeListener));
    final RenderBox renderBox = tester.renderObject(find.byType(BottomAppBar));
    final Path expectedPath = Path()
      ..addRect(Offset.zero & renderBox.size);

    final Path actualPath = shapeListenerState.cache.value;

    expect(
      actualPath,
      coversSameAreaAs(
        expectedPath,
        areaToCompare: (Offset.zero & renderBox.size).inflate(5.0),
      ),
    );
  });

  testWidgets('notch no margin', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ShapeListener(
            BottomAppBar(
              shape: RectangularNotch(),
              notchMargin: 0.0,
              child: SizedBox(height: 100.0),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: null,
            child: Icon(Icons.add),
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

    final Path expectedPath = Path()
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
      ),
    );
  });

  testWidgets('notch with margin', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ShapeListener(
            BottomAppBar(
              shape: RectangularNotch(),
              notchMargin: 6.0,
              child: SizedBox(height: 100.0),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: null,
            child: Icon(Icons.add),
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

    final double fabLeft = (babSize.width / 2.0) - (fabSize.width / 2.0) - 6.0;
    final double fabRight = fabLeft + fabSize.width + 6.0;
    final double fabBottom = 6.0 + fabSize.height / 2.0;

    final Path expectedPath = Path()
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
      ),
    );
  });

  testWidgets('observes safe area', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            padding: EdgeInsets.all(50.0),
          ),
          child: Scaffold(
            bottomNavigationBar: BottomAppBar(
              child: Center(
                child: Text('safe'),
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

  testWidgets('clipBehavior is propagated', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar:
              BottomAppBar(
                shape: RectangularNotch(),
                notchMargin: 0.0,
                child: SizedBox(height: 100.0),
              ),
        ),
      ),
    );

    PhysicalShape physicalShape = tester.widget(find.byType(PhysicalShape));
    expect(physicalShape.clipBehavior, Clip.none);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar:
          BottomAppBar(
            shape: RectangularNotch(),
            notchMargin: 0.0,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: SizedBox(height: 100.0),
          ),
        ),
      ),
    );

    physicalShape = tester.widget(find.byType(PhysicalShape));
    expect(physicalShape.clipBehavior, Clip.antiAliasWithSaveLayer);
  });

  testWidgets('BottomAppBar with shape when Scaffold.bottomNavigationBar == null', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/80878
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.green,
            child: const Icon(Icons.home),
            onPressed: () {},
          ),
          body: Stack(
            children: <Widget>[
              Container(
                color: Colors.amber,
              ),
              Container(
                alignment: Alignment.bottomCenter,
                child: BottomAppBar(
                  color: Colors.green,
                  shape: const CircularNotchedRectangle(),
                  child: Container(height: 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(FloatingActionButton)), const Rect.fromLTRB(372, 528, 428, 584));
    expect(tester.getSize(find.byType(BottomAppBar)), const Size(800, 50));
  });
}

// The bottom app bar clip path computation is only available at paint time.
// In order to examine the notch path we implement this caching painter which
// at paint time looks for a descendant PhysicalShape and caches the
// clip path it is using.
class ClipCachePainter extends CustomPainter {
  ClipCachePainter(this.context);

  late Path value;
  BuildContext context;

  @override
  void paint(Canvas canvas, Size size) {
    final RenderPhysicalShape physicalShape = findPhysicalShapeChild(context)!;
    value = physicalShape.clipper!.getClip(size);
  }

  RenderPhysicalShape? findPhysicalShapeChild(BuildContext context) {
    RenderPhysicalShape? result;
    context.visitChildElements((Element e) {
      final RenderObject renderObject = e.findRenderObject()!;
      if (renderObject.runtimeType == RenderPhysicalShape) {
        assert(result == null);
        result = renderObject as RenderPhysicalShape;
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
  const ShapeListener(this.child, { Key? key }) : super(key: key);

  final Widget child;

  @override
  State createState() => ShapeListenerState();

}

class ShapeListenerState extends State<ShapeListener> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: cache,
      child: widget.child,
    );
  }

  late ClipCachePainter cache;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cache = ClipCachePainter(context);
  }

}

class RectangularNotch extends NotchedShape {
  const RectangularNotch();

  @override
  Path getOuterPath(Rect host, Rect? guest) {
    if (guest == null)
      return Path()..addRect(host);
    return Path()
      ..moveTo(host.left, host.top)
      ..lineTo(guest.left, host.top)
      ..lineTo(guest.left, guest.bottom)
      ..lineTo(guest.right, guest.bottom)
      ..lineTo(guest.right, host.top)
      ..lineTo(host.right, host.top)
      ..lineTo(host.right, host.bottom)
      ..lineTo(host.left, host.bottom)
      ..close();
  }
}
