import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const double VIEWPORT_HEIGHT = 600;
const double VIEWPORT_WIDTH = 300;

void main() {
  testWidgets('SliverMainAxisGroup is laid out properly', (WidgetTester tester) async {
  final List<int> items = List<int>.generate(20, (int i) => i);
  final ScrollController controller = ScrollController();

  await tester.pumpWidget(
    _buildSliverMainAxisGroup(
      controller: controller,
      slivers: <Widget>[
        _buildSliverList(itemMainAxisExtent: 300, items: items, label: (int item) => Text('Group 0 Tile $item')),
        _buildSliverList(itemMainAxisExtent: 200, items: items, label: (int item) => Text('Group 1 Tile $item')),
      ],
    ),
  );
  await tester.pumpAndSettle();

  expect(controller.offset, 0);

  expect(find.text('Group 0 Tile 0'), findsOneWidget);
  expect(find.text('Group 0 Tile 1'), findsOneWidget);
  expect(find.text('Group 0 Tile 2'), findsNothing);

  expect(find.text('Group 1 Tile 0'), findsNothing);

  const double scrollOffset = 19 * 300.0;
  controller.jumpTo(scrollOffset);
  await tester.pumpAndSettle();

  expect(controller.offset, scrollOffset);
  expect(find.text('Group 0 Tile 18'), findsNothing);
  expect(find.text('Group 0 Tile 19'), findsOneWidget);
  expect(find.text('Group 1 Tile 0'), findsOneWidget);

  final List<RenderSliverList> renderSlivers = tester.renderObjectList<RenderSliverList>(find.byType(SliverList)).toList();
  final RenderSliverList first = renderSlivers[0];
  final RenderSliverList second = renderSlivers[1];

  expect(first.geometry!.layoutExtent, equals(300.0));
  expect(second.geometry!.layoutExtent, equals(300.0));
  expect(first.geometry!.scrollExtent, equals(20 * 300.0));
  expect(second.geometry!.scrollExtent, equals(20 * 200.0));

  expect((first.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(0.0));
  expect(first.constraints.scrollOffset, equals(19 * 300.0));
  expect((second.parentData! as SliverPhysicalParentData).paintOffset.dy, equals(1 * 300.0));

  final RenderSliverMainAxisGroup renderGroup =
      tester.renderObject<RenderSliverMainAxisGroup>(find.byType(SliverMainAxisGroup));
  expect(renderGroup.geometry!.scrollExtent, equals(300 * 20 + 200 * 20));
});

}

Widget _buildSliverList({
  double itemMainAxisExtent = 100,
  List<int> items = const <int>[],
  required Widget Function(int) label,
  Axis scrollDirection = Axis.vertical,
}) {
  return SliverList(
    delegate: SliverChildBuilderDelegate(
      (BuildContext context, int i) {
        return scrollDirection == Axis.vertical
          ? SizedBox(
            key: ValueKey<int>(items[i]),
            height: itemMainAxisExtent,
            child: label(items[i]),
          )
          : SizedBox(
            key: ValueKey<int>(items[i]),
            width: itemMainAxisExtent,
            child: label(items[i]));
      },
      findChildIndexCallback: (Key key) {
        final ValueKey<int> valueKey = key as ValueKey<int>;
        final int index = items.indexOf(valueKey.value);
        return index == -1 ? null : index;
      },
      childCount: items.length,
    ),
  );
}

Widget _buildSliverMainAxisGroup({
  required List<Widget> slivers,
  ScrollController? controller,
  double viewportHeight = VIEWPORT_HEIGHT,
  double viewportWidth = VIEWPORT_WIDTH,
  Axis scrollDirection = Axis.vertical,
  bool reverse = false,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        height: viewportHeight,
        width: viewportWidth,
        child: CustomScrollView(
          scrollDirection: scrollDirection,
          reverse: reverse,
          controller: controller,
          slivers: <Widget>[SliverMainAxisGroup(slivers: slivers)],
        ),
      ),
    ),
  );
}