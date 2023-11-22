import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'SliverGridDelegateWithFixedCrossAxisCount mainAxisExtent corrected',
      (WidgetTester tester) async {
    const SliverGridDelegateWithFixedCrossAxisCount delegate =
        SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      mainAxisExtent: -100,
    );

    final SliverGridRegularTileLayout sliverGridRegularTileLayout =
        delegate.getLayout(
      const SliverConstraints(
        axisDirection: AxisDirection.down,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.forward,
        scrollOffset: 100.0,
        precedingScrollExtent: 0.0,
        overlap: 0.0,
        remainingPaintExtent: 0.0,
        crossAxisExtent: 500,
        crossAxisDirection: AxisDirection.right,
        viewportMainAxisExtent: 100.0,
        remainingCacheExtent: 0.0,
        cacheOrigin: 0.0,
      ),
    ) as SliverGridRegularTileLayout;

    expect(sliverGridRegularTileLayout.childMainAxisExtent, 0);
  });

  testWidgets(
      'SliverGridDelegateWithMaxCrossAxisExtent mainAxisExtent corrected',
      (WidgetTester tester) async {
    const SliverGridDelegateWithMaxCrossAxisExtent delegate =
        SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 100,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      mainAxisExtent: -100,
    );

    final SliverGridRegularTileLayout sliverGridRegularTileLayout =
        delegate.getLayout(
      const SliverConstraints(
        axisDirection: AxisDirection.down,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.forward,
        scrollOffset: 100.0,
        precedingScrollExtent: 0.0,
        overlap: 0.0,
        remainingPaintExtent: 0.0,
        crossAxisExtent: 500,
        crossAxisDirection: AxisDirection.right,
        viewportMainAxisExtent: 100.0,
        remainingCacheExtent: 0.0,
        cacheOrigin: 0.0,
      ),
    ) as SliverGridRegularTileLayout;

    expect(sliverGridRegularTileLayout.childMainAxisExtent, 0);
  });
}
