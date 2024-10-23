// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'Widgets running in an initialWindow that was created by MultiWindowApp in runWidget can find their WindowContext',
      (WidgetTester tester) async {
    WindowContext? windowContext;

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.windowing, (MethodCall call) async {
      final Map<Object?, Object?> args =
          call.arguments as Map<Object?, Object?>;
      if (call.method == 'create') {
        final List<Object?> size = args['size']! as List<Object?>;

        return <String, Object?>{
          'viewId': tester.view.viewId,
          'archetype': WindowArchetype.regular.index,
          'width': size[0],
          'height': size[1],
          'parentViewId': null
        };
      }
      throw Exception('Unsupported method call: ${call.method}');
    });

    await tester.pumpWidget(wrapWithView: false, Builder(
      builder: (BuildContext context) {
        return MultiWindowApp(
          initialWindows: <Future<Window> Function(BuildContext)>[
            (BuildContext context) => createRegular(
                context: context,
                size: const Size(800, 600),
                builder: (BuildContext context) {
                  return Builder(builder: (BuildContext context) {
                    windowContext = WindowContext.of(context);
                    return Container();
                  });
                })
          ],
        );
      },
    ));

    await tester.pump();
    expect(windowContext, isNotNull);
  });

  testWidgets('createRegular creates a regular window',
      (WidgetTester tester) async {
    const Size windowSize = Size(800, 600);

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.windowing, (MethodCall call) async {
      final Map<Object?, Object?> args =
          call.arguments as Map<Object?, Object?>;
      if (call.method == 'createWindow') {
        final List<Object?> size = args['size']! as List<Object?>;

        return <String, Object?>{
          'viewId': tester.view.viewId,
          'archetype': WindowArchetype.regular.index,
          'width': size[0],
          'height': size[1],
          'parentViewId': null
        };
      }
      throw Exception('Unsupported method call: ${call.method}');
    });

    Window? testWindow;
    BuildContext? testContext;
    await tester.pumpWidget(wrapWithView: false, Builder(
      builder: (BuildContext context) {
        return MultiWindowApp(
          initialWindows: <Future<Window> Function(BuildContext)>[
            (BuildContext context) async {
              testContext = context;
              testWindow = await createRegular(
                  context: context,
                  size: windowSize,
                  builder: (BuildContext context) {
                    return Builder(builder: (BuildContext context) {
                      return Container();
                    });
                  });
              return testWindow!;
            }
          ],
        );
      },
    ));

    await tester.pump();

    final MultiWindowAppContext multiViewAppContext =
        MultiWindowAppContext.of(testContext!)!;
    expect(multiViewAppContext.windows.length, 1);

    final Window window = multiViewAppContext.windows.first;
    expect(window.archetype, WindowArchetype.regular);
    expect(window.size.width, windowSize.width);
    expect(window.size.height, windowSize.height);
    expect(window.parent, isNull);
    expect(window.children, isEmpty);
    expect(window.view.viewId, tester.view.viewId);
  });

  testWidgets('destroyWindow destroys a window', (WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.windowing, (MethodCall call) async {
      final Map<Object?, Object?> args =
          call.arguments as Map<Object?, Object?>;
      switch (call.method) {
        case 'createWindow':
          {
            final List<Object?> size = args['size']! as List<Object?>;

            return <String, Object?>{
              'viewId': tester.view.viewId,
              'archetype': WindowArchetype.regular.index,
              'width': size[0],
              'height': size[1],
              'parentViewId': null
            };
          }
        case 'destroyWindow':
          expect(args['viewId'], tester.view.viewId);
          return null;
        default:
          throw Exception('Unsupported method call: ${call.method}');
      }
    });

    Window? testWindow;
    BuildContext? testContext;
    await tester.pumpWidget(wrapWithView: false, Builder(
      builder: (BuildContext context) {
        return MultiWindowApp(
          initialWindows: <Future<Window> Function(BuildContext)>[
            (BuildContext context) async {
              testContext = context;
              testWindow = await createRegular(
                  context: context,
                  size: const Size(800, 600),
                  builder: (BuildContext context) {
                    return Builder(builder: (BuildContext context) {
                      return Container();
                    });
                  });
              return testWindow!;
            }
          ],
        );
      },
    ));

    await tester.pump();

    MultiWindowAppContext? multiViewAppContext =
        MultiWindowAppContext.of(testContext!);
    expect(multiViewAppContext!.windows.length, 1);

    destroyWindow(testContext!, multiViewAppContext.windows.first);

    await tester.pumpAndSettle();

    multiViewAppContext = MultiWindowAppContext.of(testContext!);
    expect(multiViewAppContext!.windows.length, 0);
  });
}
