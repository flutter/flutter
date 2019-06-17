
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  test('$WidgetsBinding initializes with $LiveTestWidgetsFlutterBinding when the environment does not contain FLUTTER_TEST', () {
    TestWidgetsFlutterBinding.ensureInitialized({});
    expect(WidgetsBinding.instance, isInstanceOf<LiveTestWidgetsFlutterBinding>());
  });
}