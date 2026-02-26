// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A simple [PreferredSizeWidget] for testing the [RawSliverAppBar.bottom] slot.
class _TestBottom extends StatelessWidget implements PreferredSizeWidget {
  const _TestBottom({required this.height});

  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height, child: const Text('bottom'));
  }
}

/// Default builder used by most tests. Returns a [SizedBox] that fills.
Widget _defaultBuilder(
  BuildContext context, {
  required double toolbarOpacity,
  required double bottomOpacity,
  required bool isScrolledUnder,
  required double minExtent,
  required double maxExtent,
  required double currentExtent,
}) {
  return SizedBox.expand(child: Container(color: const Color(0xFF00FF00)));
}

/// Wraps a [CustomScrollView] with the minimum required ancestor widgets
/// (Directionality + MediaQuery) so tests stay in the widgets layer.
Widget _buildApp({
  required List<Widget> slivers,
  double topPadding = 0.0,
  ScrollController? controller,
  ScrollPhysics? physics,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(padding: EdgeInsets.only(top: topPadding)),
      child: CustomScrollView(controller: controller, physics: physics, slivers: slivers),
    ),
  );
}

/// Helper that builds a simple scrollable list with a [RawSliverAppBar] at the
/// top followed by enough content to allow scrolling.
Widget _buildSimpleApp({
  double toolbarHeight = 56.0,
  double? expandedHeight,
  double? collapsedHeight,
  bool floating = false,
  bool pinned = false,
  bool snap = false,
  bool stretch = false,
  double stretchTriggerOffset = 100.0,
  AsyncCallback? onStretchTrigger,
  bool forceElevated = false,
  bool primary = false,
  double topPadding = 0.0,
  Widget? leading,
  PreferredSizeWidget? bottom,
  RawSliverAppBarBuilder? appBarBuilder,
  ScrollController? controller,
  ScrollPhysics? physics,
}) {
  return _buildApp(
    topPadding: topPadding,
    controller: controller,
    physics: physics,
    slivers: <Widget>[
      RawSliverAppBar(
        toolbarHeight: toolbarHeight,
        expandedHeight: expandedHeight,
        collapsedHeight: collapsedHeight,
        floating: floating,
        pinned: pinned,
        snap: snap,
        stretch: stretch,
        stretchTriggerOffset: stretchTriggerOffset,
        onStretchTrigger: onStretchTrigger,
        forceElevated: forceElevated,
        primary: primary,
        leading: leading,
        bottom: bottom,
        appBarBuilder: appBarBuilder ?? _defaultBuilder,
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          return SizedBox(height: 100.0, child: Text('Item $index'));
        }, childCount: 50),
      ),
    ],
  );
}

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // Basic rendering
  // ──────────────────────────────────────────────────────────────────────────

  testWidgets('RawSliverAppBar renders with the given toolbarHeight', (WidgetTester tester) async {
    const toolbarHeight = 72.0;
    await tester.pumpWidget(_buildSimpleApp(toolbarHeight: toolbarHeight));

    // The SliverPersistentHeader created by RawSliverAppBar should have the
    // expected max extent (toolbarHeight when expandedHeight is null and there
    // is no bottom widget, and primary is false so no top padding).
    final RenderSliver renderSliver = tester.renderObject<RenderSliver>(
      find.byType(SliverPersistentHeader),
    );
    expect(renderSliver.geometry!.maxPaintExtent, toolbarHeight);
  });

  testWidgets('RawSliverAppBar renders builder content', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildSimpleApp(
        appBarBuilder:
            (
              BuildContext context, {
              required double toolbarOpacity,
              required double bottomOpacity,
              required bool isScrolledUnder,
              required double minExtent,
              required double maxExtent,
              required double currentExtent,
            }) {
              return const Text('Custom AppBar');
            },
      ),
    );

    expect(find.text('Custom AppBar'), findsOneWidget);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Pinned behavior
  // ──────────────────────────────────────────────────────────────────────────

  testWidgets('RawSliverAppBar pinned stays visible when scrolled', (WidgetTester tester) async {
    const toolbarHeight = 56.0;
    await tester.pumpWidget(_buildSimpleApp(expandedHeight: 200.0, pinned: true));

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;

    // Scroll past the expanded height.
    position.jumpTo(300.0);
    await tester.pump();

    // The sliver should still be painting with at least the collapsed height.
    final RenderSliver renderSliver = tester.renderObject<RenderSliver>(
      find.byType(SliverPersistentHeader),
    );
    expect(renderSliver.geometry!.visible, isTrue);
    expect(renderSliver.geometry!.paintExtent, toolbarHeight);
  });

  testWidgets('RawSliverAppBar not pinned scrolls away', (WidgetTester tester) async {
    await tester.pumpWidget(_buildSimpleApp());

    // Obtain the render object before scrolling so the finder can locate it.
    final RenderSliver renderSliver = tester.renderObject<RenderSliver>(
      find.byType(SliverPersistentHeader),
    );

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;

    // Scroll past the toolbar.
    position.jumpTo(200.0);
    await tester.pump();

    expect(renderSliver.geometry!.visible, isFalse);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Floating behavior
  // ──────────────────────────────────────────────────────────────────────────

  testWidgets('RawSliverAppBar floating reappears on scroll back', (WidgetTester tester) async {
    await tester.pumpWidget(_buildSimpleApp(floating: true));

    // Obtain the render object before scrolling so the finder can locate it.
    final RenderSliver renderSliver = tester.renderObject<RenderSliver>(
      find.byType(SliverPersistentHeader),
    );

    // Use a continuous gesture so the floating header tracks scroll direction.
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(Scrollable)),
    );

    // Scroll away.
    await gesture.moveBy(const Offset(0.0, -300.0));
    await tester.pump();

    expect(renderSliver.geometry!.visible, isFalse);

    // Scroll back a little — the floating header should start to reappear.
    await gesture.moveBy(const Offset(0.0, 30.0));
    await tester.pump();

    expect(renderSliver.geometry!.visible, isTrue);

    await gesture.up();
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Snap behavior
  // ──────────────────────────────────────────────────────────────────────────

  testWidgets('RawSliverAppBar snap requires floating', (WidgetTester tester) async {
    expect(
      () => RawSliverAppBar(
        toolbarHeight: 56.0,
        snap: true,
        // floating defaults to false
        appBarBuilder: _defaultBuilder,
      ),
      throwsAssertionError,
    );
  });

  testWidgets('RawSliverAppBar floating with snap snaps into view', (WidgetTester tester) async {
    const toolbarHeight = 56.0;
    await tester.pumpWidget(_buildSimpleApp(floating: true, snap: true));

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;

    // Scroll away completely.
    position.jumpTo(300.0);
    await tester.pump();

    // A small drag back should trigger the snap animation.
    await tester.drag(find.byType(Scrollable), const Offset(0.0, 10.0));
    await tester.pump();
    await tester.pumpAndSettle();

    // After settling, the header should be fully visible.
    final RenderSliver renderSliver = tester.renderObject<RenderSliver>(
      find.byType(SliverPersistentHeader),
    );
    expect(renderSliver.geometry!.visible, isTrue);
    expect(renderSliver.geometry!.paintExtent, toolbarHeight);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Stretch behavior
  // ──────────────────────────────────────────────────────────────────────────

  testWidgets('RawSliverAppBar stretch calls onStretchTrigger', (WidgetTester tester) async {
    var stretchTriggered = false;
    await tester.pumpWidget(
      _buildSimpleApp(
        expandedHeight: 200.0,
        stretch: true,
        pinned: true,
        // Overscroll requires bouncing physics (default clamping prevents it).
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        onStretchTrigger: () async {
          stretchTriggered = true;
        },
      ),
    );

    // Over-scroll (pull down past the top).
    await tester.drag(find.byType(Scrollable), const Offset(0.0, 150.0));
    await tester.pump();

    expect(stretchTriggered, isTrue);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Expanded / collapsed height calculations
  // ──────────────────────────────────────────────────────────────────────────

  testWidgets('RawSliverAppBar defaults expandedHeight to toolbarHeight', (
    WidgetTester tester,
  ) async {
    const toolbarHeight = 64.0;
    await tester.pumpWidget(_buildSimpleApp(toolbarHeight: toolbarHeight));

    final RenderSliver renderSliver = tester.renderObject<RenderSliver>(
      find.byType(SliverPersistentHeader),
    );
    // maxExtent = topPadding(0) + (expandedHeight ?? toolbarHeight + bottomHeight)
    // = 0 + 64 = 64
    expect(renderSliver.geometry!.maxPaintExtent, toolbarHeight);
  });

  testWidgets('RawSliverAppBar respects explicit expandedHeight', (WidgetTester tester) async {
    const expandedHeight = 250.0;
    await tester.pumpWidget(_buildSimpleApp(expandedHeight: expandedHeight));

    final RenderSliver renderSliver = tester.renderObject<RenderSliver>(
      find.byType(SliverPersistentHeader),
    );
    expect(renderSliver.geometry!.maxPaintExtent, expandedHeight);
  });

  testWidgets('RawSliverAppBar respects explicit collapsedHeight', (WidgetTester tester) async {
    const collapsedHeight = 80.0;
    const expandedHeight = 200.0;
    await tester.pumpWidget(
      _buildSimpleApp(
        collapsedHeight: collapsedHeight,
        expandedHeight: expandedHeight,
        pinned: true,
      ),
    );

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;

    // Scroll fully past expanded.
    position.jumpTo(500.0);
    await tester.pump();

    final RenderSliver renderSliver = tester.renderObject<RenderSliver>(
      find.byType(SliverPersistentHeader),
    );
    // When pinned and fully collapsed, paintExtent should equal collapsedHeight.
    expect(renderSliver.geometry!.paintExtent, collapsedHeight);
  });

  testWidgets('RawSliverAppBar collapsedHeight must be >= toolbarHeight', (
    WidgetTester tester,
  ) async {
    expect(
      () => RawSliverAppBar(
        toolbarHeight: 56.0,
        collapsedHeight: 40.0, // less than toolbarHeight
        appBarBuilder: _defaultBuilder,
      ),
      throwsAssertionError,
    );
  });

  testWidgets('RawSliverAppBar with expandedHeight and bottom', (WidgetTester tester) async {
    const bottomHeight = 48.0;
    const expandedHeight = 250.0;
    await tester.pumpWidget(
      _buildSimpleApp(
        expandedHeight: expandedHeight,
        bottom: const _TestBottom(height: bottomHeight),
      ),
    );

    final RenderSliver renderSliver = tester.renderObject<RenderSliver>(
      find.byType(SliverPersistentHeader),
    );
    // maxExtent = topPadding(0) + expandedHeight = 250
    expect(renderSliver.geometry!.maxPaintExtent, expandedHeight);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Builder callback parameters
  // ──────────────────────────────────────────────────────────────────────────

  testWidgets('Builder receives correct parameters at initial state', (WidgetTester tester) async {
    const toolbarHeight = 56.0;
    const expandedHeight = 200.0;

    late double receivedToolbarOpacity;
    late double receivedBottomOpacity;
    late bool receivedIsScrolledUnder;
    late double receivedMinExtent;
    late double receivedMaxExtent;
    late double receivedCurrentExtent;

    await tester.pumpWidget(
      _buildSimpleApp(
        expandedHeight: expandedHeight,
        pinned: true,
        appBarBuilder:
            (
              BuildContext context, {
              required double toolbarOpacity,
              required double bottomOpacity,
              required bool isScrolledUnder,
              required double minExtent,
              required double maxExtent,
              required double currentExtent,
            }) {
              receivedToolbarOpacity = toolbarOpacity;
              receivedBottomOpacity = bottomOpacity;
              receivedIsScrolledUnder = isScrolledUnder;
              receivedMinExtent = minExtent;
              receivedMaxExtent = maxExtent;
              receivedCurrentExtent = currentExtent;
              return const SizedBox.expand();
            },
      ),
    );

    // At initial state (no scrolling):
    // - toolbarOpacity should be 1.0 (pinned)
    // - bottomOpacity should be 1.0 (pinned)
    // - isScrolledUnder should be false
    // - currentExtent should equal maxExtent
    expect(receivedToolbarOpacity, 1.0);
    expect(receivedBottomOpacity, 1.0);
    expect(receivedIsScrolledUnder, isFalse);
    expect(receivedMinExtent, toolbarHeight);
    expect(receivedMaxExtent, expandedHeight);
    expect(receivedCurrentExtent, expandedHeight);
  });

  testWidgets('Builder receives isScrolledUnder=true when pinned and scrolled', (
    WidgetTester tester,
  ) async {
    const expandedHeight = 200.0;

    late bool receivedIsScrolledUnder;

    await tester.pumpWidget(
      _buildSimpleApp(
        expandedHeight: expandedHeight,
        pinned: true,
        appBarBuilder:
            (
              BuildContext context, {
              required double toolbarOpacity,
              required double bottomOpacity,
              required bool isScrolledUnder,
              required double minExtent,
              required double maxExtent,
              required double currentExtent,
            }) {
              receivedIsScrolledUnder = isScrolledUnder;
              return const SizedBox.expand();
            },
      ),
    );

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;

    // Scroll past the expansion range (maxExtent - minExtent = 200 - 56 = 144).
    position.jumpTo(150.0);
    await tester.pump();

    expect(receivedIsScrolledUnder, isTrue);
  });

  testWidgets('Builder receives decreasing currentExtent as user scrolls', (
    WidgetTester tester,
  ) async {
    const toolbarHeight = 56.0;
    const expandedHeight = 200.0;

    late double receivedCurrentExtent;

    await tester.pumpWidget(
      _buildSimpleApp(
        expandedHeight: expandedHeight,
        pinned: true,
        appBarBuilder:
            (
              BuildContext context, {
              required double toolbarOpacity,
              required double bottomOpacity,
              required bool isScrolledUnder,
              required double minExtent,
              required double maxExtent,
              required double currentExtent,
            }) {
              receivedCurrentExtent = currentExtent;
              return const SizedBox.expand();
            },
      ),
    );

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;

    // Scroll down 100px.
    position.jumpTo(100.0);
    await tester.pump();

    // currentExtent = max(minExtent, maxExtent - shrinkOffset) = max(56, 200-100) = 100
    expect(receivedCurrentExtent, 100.0);

    // Scroll fully collapsed.
    position.jumpTo(300.0);
    await tester.pump();

    // currentExtent = max(56, 200-300) = 56
    expect(receivedCurrentExtent, toolbarHeight);
  });

  testWidgets('Builder toolbarOpacity fades for non-pinned bar', (WidgetTester tester) async {
    const expandedHeight = 200.0;

    late double receivedToolbarOpacity;

    await tester.pumpWidget(
      _buildSimpleApp(
        expandedHeight: expandedHeight,
        // Not pinned, not floating -> toolbar opacity fades
        appBarBuilder:
            (
              BuildContext context, {
              required double toolbarOpacity,
              required double bottomOpacity,
              required bool isScrolledUnder,
              required double minExtent,
              required double maxExtent,
              required double currentExtent,
            }) {
              receivedToolbarOpacity = toolbarOpacity;
              return const SizedBox.expand();
            },
      ),
    );

    // Initially fully visible.
    expect(receivedToolbarOpacity, 1.0);

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;

    // Scroll enough to start hiding the toolbar.
    // visibleMainHeight = maxExtent - shrinkOffset - topPadding
    // visibleToolbarHeight = visibleMainHeight - bottomHeight - extraToolbarHeight
    // For shrinkOffset = expandedHeight - toolbarHeight = 144:
    //   visibleMainHeight = 200 - 144 - 0 = 56
    //   visibleToolbarHeight = 56 - 0 - 0 = 56
    //   toolbarOpacity = clamp(56/56) = 1.0
    // For shrinkOffset = expandedHeight (= 200):
    //   visibleMainHeight = 200 - 200 - 0 = 0
    //   visibleToolbarHeight = 0 - 0 - 0 = 0
    //   toolbarOpacity = clamp(0/56) = 0.0
    position.jumpTo(expandedHeight);
    await tester.pump();
    expect(receivedToolbarOpacity, 0.0);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // RawSliverAppBarSettings (InheritedWidget)
  // ──────────────────────────────────────────────────────────────────────────

  testWidgets('RawSliverAppBarSettings is accessible from builder descendants', (
    WidgetTester tester,
  ) async {
    const toolbarHeight = 56.0;
    const expandedHeight = 200.0;

    late RawSliverAppBarSettings? settings;

    await tester.pumpWidget(
      _buildSimpleApp(
        expandedHeight: expandedHeight,
        pinned: true,
        appBarBuilder:
            (
              BuildContext context, {
              required double toolbarOpacity,
              required double bottomOpacity,
              required bool isScrolledUnder,
              required double minExtent,
              required double maxExtent,
              required double currentExtent,
            }) {
              // The builder's child is wrapped in RawSliverAppBarSettings by the
              // delegate, but the *builder's own context* is the child of that
              // InheritedWidget's subtree. We need a descendant Builder to look it up.
              return Builder(
                builder: (BuildContext innerContext) {
                  settings = innerContext
                      .dependOnInheritedWidgetOfExactType<RawSliverAppBarSettings>();
                  return const SizedBox.expand();
                },
              );
            },
      ),
    );

    expect(settings, isNotNull);
    expect(settings!.toolbarOpacity, 1.0);
    expect(settings!.minExtent, toolbarHeight);
    expect(settings!.maxExtent, expandedHeight);
    expect(settings!.currentExtent, expandedHeight);
    expect(settings!.isScrolledUnder, isFalse);
  });

  testWidgets('RawSliverAppBarSettings updates on scroll', (WidgetTester tester) async {
    const toolbarHeight = 56.0;
    const expandedHeight = 200.0;

    late RawSliverAppBarSettings? settings;

    await tester.pumpWidget(
      _buildSimpleApp(
        expandedHeight: expandedHeight,
        pinned: true,
        appBarBuilder:
            (
              BuildContext context, {
              required double toolbarOpacity,
              required double bottomOpacity,
              required bool isScrolledUnder,
              required double minExtent,
              required double maxExtent,
              required double currentExtent,
            }) {
              return Builder(
                builder: (BuildContext innerContext) {
                  settings = innerContext
                      .dependOnInheritedWidgetOfExactType<RawSliverAppBarSettings>();
                  return const SizedBox.expand();
                },
              );
            },
      ),
    );

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;

    position.jumpTo(80.0);
    await tester.pump();

    expect(settings, isNotNull);
    // currentExtent = max(56, 200-80) = 120
    expect(settings!.currentExtent, 120.0);
    expect(settings!.isScrolledUnder, isFalse);

    // Scroll past the collapse threshold (200 - 56 = 144).
    position.jumpTo(150.0);
    await tester.pump();

    expect(settings!.isScrolledUnder, isTrue);
    expect(settings!.currentExtent, toolbarHeight);
  });

  testWidgets('RawSliverAppBarSettings.hasLeading reflects leading widget', (
    WidgetTester tester,
  ) async {
    late RawSliverAppBarSettings? settings;

    Widget buildApp({Widget? leading}) {
      return _buildSimpleApp(
        pinned: true,
        leading: leading,
        appBarBuilder:
            (
              BuildContext context, {
              required double toolbarOpacity,
              required double bottomOpacity,
              required bool isScrolledUnder,
              required double minExtent,
              required double maxExtent,
              required double currentExtent,
            }) {
              return Builder(
                builder: (BuildContext innerContext) {
                  settings = innerContext
                      .dependOnInheritedWidgetOfExactType<RawSliverAppBarSettings>();
                  return const SizedBox.expand();
                },
              );
            },
      );
    }

    // Without leading.
    await tester.pumpWidget(buildApp());
    expect(settings!.hasLeading, isFalse);

    // With leading.
    await tester.pumpWidget(buildApp(leading: const Icon(IconData(0xe5c4))));
    expect(settings!.hasLeading, isTrue);
  });

  testWidgets('RawSliverAppBarSettings.createSettings factory defaults', (
    WidgetTester tester,
  ) async {
    final settings = RawSliverAppBarSettings.createSettings(
      currentExtent: 100.0,
      child: const SizedBox(),
    );

    expect(settings.toolbarOpacity, 1.0);
    expect(settings.minExtent, 100.0);
    expect(settings.maxExtent, 100.0);
    expect(settings.currentExtent, 100.0);
    expect(settings.isScrolledUnder, isNull);
    expect(settings.hasLeading, isNull);
  });

  testWidgets('RawSliverAppBarSettings.updateShouldNotify returns correct value', (
    WidgetTester tester,
  ) async {
    const settings1 = RawSliverAppBarSettings(
      toolbarOpacity: 1.0,
      minExtent: 56.0,
      maxExtent: 200.0,
      currentExtent: 200.0,
      child: SizedBox(),
    );
    const settings2 = RawSliverAppBarSettings(
      toolbarOpacity: 1.0,
      minExtent: 56.0,
      maxExtent: 200.0,
      currentExtent: 200.0,
      child: SizedBox(),
    );
    const settings3 = RawSliverAppBarSettings(
      toolbarOpacity: 0.5,
      minExtent: 56.0,
      maxExtent: 200.0,
      currentExtent: 200.0,
      child: SizedBox(),
    );

    expect(settings1.updateShouldNotify(settings2), isFalse);
    expect(settings1.updateShouldNotify(settings3), isTrue);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Primary (MediaQuery top padding)
  // ──────────────────────────────────────────────────────────────────────────

  testWidgets('RawSliverAppBar with primary adds top padding to extents', (
    WidgetTester tester,
  ) async {
    const toolbarHeight = 56.0;
    const topPadding = 24.0;

    await tester.pumpWidget(_buildSimpleApp(primary: true, topPadding: topPadding));

    final RenderSliver renderSliver = tester.renderObject<RenderSliver>(
      find.byType(SliverPersistentHeader),
    );
    // maxExtent = topPadding + toolbarHeight = 24 + 56 = 80
    expect(renderSliver.geometry!.maxPaintExtent, topPadding + toolbarHeight);
  });

  testWidgets('RawSliverAppBar with primary=false ignores top padding', (
    WidgetTester tester,
  ) async {
    const toolbarHeight = 56.0;
    const topPadding = 24.0;

    await tester.pumpWidget(_buildSimpleApp(topPadding: topPadding));

    final RenderSliver renderSliver = tester.renderObject<RenderSliver>(
      find.byType(SliverPersistentHeader),
    );
    // primary is false, so topPadding is not included.
    expect(renderSliver.geometry!.maxPaintExtent, toolbarHeight);
  });

  testWidgets('RawSliverAppBar primary pinned collapsed height includes top padding', (
    WidgetTester tester,
  ) async {
    const toolbarHeight = 56.0;
    const expandedHeight = 200.0;
    const topPadding = 24.0;

    await tester.pumpWidget(
      _buildSimpleApp(
        expandedHeight: expandedHeight,
        primary: true,
        topPadding: topPadding,
        pinned: true,
      ),
    );

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;

    // Scroll to fully collapsed.
    position.jumpTo(500.0);
    await tester.pump();

    final RenderSliver renderSliver = tester.renderObject<RenderSliver>(
      find.byType(SliverPersistentHeader),
    );
    // Collapsed height = toolbarHeight + topPadding = 56 + 24 = 80
    expect(renderSliver.geometry!.paintExtent, toolbarHeight + topPadding);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Bottom widget
  // ──────────────────────────────────────────────────────────────────────────

  testWidgets('RawSliverAppBar bottom widget contributes to collapsed height', (
    WidgetTester tester,
  ) async {
    const toolbarHeight = 56.0;
    const bottomHeight = 48.0;
    const expandedHeight = 300.0;

    await tester.pumpWidget(
      _buildSimpleApp(
        expandedHeight: expandedHeight,
        pinned: true,
        bottom: const _TestBottom(height: bottomHeight),
      ),
    );

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;

    // Scroll to fully collapsed.
    position.jumpTo(500.0);
    await tester.pump();

    final RenderSliver renderSliver = tester.renderObject<RenderSliver>(
      find.byType(SliverPersistentHeader),
    );
    // collapsedHeight = toolbarHeight + bottomHeight = 56 + 48 = 104
    expect(renderSliver.geometry!.paintExtent, toolbarHeight + bottomHeight);
  });

  testWidgets('RawSliverAppBar pinned+floating+bottom collapses to just bottom+topPadding', (
    WidgetTester tester,
  ) async {
    const bottomHeight = 48.0;
    const expandedHeight = 300.0;

    await tester.pumpWidget(
      _buildSimpleApp(
        expandedHeight: expandedHeight,
        pinned: true,
        floating: true,
        bottom: const _TestBottom(height: bottomHeight),
      ),
    );

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;

    // Scroll to fully collapsed.
    position.jumpTo(500.0);
    await tester.pump();

    final RenderSliver renderSliver = tester.renderObject<RenderSliver>(
      find.byType(SliverPersistentHeader),
    );
    // When pinned && floating && bottom != null, collapsedHeight = 0 + bottomHeight + topPadding
    // = 0 + 48 + 0 = 48
    expect(renderSliver.geometry!.paintExtent, bottomHeight);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // forceElevated
  // ──────────────────────────────────────────────────────────────────────────

  testWidgets('RawSliverAppBar forceElevated makes isScrolledUnder true without scrolling', (
    WidgetTester tester,
  ) async {
    late bool receivedIsScrolledUnder;

    await tester.pumpWidget(
      _buildSimpleApp(
        forceElevated: true,
        pinned: true,
        appBarBuilder:
            (
              BuildContext context, {
              required double toolbarOpacity,
              required double bottomOpacity,
              required bool isScrolledUnder,
              required double minExtent,
              required double maxExtent,
              required double currentExtent,
            }) {
              receivedIsScrolledUnder = isScrolledUnder;
              return const SizedBox.expand();
            },
      ),
    );

    // Without any scrolling, isScrolledUnder should still be true due to forceElevated.
    expect(receivedIsScrolledUnder, isTrue);
  });

  testWidgets('RawSliverAppBar without forceElevated has isScrolledUnder=false initially', (
    WidgetTester tester,
  ) async {
    late bool receivedIsScrolledUnder;

    await tester.pumpWidget(
      _buildSimpleApp(
        pinned: true,
        appBarBuilder:
            (
              BuildContext context, {
              required double toolbarOpacity,
              required double bottomOpacity,
              required bool isScrolledUnder,
              required double minExtent,
              required double maxExtent,
              required double currentExtent,
            }) {
              receivedIsScrolledUnder = isScrolledUnder;
              return const SizedBox.expand();
            },
      ),
    );

    expect(receivedIsScrolledUnder, isFalse);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Edge cases and configuration changes
  // ──────────────────────────────────────────────────────────────────────────

  testWidgets('RawSliverAppBar stretchTriggerOffset must be positive', (WidgetTester tester) async {
    expect(
      () => RawSliverAppBar(
        toolbarHeight: 56.0,
        stretchTriggerOffset: 0.0,
        appBarBuilder: _defaultBuilder,
      ),
      throwsAssertionError,
    );
  });

  testWidgets('Changing snap from true to false updates correctly', (WidgetTester tester) async {
    // Start with snap: true, floating: true.
    await tester.pumpWidget(_buildSimpleApp(floating: true, snap: true));

    // Switch to snap: false (floating stays true).
    await tester.pumpWidget(_buildSimpleApp(floating: true));

    // No crash, widget updates fine.
    expect(find.byType(RawSliverAppBar), findsOneWidget);
  });

  testWidgets('Changing stretch updates configuration', (WidgetTester tester) async {
    await tester.pumpWidget(_buildSimpleApp(pinned: true));

    await tester.pumpWidget(_buildSimpleApp(stretch: true, pinned: true));

    // No crash, widget updates fine.
    expect(find.byType(RawSliverAppBar), findsOneWidget);
  });

  testWidgets('RawSliverAppBar removes bottom MediaQuery padding', (WidgetTester tester) async {
    late EdgeInsets receivedPadding;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(top: 24.0, bottom: 34.0)),
          child: CustomScrollView(
            slivers: <Widget>[
              RawSliverAppBar(
                toolbarHeight: 56.0,
                pinned: true,
                appBarBuilder:
                    (
                      BuildContext context, {
                      required double toolbarOpacity,
                      required double bottomOpacity,
                      required bool isScrolledUnder,
                      required double minExtent,
                      required double maxExtent,
                      required double currentExtent,
                    }) {
                      receivedPadding = MediaQuery.paddingOf(context);
                      return const SizedBox.expand();
                    },
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
                  return SizedBox(height: 100.0, child: Text('Item $index'));
                }, childCount: 50),
              ),
            ],
          ),
        ),
      ),
    );

    // RawSliverAppBar wraps with MediaQuery.removePadding(removeBottom: true),
    // so the builder should see bottom padding removed.
    expect(receivedPadding.bottom, 0.0);
    // Top padding should still be there (it's consumed by the bar itself when
    // primary is true, but the MediaQuery still has it).
    expect(receivedPadding.top, 24.0);
  });

  testWidgets('RawSliverAppBar pinned+floating+bottom: toolbar opacity fades', (
    WidgetTester tester,
  ) async {
    const bottomHeight = 48.0;
    const expandedHeight = 300.0;

    late double receivedToolbarOpacity;
    late double receivedBottomOpacity;

    await tester.pumpWidget(
      _buildSimpleApp(
        expandedHeight: expandedHeight,
        pinned: true,
        floating: true,
        bottom: const _TestBottom(height: bottomHeight),
        appBarBuilder:
            (
              BuildContext context, {
              required double toolbarOpacity,
              required double bottomOpacity,
              required bool isScrolledUnder,
              required double minExtent,
              required double maxExtent,
              required double currentExtent,
            }) {
              receivedToolbarOpacity = toolbarOpacity;
              receivedBottomOpacity = bottomOpacity;
              return const SizedBox.expand();
            },
      ),
    );

    // Initially fully visible.
    expect(receivedToolbarOpacity, 1.0);
    expect(receivedBottomOpacity, 1.0);

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;

    // Scroll to fully collapsed. For pinned+floating+bottom:
    // collapsedHeight = 0 + 48 + 0 = 48, so the toolbar fades out.
    position.jumpTo(500.0);
    await tester.pump();

    // Toolbar should have faded (isPinnedWithOpacityFade path).
    expect(receivedToolbarOpacity, 0.0);
    // Bottom should stay at 1.0 because pinned.
    expect(receivedBottomOpacity, 1.0);
  });
}
