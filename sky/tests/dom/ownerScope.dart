import "../resources/third_party/unittest/unittest.dart";
import "../resources/unit.dart";

import "dart:sky";

void main() {
  initUnit();

  test("should return null for elements not a child of a scope", () {
    var doc = new Document();
    var element = doc.createElement("div");
    expect(element.owner, isNull);
  });
  test("should return the document for elements in the document scope", () {
    var doc = new Document();
    var element = doc.createElement("div");
    doc.appendChild(element);
    expect(element.owner, equals(doc));
  });
}
