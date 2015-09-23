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
  Widget build(BuildContext context) => child;
}

class WidgetTester {

  void walkElements(ElementVisitor visitor) {
    void walk(Element element) {
      visitor(element);
      element.visitChildren(walk);
    }
    WidgetFlutterBinding.instance.renderViewElement.visitChildren(walk);
  }

  Element findElement(bool predicate(Element element)) {
    try {
      walkElements((Element element) {
        if (predicate(element))
          throw element;
      });
    } on Element catch (e) {
      return e;
    }
    return null;
  }

  Element findElementByKey(Key key) {
    return findElement((Element element) => element.widget.key == key);
  }

  void pumpFrame(Widget widget) {
    runApp(widget);
    WidgetFlutterBinding.instance.beginFrame(0.0); // TODO(ianh): https://github.com/flutter/engine/issues/1084
  }

  void pumpFrameWithoutChange() {
    WidgetFlutterBinding.instance.beginFrame(0.0); // TODO(ianh): https://github.com/flutter/engine/issues/1084
  }

}
