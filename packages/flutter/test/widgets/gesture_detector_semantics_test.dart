// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Vertical gesture detector has up/down actions', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    int callCount = 0;
    final GlobalKey detectorKey = GlobalKey();

    await tester.pumpWidget(
      Center(
        child: GestureDetector(
          key: detectorKey,
          onVerticalDragStart: (DragStartDetails _) {
            callCount += 1;
          },
          child: Container(),
        ),
      )
    );

    expect(semantics, includesNodeWith(
        actions: <SemanticsAction>[SemanticsAction.scrollUp, SemanticsAction.scrollDown]),
    );

    final int detectorId = detectorKey.currentContext.findRenderObject().debugSemantics.id;
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollLeft);
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollRight);
    expect(callCount, 0);
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollUp);
    expect(callCount, 1);
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollDown);
    expect(callCount, 2);

    semantics.dispose();
  });

  testWidgets('Horizontal gesture detector has up/down actions', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    int callCount = 0;
    final GlobalKey detectorKey = GlobalKey();

    await tester.pumpWidget(
        Center(
          child: GestureDetector(
            key: detectorKey,
            onHorizontalDragStart: (DragStartDetails _) {
              callCount += 1;
            },
            child: Container(),
          ),
        )
    );

    expect(semantics, includesNodeWith(
        actions: <SemanticsAction>[SemanticsAction.scrollLeft, SemanticsAction.scrollRight]),
    );

    final int detectorId = detectorKey.currentContext.findRenderObject().debugSemantics.id;
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollUp);
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollDown);
    expect(callCount, 0);
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollLeft);
    expect(callCount, 1);
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollRight);
    expect(callCount, 2);

    semantics.dispose();
  });

  testWidgets('All registered handlers for the gesture kind are called', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    final Set<String> logs = <String>{};
    final GlobalKey detectorKey = GlobalKey();

    await tester.pumpWidget(
      Center(
        child: GestureDetector(
          key: detectorKey,
          onHorizontalDragStart: (_) { logs.add('horizontal'); },
          onPanStart: (_) { logs.add('pan'); },
          child: Container(),
        ),
      ),
    );

    final int detectorId = detectorKey.currentContext.findRenderObject().debugSemantics.id;
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollLeft);
    expect(logs, <String>{'horizontal', 'pan'});

    semantics.dispose();
  });

  testWidgets('Replacing recognizers should update semantic handlers', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    // How the test is set up:
    //
    //  * In the base state, RawGestureDetector's recognizer is a HorizontalGR
    //  * Calling `introduceLayoutPerformer()` adds a `_TestLayoutPerformer` as
    //    child of RawGestureDetector, which invokes a given callback during
    //    layout phase.
    //  * The aforementioned callback replaces the detector's recognizer with a
    //    TapGR.
    //  * This test makes sure the replacement correctly updates semantics.

    final Set<String> logs = <String>{};
    final GlobalKey<RawGestureDetectorState> detectorKey = GlobalKey();
    final VoidCallback performLayout = () {
      detectorKey.currentState.replaceGestureRecognizers(<Type, GestureRecognizerFactory>{
        TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (TapGestureRecognizer instance) {
            instance
              ..onTap = () { logs.add('tap'); };
          },
        )
      });
    };

    bool hasLayoutPerformer = false;
    VoidCallback introduceLayoutPerformer;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setter) {
          introduceLayoutPerformer = () {
            setter(() {
              hasLayoutPerformer = true;
            });
          };
          return Center(
            child: RawGestureDetector(
              key: detectorKey,
              gestures: <Type, GestureRecognizerFactory>{
                HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
                  () => HorizontalDragGestureRecognizer(),
                  (HorizontalDragGestureRecognizer instance) {
                    instance
                      ..onStart = (_) { logs.add('horizontal'); };
                  },
                )
              },
              child: hasLayoutPerformer ? _TestLayoutPerformer(performLayout: performLayout) : null,
            ),
          );
        },
      ),
    );

    final int detectorId = detectorKey.currentContext.findRenderObject().debugSemantics.id;
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollLeft);
    expect(logs, <String>{'horizontal'});
    logs.clear();

    introduceLayoutPerformer();
    await tester.pumpAndSettle();

    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollLeft);
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.tap);
    expect(logs, <String>{'tap'});
    logs.clear();

    semantics.dispose();
  });

  testWidgets('RawGestureDetector caches handlers returned by GestureSemanticsMapping', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    final List<String> logs = <String>[];
    final GlobalKey detectorKey = GlobalKey();

    bool objectUpdated = false;
    VoidCallback updateRenderObject;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setter) {
          updateRenderObject = () {
            setter(() {
              objectUpdated = true;
            });
          };
          return Directionality(
            textDirection: TextDirection.ltr,
            child: RawGestureDetector(
              key: detectorKey,
              semanticsMapping: _UnstableGestureSemanticsMapping(
                onTap: (int counter) => logs.add('Tap$counter'),
              ),
              child: objectUpdated ? Container() : const Icon(IconData(3)),
            ),
          );
        }
      ),
    );

    final int detectorId = detectorKey.currentContext.findRenderObject().debugSemantics.id;
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.tap);
    expect(logs, <String>['Tap1']);
    logs.clear();

    updateRenderObject();
    await tester.pumpAndSettle();
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.tap);
    expect(logs, <String>['Tap1']);

    semantics.dispose();
  });

  group('DefaultGestureSemanticsMapping', () {
    group('getTapHandler', () {
      test('should return null when there is no TapGR', () {
        const GestureSemanticsMapping mapping = DefaultGestureSemanticsMapping();
        final GestureTapCallback callback = mapping.getTapHandler((Type type) {
          return null;
        });
        expect(callback, isNull);
      });

      test('should return non-null when there is TapGR with no callbacks', () {
        const GestureSemanticsMapping mapping = DefaultGestureSemanticsMapping();
        final GestureTapCallback callback = mapping.getTapHandler((Type type) {
          switch(type) {
            case TapGestureRecognizer :
              return TapGestureRecognizer();
            default:
              return null;
          }
        });
        expect(callback, isNotNull);
      });

      test('should return a callback that correctly calls callbacks', () {
        const GestureSemanticsMapping mapping = DefaultGestureSemanticsMapping();
        final List<String> logs = <String>[];
        final GestureTapCallback callback = mapping.getTapHandler((Type type) {
          switch(type) {
            case TapGestureRecognizer :
              return TapGestureRecognizer()
                ..onTap = () {logs.add('tap');}
                ..onTapUp = (_) {logs.add('tapUp');}
                ..onTapDown = (_) {logs.add('tapDown');}
                ..onTapCancel = () {logs.add('WRONG');}
                ..onSecondaryTapDown = (_) {logs.add('WRONG');};
            default:
              return null;
          }
        });
        expect(callback, isNotNull);
        callback();
        expect(logs, <String>['tapDown', 'tapUp', 'tap']);
      });
    });

    group('getLongPressHandler', () {
      test('should return null when there is no LongPressGR', () {
        const GestureSemanticsMapping mapping = DefaultGestureSemanticsMapping();
        final GestureLongPressCallback callback = mapping.getLongPressHandler((Type type) {
          return null;
        });
        expect(callback, isNull);
      });

      test('should return non-null when there is LongPressGR with no callbacks', () {
        const GestureSemanticsMapping mapping = DefaultGestureSemanticsMapping();
        final GestureLongPressCallback callback = mapping.getLongPressHandler((Type type) {
          switch(type) {
            case LongPressGestureRecognizer:
              return LongPressGestureRecognizer();
            default:
              return null;
          }
        });
        expect(callback, isNotNull);
      });

      test('should return a callback that correctly calls callbacks', () {
        const GestureSemanticsMapping mapping = DefaultGestureSemanticsMapping();
        final List<String> logs = <String>[];
        final GestureLongPressCallback callback = mapping.getLongPressHandler((Type type) {
          switch(type) {
            case LongPressGestureRecognizer:
              return LongPressGestureRecognizer()
                ..onLongPress = () {logs.add('LP');}
                ..onLongPressStart = (_) {logs.add('LPStart');}
                ..onLongPressUp = () {logs.add('LPUp');}
                ..onLongPressEnd = (_) {logs.add('LPEnd');}
                ..onLongPressMoveUpdate = (_) {logs.add('WRONG');};
            default:
              return null;
          }
        });
        expect(callback, isNotNull);
        callback();
        expect(logs, <String>['LPStart', 'LP', 'LPEnd', 'LPUp']);
      });
    });

    group('getHorizontalDragUpdateHandler', () {
      test('should return null when there is no matching recognizers', () {
        const GestureSemanticsMapping mapping = DefaultGestureSemanticsMapping();
        final GestureDragUpdateCallback callback = mapping.getHorizontalDragUpdateHandler(
          (Type type) { return null; }
        );
        expect(callback, isNull);
      });

      test('should return non-null when there is either matching recognizer with no callbacks', () {
        const GestureSemanticsMapping mapping = DefaultGestureSemanticsMapping();
        final GestureDragUpdateCallback callback1 = mapping.getHorizontalDragUpdateHandler((Type type) {
          switch(type) {
            case HorizontalDragGestureRecognizer:
              return HorizontalDragGestureRecognizer();
            default:
              return null;
          }
        });
        expect(callback1, isNotNull);

        final GestureDragUpdateCallback callback2 = mapping.getHorizontalDragUpdateHandler(
          (Type type) {
            switch(type) {
              case PanGestureRecognizer:
                return PanGestureRecognizer();
              default:
                return null;
            }
          }
        );
        expect(callback2, isNotNull);
      });

      test('should return a callback that correctly calls callbacks', () {
        const GestureSemanticsMapping mapping = DefaultGestureSemanticsMapping();
        final List<String> logs = <String>[];
        final GestureDragUpdateCallback callback = mapping.getHorizontalDragUpdateHandler((Type type) {
          switch(type) {
            case PanGestureRecognizer:
              return PanGestureRecognizer()
                ..onStart = (_) {logs.add('PStart');}
                ..onDown = (_) {logs.add('PDown');}
                ..onEnd = (_) {logs.add('PEnd');}
                ..onUpdate = (_) {logs.add('PUpdate');}
                ..onCancel = () {logs.add('WRONG');};
            case HorizontalDragGestureRecognizer:
              return HorizontalDragGestureRecognizer()
                ..onStart = (_) {logs.add('HStart');}
                ..onDown = (_) {logs.add('HDown');}
                ..onEnd = (_) {logs.add('HEnd');}
                ..onUpdate = (_) {logs.add('HUpdate');}
                ..onCancel = () {logs.add('WRONG');};
            default:
              return null;
          }
        });
        expect(callback, isNotNull);
        callback(DragUpdateDetails(
          delta: const Offset(0, 0),
          globalPosition: const Offset(0, 0),
        ));
        expect(logs, <String>['HDown', 'HStart', 'HUpdate', 'HEnd',
          'PDown', 'PStart', 'PUpdate', 'PEnd',]);
      });
    });

    group('getVerticalDragUpdateHandler', () {
      test('should return null when there is no matching recognizers', () {
        const GestureSemanticsMapping mapping = DefaultGestureSemanticsMapping();
        final GestureDragUpdateCallback callback = mapping.getVerticalDragUpdateHandler(
          (Type type) { return null; }
        );
        expect(callback, isNull);
      });

      test('should return non-null when there is either matching recognizer with no callbacks', () {
        const GestureSemanticsMapping mapping = DefaultGestureSemanticsMapping();
        final GestureDragUpdateCallback callback1 = mapping.getVerticalDragUpdateHandler((Type type) {
          switch(type) {
            case VerticalDragGestureRecognizer:
              return VerticalDragGestureRecognizer();
            default:
              return null;
          }
        });
        expect(callback1, isNotNull);

        final GestureDragUpdateCallback callback2 = mapping.getVerticalDragUpdateHandler(
          (Type type) {
            switch(type) {
              case PanGestureRecognizer:
                return PanGestureRecognizer();
              default:
                return null;
            }
          }
        );
        expect(callback2, isNotNull);
      });

      test('should return a callback that correctly calls callbacks', () {
        const GestureSemanticsMapping mapping = DefaultGestureSemanticsMapping();
        final List<String> logs = <String>[];
        final GestureDragUpdateCallback callback = mapping.getVerticalDragUpdateHandler((Type type) {
          switch(type) {
            case PanGestureRecognizer:
              return PanGestureRecognizer()
                ..onStart = (_) {logs.add('PStart');}
                ..onDown = (_) {logs.add('PDown');}
                ..onEnd = (_) {logs.add('PEnd');}
                ..onUpdate = (_) {logs.add('PUpdate');}
                ..onCancel = () {logs.add('WRONG');};
            case VerticalDragGestureRecognizer:
              return VerticalDragGestureRecognizer()
                ..onStart = (_) {logs.add('VStart');}
                ..onDown = (_) {logs.add('VDown');}
                ..onEnd = (_) {logs.add('VEnd');}
                ..onUpdate = (_) {logs.add('VUpdate');}
                ..onCancel = () {logs.add('WRONG');};
            default:
              return null;
          }
        });
        expect(callback, isNotNull);
        callback(DragUpdateDetails(
          delta: const Offset(0, 0),
          globalPosition: const Offset(0, 0),
        ));
        expect(logs, <String>['VDown', 'VStart', 'VUpdate', 'VEnd',
          'PDown', 'PStart', 'PUpdate', 'PEnd',]);
      });
    });
  });
}

