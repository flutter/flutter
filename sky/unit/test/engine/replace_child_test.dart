import 'dart:ui';

import 'package:test/test.dart';

import 'dom_utils.dart';

void main() {
  Document document = new Document();

  test("should replace elements", () {
    Element parent = document.createElement("div");
    Element oldChild = parent.appendChild(document.createElement("div"));
    Element newChild = document.createElement("div");
    oldChild.replaceWith(<Node>[newChild]);
    expect(oldChild.parentNode, isNull);
    expect(newChild.parentNode, equals(parent));
  });

  test("should replace text", () {
    Element parent = document.createElement("div");
    Node oldChild = parent.appendChild(document.createText(" it's a text "));
    Element newChild = document.createElement("div");
    oldChild.replaceWith(<Node>[newChild]);
    expect(oldChild.parentNode, isNull);
    expect(newChild.parentNode, equals(parent));
  });

  test("should replace children with a fragment", () {
    DocumentFragment fragment = document.createDocumentFragment();
    Element child1 = fragment.appendChild(document.createElement("div"));
    Node child2 = fragment.appendChild(document.createText(" text "));
    Node child3 = fragment.appendChild(document.createText(" "));
    Element child4 = fragment.appendChild(document.createElement("div"));
    Element parent = document.createElement("div");
    Element oldChild = parent.appendChild(document.createElement("div"));
    Element lastChild = parent.appendChild(document.createElement("div"));
    oldChild.replaceWith(<Node>[fragment]);
    expect(child1.parentNode, equals(parent));
    expect(child2.parentNode, equals(parent));
    expect(child3.parentNode, equals(parent));
    expect(child4.parentNode, equals(parent));
    expect(oldChild.parentNode, isNull);
    expect(childNodeCount(parent), equals(5));
    expect(childElementCount(parent), equals(3));
    expect(parent.lastChild, equals(lastChild));
  });

  // test("should throw when appending to a text", () {
  //   var parent = new Text();
  //   expect(() {
  //     parent.replaceChild(document.createElement("div"), null);
  //   }, throws);
  // });
}
