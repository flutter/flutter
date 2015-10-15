import 'dart:ui';

import 'package:test/test.dart';

void main() {
  Document document = new Document();

  test("should throw with invalid arguments", () {
    Element parent = document.createElement("div");
    Element child = document.createElement("div");
    parent.appendChild(child);
    // TODO(eseidel): This should throw!
    // expect(() {
    //   parent.insertBefore([parent]);
    // }, throws);
    expect(() {
      child.insertBefore(<Node>[parent]);
    }, throws);
  });

}
