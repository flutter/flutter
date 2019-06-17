
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  test('$WidgetsBinding initializes with $LiveTestWidgetsFlutterBinding when FLUTTER_TEST = "false"', () {
    TestWidgetsFlutterBinding.ensureInitialized({'FLUTTER_TEST': 'false'});
    expect(WidgetsBinding.instance, isInstanceOf<LiveTestWidgetsFlutterBinding>());
  });
}