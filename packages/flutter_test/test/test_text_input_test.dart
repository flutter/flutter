// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PageRoute<T> defaultPageRouteBuilder<T>(RouteSettings settings, WidgetBuilder builder) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) => builder(context),
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) => child,
    );
  }

  Widget buildTestApp({required TextEditingController controller, required FocusNode focusNode}) {
    return WidgetsApp(
      color: const Color(0xFFFFFFFF),
      pageRouteBuilder: defaultPageRouteBuilder,
      home: SizedBox.expand(
        child: Center(
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(),
            cursorColor: const Color(0xFFFF0000),
            backgroundCursorColor: const Color(0xFFFAFAFA),
          ),
        ),
      ),
    );
  }

  testWidgets('enterText works', (WidgetTester tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(buildTestApp(controller: controller, focusNode: focusNode));

    final EditableTextState state = tester.state(find.byType(EditableText));
    expect(state.textEditingValue.text, '');

    await tester.enterText(find.byType(EditableText), 'let there be text');
    expect(state.textEditingValue.text, 'let there be text');
    expect(state.textEditingValue.selection.isCollapsed, isTrue);
    expect(state.textEditingValue.selection.baseOffset, 17);
  });

  group('method call handler', () {
    tearDown(() {
      // Since all of these tests call setMethodCallHandler, reset the default
      // method call handler here.
      TextInput.setChannel(SystemChannels.textInput);
    });

    testWidgets(
      'receiveAction() forwards exception when exception occurs during action processing',
      (WidgetTester tester) async {
        // Setup a widget that can receive focus so that we can open the keyboard.
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);

        await tester.pumpWidget(buildTestApp(controller: controller, focusNode: focusNode));

        // Keyboard must be shown for receiveAction() to function.
        await tester.showKeyboard(find.byType(EditableText));

        // Register a handler for the text input channel that throws an error. This
        // error should be reported within a PlatformException by TestTextInput.
        SystemChannels.textInput.setMethodCallHandler((MethodCall call) {
          throw FlutterError('A fake error occurred during action processing.');
        });

        await expectLater(
          () => tester.testTextInput.receiveAction(TextInputAction.done),
          throwsA(isA<PlatformException>()),
        );
      },
    );

    testWidgets('selectors are called on macOS', (WidgetTester tester) async {
      List<dynamic>? selectorNames;
      await SystemChannels.textInput.invokeMethod('TextInput.setClient', <dynamic>[
        1,
        <String, dynamic>{},
      ]);
      await SystemChannels.textInput.invokeMethod('TextInput.show');
      SystemChannels.textInput.setMethodCallHandler((MethodCall call) async {
        if (call.method == 'TextInputClient.performSelectors') {
          selectorNames = (call.arguments as List<dynamic>)[1] as List<dynamic>;
        }
      });
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
      await SystemChannels.textInput.invokeMethod('TextInput.clearClient');

      if (defaultTargetPlatform == TargetPlatform.macOS) {
        expect(selectorNames, <dynamic>['moveBackward:', 'moveToBeginningOfParagraph:']);
      } else {
        expect(selectorNames, isNull);
      }
    }, variant: TargetPlatformVariant.all());

    testWidgets('selector is called for ctrl + backspace on macOS', (WidgetTester tester) async {
      List<dynamic>? selectorNames;
      await SystemChannels.textInput.invokeMethod('TextInput.setClient', <dynamic>[
        1,
        <String, dynamic>{},
      ]);
      await SystemChannels.textInput.invokeMethod('TextInput.show');
      SystemChannels.textInput.setMethodCallHandler((MethodCall call) async {
        if (call.method == 'TextInputClient.performSelectors') {
          selectorNames = (call.arguments as List<dynamic>)[1] as List<dynamic>;
        }
      });
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.backspace);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.backspace);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await SystemChannels.textInput.invokeMethod('TextInput.clearClient');

      if (defaultTargetPlatform == TargetPlatform.macOS) {
        expect(selectorNames, <dynamic>['deleteBackwardByDecomposingPreviousCharacter:']);
      } else {
        expect(selectorNames, isNull);
      }
    }, variant: TargetPlatformVariant.all());
  });

  // Run this test twice to ensure that the TestTextInputKeyHandler is cleared
  // between tests.
  // Regression test for https://github.com/flutter/flutter/issues/171491.
  for (var i = 0; i < 2; i++) {
    testWidgets('keyboard shortcut handling is cleared between tests (${i + 1}/2)', (
      WidgetTester tester,
    ) async {
      final client = _PerformSelectorInputClient();

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.expand(
            child: Focus(focusNode: focusNode, autofocus: true, child: Container()),
          ),
        ),
      );

      final TextInputConnection connection = TextInput.attach(
        client,
        const TextInputConfiguration(),
      );
      addTearDown(connection.close);
      connection.show();

      // Press the left arrow, which should trigger a "moveLeft:" selector call.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft, platform: 'macos');

      expect(client.performSelectorCalled, isTrue);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  }
}

/// A [TextInputClient] that reports whether the `performSelector` method was
/// called.
class _PerformSelectorInputClient with TextInputClient {
  bool get performSelectorCalled => _performSelectorCalled;
  bool _performSelectorCalled = false;

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  TextEditingValue? get currentTextEditingValue => _currentTextEditingValue;
  TextEditingValue _currentTextEditingValue = TextEditingValue.empty;

  @override
  void performSelector(String selectorName) {
    super.performSelector(selectorName);
    _performSelectorCalled = true;
  }

  @override
  void connectionClosed() {}

  @override
  void updateEditingValue(TextEditingValue value) {
    _currentTextEditingValue = value;
  }

  @override
  void performAction(TextInputAction action) {}

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}
}