class _TestLayoutPerformer extends SingleChildRenderObjectWidget {
  const _TestLayoutPerformer({
    Key key,
    this.performLayout,
  }) : super(key: key);

  final VoidCallback performLayout;

  @override
  _RenderTestLayoutPerformer createRenderObject(BuildContext context) {
    return _RenderTestLayoutPerformer(performLayout: performLayout);
  }
}

class _RenderTestLayoutPerformer extends RenderBox {
  _RenderTestLayoutPerformer({VoidCallback performLayout}) : _performLayout = performLayout;

  VoidCallback _performLayout;

  @override
  void performLayout() {
    size = const Size(1, 1);
    if (_performLayout != null)
      _performLayout();
  }
}

// This mapping calls the given onTap with an integer, but this integer increases
// every time getTapHander is called.
class _UnstableGestureSemanticsMapping implements GestureSemanticsMapping {
  _UnstableGestureSemanticsMapping({
    this.onTap,
  });

  final void Function(int) onTap;
  int _counter = 0;

  @override
  GestureTapCallback getTapHandler(GetRecognizerHandler getRecognizer) {
    _counter++;
    return () => onTap(_counter);
  }
  @override
  GestureLongPressCallback getLongPressHandler(GetRecognizerHandler getRecognizer) => null;
  @override
  GestureDragUpdateCallback getHorizontalDragUpdateHandler(GetRecognizerHandler getRecognizer) => null;
  @override
  GestureDragUpdateCallback getVerticalDragUpdateHandler(GetRecognizerHandler getRecognizer) => null;
}
