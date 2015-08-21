import 'dart:sky' as sky;

import 'package:test/test.dart';

void main() {
  test("createText(null) shouldn't crash", () {
    var doc = new sky.Document();
    doc.createText(null);
  });
}
