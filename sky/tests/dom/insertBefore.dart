import "../resources/dom_utils.dart";
import "../resources/third_party/unittest/unittest.dart";
import "../resources/unit.dart";

import "dart:sky";

void main() {
  initUnit();

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
