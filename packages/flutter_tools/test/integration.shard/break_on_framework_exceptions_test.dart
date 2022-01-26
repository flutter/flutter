// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(gspencergoog): Remove this tag once this test's state leaks/test
// dependencies have been fixed.
// https://github.com/flutter/flutter/issues/85160
// Fails with "flutter test --test-randomize-ordering-seed=1000"
@Tags(<String>['no-shuffle'])

import 'package:file/file.dart';

import '../src/common.dart';
import 'test_data/project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('break_on_framework_exceptions.');
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  testWithoutContext('breaks when AnimationController listener throws', () async {
    final TestProject project = TestProject(
      r'''
      AnimationController(vsync: TestVSync(), duration: Duration.zero)
        ..addListener(() {
          throw 'AnimationController listener';
        })
        ..forward();
      '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'AnimationController listener';"));
  });

  testWithoutContext('breaks when AnimationController status listener throws', () async {
    final TestProject project = TestProject(
      r'''
      AnimationController(vsync: TestVSync(), duration: Duration.zero)
        ..addStatusListener((AnimationStatus _) {
          throw 'AnimationController status listener';
        })
        ..forward();
      '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'AnimationController status listener';"));
  });

  testWithoutContext('breaks when ChangeNotifier listener throws', () async {
    final TestProject project = TestProject(
       r'''
       ValueNotifier<int>(0)
         ..addListener(() {
           throw 'ValueNotifier listener';
         })
         ..value = 1;
       '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'ValueNotifier listener';"));
  });

  testWithoutContext('breaks when handling a gesture throws', () async {
    final TestProject project = TestProject(
      r'''
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: ElevatedButton(
              child: const Text('foo'),
              onPressed: () {
                throw 'while handling a gesture';
              },
            ),
          ),
        )
      );
      await tester.tap(find.byType(ElevatedButton));
      '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'while handling a gesture';"));
  });

  testWithoutContext('breaks when platform message callback throws', () async {
    final TestProject project = TestProject(
      r'''
      BasicMessageChannel<String>('foo', const StringCodec()).setMessageHandler((_) {
        throw 'platform message callback';
      });
      tester.binding.defaultBinaryMessenger.handlePlatformMessage('foo', const StringCodec().encodeMessage('Hello'), (_) {});
      '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'platform message callback';"));
  });

  testWithoutContext('breaks when SliverChildBuilderDelegate.builder throws', () async {
    final TestProject project = TestProject(
      r'''
      await tester.pumpWidget(MaterialApp(
        home: ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            throw 'cannot build child';
          },
        ),
      ));
      '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'cannot build child';"));
  });

  testWithoutContext('breaks when EditableText.onChanged throws', () async {
    final TestProject project = TestProject(
      r'''
      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: TextField(
            onChanged: (String t) {
              throw 'onChanged';
            },
          ),
        ),
      ));
      await tester.enterText(find.byType(TextField), 'foo');
      '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'onChanged';"));
  });

  testWithoutContext('breaks when EditableText.onEditingComplete throws', () async {
    final TestProject project = TestProject(
      r'''
      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: TextField(
            onEditingComplete: () {
              throw 'onEditingComplete';
            },
          ),
        ),
      ));
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'onEditingComplete';"));
  });

  testWithoutContext('breaks when EditableText.onSelectionChanged throws', () async {
    final TestProject project = TestProject(
      r'''
      await tester.pumpWidget(MaterialApp(
        home: SelectableText('hello',
          onSelectionChanged: (TextSelection selection, SelectionChangedCause? cause) {
            throw 'onSelectionChanged';
          },
        ),
      ));
      await tester.tap(find.byType(SelectableText));
      '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'onSelectionChanged';"));
  });

  testWithoutContext('breaks when Action listener throws', () async {
    final TestProject project = TestProject(
      r'''
      CallbackAction<Intent>(onInvoke: (Intent _) { })
        ..addActionListener((_) {
          throw 'action listener';
        })
        ..notifyActionListeners();
      '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'action listener';"));
  });

  testWithoutContext('breaks when pointer route throws', () async {
    final TestProject project = TestProject(
      r'''
      PointerRouter()
        ..addRoute(2, (PointerEvent event) {
          throw 'pointer route';
        })
        ..route(TestPointer(2).down(Offset.zero));
      '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'pointer route';"));
  });

  testWithoutContext('breaks when PointerSignalResolver callback throws', () async {
    final TestProject project = TestProject(
      r'''
      const PointerScrollEvent originalEvent = PointerScrollEvent();
      PointerSignalResolver()
        ..register(originalEvent, (PointerSignalEvent event) {
          throw 'PointerSignalResolver callback';
        })
        ..resolve(originalEvent);
      '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'PointerSignalResolver callback';"));
  });

  testWithoutContext('breaks when PointerSignalResolver callback throws', () async {
    final TestProject project = TestProject(
      r'''
      FocusManager.instance
        ..addHighlightModeListener((_) {
          throw 'highlight mode listener';
        })
        ..highlightStrategy = FocusHighlightStrategy.alwaysTouch
        ..highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'highlight mode listener';"));
  });

  testWithoutContext('breaks when GestureBinding.dispatchEvent throws', () async {
    final TestProject project = TestProject(
      r'''
      await tester.pumpWidget(
        MouseRegion(
          onHover: (_) {
            throw 'onHover';
          },
        )
      );
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(MouseRegion)));
      await tester.pump();
      gesture.removePointer();
      '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'onHover';"));
  });

  testWithoutContext('breaks when ImageStreamListener.onImage throws', () async {
    final TestProject project = TestProject(
      r'''
      final Completer<ImageInfo> completer = Completer<ImageInfo>();
      OneFrameImageStreamCompleter(completer.future)
        ..addListener(ImageStreamListener((ImageInfo _, bool __) {
          throw 'setImage';
        }));
      completer.complete(ImageInfo(image: image));
      ''',
      setup: r'''
        late ui.Image image;
        setUp(() async {
          image = await createTestImage();
        });
      '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'setImage';"));
  });

  testWithoutContext('breaks when ImageStreamListener.onError throws', () async {
    final TestProject project = TestProject(
      r'''
      final Completer<ImageInfo> completer = Completer<ImageInfo>();
      OneFrameImageStreamCompleter(completer.future)
        ..addListener(ImageStreamListener(
          (ImageInfo _, bool __) { },
          onError: (Object _, StackTrace? __) {
            throw 'onError';
          },
        ));
      completer.completeError('ERROR');
      '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'onError';"));
  });

  testWithoutContext('breaks when LayoutBuilder.builder throws', () async {
    final TestProject project = TestProject(
      r'''
      await tester.pumpWidget(LayoutBuilder(
        builder: (_, __) {
          throw 'LayoutBuilder.builder';
        },
      ));
      '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'LayoutBuilder.builder';"));
  });

  testWithoutContext('breaks when _CallbackHookProvider callback throws', () async {
    final TestProject project = TestProject(
      r'''
      RootBackButtonDispatcher()
        ..addCallback(() {
          throw '_CallbackHookProvider.callback';
        })
        ..invokeCallback(Future.value(false));
      '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw '_CallbackHookProvider.callback';"));
  });

  testWithoutContext('breaks when TimingsCallback throws', () async {
    final TestProject project = TestProject(
      r'''
      SchedulerBinding.instance!.addTimingsCallback((List<FrameTiming> timings) {
        throw 'TimingsCallback';
      });
      ui.window.onReportTimings!(<FrameTiming>[]);
      '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'TimingsCallback';"));
  });

  testWithoutContext('breaks when TimingsCallback throws', () async {
    final TestProject project = TestProject(
      r'''
      SchedulerBinding.instance!.scheduleTask(
        () {
          throw 'scheduled task';
        },
        Priority.touch,
      );
      await tester.pumpAndSettle();
      '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'scheduled task';"));
  });

  testWithoutContext('breaks when FrameCallback throws', () async {
    final TestProject project = TestProject(
      r'''
      SchedulerBinding.instance!.addPostFrameCallback((_) {
        throw 'FrameCallback';
      });
      await tester.pump();
      '''
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'FrameCallback';"));
  });

  testWithoutContext('breaks when attaching to render tree throws', () async {
    final TestProject project = TestProject(
      r'''
      await tester.pumpWidget(TestWidget());
      ''',
      classes: r'''
        class TestWidget extends StatelessWidget {
          @override
          StatelessElement createElement() {
            throw 'create element';
          }

          @override
          Widget build(BuildContext context) => Container();
        }
      ''',
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'create element';"));
  });

  testWithoutContext('breaks when RenderObject.performLayout throws', () async {
    final TestProject project = TestProject(
      r'''
      TestRender().layout(BoxConstraints());
      ''',
      classes: r'''
        class TestRender extends RenderBox {
          @override
          void performLayout() {
            throw 'performLayout';
          }
        }
      ''',
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'performLayout';"));
  });

  testWithoutContext('breaks when RenderObject.performResize throws', () async {
    final TestProject project = TestProject(
      r'''
      TestRender().layout(BoxConstraints());
      ''',
      classes: r'''
        class TestRender extends RenderBox {
          @override
          bool get sizedByParent => true;

          @override
          void performResize() {
            throw 'performResize';
          }
        }
      ''',
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'performResize';"));
  });

  testWithoutContext('breaks when RenderObject.performLayout (without resize) throws', () async {
    final TestProject project = TestProject(
      r'''
      await tester.pumpWidget(TestWidget());
      tester.renderObject<TestRender>(find.byType(TestWidget)).layoutThrows = true;
      await tester.pump();
      ''',
      classes: r'''
        class TestWidget extends LeafRenderObjectWidget {
          @override
          RenderObject createRenderObject(BuildContext context) => TestRender();
        }

        class TestRender extends RenderBox {
          bool get layoutThrows => _layoutThrows;
          bool _layoutThrows = false;
          set layoutThrows(bool value) {
            if (value == _layoutThrows) {
              return;
            }
            _layoutThrows = value;
            markNeedsLayout();
          }

          @override
          void performLayout() {
            if (layoutThrows) {
              throw 'performLayout without resize';
            }
            size = constraints.biggest;
          }
        }
      ''',
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'performLayout without resize';"));
  });

  testWithoutContext('breaks when StatelessWidget.build throws', () async {
    final TestProject project = TestProject(
      r'''
      await tester.pumpWidget(TestWidget());
      ''',
      classes: r'''
        class TestWidget extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            throw 'StatelessWidget.build';
          }
        }
      ''',
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'StatelessWidget.build';"));
  });

  testWithoutContext('breaks when StatefulWidget.build throws', () async {
    final TestProject project = TestProject(
      r'''
      await tester.pumpWidget(TestWidget());
      ''',
      classes: r'''
        class TestWidget extends StatefulWidget {
          @override
          _TestWidgetState createState() => _TestWidgetState();
        }

        class _TestWidgetState extends State<TestWidget> {
          @override
          Widget build(BuildContext context) {
            throw 'StatefulWidget.build';
          }
        }
      ''',
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'StatefulWidget.build';"));
  });

  testWithoutContext('breaks when finalizing the tree throws', () async {
    final TestProject project = TestProject(
      r'''
      await tester.pumpWidget(TestWidget());
      ''',
      classes: r'''
        class TestWidget extends StatefulWidget {
          @override
          _TestWidgetState createState() => _TestWidgetState();
        }

        class _TestWidgetState extends State<TestWidget> {
          @override
          void dispose() {
            super.dispose();
            throw 'dispose';
          }

          @override
          Widget build(BuildContext context) => Container();
        }
      ''',
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'dispose';"));
  });

  testWithoutContext('breaks when rebuilding dirty elements throws', () async {
    final TestProject project = TestProject(
      r'''
      await tester.pumpWidget(TestWidget());
      tester.element<TestElement>(find.byType(TestWidget)).throwOnRebuild = true;
      await tester.pump();
      ''',
      classes: r'''
        class TestWidget extends StatelessWidget {
          @override
          StatelessElement createElement() => TestElement(this);

          @override
          Widget build(BuildContext context) => Container();
        }

        class TestElement extends StatelessElement {
          TestElement(StatelessWidget widget) : super(widget);

          bool get throwOnRebuild => _throwOnRebuild;
          bool _throwOnRebuild = false;
          set throwOnRebuild(bool value) {
            if (value == _throwOnRebuild) {
              return;
            }
            _throwOnRebuild = value;
            markNeedsBuild();
          }

          @override
          void rebuild() {
            if (_throwOnRebuild) {
              throw 'rebuild';
            }
            super.rebuild();
          }
        }
      ''',
    );
    await project.setUpIn(tempDir);
    final FlutterTestTestDriver flutter = FlutterTestTestDriver(tempDir);
    await flutter.test(withDebugger: true, pauseOnExceptions: true);
    await flutter.waitForPause();

    final int? breakLine = (await flutter.getSourceLocation())?.line;
    expect(breakLine, project.lineContaining(project.test, "throw 'rebuild';"));
  });
}

class TestProject extends Project {
  TestProject(this.testBody, { this.setup, this.classes });

  final String testBody;
  final String? setup;
  final String? classes;

  @override
  final String pubspec = '''
    name: test
    environment:
      sdk: ">=2.12.0-0 <3.0.0"

    dependencies:
      flutter:
        sdk: flutter
    dev_dependencies:
      flutter_test:
        sdk: flutter
  ''';

  @override
  final String main = '';

  @override
  String get test => _test.replaceFirst('// SETUP', setup ?? '').replaceFirst('// TEST_BODY', testBody).replaceFirst('// CLASSES', classes ?? '');

  final String _test = r'''
    import 'dart:async';
    import 'dart:ui' as ui;

    import 'package:flutter/animation.dart';
    import 'package:flutter/foundation.dart';
    import 'package:flutter/gestures.dart';
    import 'package:flutter/material.dart';
    import 'package:flutter/scheduler.dart';
    import 'package:flutter/services.dart';
    import 'package:flutter_test/flutter_test.dart';

    void main() {
      // SETUP
      testWidgets('test', (WidgetTester tester) async {
        // TEST_BODY
      });
    }
    // CLASSES
  ''';
}
