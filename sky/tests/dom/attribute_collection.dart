import "../resources/third_party/unittest/unittest.dart";
import "../resources/unit.dart";

import "dart:sky";

void main() {
  initUnit();

  var div;
  setUp(() {
    var document = new Document();
    div = document.createElement("div");
  });

  test("should get by index", () {
    div.setAttribute("attr0", "value0");
    div.setAttribute("attr1", "value1");
    var attrs = div.getAttributes();
    expect(attrs.length, equals(2));
    expect(attrs[0].name, equals("attr0"));
    expect(attrs[0].value, equals("value0"));
    expect(attrs[1].name, equals("attr1"));
    expect(attrs[1].value, equals("value1"));
  });
  test("should set by name", () {
    div.setAttribute("attrName", "value0");
    expect(div.getAttribute("attrName"), equals("value0"));
    expect(div.getAttributes()[0].name, equals("attrName"));
    expect(div.getAttributes()[0].value, equals("value0"));
    div.setAttribute("attrName", "new value");
    expect(div.getAttribute("attrName"), equals("new value"));
    expect(div.getAttributes()[0].name, equals("attrName"));
    expect(div.getAttributes()[0].value, equals("new value"));
  });
  test("should be case sensitive", () {
    div.setAttribute("attrName", "value0");
    expect(div.getAttribute("attrname"), isNull);
    expect(div.getAttribute("attrName"), equals("value0"));
  });
  test("should not live update", () {
    div.setAttribute("attr0", "0");
    div.setAttribute("attr1", "1");
    div.setAttribute("attr2", "2");
    var oldAttributes = div.getAttributes();
    expect(oldAttributes.length, equals(3));
    div.removeAttribute("attr1");
    expect(oldAttributes.length, equals(3));
    div.setAttribute("attr0", "value0");
    div.setAttribute("attr2", "value2");
    var newAttributes = div.getAttributes();
    expect(newAttributes.length, equals(2));
    expect(newAttributes[0].name, equals("attr0"));
    expect(newAttributes[0].value, equals("value0"));
    expect(newAttributes[1].name, equals("attr2"));
    expect(newAttributes[1].value, equals("value2"));
    expect(newAttributes, isNot(equals(oldAttributes)));
    expect(oldAttributes[0].name, equals("attr0"));
    expect(oldAttributes[0].value, equals("0"));
    expect(oldAttributes[1].name, equals("attr1"));
    expect(oldAttributes[1].value, equals("1"));
    expect(oldAttributes[2].name, equals("attr2"));
    expect(oldAttributes[2].value, equals("2"));
  });
}
