import 'package:sky/src/fn3/framework.dart';

class TestComponent extends StatelessComponent {
  TestComponent({ this.child });
  final Widget child;
  Widget build() => child;
}

final Object _rootSlot = new Object();

class WidgetTester {
  StatelessComponentElement _rootElement;

  void walkElements(ElementVisitor visitor) {
    void walk(Element element) {
      visitor(element);
      element.visitChildren(walk);
    }

    _rootElement.visitChildren(walk);
  }

  Element findElement(bool predicate(Element widget)) {
    try {
      walkElements((Element widget) {
        if (predicate(widget))
          throw widget;
      });
    } catch (e) {
      if (e is Element)
        return e;
      rethrow;
    }
    return null;
  }

  void pumpFrame(Widget widget) {
    if (_rootElement == null) {
      _rootElement = new StatelessComponentElement(new TestComponent(child: widget));
      _rootElement.mount(null, _rootSlot);
    } else {
      _rootElement.update(new TestComponent(child: widget));
    }
  }

}
