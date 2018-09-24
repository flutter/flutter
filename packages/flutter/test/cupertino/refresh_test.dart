// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  MockHelper mockHelper;

  /// Completer that holds the future given to the CupertinoSliverRefreshControl.
  Completer<void> refreshCompleter;

  /// The widget that the indicator builder given to the CupertinoSliverRefreshControl
  /// returns.
  Widget refreshIndicator;

  /// These two Functions are required to avoid tearing off of the MockHelper object,
  /// which is not supported when using Dart 2 runtime semantics.
  final Function builder = (BuildContext context, RefreshIndicatorMode refreshState,
          double pulledExtent,
          double refreshTriggerPullDistance,
          double refreshIndicatorExtent) =>
      mockHelper.builder(context, refreshState, pulledExtent, refreshTriggerPullDistance,
          refreshIndicatorExtent);

  final Function onRefresh = () => mockHelper.refreshTask();

  setUp(() {
    mockHelper = MockHelper();
    refreshCompleter = Completer<void>.sync();
    refreshIndicator = Container();

    when(mockHelper.builder(
            any, any, any, any, any))
        .thenAnswer((Invocation i) {
      final RefreshIndicatorMode refreshState = i.positionalArguments[1];
      final double pulledExtent = i.positionalArguments[2];
      final double refreshTriggerPullDistance = i.positionalArguments[3];
      final double refreshIndicatorExtent = i.positionalArguments[4];
      if (refreshState == RefreshIndicatorMode.inactive) {
        throw TestFailure(
          'RefreshControlIndicatorBuilder should never be called with the '
          "inactive state because there's nothing to build in that case"
        );
      }
      if (pulledExtent < 0.0) {
        throw TestFailure('The pulledExtent should never be less than 0.0');
      }
      if (refreshTriggerPullDistance < 0.0) {
        throw TestFailure('The refreshTriggerPullDistance should never be less than 0.0');
      }
      if (refreshIndicatorExtent < 0.0) {
        throw TestFailure('The refreshIndicatorExtent should never be less than 0.0');
      }
      return refreshIndicator;
    });
    when(mockHelper.refreshTask()).thenAnswer((_) => refreshCompleter.future);
  });

  int testListLength = 10;
  SliverList buildAListOfStuff() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return Container(
            height: 200.0,
            child: Center(child: Text(index.toString())),
          );
        },
        childCount: testListLength,
      ),
    );
  }

  final Function uiTestGroup = () {
    testWidgets("doesn't invoke anything without user interaction", (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            slivers: <Widget>[
              CupertinoSliverRefreshControl(
                builder: builder,
              ),
              buildAListOfStuff(),
            ],
          ),
        ),
      );

      verifyNoMoreInteractions(mockHelper);

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '0')),
        const Offset(0.0, 0.0),
      );

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('calls the indicator builder when starting to overscroll', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            slivers: <Widget>[
              CupertinoSliverRefreshControl(
                builder: builder,
              ),
              buildAListOfStuff(),
            ],
          ),
        ),
      );

      // Drag down but not enough to trigger the refresh.
      await tester.drag(find.text('0'), const Offset(0.0, 50.0));
      await tester.pump();

      // The function is referenced once while passing into CupertinoSliverRefreshControl
      // and is called.
      verify(mockHelper.builder(
        any,
        RefreshIndicatorMode.drag,
        50.0,
        100.0, // Default value.
        60.0, // Default value.
      ));
      verifyNoMoreInteractions(mockHelper);

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '0')),
        const Offset(0.0, 50.0),
      );

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
      "don't call the builder if overscroll doesn't move slivers like on Android",
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverRefreshControl(
                  builder: builder,
                ),
                buildAListOfStuff(),
              ],
            ),
          ),
        );

        // Drag down but not enough to trigger the refresh.
        await tester.drag(find.text('0'), const Offset(0.0, 50.0));
        await tester.pump();

        verifyNoMoreInteractions(mockHelper);

        expect(
          tester.getTopLeft(find.widgetWithText(Container, '0')),
          const Offset(0.0, 0.0),
        );

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets('let the builder update as cancelled drag scrolls away', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            slivers: <Widget>[
              CupertinoSliverRefreshControl(
                builder: builder,
              ),
              buildAListOfStuff(),
            ],
          ),
        ),
      );

      // Drag down but not enough to trigger the refresh.
      await tester.drag(find.text('0'), const Offset(0.0, 50.0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(seconds: 3));

      verifyInOrder(<void>[
        mockHelper.builder(
          any,
          RefreshIndicatorMode.drag,
          50.0,
          100.0, // Default value.
          60.0, // Default value.
        ),
        mockHelper.builder(
          any,
          RefreshIndicatorMode.drag,
          argThat(moreOrLessEquals(48.36801747187993)),
          100.0, // Default value.
          60.0, // Default value.
        ),
        mockHelper.builder(
          any,
          RefreshIndicatorMode.drag,
          argThat(moreOrLessEquals(44.63031931875867)),
          100.0, // Default value.
          60.0, // Default value.
        ),
        // The builder isn't called again when the sliver completely goes away.
      ]);
      verifyNoMoreInteractions(mockHelper);

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '0')),
        const Offset(0.0, 0.0),
      );

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('drag past threshold triggers refresh task', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final List<MethodCall> platformCallLog = <MethodCall>[];

      SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
        platformCallLog.add(methodCall);
      });

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            slivers: <Widget>[
              CupertinoSliverRefreshControl(
                builder: builder,
                onRefresh: onRefresh,
              ),
              buildAListOfStuff(),
            ],
          ),
        ),
      );

      final TestGesture gesture = await tester.startGesture(const Offset(0.0, 0.0));
      await gesture.moveBy(const Offset(0.0, 99.0));
      await tester.pump();
      await gesture.moveBy(const Offset(0.0, -30.0));
      await tester.pump();
      await gesture.moveBy(const Offset(0.0, 50.0));
      await tester.pump();

      verifyInOrder(<void>[
        mockHelper.builder(
          any,
          RefreshIndicatorMode.drag,
          99.0,
          100.0, // Default value.
          60.0, // Default value.
        ),
        mockHelper.builder(
          any,
          RefreshIndicatorMode.drag,
          argThat(moreOrLessEquals(86.78169)),
          100.0, // Default value.
          60.0, // Default value.
        ),
        mockHelper.builder(
          any,
          RefreshIndicatorMode.armed,
          argThat(moreOrLessEquals(105.80452021305739)),
          100.0, // Default value.
          60.0, // Default value.
        ),
        // The refresh callback is triggered after the frame.
        mockHelper.refreshTask(),
      ]);
      verifyNoMoreInteractions(mockHelper);

      expect(
        platformCallLog.last,
        isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.mediumImpact'),
      );
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
      'refreshing task keeps the sliver expanded forever until done',
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverRefreshControl(
                  builder: builder,
                  onRefresh: onRefresh,
                ),
                buildAListOfStuff(),
              ],
            ),
          ),
        );

        await tester.drag(find.text('0'), const Offset(0.0, 150.0));
        await tester.pump();
        // Let it start snapping back.
        await tester.pump(const Duration(milliseconds: 50));

        verifyInOrder(<void>[
          mockHelper.builder(
            any,
            RefreshIndicatorMode.armed,
            150.0,
            100.0, // Default value.
            60.0, // Default value.
          ),
          mockHelper.refreshTask(),
          mockHelper.builder(
            any,
            RefreshIndicatorMode.armed,
            argThat(moreOrLessEquals(127.10396988577114)),
            100.0, // Default value.
            60.0, // Default value.
          ),
        ]);

        // Reaches refresh state and sliver's at 60.0 in height after a while.
        await tester.pump(const Duration(seconds: 1));
        verify(mockHelper.builder(
          any,
          RefreshIndicatorMode.refresh,
          60.0,
          100.0, // Default value.
          60.0, // Default value.
        ));

        // Stays in that state forever until future completes.
        await tester.pump(const Duration(seconds: 1000));
        verifyNoMoreInteractions(mockHelper);
        expect(
          tester.getTopLeft(find.widgetWithText(Container, '0')),
          const Offset(0.0, 60.0),
        );

        refreshCompleter.complete(null);
        await tester.pump();

        verify(mockHelper.builder(
          any,
          RefreshIndicatorMode.done,
          60.0,
          100.0, // Default value.
          60.0, // Default value.
        ));
        verifyNoMoreInteractions(mockHelper);

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets('expanded refreshing sliver scrolls normally', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      refreshIndicator = const Center(child: Text('-1'));

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            slivers: <Widget>[
              CupertinoSliverRefreshControl(
                builder: builder,
                onRefresh: onRefresh,
              ),
              buildAListOfStuff(),
            ],
          ),
        ),
      );

      await tester.drag(find.text('0'), const Offset(0.0, 150.0));
      await tester.pump();

      verify(mockHelper.builder(
        any,
        RefreshIndicatorMode.armed,
        150.0,
        100.0, // Default value.
        60.0, // Default value.
      ));

      // Given a box constraint of 150, the Center will occupy all that height.
      expect(
        tester.getRect(find.widgetWithText(Center, '-1')),
        Rect.fromLTRB(0.0, 0.0, 800.0, 150.0),
      );

      await tester.drag(find.text('0'), const Offset(0.0, -300.0));
      await tester.pump();

      // Refresh indicator still being told to layout the same way.
      verify(mockHelper.builder(
        any,
        RefreshIndicatorMode.refresh,
        60.0,
        100.0, // Default value.
        60.0, // Default value.
      ));

      // Now the sliver is scrolled off screen.
      expect(
        tester.getTopLeft(find.widgetWithText(Center, '-1', skipOffstage: false)).dy,
        moreOrLessEquals(-175.38461538461536),
      );
      expect(
        tester.getBottomLeft(find.widgetWithText(Center, '-1', skipOffstage: false)).dy,
        moreOrLessEquals(-115.38461538461536),
      );
      expect(
        tester.getTopLeft(find.widgetWithText(Center, '0')).dy,
        moreOrLessEquals(-115.38461538461536),
      );

      // Scroll the top of the refresh indicator back to overscroll, it will
      // snap to the size of the refresh indicator and stay there.
      await tester.drag(find.text('1'), const Offset(0.0, 200.0));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(
        tester.getRect(find.widgetWithText(Center, '-1')),
        Rect.fromLTRB(0.0, 0.0, 800.0, 60.0),
      );
      expect(
        tester.getRect(find.widgetWithText(Center, '0')),
        Rect.fromLTRB(0.0, 60.0, 800.0, 260.0),
      );

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('expanded refreshing sliver goes away when done', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      refreshIndicator = const Center(child: Text('-1'));

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            slivers: <Widget>[
              CupertinoSliverRefreshControl(
                builder: builder,
                onRefresh: onRefresh,
              ),
              buildAListOfStuff(),
            ],
          ),
        ),
      );

      await tester.drag(find.text('0'), const Offset(0.0, 150.0));
      await tester.pump();
      verify(mockHelper.builder(
        any,
        RefreshIndicatorMode.armed,
        150.0,
        100.0, // Default value.
        60.0, // Default value.
      ));
      expect(
        tester.getRect(find.widgetWithText(Center, '-1')),
        Rect.fromLTRB(0.0, 0.0, 800.0, 150.0),
      );
      verify(mockHelper.refreshTask());

      // Rebuilds the sliver with a layout extent now.
      await tester.pump();
      // Let it snap back to occupy the indicator's final sliver space only.
      await tester.pump(const Duration(seconds: 2));
      verify(mockHelper.builder(
        any,
        RefreshIndicatorMode.refresh,
        60.0,
        100.0, // Default value.
        60.0, // Default value.
      ));
      expect(
        tester.getRect(find.widgetWithText(Center, '-1')),
        Rect.fromLTRB(0.0, 0.0, 800.0, 60.0),
      );
      expect(
        tester.getRect(find.widgetWithText(Center, '0')),
        Rect.fromLTRB(0.0, 60.0, 800.0, 260.0),
      );

      refreshCompleter.complete(null);
      await tester.pump();
      verify(mockHelper.builder(
        any,
        RefreshIndicatorMode.done,
        60.0,
        100.0, // Default value.
        60.0, // Default value.
      ));

      await tester.pump(const Duration(seconds: 5));
      expect(find.text('-1'), findsNothing);
      expect(
        tester.getRect(find.widgetWithText(Center, '0')),
        Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
      );

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
      'retracting sliver during done cannot be pulled to refresh again until fully retracted',
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        refreshIndicator = const Center(child: Text('-1'));

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverRefreshControl(
                  builder: builder,
                  onRefresh: onRefresh,
                ),
                buildAListOfStuff(),
              ],
            ),
          ),
        );

        await tester.drag(find.text('0'), const Offset(0.0, 150.0));
        await tester.pump();
        verify(mockHelper.refreshTask());

        refreshCompleter.complete(null);
        await tester.pump();
        verify(mockHelper.builder(
          any,
          RefreshIndicatorMode.done,
          150.0, // Still overscrolled here.
          100.0, // Default value.
          60.0, // Default value.
        ));

        // Let it start going away but not fully.
        await tester.pump(const Duration(milliseconds: 100));
        // The refresh indicator is still building.
        verify(mockHelper.builder(
          any,
          RefreshIndicatorMode.done,
          91.31180913199277,
          100.0, // Default value.
          60.0, // Default value.
        ));
        expect(
          tester.getBottomLeft(find.widgetWithText(Center, '-1')).dy,
          moreOrLessEquals(91.311809131992776),
        );

        // Start another drag by an amount that would have been enough to
        // trigger another refresh if it were in the right state.
        await tester.drag(find.text('0'), const Offset(0.0, 150.0));
        await tester.pump();

        // Instead, it's still in the done state because the sliver never
        // fully retracted.
        verify(mockHelper.builder(
          any,
          RefreshIndicatorMode.done,
          147.3772721631821,
          100.0, // Default value.
          60.0, // Default value.
        ));

        // Now let it fully go away.
        await tester.pump(const Duration(seconds: 5));
        expect(find.text('-1'), findsNothing);
        expect(
          tester.getRect(find.widgetWithText(Center, '0')),
          Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
        );

        // Start another drag. It's now in drag mode.
        await tester.drag(find.text('0'), const Offset(0.0, 40.0));
        await tester.pump();
        verify(mockHelper.builder(
          any,
          RefreshIndicatorMode.drag,
          40.0,
          100.0, // Default value.
          60.0, // Default value.
        ));

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'sliver held in overscroll when task finishes completes normally',
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        refreshIndicator = const Center(child: Text('-1'));

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverRefreshControl(
                  builder: builder,
                  onRefresh: onRefresh,
                ),
                buildAListOfStuff(),
              ],
            ),
          ),
        );

        final TestGesture gesture = await tester.startGesture(const Offset(0.0, 0.0));
        // Start a refresh.
        await gesture.moveBy(const Offset(0.0, 150.0));
        await tester.pump();
        verify(mockHelper.refreshTask());

        // Complete the task while held down.
        refreshCompleter.complete(null);
        await tester.pump();
        verify(mockHelper.builder(
          any,
          RefreshIndicatorMode.done,
          150.0, // Still overscrolled here.
          100.0, // Default value.
          60.0, // Default value.
        ));
        expect(
          tester.getRect(find.widgetWithText(Center, '0')),
          Rect.fromLTRB(0.0, 150.0, 800.0, 350.0),
        );

        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(seconds: 5));
        expect(find.text('-1'), findsNothing);
        expect(
          tester.getRect(find.widgetWithText(Center, '0')),
          Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
        );

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'sliver scrolled away when task completes properly removes itself',
      (WidgetTester tester) async {
        if (testListLength < 4) {
          // This test only makes sense when the list is long enough that
          // the indicator can be scrolled away while refreshing.
          return;
        }
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        refreshIndicator = const Center(child: Text('-1'));

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverRefreshControl(
                  builder: builder,
                  onRefresh: onRefresh,
                ),
                buildAListOfStuff(),
              ],
            ),
          ),
        );

        // Start a refresh.
        await tester.drag(find.text('0'), const Offset(0.0, 150.0));
        await tester.pump();
        verify(mockHelper.refreshTask());

        await tester.drag(find.text('0'), const Offset(0.0, -300.0));
        await tester.pump();

        // Refresh indicator still being told to layout the same way.
        verify(mockHelper.builder(
          any,
          RefreshIndicatorMode.refresh,
          60.0,
          100.0, // Default value.
          60.0, // Default value.
        ));

        // Now the sliver is scrolled off screen.
        expect(
          tester.getTopLeft(find.widgetWithText(Center, '-1', skipOffstage: false)).dy,
          moreOrLessEquals(-175.38461538461536),
        );
        expect(
          tester.getBottomLeft(find.widgetWithText(Center, '-1', skipOffstage: false)).dy,
          moreOrLessEquals(-115.38461538461536),
        );

        // Complete the task while scrolled away.
        refreshCompleter.complete(null);
        // The sliver is instantly gone since there is no overscroll physics
        // simulation.
        await tester.pump();

        // The next item's position is not disturbed.
        expect(
          tester.getTopLeft(find.widgetWithText(Center, '0')).dy,
          moreOrLessEquals(-115.38461538461536),
        );

        // Scrolling past the first item still results in a new overscroll.
        // The layout extent is gone.
        await tester.drag(find.text('1'), const Offset(0.0, 120.0));
        await tester.pump();

        verify(mockHelper.builder(
          any,
          RefreshIndicatorMode.drag,
          4.615384615384642,
          100.0, // Default value.
          60.0, // Default value.
        ));

        // Snaps away normally.
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(find.text('-1'), findsNothing);
        expect(
          tester.getRect(find.widgetWithText(Center, '0')),
          Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
        );

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      "don't do anything unless it can be overscrolled at the start of the list",
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        refreshIndicator = const Center(child: Text('-1'));

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CustomScrollView(
              slivers: <Widget>[
                buildAListOfStuff(),
                CupertinoSliverRefreshControl( // it's in the middle now.
                  builder: builder,
                  onRefresh: onRefresh,
                ),
                buildAListOfStuff(),
              ],
            ),
          ),
        );

        await tester.fling(find.byType(Container).first, const Offset(0.0, 200.0), 2000.0);

        await tester.fling(find.byType(Container).first, const Offset(0.0, -200.0), 3000.0);

        verifyNoMoreInteractions(mockHelper);

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'without an onRefresh, builder is called with arm for one frame then sliver goes away',
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        refreshIndicator = const Center(child: Text('-1'));

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverRefreshControl(
                  builder: builder,
                ),
                buildAListOfStuff(),
              ],
            ),
          ),
        );

        await tester.drag(find.text('0'), const Offset(0.0, 150.0));
        await tester.pump();
        verify(mockHelper.builder(
          any,
          RefreshIndicatorMode.armed,
          150.0,
          100.0, // Default value.
          60.0, // Default value.
        ));

        await tester.pump(const Duration(milliseconds: 10));
        verify(mockHelper.builder(
          any,
          RefreshIndicatorMode.done, // Goes to done on the next frame.
          148.6463892921364,
          100.0, // Default value.
          60.0, // Default value.
        ));

        await tester.pump(const Duration(seconds: 5));
        expect(find.text('-1'), findsNothing);
        expect(
          tester.getRect(find.widgetWithText(Center, '0')),
          Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
        );

        debugDefaultTargetPlatformOverride = null;
      }
    );
  };

  final Function stateMachineTestGroup = () {
    testWidgets('starts in inactive state', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            slivers: <Widget>[
              CupertinoSliverRefreshControl(
                builder: builder,
              ),
              buildAListOfStuff(),
            ],
          ),
        ),
      );

      expect(
        CupertinoSliverRefreshControl.state(tester.element(find.byType(LayoutBuilder, skipOffstage: false))),
        RefreshIndicatorMode.inactive,
      );

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('goes to drag and returns to inactive in a small drag', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            slivers: <Widget>[
              CupertinoSliverRefreshControl(
                builder: builder,
              ),
              buildAListOfStuff(),
            ],
          ),
        ),
      );

      await tester.drag(find.text('0'), const Offset(0.0, 20.0));
      await tester.pump();

      expect(
        CupertinoSliverRefreshControl.state(tester.element(find.byType(LayoutBuilder))),
        RefreshIndicatorMode.drag,
      );

      await tester.pump(const Duration(seconds: 2));

      expect(
        CupertinoSliverRefreshControl.state(tester.element(find.byType(LayoutBuilder, skipOffstage: false))),
        RefreshIndicatorMode.inactive,
      );

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('goes to armed the frame it passes the threshold', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CustomScrollView(
            slivers: <Widget>[
              CupertinoSliverRefreshControl(
                builder: builder,
                refreshTriggerPullDistance: 80.0,
              ),
              buildAListOfStuff(),
            ],
          ),
        ),
      );

      final TestGesture gesture = await tester.startGesture(const Offset(0.0, 0.0));
      await gesture.moveBy(const Offset(0.0, 79.0));
      await tester.pump();
      expect(
        CupertinoSliverRefreshControl.state(tester.element(find.byType(LayoutBuilder))),
        RefreshIndicatorMode.drag,
      );

      await gesture.moveBy(const Offset(0.0, 3.0)); // Overscrolling, need to move more than 1px.
      await tester.pump();
      expect(
        CupertinoSliverRefreshControl.state(tester.element(find.byType(LayoutBuilder))),
        RefreshIndicatorMode.armed,
      );

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
      'goes to refresh the frame it crossed back the refresh threshold',
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverRefreshControl(
                  builder: builder,
                  onRefresh: onRefresh,
                  refreshTriggerPullDistance: 90.0,
                  refreshIndicatorExtent: 50.0,
                ),
                buildAListOfStuff(),
              ],
            ),
          ),
        );

        final TestGesture gesture = await tester.startGesture(const Offset(0.0, 0.0));
        await gesture.moveBy(const Offset(0.0, 90.0)); // Arm it.
        await tester.pump();
        expect(
          CupertinoSliverRefreshControl.state(tester.element(find.byType(LayoutBuilder))),
          RefreshIndicatorMode.armed,
        );

        await gesture.moveBy(const Offset(0.0, -80.0)); // Overscrolling, need to move more than -40.
        await tester.pump();
        expect(
          tester.getTopLeft(find.widgetWithText(Container, '0')).dy,
          moreOrLessEquals(49.775111111111116), // Below 50 now.
        );
        expect(
          CupertinoSliverRefreshControl.state(tester.element(find.byType(LayoutBuilder))),
          RefreshIndicatorMode.refresh,
        );

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'goes to done internally as soon as the task finishes',
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverRefreshControl(
                  builder: builder,
                  onRefresh: onRefresh,
                ),
                buildAListOfStuff(),
              ],
            ),
          ),
        );

        await tester.drag(find.text('0'), const Offset(0.0, 100.0));
        await tester.pump();
        expect(
          CupertinoSliverRefreshControl.state(tester.element(find.byType(LayoutBuilder))),
          RefreshIndicatorMode.armed,
        );
        // The sliver scroll offset correction is applied on the next frame.
        await tester.pump();

        await tester.pump(const Duration(seconds: 2));
        expect(
          CupertinoSliverRefreshControl.state(tester.element(find.byType(LayoutBuilder))),
          RefreshIndicatorMode.refresh,
        );
        expect(
          tester.getRect(find.widgetWithText(Container, '0')),
          Rect.fromLTRB(0.0, 60.0, 800.0, 260.0),
        );

        refreshCompleter.complete(null);
        // The task completed between frames. The internal state goes to done
        // right away even though the sliver gets a new offset correction the
        // next frame.
        expect(
          CupertinoSliverRefreshControl.state(tester.element(find.byType(LayoutBuilder))),
          RefreshIndicatorMode.done,
        );

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'goes back to inactive when retracting back past 10% of arming distance',
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverRefreshControl(
                  builder: builder,
                  onRefresh: onRefresh,
                ),
                buildAListOfStuff(),
              ],
            ),
          ),
        );

        final TestGesture gesture = await tester.startGesture(const Offset(0.0, 0.0));
        await gesture.moveBy(const Offset(0.0, 150.0));
        await tester.pump();
        expect(
          CupertinoSliverRefreshControl.state(tester.element(find.byType(LayoutBuilder))),
          RefreshIndicatorMode.armed,
        );

        refreshCompleter.complete(null);
        expect(
          CupertinoSliverRefreshControl.state(tester.element(find.byType(LayoutBuilder))),
          RefreshIndicatorMode.done,
        );
        await tester.pump();

        // Now back in overscroll mode.
        await gesture.moveBy(const Offset(0.0, -200.0));
        await tester.pump();
        expect(
          tester.getTopLeft(find.widgetWithText(Container, '0')).dy,
          moreOrLessEquals(27.944444444444457),
        );
        // Need to bring it to 100 * 0.1 to reset to inactive.
        expect(
          CupertinoSliverRefreshControl.state(tester.element(find.byType(LayoutBuilder))),
          RefreshIndicatorMode.done,
        );

        await gesture.moveBy(const Offset(0.0, -35.0));
        await tester.pump();
        expect(
          tester.getTopLeft(find.widgetWithText(Container, '0')).dy,
          moreOrLessEquals(9.313890708161875),
        );
        expect(
          CupertinoSliverRefreshControl.state(tester.element(find.byType(LayoutBuilder))),
          RefreshIndicatorMode.inactive,
        );

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'goes back to inactive if already scrolled away when task completes',
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverRefreshControl(
                  builder: builder,
                  onRefresh: onRefresh,
                ),
                buildAListOfStuff(),
              ],
            ),
          ),
        );

        final TestGesture gesture = await tester.startGesture(const Offset(0.0, 0.0));
        await gesture.moveBy(const Offset(0.0, 150.0));
        await tester.pump();
        expect(
          CupertinoSliverRefreshControl.state(tester.element(find.byType(LayoutBuilder))),
          RefreshIndicatorMode.armed,
        );
        await tester.pump(); // Sliver scroll offset correction is applied one frame later.

        await gesture.moveBy(const Offset(0.0, -300.0));
        await tester.pump();
        // The refresh indicator is offscreen now.
        expect(
          tester.getTopLeft(find.widgetWithText(Container, '0')).dy,
          moreOrLessEquals(-145.0332383665717),
        );
        expect(
          CupertinoSliverRefreshControl.state(tester.element(find.byType(LayoutBuilder, skipOffstage: false))),
          RefreshIndicatorMode.refresh,
        );

        refreshCompleter.complete(null);
        // The sliver layout extent is removed on next frame.
        await tester.pump();
        expect(
          CupertinoSliverRefreshControl.state(tester.element(find.byType(LayoutBuilder, skipOffstage: false))),
          RefreshIndicatorMode.inactive,
        );
        // Nothing moved.
        expect(
          tester.getTopLeft(find.widgetWithText(Container, '0')).dy,
          moreOrLessEquals(-145.0332383665717),
        );
        await tester.pump(const Duration(seconds: 2));
        // Everything stayed as is.
        expect(
          tester.getTopLeft(find.widgetWithText(Container, '0')).dy,
          moreOrLessEquals(-145.0332383665717),
        );

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      "don't have to build any indicators or occupy space during refresh",
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        refreshIndicator = const Center(child: Text('-1'));

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverRefreshControl(
                  builder: null,
                  onRefresh: onRefresh,
                  refreshIndicatorExtent: 0.0,
                ),
                buildAListOfStuff(),
              ],
            ),
          ),
        );

        await tester.drag(find.text('0'), const Offset(0.0, 150.0));
        await tester.pump();
        expect(
          CupertinoSliverRefreshControl.state(tester.element(find.byType(LayoutBuilder))),
          RefreshIndicatorMode.armed,
        );

        await tester.pump();
        await tester.pump(const Duration(seconds: 5));
        // In refresh mode but has no UI.
        expect(
          CupertinoSliverRefreshControl.state(tester.element(find.byType(LayoutBuilder, skipOffstage: false))),
          RefreshIndicatorMode.refresh,
        );
        expect(
          tester.getRect(find.widgetWithText(Center, '0')),
          Rect.fromLTRB(0.0, 0.0, 800.0, 200.0),
        );
        verify(mockHelper.refreshTask()); // The refresh function still called.

        refreshCompleter.complete(null);
        await tester.pump();
        // Goes to inactive right away since the sliver is already collapsed.
        expect(
          CupertinoSliverRefreshControl.state(tester.element(find.byType(LayoutBuilder, skipOffstage: false))),
          RefreshIndicatorMode.inactive,
        );

        debugDefaultTargetPlatformOverride = null;
      }
    );
  };

  group('UI tests long list', uiTestGroup);

  // Test the internal state machine directly to make sure the UI aren't just
  // correct by coincidence.
  group('state machine test long list', stateMachineTestGroup);

  // Retest everything and make sure that it still works when the whole list
  // is smaller than the viewport size.
  testListLength = 2;
  group('UI tests short list', uiTestGroup);

  // Test the internal state machine directly to make sure the UI aren't just
  // correct by coincidence.
  group('state machine test short list', stateMachineTestGroup);
}

class MockHelper extends Mock {
  Widget builder(
    BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
  );

  Future<void> refreshTask();
}
