import 'dart:sky';

import 'package:test/test.dart';

void main() {
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
