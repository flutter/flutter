import 'package:mojo_services/keyboard/keyboard.mojom.dart';
import 'package:quiver/testing/async.dart';
import 'package:sky/rendering.dart';
import 'package:sky/services.dart';
import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';
import '../services/mock_services.dart';

class MockKeyboard implements KeyboardService {
  KeyboardClient client;

  void show(KeyboardClientStub client, KeyboardType type) {
    this.client = client.impl;
  }

  void showByRequest() {}

  void hide() {}
}

void main() {
  MockKeyboard mockKeyboard = new MockKeyboard();
  serviceMocker.registerMockService(KeyboardServiceName, mockKeyboard);

  test('Editable text has consistent width', () {
    WidgetTester tester = new WidgetTester();

    GlobalKey inputKey = new GlobalKey();
    String inputValue;

    Widget builder() {
      return new Center(
        child: new Input(
          key: inputKey,
          placeholder: 'Placeholder',
          onChanged: (value) { inputValue = value; }
        )
      );
    }

    tester.pumpFrame(builder);

    Input input = tester.findWidget((Widget widget) => widget.key == inputKey);
    Size emptyInputSize = (input.renderObject as RenderBox).size;

    // Simulate entry of text through the keyboard.
    expect(mockKeyboard.client, isNotNull);
    const String testValue = 'Test';
    mockKeyboard.client.setComposingText(testValue, testValue.length);

    // Check that the onChanged event handler fired.
    expect(inputValue, equals(testValue));

    tester.pumpFrame(builder);

    // Check that the Input with text has the same size as the empty Input.
    expect((input.renderObject as RenderBox).size, equals(emptyInputSize));
  });

  test('Cursor blinks', () {
    WidgetTester tester = new WidgetTester();

    GlobalKey inputKey = new GlobalKey();

    Widget builder() {
      return new Center(
        child: new Input(
          key: inputKey,
          placeholder: 'Placeholder'
        )
      );
    }

    new FakeAsync().run((async) {
      tester.pumpFrame(builder);

      EditableText editableText = tester.findWidget(
          (Widget widget) => widget is EditableText);

      // Check that the cursor visibility toggles after each blink interval.
      void checkCursorToggle() {
        bool initialShowCursor = editableText.test_showCursor;
        async.elapse(editableText.test_cursorBlinkPeriod);
        expect(editableText.test_showCursor, equals(!initialShowCursor));
        async.elapse(editableText.test_cursorBlinkPeriod);
        expect(editableText.test_showCursor, equals(initialShowCursor));
      }

      checkCursorToggle();

      // Try the test again with a nonempty EditableText.
      mockKeyboard.client.setComposingText('X', 1);
      checkCursorToggle();
    });
  });
}
