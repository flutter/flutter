import 'dart:ui' as ui;

import 'package:test/test.dart';

void main() {
  test("createText(null) shouldn't crash", () {
    var doc = new ui.Document();
    doc.createText(null);
  });
}
