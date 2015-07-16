import "../resources/third_party/unittest/unittest.dart";
import "../resources/unit.dart";

import "dart:sky";

void main() {
  initUnit();

  test('should be settable using "style" attribute', () {
    LayoutRoot layoutRoot = new LayoutRoot();
    var document = new Document();
    var foo = document.createElement('foo');
    layoutRoot.rootElement = foo;

    foo.setAttribute('style', 'color: red');

    expect(foo.getAttribute('style'), equals('color: red'));
    expect(foo.style["color"], equals('rgb(255, 0, 0)'));
  });
}
