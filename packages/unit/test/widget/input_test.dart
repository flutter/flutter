import 'package:mojo_services/keyboard/keyboard.mojom.dart';
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
    testWidgets((WidgetTester tester) {
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

      tester.pumpWidget(builder());

      Element input = tester.findElementByKey(inputKey);
      Size emptyInputSize = (input.renderObject as RenderBox).size;

      // Simulate entry of text through the keyboard.
      expect(mockKeyboard.client, isNotNull);
      const String testValue = 'Test';
      mockKeyboard.client.setComposingText(testValue, testValue.length);

      // Check that the onChanged event handler fired.
      expect(inputValue, equals(testValue));

      tester.pumpWidget(builder());

      // Check that the Input with text has the same size as the empty Input.
      expect((input.renderObject as RenderBox).size, equals(emptyInputSize));
    });
  });

  test('Cursor blinks', () {
    testWidgets((WidgetTester tester) {
      GlobalKey inputKey = new GlobalKey();

      Widget builder() {
        return new Center(
          child: new Input(
            key: inputKey,
            placeholder: 'Placeholder'
          )
        );
      }

      tester.pumpWidget(builder());

      EditableTextState editableText = tester.findStateOfType(EditableTextState);

      // Check that the cursor visibility toggles after each blink interval.
      void checkCursorToggle() {
        bool initialShowCursor = editableText.test_showCursor;
        tester.async.elapse(editableText.test_cursorBlinkPeriod);
        expect(editableText.test_showCursor, equals(!initialShowCursor));
        tester.async.elapse(editableText.test_cursorBlinkPeriod);
        expect(editableText.test_showCursor, equals(initialShowCursor));
      }

      checkCursorToggle();

      // Try the test again with a nonempty EditableText.
      mockKeyboard.client.setComposingText('X', 1);
      checkCursorToggle();
    });
  });
}
