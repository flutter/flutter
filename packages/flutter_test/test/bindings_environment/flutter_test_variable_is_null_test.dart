
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  test('$WidgetsBinding initializes with $AutomatedTestWidgetsFlutterBinding when FLUTTER_TEST is defined but null', () {
    TestWidgetsFlutterBinding.ensureInitialized({'FLUTTER_TEST': null});
    expect(WidgetsBinding.instance, isInstanceOf<AutomatedTestWidgetsFlutterBinding>());
  });
}