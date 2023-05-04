// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'two_dimensional_utils.dart';

void main() {
  group('TwoDimensionalChildDelegate', () {
    group('TwoDimensionalChildBuilderDelegate', () {
      testWidgets('repaintBoundaries', (WidgetTester tester) async {
        // Default - adds repaint boundaries
        await tester.pumpWidget(buildSimpleTest(
          delegate: TwoDimensionalChildBuilderDelegate(
            // Only build 1 child
            maxXIndex: 0,
            maxYIndex: 0,
            builder: (BuildContext context, ChildVicinity vicinity) {
              return SizedBox(
                height: 200,
                width: 200,
                child: Center(child: Text('R${vicinity.xIndex}:C${vicinity.yIndex}')),
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
        await tester.pumpWidget(buildSimpleTest(
          delegate: TwoDimensionalChildBuilderDelegate(
            // Only build 1 child
            maxXIndex: 0,
            maxYIndex: 0,
            addRepaintBoundaries: false,
            builder: (BuildContext context, ChildVicinity vicinity) {
              return SizedBox(
                height: 200,
                width: 200,
                child: Center(child: Text('R${vicinity.xIndex}:C${vicinity.yIndex}')),
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
              child: Center(child: Text('R${vicinity.xIndex}:C${vicinity.yIndex}')),
            );
          }
        );
        await tester.pumpWidget(buildSimpleTest(
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
        await tester.pumpWidget(buildSimpleTest(
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
              child: Center(child: Text('R${vicinity.xIndex}:C${vicinity.yIndex}')),
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
        await tester.pumpWidget(buildSimpleTest(
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
        await tester.pumpWidget(buildSimpleTest(
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

    }, variant: TargetPlatformVariant.all());

    testWidgets('horizontal and vertical getters', (WidgetTester tester) async {
      // Assert if there is no state yet.

      // Gets state

    }, variant: TargetPlatformVariant.all());

    testWidgets('creates fallback ScrollControllers if not provided by ScrollableDetails', (WidgetTester tester) async {

    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts the axis directions do not conflict with one another', (WidgetTester tester) async {
      // Horizontal mismatch

      // Vertical mismatch

    }, variant: TargetPlatformVariant.all());

    testWidgets('correctly sets restorationIds', (WidgetTester tester) async {
      // with restorationID set

      // default restorationID

    }, variant: TargetPlatformVariant.all());

    testWidgets('Inner Scrollables receive the correct details from TwoDimensionalScrollable', (WidgetTester tester) async {
      // Default

      // Customized

    }, variant: TargetPlatformVariant.all());

    testWidgets('calls on the ScrollBehavior to build two scrollbars', (WidgetTester tester) async {
      // with restorationID set

      // default restorationID

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
    // Horizontal mismatch

    // Vertical mismatch
  });

  test('TwoDimensionalViewportParentData', () {
    // Default vicinity is invalid

    // isVisible cases

    // toString
  });

  test('ChildVicinity comparable', () {
    // ==

    // compareTo

    // hashCode

    // toString
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
