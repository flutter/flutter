import "../resources/dom_utils.dart";
import "../resources/third_party/unittest/unittest.dart";
import "../resources/unit.dart";

import "dart:sky";

void main() {
  initUnit();

  var document = new Document();

  test("should replace elements", () {
    var parent = document.createElement("div");
    var oldChild = parent.appendChild(document.createElement("div"));
    var newChild = document.createElement("div");
    oldChild.replaceWith([newChild]);
    expect(oldChild.parentNode, isNull);
    expect(newChild.parentNode, equals(parent));
  });

  test("should replace text", () {
    var parent = document.createElement("div");
    var oldChild = parent.appendChild(document.createText(" it's a text "));
    var newChild = document.createElement("div");
    oldChild.replaceWith([newChild]);
    expect(oldChild.parentNode, isNull);
    expect(newChild.parentNode, equals(parent));
  });

  test("should replace children with a fragment", () {
    var fragment = document.createDocumentFragment();
    var child1 = fragment.appendChild(document.createElement("div"));
    var child2 = fragment.appendChild(document.createText(" text "));
    var child3 = fragment.appendChild(document.createText(" "));
    var child4 = fragment.appendChild(document.createElement("div"));
    var parent = document.createElement("div");
    var oldChild = parent.appendChild(document.createElement("div"));
    var lastChild = parent.appendChild(document.createElement("div"));
    oldChild.replaceWith([fragment]);
    expect(child1.parentNode, equals(parent));
    expect(child2.parentNode, equals(parent));
    expect(child3.parentNode, equals(parent));
    expect(child4.parentNode, equals(parent));
    expect(oldChild.parentNode, isNull);
    expect(childNodeCount(parent), equals(5));
    expect(childElementCount(parent), equals(3));
    expect(parent.lastChild, equals(lastChild));
  });

  // test("should throw when inserting a tree scope", () {
  //   var parent = document.createElement("div");
  //   var doc = new Document();
  //   var shadowRoot = document.createElement("span").ensureShadowRoot();
  //   expect(() {
  //     parent.replaceChild(doc);
  //   }, throws);
  //   expect(() {
  //     parent.replaceChild(shadowRoot);
  //   }, throws);
  //   expect(() {
  //     doc.replaceChild(fragment);
  //   }, throws);
  // });

  // test("should throw when appending to a text", () {
  //   var parent = new Text();
  //   expect(() {
  //     parent.replaceChild(document.createElement("div"), null);
  //   }, throws);
  // });
}
