import 'dart:sky' as sky;

import 'package:sky/rendering.dart';
import 'package:sky/src/fn3.dart';

import '../engine/mock_events.dart';

class RootComponent extends StatefulComponent {
  RootComponentState createState() => new RootComponentState();
}

class RootComponentState extends State<RootComponent> {
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

  void pumpFrame(Widget widget, [ double frameTimeMs = 0.0 ]) {
    runApp(widget);
    WidgetFlutterBinding.instance.beginFrame(frameTimeMs); // TODO(ianh): https://github.com/flutter/engine/issues/1084
  }

  void pumpFrameWithoutChange([ double frameTimeMs = 0.0 ]) {
    WidgetFlutterBinding.instance.beginFrame(frameTimeMs); // TODO(ianh): https://github.com/flutter/engine/issues/1084
  }


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

  Element findText(String text) {
    return findElement((Element element) {
      return element.widget is Text && element.widget.data == text;
    });
  }

  State findStateOfType(Type type) {
    StatefulComponentElement element = findElement((Element element) {
      return element is StatefulComponentElement && element.state.runtimeType == type;
    });
    return element?.state;
  }

  Point getCenter(Element element) {
    return _getElementPoint(element, (Size size) => size.center(Point.origin));
  }

  Point getTopLeft(Element element) {
    return _getElementPoint(element, (_) => Point.origin);
  }

  Point getTopRight(Element element) {
    return _getElementPoint(element, (Size size) => size.topRight(Point.origin));
  }

  Point getBottomLeft(Element element) {
    return _getElementPoint(element, (Size size) => size.bottomLeft(Point.origin));
  }

  Point getBottomRight(Element element) {
    return _getElementPoint(element, (Size size) => size.bottomRight(Point.origin));
  }

  Point _getElementPoint(Element element, Function sizeToPoint) {
    assert(element != null);
    RenderBox box = element.renderObject as RenderBox;
    assert(box != null);
    return box.localToGlobal(sizeToPoint(box.size));
  }


  void tap(Element element, { int pointer: 1 }) {
    tapAt(getCenter(element), pointer: pointer);
  }

  void tapAt(Point location, { int pointer: 1 }) {
    HitTestResult result = _hitTest(location);
    TestPointer p = new TestPointer(pointer);
    _dispatchEvent(p.down(location), result);
    _dispatchEvent(p.up(), result);
  }

  void dispatchEvent(sky.Event event, Point location) {
    _dispatchEvent(event, _hitTest(location));
  }

  HitTestResult _hitTest(Point location) => WidgetFlutterBinding.instance.hitTest(location);

  void _dispatchEvent(sky.Event event, HitTestResult result) {
    WidgetFlutterBinding.instance.dispatchEvent(event, result);
  }

}
