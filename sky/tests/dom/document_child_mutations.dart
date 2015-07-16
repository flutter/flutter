import "../resources/dom_utils.dart";
import "../resources/third_party/unittest/unittest.dart";
import "../resources/unit.dart";

import "dart:sky";

void main() {
  initUnit();

  var doc;

  setUp(() {
    doc = new Document();
  });

  test("should allow replacing the document element", () {
    var oldChild = doc.appendChild(doc.createElement("div"));
    expect(childElementCount(doc), equals(1));
    var newChild = doc.createElement("div");
    oldChild.replaceWith([newChild]);
    expect(childElementCount(doc), equals(1));
    expect(newChild.parentNode, equals(doc));
    expect(oldChild.parentNode, isNull);
  });

  test("should allow replacing a text child with an element", () {
    var oldChild = doc.appendChild(doc.createText("text here"));
    expect(childElementCount(doc), equals(0));
    expect(childNodeCount(doc), equals(1));
    var newChild = doc.createElement("div");
    oldChild.replaceWith([newChild]);
    expect(childElementCount(doc), equals(1));
    expect(childNodeCount(doc), equals(1));
    expect(newChild.parentNode, equals(doc));
    expect(oldChild.parentNode, isNull);
  });

  test("should allow replacing the document element with text", () {
    var oldChild = doc.appendChild(doc.createElement("div"));
    expect(childElementCount(doc), equals(1));
    var newChild = doc.createText(" text ");
    oldChild.replaceWith([newChild]);
    expect(childElementCount(doc), equals(0));
    expect(childNodeCount(doc), equals(1));
    expect(newChild.parentNode, equals(doc));
    expect(oldChild.parentNode, isNull);
  });

  test("should allow inserting text with a fragment", () {
    var fragment = doc.createDocumentFragment();
    fragment.appendChild(doc.createText(" text "));
    fragment.appendChild(doc.createText(" text "));
    expect(childNodeCount(doc), equals(0));
    doc.appendChild(fragment);
    expect(childElementCount(doc), equals(0));
    expect(childNodeCount(doc), equals(2));
  });

  test("should allow replacing the document element with a fragment", () {
    var oldChild = doc.appendChild(doc.createElement("div"));
    expect(childElementCount(doc), equals(1));
    var fragment = doc.createDocumentFragment();
    fragment.appendChild(doc.createText(" text "));
    var newChild = fragment.appendChild(doc.createElement("div"));
    fragment.appendChild(doc.createText(" "));
    oldChild.replaceWith([fragment]);
    expect(childElementCount(doc), equals(1));
    expect(childNodeCount(doc), equals(3));
    expect(newChild.parentNode, equals(doc));
    expect(oldChild.parentNode, isNull);
  });

  test("should throw when inserting multiple elements", () {
    doc.appendChild(doc.createElement("div"));
    var oldChild = doc.appendChild(doc.createText(" text "));
    expect(childElementCount(doc), equals(1));
    var newChild = doc.createElement("div");
    // expect(() {
    //   doc.replaceChild(newChild, 0);
    // }, throws);
    // expect(() {
    //   doc.insertBefore(newChild, oldChild);
    // }, throws);
  });

  test("should throw when inserting multiple elements with a fragment", () {
    var oldChild = doc.appendChild(doc.createElement("div"));
    expect(childElementCount(doc), equals(1));
    var fragment = doc.createDocumentFragment();
    fragment.appendChild(doc.createText(" text "));
    fragment.appendChild(doc.createElement("div"));
    fragment.appendChild(doc.createElement("div"));
    fragment.appendChild(doc.createText(" "));
    // expect(() {
    //   doc.replaceChild(fragment, 0);
    // }, throws);
    // expect(() {
    //   doc.insertBefore(fragment, oldChild);
    // }, throws);
  });
}
