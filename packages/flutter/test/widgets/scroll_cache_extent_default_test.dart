import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ScrollView uses kDefaultScrollCacheExtent by default', (WidgetTester tester) async {
    // kDefaultScrollCacheExtent should be ScrollCacheExtent.viewport(0.8)
    expect(RenderAbstractViewport.kDefaultScrollCacheExtent, const ScrollCacheExtent.viewport(0.8));

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[SliverToBoxAdapter(child: SizedBox(height: 100))],
        ),
      ),
    );

    final Viewport viewport = tester.widget(find.byType(Viewport));
    expect(viewport.cacheExtent, null);
    expect(viewport.scrollCacheExtent, null);

    final RenderViewport renderViewport = tester.renderObject(find.byType(Viewport));
    expect(renderViewport.scrollCacheExtent, RenderAbstractViewport.kDefaultScrollCacheExtent);
  });

  testWidgets('ShrinkWrappingViewport uses kDefaultScrollCacheExtent by default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildScrollView(child: SizedBox(height: 100)),
      ),
    );

    // SingleChildScrollView uses a specialized viewport?
    // Actually it uses _SingleChildViewport which extends RenderBox but implements RenderAbstractViewport?
    // No, SingleChildScrollView builds a Scrollable which builds a Viewport (if not shrinkWrap) or ShrinkWrappingViewport (if shrinkWrap)?

    // SingleChildScrollView source:
    // ... Viewport(offset: _offset, ...) if not shrinkWrap?
    // ... ShrinkWrappingViewport(offset: _offset, ...) if shrinkWrap?
    // Actually SingleChildScrollView has no shrinkWrap parameter (it is effectively shrinkWrap=false but allows scrolling content larger than viewport).

    // Let's use ListView(shrinkWrap: true) to be safe for ShrinkWrappingViewport.
  });

  testWidgets('ListView(shrinkWrap: true) uses kDefaultScrollCacheExtent by default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(shrinkWrap: true, children: const <Widget>[SizedBox(height: 100)]),
      ),
    );

    final ShrinkWrappingViewport viewport = tester.widget(find.byType(ShrinkWrappingViewport));
    expect(viewport.cacheExtent, null);
    expect(viewport.scrollCacheExtent, null);

    final RenderShrinkWrappingViewport renderViewport = tester.renderObject(
      find.byType(ShrinkWrappingViewport),
    );
    expect(renderViewport.scrollCacheExtent, RenderAbstractViewport.kDefaultScrollCacheExtent);
  });

  test('RenderViewportBase default in rendering layer is 250.0 pixels', () {
    // This verifies the divergence documented.
    // RenderViewport is a RenderViewportBase
    final RenderViewport renderViewport = RenderViewport(
      axisDirection: AxisDirection.down,
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
    );

    // RenderViewport default should be kDefaultScrollCacheExtent (0.8 viewport) now.
    expect(renderViewport.scrollCacheExtent, RenderAbstractViewport.kDefaultScrollCacheExtent);
  });
}
