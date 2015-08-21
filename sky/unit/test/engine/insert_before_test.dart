import 'dart:sky';

import 'package:test/test.dart';

void main() {
  Document document = new Document();

  test("should throw with invalid arguments", () {
    var parent = document.createElement("div");
    var child = document.createElement("div");
    parent.appendChild(child);
    // TODO(eseidel): This should throw!
    // expect(() {
    //   parent.insertBefore([parent]);
    // }, throws);
    expect(() {
      child.insertBefore([parent]);
    }, throws);
  });

}
