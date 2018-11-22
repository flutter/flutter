import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The viewport size comes from the test system. We explicitly declare it
  // here so that if a different viewport size is used we can change it for all
  // tests in the suite.
  const Size viewportSize = Size(800.0, 600.0);

  group('Plain CupertinoTableView', () {
    testWidgets('CupertinoTableView lays out prebuilt cells vertically like a list', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoTableView.plain(
            plainChildren: <Widget>[
              SizedBox(key: Key('cell1'), width: double.infinity, height: 100.0),
              SizedBox(key: Key('cell2'), width: double.infinity, height: 100.0),
              SizedBox(key: Key('cell3'), width: double.infinity, height: 100.0),
            ],
          ),
        ),
      );

      // Ensure that each cell in the list is laid out as wide as the viewport
      // and with a top-edge y-value that corresponds to the cells being stacked
      // vertically.
      final Offset box1TopRight = tester.getTopRight(find.byKey(const Key('cell1')));
      expect(box1TopRight, Offset(viewportSize.width, 0.0));

      final Offset box2TopRight = tester.getTopRight(find.byKey(const Key('cell2')));
      expect(box2TopRight, Offset(viewportSize.width, 100.0));

      final Offset box3TopRight = tester.getTopRight(find.byKey(const Key('cell3')));
      expect(box3TopRight, Offset(viewportSize.width, 200.0));
    });

    testWidgets('CupertinoTableView lays out lazily built cells vertically like a list', (WidgetTester tester) async {
      // We supply a custom ScrollController so that we can jump down the list
      // and force additional cells to be built.
      final ScrollController scrollController = ScrollController();

      // We'll build up to 20 table cells lazily.
      final IndexedWidgetBuilder widgetBuilder = (BuildContext context, int index) {
        // Build up to 20 cells.
        if (index < 20) {
          return const SizedBox(key: Key('cell'), width: double.infinity, height: 100.0);
        } else {
          return null;
        }
      };

      // We need to track which cells were built so that we can confirm the
      // lazy build behavior of CupertinoTableView.
      final _TrackingIndexedWidgetBuilder trackingWidgetBuilder = _TrackingIndexedWidgetBuilder(
        builder: widgetBuilder,
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoTableView.plainBuilder(
            scrollController: scrollController,
            plainChildCount: 20,
            plainChildrenBuilder: trackingWidgetBuilder.buildWithTracking,
          ),
        ),
      );

      // Ensure that the 6 visible cells really are rendered.
      expect(find.byKey(const Key('cell')).evaluate().length, 6);

      // Ensure that only 9 cells have been built (the 6 on screen + 3 more
      // due to cache extent).
      expect(trackingWidgetBuilder.didBuildAllWidgetsInRange(0, 9), true);
      expect(trackingWidgetBuilder.didNotBuildAnyWidgetsInRange(9, 20), true);

      // Ensure that the 6 on-screen cells have the correct width and y-values
      final Offset cell1TopRight = tester.getTopRight(find.byKey(const Key('cell')).at(0));
      expect(cell1TopRight, const Offset(800.0, 0.0));

      final Offset cell2TopRight = tester.getTopRight(find.byKey(const Key('cell')).at(1));
      expect(cell2TopRight, const Offset(800.0, 100.0));

      final Offset cell3TopRight = tester.getTopRight(find.byKey(const Key('cell')).at(2));
      expect(cell3TopRight, const Offset(800.0, 200.0));

      final Offset cell4TopRight = tester.getTopRight(find.byKey(const Key('cell')).at(3));
      expect(cell4TopRight, const Offset(800.0, 300.0));

      final Offset cell5TopRight = tester.getTopRight(find.byKey(const Key('cell')).at(4));
      expect(cell5TopRight, const Offset(800.0, 400.0));

      final Offset cell6TopRight = tester.getTopRight(find.byKey(const Key('cell')).at(5));
      expect(cell6TopRight, const Offset(800.0, 500.0));

      // Scroll all the way to the bottom and ensure that all 20 cells were built.
      scrollController.jumpTo(1400.0);
      await tester.pumpAndSettle();
      expect(trackingWidgetBuilder.didBuildAllWidgetsInRange(0, 20), true);
    });

    testWidgets('Empty CupertinoTableView draws dividers throughout the viewport', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoTableView.plain(
            plainChildren: <Widget>[],
          ),
        ),
      );

      // Find the dividers RenderObject and retrieve a description of its state.
      final RenderObject dividersSearchResult = tester.renderObject(find.byType(CupertinoTableViewExtraDividers));
      assert(dividersSearchResult != null, 'Could not locate the dividers render object.');
      final CupertinoTableViewExtraDividersRenderObject dividers = dividersSearchResult;
      final CupertinoTableViewExtraDividersDescription description = dividers.debugDescribe();

      // We expect the dividers to draw themselves because the content of the
      // CupertinoTableView is not scrollable.
      expect(description.isDrawingDividers, true);

      // We expect the dividers to be as tall as the default cell height.
      expect(description.dividerGapHeight, kDefaultTableViewCellHeight);

      // We expect the dividers to paint all available space because there are no cells.
      expect(description.extraDividersExtent, viewportSize.height);
    });

    test('CupertinoTableView decorates each cell with a divider', () {
      // TODO(mattcarroll):
    });

    testWidgets('CupertinoTableView draws extra dividers when content does not exceed viewport', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoTableView.plain(
            plainChildren: <Widget>[
              SizedBox(width: double.infinity, height: 100.0),
              SizedBox(width: double.infinity, height: 100.0),
              SizedBox(width: double.infinity, height: 100.0),
            ],
          ),
        ),
      );

      // Find the dividers RenderObject and retrieve a description of its state.
      final RenderObject dividersSearchResult = tester.renderObject(find.byType(CupertinoTableViewExtraDividers));
      assert(dividersSearchResult != null, 'Could not locate the dividers render object.');
      final CupertinoTableViewExtraDividersRenderObject dividers = dividersSearchResult;
      final CupertinoTableViewExtraDividersDescription description = dividers.debugDescribe();

      // We expect the dividers to draw themselves because the content of the
      // CupertinoTableView is not scrollable.
      expect(description.isDrawingDividers, true);

      // We expect the dividers to paint the height of the viewport minus the
      // total height of the cells.
      expect(description.extraDividersExtent, viewportSize.height - 300.0);
    });

    testWidgets('CupertinoTableView draws extra dividers with the same height as the last cell', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoTableView.plain(
            plainChildren: <Widget>[
              SizedBox(width: double.infinity, height: 100.0),
              SizedBox(width: double.infinity, height: 100.0),
              SizedBox(width: double.infinity, height: 100.0),
            ],
          ),
        ),
      );

      // We must pump and settle in this case because an extra frame is required
      // to report back the height of the last cell. Only then will the dividers
      // be drawn with the appropriate gap height.
      await tester.pumpAndSettle();

      // Find the dividers RenderObject and retrieve a description of its state.
      final RenderObject dividersSearchResult = tester.renderObject(find.byType(CupertinoTableViewExtraDividers));
      assert(dividersSearchResult != null, 'Could not locate the dividers render object.');
      final CupertinoTableViewExtraDividersRenderObject dividers = dividersSearchResult;
      final CupertinoTableViewExtraDividersDescription description = dividers.debugDescribe();

      // We expect the dividers to be as tall as the last cell's height.
      expect(description.dividerGapHeight, 100.0);
    });

    testWidgets('CupertinoTableView does not draw extra dividers when content exceeds viewport', (WidgetTester tester) async {
      final ScrollController scrollController = ScrollController();

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoTableView.plain(
            scrollController: scrollController,
            plainChildren: const <Widget>[
              SizedBox(width: double.infinity, height: 300.0),
              SizedBox(width: double.infinity, height: 300.0),
            ],
          ),
        ),
      );

      // Overscroll past the bottom of the list to force the dividers Sliver to
      // be created. Once it's created we can verify that it is not drawing dividers.
      scrollController.jumpTo(600.0);
      await tester.pumpAndSettle();

      // Find the dividers RenderObject and retrieve a description of its state.
      final RenderViewport renderViewport = tester.renderObject(find.byType(Viewport));
      final CupertinoTableViewExtraDividersRenderObject extraDividersSliver = renderViewport.lastChild;
      final CupertinoTableViewExtraDividersDescription description = extraDividersSliver.debugDescribe();

      // We do NOT expect the dividers to draw themselves because the content of
      // the CupertinoTableView is scrollable (exceeds the viewport).
      expect(description.isDrawingDividers, false);

      // When the dividers are not painted, the extent of the extra dividers
      // should be zero.
      expect(description.extraDividersExtent, 0.0);
    });
  });

  group('Grouped CupertinoTableView', () {
    // TODO(mattcarroll): fill out all group related tests
  });
}

class _TrackingIndexedWidgetBuilder {
  _TrackingIndexedWidgetBuilder({
    this.builder,
  });

  final Set<int> builtIndices = Set<int>();
  final IndexedWidgetBuilder builder;

  Widget buildWithTracking(BuildContext context, int index) {
    final Widget builtWidget = builder(context, index);

    if (builtWidget != null) {
      builtIndices.add(index);
    }

    return builtWidget;
  }

  bool didBuildWidget(int index) {
    return builtIndices.contains(index);
  }

  bool didBuildAllWidgetsInRange(int startIndex, int endIndexExclusive) {
    for (int i = startIndex; i < endIndexExclusive; i += 1) {
      if (!builtIndices.contains(i)) {
        return false;
      }
    }
    return true;
  }

  bool didNotBuildAnyWidgetsInRange(int startIndex, int endIndexExclusive) {
    for (int i = startIndex; i < endIndexExclusive; i += 1) {
      if (builtIndices.contains(i)) {
        return false;
      }
    }
    return true;
  }
}