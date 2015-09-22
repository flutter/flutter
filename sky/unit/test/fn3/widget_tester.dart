import 'package:sky/src/fn3.dart';

class RootComponent extends StatefulComponent {
  RootComponentState createState() => new RootComponentState(this);
}

class RootComponentState extends ComponentState<RootComponent> {
  RootComponentState(RootComponent widget) : super(widget);
  Widget _child = new DecoratedBox(decoration: new BoxDecoration());
  Widget get child => _child;
  void set child(Widget value) {
    if (value != _child) {
      setState(() {
        _child = value;
      });
    }
  }
  Widget build() => child;
}

const Object _rootSlot = const Object();

class WidgetTester {

  WidgetTester() {
    WidgetSkyBinding.initWidgetSkyBinding();
    _rootElement = new StatefulComponentElement(new RootComponent());
    _rootElement.mount(null, _rootSlot);
  }

  StatefulComponentElement _rootElement;

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
    (_rootElement.state as RootComponentState).child = widget;
    WidgetSkyBinding.instance.beginFrame(0.0); // TODO(ianh): https://github.com/flutter/engine/issues/1084
  }

  void pumpFrameWithoutChange() {
    WidgetSkyBinding.instance.beginFrame(0.0); // TODO(ianh): https://github.com/flutter/engine/issues/1084
  }

}
