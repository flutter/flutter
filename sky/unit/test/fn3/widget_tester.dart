import 'package:sky/src/fn3/framework.dart';

class TestComponent extends Component {
  TestComponent({ this.child });
  final Widget child;
  Widget build() => child;
}

final Object _rootSlot = new Object();

class WidgetTester {
  ComponentElement _rootElement;

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
      _rootElement = new ComponentElement(new TestComponent(child: widget));
      _rootElement.mount(_rootSlot);
    } else {
      _rootElement.update(new TestComponent(child: widget));
    }
  }

}
