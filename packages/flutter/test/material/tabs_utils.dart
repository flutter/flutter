// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// This returns render paragraph of the Tab label text.
RenderParagraph getTabText(WidgetTester tester, String text) {
  return tester.renderObject<RenderParagraph>(
    find.descendant(
      of: find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_TabStyle'),
      matching: find.text(text),
    ),
  );
}

// This creates and returns a TabController.
TabController createTabController({
  required int length,
  required TickerProvider vsync,
  int initialIndex = 0,
  Duration? animationDuration,
}) {
  final result = TabController(
    length: length,
    vsync: vsync,
    initialIndex: initialIndex,
    animationDuration: animationDuration,
  );
  addTearDown(result.dispose);
  return result;
}

// This widget is used to test widget state in the tabs_test.dart file.
class TabStateMarker extends StatefulWidget {
  const TabStateMarker({super.key, this.child});

  final Widget? child;

  @override
  TabStateMarkerState createState() => TabStateMarkerState();
}

class TabStateMarkerState extends State<TabStateMarker> {
  String? marker;

  @override
  Widget build(BuildContext context) {
    return widget.child ?? Container();
  }
}

// Tab controller builder for TabControllerFrame widget.
typedef TabControllerFrameBuilder = Widget Function(BuildContext context, TabController controller);

// This widget creates a TabController and passes it to the builder.
class TabControllerFrame extends StatefulWidget {
  const TabControllerFrame({
    super.key,
    required this.length,
    this.initialIndex = 0,
    required this.builder,
  });

  final int length;
  final int initialIndex;
  final TabControllerFrameBuilder builder;

  @override
  TabControllerFrameState createState() => TabControllerFrameState();
}

class TabControllerFrameState extends State<TabControllerFrame>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      vsync: this,
      length: widget.length,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _controller);
  }
}

// Test utility class to test tab indicator drawing.
class TabIndicatorRecordingCanvas extends TestRecordingCanvas {
  TabIndicatorRecordingCanvas(this.indicatorColor);

  final Color indicatorColor;
  late Rect indicatorRect;

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    // Assuming that the indicatorWeight is 2.0, the default.
    const indicatorWeight = 2.0;
    if (paint.color == indicatorColor) {
      indicatorRect = Rect.fromPoints(p1, p2).inflate(indicatorWeight / 2.0);
    }
  }
}

// This creates a Fake implementation of ScrollMetrics.
class TabMockScrollMetrics extends Fake implements ScrollMetrics {}

class TabBarTestScrollPhysics extends ScrollPhysics {
  const TabBarTestScrollPhysics({super.parent});

  @override
  TabBarTestScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return TabBarTestScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return offset == 10 ? 20 : offset;
  }

  static final SpringDescription _kDefaultSpring = SpringDescription.withDampingRatio(
    mass: 0.5,
    stiffness: 500.0,
    ratio: 1.1,
  );

  @override
  SpringDescription get spring => _kDefaultSpring;
}

// This widget is used to log the lifecycle of the TabBarView children.
class TabBody extends StatefulWidget {
  const TabBody({super.key, required this.index, required this.log, this.marker = ''});

  final int index;
  final List<String> log;
  final String marker;

  @override
  State<TabBody> createState() => TabBodyState();
}

class TabBodyState extends State<TabBody> {
  @override
  void initState() {
    widget.log.add('init: ${widget.index}');
    super.initState();
  }

  @override
  void didUpdateWidget(TabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // To keep the logging straight, widgets must not change their index.
    assert(oldWidget.index == widget.index);
  }

  @override
  void dispose() {
    widget.log.add('dispose: ${widget.index}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: widget.marker.isEmpty
          ? Text('${widget.index}')
          : Text('${widget.index}-${widget.marker}'),
    );
  }
}

// This widget is used to test the lifecycle of the TabBarView children with Ink widget.
class TabKeepAliveInk extends StatefulWidget {
  const TabKeepAliveInk({super.key, required this.title});

  final String title;

  @override
  State<StatefulWidget> createState() => _TabKeepAliveInkState();
}

class _TabKeepAliveInkState extends State<TabKeepAliveInk> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Ink(child: Text(widget.title));
  }
}

// This widget is used to test the lifecycle of the TabBarView children.
class TabAlwaysKeepAliveWidget extends StatefulWidget {
  const TabAlwaysKeepAliveWidget({super.key});

  static String text = 'AlwaysKeepAlive';

  @override
  State<TabAlwaysKeepAliveWidget> createState() => _TabAlwaysKeepAliveWidgetState();
}

class _TabAlwaysKeepAliveWidgetState extends State<TabAlwaysKeepAliveWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Text(TabAlwaysKeepAliveWidget.text);
  }
}

// This decoration is used to test the indicator decoration image configuration.
class TestIndicatorDecoration extends Decoration {
  final List<TestIndicatorBoxPainter> painters = <TestIndicatorBoxPainter>[];

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    final painter = TestIndicatorBoxPainter();
    painters.add(painter);
    return painter;
  }
}

class TestIndicatorBoxPainter extends BoxPainter {
  ImageConfiguration? lastConfiguration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    lastConfiguration = configuration;
  }
}

// Ease out sine (decelerating).
double _decelerateInterpolation(double fraction) {
  return math.sin((fraction * math.pi) / 2.0);
}

// Ease in sine (accelerating).
double _accelerateInterpolation(double fraction) {
  return 1.0 - math.cos((fraction * math.pi) / 2.0);
}

// Returns Tab indicator RRect with elastic animation.
RRect tabIndicatorRRectElasticAnimation(
  RenderBox tabBarBox,
  Rect currentRect,
  Rect fromRect,
  Rect toRect,
  double progress,
) {
  const indicatorWeight = 3.0;
  final double leftFraction = _accelerateInterpolation(progress);
  final double rightFraction = _decelerateInterpolation(progress);

  return RRect.fromLTRBAndCorners(
    lerpDouble(fromRect.left, toRect.left, leftFraction)!,
    tabBarBox.size.height - indicatorWeight,
    lerpDouble(fromRect.right, toRect.right, rightFraction)!,
    tabBarBox.size.height,
    topLeft: const Radius.circular(indicatorWeight),
    topRight: const Radius.circular(indicatorWeight),
  );
}

// This decoration is used to test async image loading in indicator.
class TabBarAsyncImageIndicatorDecoration extends Decoration {
  TabBarAsyncImageIndicatorDecoration() : _paintCounter = _TabBarPaintCounter();

  final _TabBarPaintCounter _paintCounter;

  /// The number of times the indicator has been painted.
  int get paintCount => _paintCounter.count;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return TabBarAsyncImageIndicatorBoxPainter(
      onChanged: onChanged,
      onPaint: _paintCounter.increment,
    );
  }
}

// Helper class to track paint counts.
class _TabBarPaintCounter {
  int count = 0;

  void increment() {
    count++;
  }
}

// Box painter that simulates async image loading for testing TabBar indicators.
class TabBarAsyncImageIndicatorBoxPainter extends BoxPainter {
  TabBarAsyncImageIndicatorBoxPainter({VoidCallback? onChanged, this.onPaint}) : super(onChanged);

  final VoidCallback? onPaint;
  bool _imagePainted = false;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    onPaint?.call();

    // Simulate async image loading on first paint.
    if (!_imagePainted && onChanged != null) {
      _imagePainted = true;
      Future.delayed(Duration.zero, () {
        onChanged!();
      });
    }

    // Paint a simple rectangle to indicate the indicator was painted.
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(offset.dx, configuration.size!.height - 2.0, configuration.size!.width, 2.0),
      paint,
    );
  }
}
