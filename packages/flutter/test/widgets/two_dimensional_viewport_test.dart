// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'two_dimensional_utils.dart';

void main() {
  group('TwoDimensionalChildDelegate', () {
    group('TwoDimensionalChildBuilderDelegate', () {
      testWidgets('repaintBoundaries', (WidgetTester tester) async {
        // Default - adds repaint boundaries
        await tester.pumpWidget(simpleBuilderTest(
          delegate: TwoDimensionalChildBuilderDelegate(
            // Only build 1 child
            maxXIndex: 0,
            maxYIndex: 0,
            builder: (BuildContext context, ChildVicinity vicinity) {
              return SizedBox(
                height: 200,
                width: 200,
                child: Center(child: Text('C${vicinity.xIndex}:R${vicinity.yIndex}')),
              );
            }
          )
        ));
        await tester.pumpAndSettle();

        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
            expect(find.byType(RepaintBoundary), findsNWidgets(7));
          case TargetPlatform.iOS:
          case TargetPlatform.linux:
          case TargetPlatform.macOS:
          case TargetPlatform.windows:
            expect(find.byType(RepaintBoundary), findsNWidgets(3));
        }

        // None
        await tester.pumpWidget(simpleBuilderTest(
          delegate: TwoDimensionalChildBuilderDelegate(
            // Only build 1 child
            maxXIndex: 0,
            maxYIndex: 0,
            addRepaintBoundaries: false,
            builder: (BuildContext context, ChildVicinity vicinity) {
              return SizedBox(
                height: 200,
                width: 200,
                child: Center(child: Text('C${vicinity.xIndex}:R${vicinity.yIndex}')),
              );
            }
          )
        ));
        await tester.pumpAndSettle();

        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
            expect(find.byType(RepaintBoundary), findsNWidgets(6));
          case TargetPlatform.iOS:
          case TargetPlatform.linux:
          case TargetPlatform.macOS:
          case TargetPlatform.windows:
            expect(find.byType(RepaintBoundary), findsNWidgets(2));
        }
      }, variant: TargetPlatformVariant.all());

      testWidgets('will return null from build for exceeding maxXIndex and maxYIndex', (WidgetTester tester) async {
        late BuildContext capturedContext;
        final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
          // Only build 1 child
          maxXIndex: 0,
          maxYIndex: 0,
          addRepaintBoundaries: false,
          builder: (BuildContext context, ChildVicinity vicinity) {
            capturedContext = context;
            return SizedBox(
              height: 200,
              width: 200,
              child: Center(child: Text('C${vicinity.xIndex}:R${vicinity.yIndex}')),
            );
          }
        );
        await tester.pumpWidget(simpleBuilderTest(
          delegate: delegate,
        ));
        await tester.pumpAndSettle();
        // maxXIndex
        expect(
          delegate.build(capturedContext, const ChildVicinity(xIndex: 1, yIndex: 0)),
          isNull,
        );

        // maxYIndex
        expect(
          delegate.build(capturedContext, const ChildVicinity(xIndex: 0, yIndex: 1)),
          isNull,
        );

        // Both
        expect(
          delegate.build(capturedContext, const ChildVicinity(xIndex: 1, yIndex: 1)),
          isNull,
        );
      }, variant: TargetPlatformVariant.all());

      testWidgets('throws an error when builder throws', (WidgetTester tester) async {
        final List<Object> exceptions = <Object>[];
        final FlutterExceptionHandler? oldHandler = FlutterError.onError;
        FlutterError.onError = (FlutterErrorDetails details) {
          exceptions.add(details.exception);
        };
        final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
          // Only build 1 child
          maxXIndex: 0,
          maxYIndex: 0,
          addRepaintBoundaries: false,
          builder: (BuildContext context, ChildVicinity vicinity) {
            throw 'Builder error!';
          }
        );
        await tester.pumpWidget(simpleBuilderTest(
          delegate: delegate,
        ));
        await tester.pumpAndSettle();
        FlutterError.onError = oldHandler;

        expect(exceptions.isNotEmpty, isTrue);
        expect(exceptions.length, 1);
        expect(exceptions[0] as String, contains('Builder error!'));
      }, variant: TargetPlatformVariant.all());

      testWidgets('shouldRebuild', (WidgetTester tester) async {
        final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
          builder: (BuildContext context, ChildVicinity vicinity) {
            return SizedBox(
              height: 200,
              width: 200,
              child: Center(child: Text('C${vicinity.xIndex}:R${vicinity.yIndex}')),
            );
          }
        );
        expect(delegate.shouldRebuild(delegate), isTrue);
      }, variant: TargetPlatformVariant.all());
    });

    group('TwoDimensionalChildListDelegate', () {
      testWidgets('repaintBoundaries', (WidgetTester tester) async {
        final List<List<Widget>> children = <List<Widget>>[];
        children.add(<Widget>[
          const SizedBox(
            height: 200,
            width: 200,
            child: Center(child: Text('R0:C0')),
          )
        ]);
        // Default - adds repaint boundaries
        await tester.pumpWidget(simpleListTest(
          delegate: TwoDimensionalChildListDelegate(
            // Only builds 1 child
            children: children,
          )
        ));
        await tester.pumpAndSettle();

        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
            expect(find.byType(RepaintBoundary), findsNWidgets(7));
          case TargetPlatform.iOS:
          case TargetPlatform.linux:
          case TargetPlatform.macOS:
          case TargetPlatform.windows:
            expect(find.byType(RepaintBoundary), findsNWidgets(3));
        }

        // None
        await tester.pumpWidget(simpleListTest(
          delegate: TwoDimensionalChildListDelegate(
            // Different children triggers rebuild
            children: <List<Widget>>[<Widget>[Container()]],
            addRepaintBoundaries: false,
          )
        ));
        await tester.pumpAndSettle();

        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
            expect(find.byType(RepaintBoundary), findsNWidgets(6));
          case TargetPlatform.iOS:
          case TargetPlatform.linux:
          case TargetPlatform.macOS:
          case TargetPlatform.windows:
            expect(find.byType(RepaintBoundary), findsNWidgets(2));
        }
      }, variant: TargetPlatformVariant.all());

      testWidgets('will return null for a ChildVicinity outside of list bounds', (WidgetTester tester) async {
        final List<List<Widget>> children = <List<Widget>>[];
        children.add(<Widget>[
          const SizedBox(
            height: 200,
            width: 200,
            child: Center(child: Text('R0:C0')),
          )
        ]);
        final TwoDimensionalChildListDelegate delegate = TwoDimensionalChildListDelegate(
          // Only builds 1 child
          children: children,
        );

        // X index
        expect(
          delegate.build(_NullBuildContext(), const ChildVicinity(xIndex: 1, yIndex: 0)),
          isNull,
        );
        // Y index
        expect(
          delegate.build(_NullBuildContext(), const ChildVicinity(xIndex: 0, yIndex: 1)),
          isNull,
        );

        // Both
        expect(
          delegate.build(_NullBuildContext(), const ChildVicinity(xIndex: 1, yIndex: 1)),
          isNull,
        );
      }, variant: TargetPlatformVariant.all());

      testWidgets('shouldRebuild', (WidgetTester tester) async {
        final List<List<Widget>> children = <List<Widget>>[];
        children.add(<Widget>[
          const SizedBox(
            height: 200,
            width: 200,
            child: Center(child: Text('R0:C0')),
          )
        ]);
        final TwoDimensionalChildListDelegate delegate = TwoDimensionalChildListDelegate(
          // Only builds 1 child
          children: children,
        );
        expect(delegate.shouldRebuild(delegate), isFalse);

        final List<List<Widget>> newChildren = <List<Widget>>[];
        final TwoDimensionalChildListDelegate oldDelegate = TwoDimensionalChildListDelegate(
          children: newChildren,
        );

        expect(delegate.shouldRebuild(oldDelegate), isTrue);
      }, variant: TargetPlatformVariant.all());
    });
  });

  group('TwoDimensionalScrollable', () {
    testWidgets('.of, .maybeOf', (WidgetTester tester) async {
      late BuildContext capturedContext;
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 0,
        maxYIndex: 0,
        builder: (BuildContext context, ChildVicinity vicinity) {
          capturedContext = context;
          return const SizedBox.square(dimension: 200);
        }
      );
      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
      ));
      await tester.pumpAndSettle();

      expect(TwoDimensionalScrollable.of(capturedContext), isNotNull);
      expect(TwoDimensionalScrollable.maybeOf(capturedContext), isNotNull);

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          capturedContext = context;
          TwoDimensionalScrollable.of(context);
          return Container();
        }
      ));
      await tester.pumpAndSettle();
      final dynamic exception = tester.takeException();
      expect(exception, isFlutterError);
      final FlutterError error = exception as FlutterError;
      expect(error.toString(), contains(
        'TwoDimensionalScrollable.of() was called with a context that does '
        'not contain a TwoDimensionalScrollable widget.'
      ));

      expect(TwoDimensionalScrollable.maybeOf(capturedContext), isNull);
    }, variant: TargetPlatformVariant.all());

    testWidgets('horizontal and vertical getters', (WidgetTester tester) async {
      late BuildContext capturedContext;
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 0,
        maxYIndex: 0,
        builder: (BuildContext context, ChildVicinity vicinity) {
          capturedContext = context;
          return const SizedBox.square(dimension: 200);
        }
      );
      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
      ));
      await tester.pumpAndSettle();

      final TwoDimensionalScrollableState scrollable = TwoDimensionalScrollable.of(capturedContext);
      expect(scrollable.verticalScrollable.position.pixels, 0.0);
      expect(scrollable.horizontalScrollable.position.pixels, 0.0);
    }, variant: TargetPlatformVariant.all());

    testWidgets('creates fallback ScrollControllers if not provided by ScrollableDetails', (WidgetTester tester) async {
      late BuildContext capturedContext;
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 0,
        maxYIndex: 0,
        builder: (BuildContext context, ChildVicinity vicinity) {
          capturedContext = context;
          return const SizedBox.square(dimension: 200);
        }
      );
      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
      ));
      await tester.pumpAndSettle();

      // Vertical
      final ScrollableState vertical = Scrollable.of(capturedContext, axis: Axis.vertical);
      expect(vertical.widget.controller, isNotNull);
      // Horizontal
      final ScrollableState horizontal = Scrollable.of(capturedContext, axis: Axis.horizontal);
      expect(horizontal.widget.controller, isNotNull);
    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts the axis directions do not conflict with one another', (WidgetTester tester) async {
      final List<Object> exceptions = <Object>[];
      final FlutterExceptionHandler? oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        exceptions.add(details.exception);
      };
      // Horizontal mismatch
      await tester.pumpWidget(TwoDimensionalScrollable(
        horizontalDetails: const ScrollableDetails.horizontal(),
        verticalDetails: const ScrollableDetails.horizontal(),
        viewportBuilder: (BuildContext context, ViewportOffset verticalPosition, ViewportOffset horizontalPosition) {
          return Container();
        },
      ));

      // Vertical mismatch
      await tester.pumpWidget(TwoDimensionalScrollable(
        horizontalDetails: const ScrollableDetails.vertical(),
        verticalDetails: const ScrollableDetails.vertical(),
        viewportBuilder: (BuildContext context, ViewportOffset verticalPosition, ViewportOffset horizontalPosition) {
          return Container();
        },
      ));

      // Both
      await tester.pumpWidget(TwoDimensionalScrollable(
        horizontalDetails: const ScrollableDetails.vertical(),
        verticalDetails: const ScrollableDetails.horizontal(),
        viewportBuilder: (BuildContext context, ViewportOffset verticalPosition, ViewportOffset horizontalPosition) {
          return Container();
        },
      ));

      expect(exceptions.length, 3);
      for (final Object exception in exceptions) {
        expect(exception, isAssertionError);
        expect((exception as AssertionError).message, contains('are not Axis'));
      }
      FlutterError.onError = oldHandler;
    }, variant: TargetPlatformVariant.all());

    testWidgets('correctly sets restorationIds', (WidgetTester tester) async {
      late BuildContext capturedContext;
      // with restorationID set
      await tester.pumpWidget(TwoDimensionalScrollable(
        restorationId: 'Custom Restoration ID',
        horizontalDetails: const ScrollableDetails.horizontal(),
        verticalDetails: const ScrollableDetails.vertical(),
        viewportBuilder: (BuildContext context, ViewportOffset verticalPosition, ViewportOffset horizontalPosition) {
          return SizedBox.square(
            dimension: 200,
            child: Builder(
              builder: (BuildContext context) {
                capturedContext = context;
                return Container();
              },
            )
          );
        },
      ));
      await tester.pumpAndSettle();

      // TODO(Piinks): Ask goderbauer why this isn't finding the restoration scope.
      // expect(
      //   RestorationScope.of(capturedContext).restorationId,
      //   'Custom Restoration ID',
      // );
      expect(
        Scrollable.of(capturedContext, axis: Axis.vertical).widget.restorationId,
        'OuterVerticalTwoDimensionalScrollable',
      );
      expect(
        Scrollable.of(capturedContext, axis: Axis.horizontal).widget.restorationId,
        'InnerHorizontalTwoDimensionalScrollable',
      );

      // default restorationID
      await tester.pumpWidget(TwoDimensionalScrollable(
        horizontalDetails: const ScrollableDetails.horizontal(),
        verticalDetails: const ScrollableDetails.vertical(),
        viewportBuilder: (BuildContext context, ViewportOffset verticalPosition, ViewportOffset horizontalPosition) {
          return SizedBox.square(
            dimension: 200,
            child: Builder(
              builder: (BuildContext context) {
                capturedContext = context;
                return Container();
              },
            )
          );
        },
      ));
      await tester.pumpAndSettle();

      expect(
        RestorationScope.maybeOf(capturedContext),
        isNull,
      );
      expect(
        Scrollable.of(capturedContext, axis: Axis.vertical).widget.restorationId,
        'OuterVerticalTwoDimensionalScrollable',
      );
      expect(
        Scrollable.of(capturedContext, axis: Axis.horizontal).widget.restorationId,
        'InnerHorizontalTwoDimensionalScrollable',
      );
    }, variant: TargetPlatformVariant.all());

    testWidgets('Inner Scrollables receive the correct details from TwoDimensionalScrollable', (WidgetTester tester) async {
      // Default
      late BuildContext capturedContext;
      await tester.pumpWidget(TwoDimensionalScrollable(
        horizontalDetails: const ScrollableDetails.horizontal(),
        verticalDetails: const ScrollableDetails.vertical(),
        viewportBuilder: (BuildContext context, ViewportOffset verticalPosition, ViewportOffset horizontalPosition) {
          return SizedBox.square(
            dimension: 200,
            child: Builder(
              builder: (BuildContext context) {
                capturedContext = context;
                return Container();
              },
            )
          );
        },
      ));
      await tester.pumpAndSettle();

      // Vertical
      ScrollableState vertical = Scrollable.of(capturedContext, axis: Axis.vertical);
      expect(vertical.widget.key, isNotNull);
      expect(vertical.widget.axisDirection, AxisDirection.down);
      expect(vertical.widget.controller, isNotNull);
      expect(vertical.widget.physics, isNull);
      expect(vertical.widget.clipBehavior, Clip.hardEdge);
      expect(vertical.widget.incrementCalculator, isNull);
      expect(vertical.widget.excludeFromSemantics, isFalse);
      expect(vertical.widget.restorationId, 'OuterVerticalTwoDimensionalScrollable');
      expect(vertical.widget.dragStartBehavior, DragStartBehavior.start);

      // Horizontal
      ScrollableState horizontal = Scrollable.of(capturedContext, axis: Axis.horizontal);
      expect(horizontal.widget.key, isNotNull);
      expect(horizontal.widget.axisDirection, AxisDirection.right);
      expect(horizontal.widget.controller, isNotNull);
      expect(horizontal.widget.physics, isNull);
      expect(horizontal.widget.clipBehavior, Clip.hardEdge);
      expect(horizontal.widget.incrementCalculator, isNull);
      expect(horizontal.widget.excludeFromSemantics, isFalse);
      expect(horizontal.widget.restorationId, 'InnerHorizontalTwoDimensionalScrollable');
      expect(horizontal.widget.dragStartBehavior, DragStartBehavior.start);

      // Customized
      final ScrollController horizontalController = ScrollController();
      final ScrollController verticalController = ScrollController();
      double calculator(_) => 0.0;
      await tester.pumpWidget(TwoDimensionalScrollable(
        incrementCalculator: calculator,
        excludeFromSemantics: true,
        dragStartBehavior: DragStartBehavior.down,
        horizontalDetails: ScrollableDetails.horizontal(
          reverse: true,
          controller: horizontalController,
          physics: const ClampingScrollPhysics(),
          decorationClipBehavior: Clip.antiAlias,
        ),
        verticalDetails: ScrollableDetails.vertical(
          reverse: true,
          controller: verticalController,
          physics: const AlwaysScrollableScrollPhysics(),
          decorationClipBehavior: Clip.antiAliasWithSaveLayer,
        ),
        viewportBuilder: (BuildContext context, ViewportOffset verticalPosition, ViewportOffset horizontalPosition) {
          return SizedBox.square(
            dimension: 200,
            child: Builder(
              builder: (BuildContext context) {
                capturedContext = context;
                return Container();
              },
            )
          );
        },
      ));
      await tester.pumpAndSettle();

      // Vertical
      vertical = Scrollable.of(capturedContext, axis: Axis.vertical);
      expect(vertical.widget.key, isNotNull);
      expect(vertical.widget.axisDirection, AxisDirection.up);
      expect(vertical.widget.controller, verticalController);
      expect(vertical.widget.physics, const AlwaysScrollableScrollPhysics());
      expect(vertical.widget.clipBehavior, Clip.antiAliasWithSaveLayer);
      expect(
        vertical.widget.incrementCalculator!(ScrollIncrementDetails(
          type: ScrollIncrementType.line,
          metrics: verticalController.position,
        )),
        0.0,
      );
      expect(vertical.widget.excludeFromSemantics, isTrue);
      expect(vertical.widget.restorationId, 'OuterVerticalTwoDimensionalScrollable');
      expect(vertical.widget.dragStartBehavior, DragStartBehavior.down);

      // Horizontal
      horizontal = Scrollable.of(capturedContext, axis: Axis.horizontal);
      expect(horizontal.widget.key, isNotNull);
      expect(horizontal.widget.axisDirection, AxisDirection.left);
      expect(horizontal.widget.controller, horizontalController);
      expect(horizontal.widget.physics, const ClampingScrollPhysics());
      expect(horizontal.widget.clipBehavior, Clip.antiAlias);
      expect(
        horizontal.widget.incrementCalculator!(ScrollIncrementDetails(
          type: ScrollIncrementType.line,
          metrics: horizontalController.position,
        )),
        0.0,
      );
      expect(horizontal.widget.excludeFromSemantics, isTrue);
      expect(horizontal.widget.restorationId, 'InnerHorizontalTwoDimensionalScrollable');
      expect(horizontal.widget.dragStartBehavior, DragStartBehavior.down);
    }, variant: TargetPlatformVariant.all());

    group('DiagonalDragBehavior', () {
      testWidgets('none (default)', (WidgetTester tester) async {

      }, variant: TargetPlatformVariant.all());

      testWidgets('weightedEvent', (WidgetTester tester) async {

      }, variant: TargetPlatformVariant.all());

      testWidgets('weightedContinuous', (WidgetTester tester) async {

      }, variant: TargetPlatformVariant.all());

      testWidgets('free', (WidgetTester tester) async {

      }, variant: TargetPlatformVariant.all());
    });
  });

  testWidgets('TwoDimensionalViewport asserts against axes mismatch', (WidgetTester tester) async {
    final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
      maxXIndex: 0,
      maxYIndex: 0,
      builder: (BuildContext context, ChildVicinity vicinity) {
        return const SizedBox.square(dimension: 200);
      }
    );

    // Horizontal mismatch
    expect(
      () {
        SimpleBuilderTableViewport(
          verticalOffset: ViewportOffset.fixed(0.0),
          verticalAxisDirection: AxisDirection.left,
          horizontalOffset: ViewportOffset.fixed(0.0),
          horizontalAxisDirection: AxisDirection.right,
          delegate: delegate,
          mainAxis: Axis.vertical,
        );
      },
      throwsA(
        isA<AssertionError>().having(
          (AssertionError error) => error.toString(),
          'description',
          contains('AxisDirection is not Axis.'),
        ),
      ),
    );

    // Vertical mismatch
    expect(
      () {
        SimpleBuilderTableViewport(
          verticalOffset: ViewportOffset.fixed(0.0),
          verticalAxisDirection: AxisDirection.up,
          horizontalOffset: ViewportOffset.fixed(0.0),
          horizontalAxisDirection: AxisDirection.down,
          delegate: delegate,
          mainAxis: Axis.vertical,
        );
      },
      throwsA(
        isA<AssertionError>().having(
          (AssertionError error) => error.toString(),
          'description',
          contains('AxisDirection is not Axis.'),
        ),
      ),
    );

    // Both
    expect(
      () {
        SimpleBuilderTableViewport(
          verticalOffset: ViewportOffset.fixed(0.0),
          verticalAxisDirection: AxisDirection.left,
          horizontalOffset: ViewportOffset.fixed(0.0),
          horizontalAxisDirection: AxisDirection.down,
          delegate: delegate,
          mainAxis: Axis.vertical,
        );
      },
      throwsA(
        isA<AssertionError>().having(
          (AssertionError error) => error.toString(),
          'description',
          contains('AxisDirection is not Axis.'),
        ),
      ),
    );
  });

  test('TwoDimensionalViewportParentData', () {
    // Default vicinity is invalid
    final TwoDimensionalViewportParentData parentData = TwoDimensionalViewportParentData();
    expect(parentData.vicinity, ChildVicinity.invalid);

    // toString
    parentData
      ..vicinity = const ChildVicinity(xIndex: 10, yIndex: 10)
      ..paintOffset = const Offset(20.0, 20.0)
      ..layoutOffset = const Offset(20.0, 20.0);
    expect(
      parentData.toString(),
      'vicinity=(yIndex: 10, xIndex: 10); layoutOffset=Offset(20.0, 20.0); '
      'paintOffset=Offset(20.0, 20.0); not visible ',
    );
  });

  test('ChildVicinity comparable', () {
    const ChildVicinity baseVicinity = ChildVicinity(xIndex: 0, yIndex: 0);
    const ChildVicinity sameXVicinity = ChildVicinity(xIndex: 0, yIndex: 2);
    const ChildVicinity sameYVicinity = ChildVicinity(xIndex: 3, yIndex: 0);
    const ChildVicinity sameNothingVicinity = ChildVicinity(xIndex: 20, yIndex: 30);
    // ==
    expect(baseVicinity == baseVicinity, isTrue);
    expect(baseVicinity == sameXVicinity, isFalse);
    expect(baseVicinity == sameYVicinity, isFalse);
    expect(baseVicinity == sameNothingVicinity, isFalse);

    // compareTo
    expect(baseVicinity.compareTo(baseVicinity), 0);
    expect(baseVicinity.compareTo(sameXVicinity), -2);
    expect(baseVicinity.compareTo(sameYVicinity), -3);
    expect(baseVicinity.compareTo(sameNothingVicinity), -20);

    // toString
    expect(baseVicinity.toString(), '(yIndex: 0, xIndex: 0)');
    expect(sameXVicinity.toString(), '(yIndex: 2, xIndex: 0)');
    expect(sameYVicinity.toString(), '(yIndex: 0, xIndex: 3)');
    expect(sameNothingVicinity.toString(), '(yIndex: 30, xIndex: 20)');
  });

  group('RenderTwoDimensionalViewport', () {
    testWidgets('asserts against axes mismatch', (WidgetTester tester) async {
      // Horizontal mismatch

      // Vertical mismatch
    });

    testWidgets('getters', (WidgetTester tester) async {
      // clipBehavior

      // cacheExtent

      // isRepaintBoundary

      // sizedByParent

      // viewportDimension - also asserts hasSize

      // horizontalOffset

      // horizontalAxisDirection

      // verticalOffset

      // verticalAxisDirection

      // delegate

      // mainAxis
    }, variant: TargetPlatformVariant.all());

    testWidgets('childrenInPaintOrder correlates with mainAxis', (WidgetTester tester) async {
      // mainAxis is vertical

      // mainAxis is horizontal
    }, variant: TargetPlatformVariant.all());

    testWidgets('sets up parent data', (WidgetTester tester) async {
      // parent data is TwoDimensionalViewportParentData

      // parentDataOf method works

      // parentData is computed correctly - normal axes
      // - layoutOffset, paintOffset, paintExtent, isVisible, ChildVicinity

      // parentData is computed correctly - reverse axes
      // - vertical reverse, horizontal reverse, both reverse
    }, variant: TargetPlatformVariant.all());

    testWidgets('computeChildPaintExtent', (WidgetTester tester) async {
      // Full view
      // Scrolled into top
      // Scrolled into bottom
      // Scrolled into leading edge
      // Scrolled into trailing edge
      // Scrolled into top left corner
      // Scrolled into top right corner
      // Scrolled into bottom left corner
      // Scrolled into bottom right corner

      // Reversed, vertical, horizontal, both
    }, variant: TargetPlatformVariant.all());

    testWidgets('computeChildPaintOffset', (WidgetTester tester) async {
      // Normal axes

      // Reversed, vertical, horizontal, both
    }, variant: TargetPlatformVariant.all());

    testWidgets('debugDescribeChildren', (WidgetTester tester) async {

    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts that both axes are bounded', (WidgetTester tester) async {
      // Compose unbounded

      // Call computeDryLayout with unbounded constraints
    }, variant: TargetPlatformVariant.all());

    testWidgets('correctly resizes dimensions', (WidgetTester tester) async {
      // performResize

      // didResize
    }, variant: TargetPlatformVariant.all());

    testWidgets('needsDelegateRebuild', (WidgetTester tester) async {

    }, variant: TargetPlatformVariant.all());

    testWidgets('hitTestChildren', (WidgetTester tester) async {

    }, variant: TargetPlatformVariant.all());

    testWidgets('getChildFor', (WidgetTester tester) async {
      // returns child

      // returns null
    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts vicinity is valid', (WidgetTester tester) async {
      // buildOrObtainChildFor

      // _checkVicinity
    }, variant: TargetPlatformVariant.all());

    testWidgets('buildOrObtainChild can return null', (WidgetTester tester) async {
      // buildOrObtainChildFor

      // _checkVicinity
    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts the vicinity of the parent data is correct', (WidgetTester tester) async {
      // _checkVicinity
    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts that content dimensions have been applied', (WidgetTester tester) async {
      // Vertical

      // Horizontal
    }, variant: TargetPlatformVariant.all());

    testWidgets('will not rebuild a child if it can be reused', (WidgetTester tester) async {

    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts the layoutOffset has been set by the subclass', (WidgetTester tester) async {

    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts the children have a size after layoutChildSequence', (WidgetTester tester) async {

    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts the children have been laid out with parentUsesSize: true', (WidgetTester tester) async {

    }, variant: TargetPlatformVariant.all());

    testWidgets('does not support intrinsics', (WidgetTester tester) async {
      // computeMinIntrinsicWidth

      // computeMaxIntrinsicWidth

      // computeMinIntrinsicHeight

      // computeMaxIntrinsicHeight
    }, variant: TargetPlatformVariant.all());
  });
}

class _NullBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
