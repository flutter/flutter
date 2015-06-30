import "../resources/third_party/unittest/unittest.dart";
import "../resources/unit.dart";

import "dart:sky";

void main() {
  initUnit();

  test("getChildElements should only include immediate children", () {
    var doc = new Document();
    var parent = doc.createElement('parent');
    var child1 = doc.createElement('child1');
    var child2 = doc.createElement('child1');
    var grandchild = doc.createElement('grandchild');

    doc.appendChild(parent);
    parent.appendChild(child1);
    parent.appendChild(child2);
    child1.appendChild(grandchild);

    var children = parent.getChildElements();
    expect(children.length, equals(2));
    expect(children[0], equals(child1));
    expect(children[1], equals(child2));
  });
}
