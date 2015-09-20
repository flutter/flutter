import 'package:mojo_services/keyboard/keyboard.mojom.dart';
import 'package:sky/rendering.dart';
import 'package:sky/services.dart';
import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';
import '../services/mock_services.dart';

class MockKeyboard implements KeyboardService {
  KeyboardClient client;

  void show(KeyboardClientStub client, int type) {
    this.client = client.impl;
  }

  void showByRequest() {}

  void hide() {}
}

void main() {
  test('Editable text has consistent width', () {
    WidgetTester tester = new WidgetTester();

    MockKeyboard mockKeyboard = new MockKeyboard();
    serviceMocker.registerMockService(KeyboardServiceName, mockKeyboard);

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
}
