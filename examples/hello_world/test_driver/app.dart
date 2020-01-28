import 'dart:html';

import 'package:flutter_driver/driver_extension.dart';
import 'package:hello_world/main.dart' as app;


void main() async {
  // This line enables the extension.
  enableFlutterDriverExtension(handler: FlutterWebDataHandler().checkElement);

  // Call the `main()` function of the app, or call `runApp` with
  // any widget you are interested in testing.
  app.main();
}

// typedef DataHandler = Future<String> Function(String message);

class FlutterWebDataHandler {
  Future<String> checkElement(String message) {
    if (message == 'input') {
      final List<Node> nodeList = document.getElementsByTagName('input');
      return Future<String>.value(nodeList?.length.toString());
    } else if (message == 'setText') {
      final List<Node> nodeList = document.getElementsByTagName('input');
      if (nodeList.isNotEmpty) {
        final InputElement input = nodeList.first as InputElement;
        input.value = 'setText';
        input.text = 'setText';
        return Future<String>.value('true');
      } else {
        return Future<String>.value('false');
      }
    } else {
      return Future<String>.value('0');
    }
  }
}
