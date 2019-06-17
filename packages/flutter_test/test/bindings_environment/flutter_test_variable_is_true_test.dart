import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  test('$WidgetsBinding initializes with $AutomatedTestWidgetsFlutterBinding when FLUTTER_TEST = "true"', () {
    TestWidgetsFlutterBinding.ensureInitialized({'FLUTTER_TEST': 'true'});
    expect(WidgetsBinding.instance, isInstanceOf<AutomatedTestWidgetsFlutterBinding>());
  });
}