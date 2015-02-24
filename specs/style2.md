Sky Style Language
==================

Note: This is a work in progress that will eventually replace
(style.md)[style.md].

The Sky style API looks like the following:

```dart

  // all properties can be set as strings:
  element.style['color'] = 'blue';

  // some properties have dedicated APIs
  // color
  element.style.color.red += 1; // 0..255
  element.style.color.blue += 10; // 0..255
  element.style.color.green = 255; // 0..255
  element.style.color.alpha = 128; // 0..255
  // transform
  element.style.transform..reset()
                         ..translate(100, 100)
                         ..rotate(PI/8)
                         ..translate(-100, -100);
  element.style.transform.translate(10, 0);
  // height, width
  element.style.height.auto = true;
  if (element.style.height.auto)
    element.style.height.pixels = 10;
  element.style.height.pixels += 1;
  element.style.height.em = 1;

  // each property with a dedicated API defines a shorthand setter
  // style.transform takes a matrix:
  element.style.transform = new Matrix(1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
  // style.color takes a 32bit int:
  element.style.color = 0xFF009900;
  // style.height and style.width takes pixels or the constant 'auto':
  element.style.height = auto;
  element.style.width = 100;
  // all properties with a dedicated API can also be set to null, inherit, or initial:
  element.style.transform = null; // unset the property
  element.style.color = initial; // set it to its initial value
  element.style.color = inherit; // make it get its parent's value

  // you can create a blank StyleDeclaration object:
  var style = new StyleDeclaration();
  // you can replace an element's StyleDeclaration object wholesale:
  element.style = style;
  // you can clone a StyleDeclaration object:
  var style2 = new StyleDeclaration.clone(style);
```

The dart:sky library contains the following to define this API:

```dart
import 'dart:mirrors';
import 'dart:math';

class WeakMap<Key, Value> {
  // This is not actually a weak map right now, because Dart doesn't let us have weak references.
  // We should fix that, or else we're going to keep alive every object you ever tear off through
  // the StyleDeclaration API, even if you never use it again, until the StyleDeclaration object
  // itself is GC'ed, which is likely when the element is GC'ed, which is likely never.
  Map<Key, Value> _map = new Map<Key, Value>();
  operator[](Key key) => _map[key];
  operator[]=(Key key, Value value) => _map[key] = value;
  bool containsKey(Key key) => _map.containsKey(key);
}

typedef void StringSetter(Symbol propertySymbol, StyleDeclaration declaration, String value);
typedef String StringGetter(Symbol propertySymbol, StyleDeclaration declaration);
typedef Property ObjectConstructor(Symbol propertySymbol, StyleDeclaration declaration);

class PropertyTable {
  const PropertyTable({this.symbol, this.inherited, this.stringGetter, this.stringSetter, this.objectConstructor});
  final Symbol symbol;
  final bool inherited;
  final StringSetter stringSetter;
  final StringGetter stringGetter;
  final ObjectConstructor objectConstructor;
}

Map<Symbol, PropertyTable> _registeredProperties = new Map<Symbol, PropertyTable>();
void registerProperty(PropertyTable data) {
  assert(data.symbol is Symbol);
  assert(data.inherited is bool);
  assert(data.stringSetter is StringSetter);
  assert(data.stringGetter is StringGetter);
  assert(data.objectConstructor == null || data.objectConstructor is ObjectConstructor);
  assert(!_registeredProperties.containsKey(data.symbol));
  _registeredProperties[data.symbol] = data;
}

@proxy
class StyleDeclaration {
  StyleDeclaration() { this._init(); }
  StyleDeclaration.clone(StyleDeclaration template) { this.init(template); }
  external void _init([StyleDeclaration template]); // O(1)
  // This class has C++-backed internal state representing the
  // properties known to the system. It's assumed that Property
  // subclasses are also C++-backed and can directly manipulate this
  // internal state.
  // If the argument 'template' is provided, then this should be a clone
  // of the styles of the template StyleDeclaration

  operator [](String propertyName) {
    var propertySymbol = new Symbol(propertyName);
    if (_registeredProperties.containsKey(propertySymbol))
      return _registeredProperties[propertySymbol].stringGetter(propertySymbol, this);
    throw new ArgumentError(propertyName);
  }

  operator []=(String propertyName, String newValue) {
    var propertySymbol = new Symbol(propertyName);
    if (_registeredProperties.containsKey(propertySymbol))
      return _registeredProperties[propertySymbol].stringSetter(propertySymbol, this, newValue);
    throw new ArgumentError(propertyName);
  }

  // some properties expose dedicated APIs so you don't have to use string manipulation
  WeakMap<Symbol, Property> _properties = new WeakMap<Symbol, Property>();
  noSuchMethod(Invocation invocation) {
    Symbol propertySymbol;
    if (invocation.isSetter) {
      // when it's a setter, the name will be "foo=" rather than "foo"
      String propertyName = MirrorSystem.getName(invocation.memberName);
      assert(propertyName[propertyName.length-1] == '=');
      propertySymbol = new Symbol(propertyName.substring(0, propertyName.length-1));
    } else {
      propertySymbol = invocation.memberName;
    }
    Property property;
    if (!_properties.containsKey(propertySymbol)) {
      if (_registeredProperties.containsKey(propertySymbol)) {
        var constructor = _registeredProperties[propertySymbol].objectConstructor;
        if (constructor == null)
          return super.noSuchMethod(invocation);
        property = constructor(propertySymbol, this);
      } else {
        return super.noSuchMethod(invocation);
      }
    } else {
      property = _properties[propertySymbol];
    }
    if (invocation.isMethod) {
      if (property is Function)
        return Function.apply(property as Function, invocation.positionalArguments, invocation.namedArguments);
      return super.noSuchMethod(invocation);
    }
    if (invocation.isSetter)
      return Function.apply(property.setter, invocation.positionalArguments, invocation.namedArguments);
    return property;
  }
}

const initial = const Object();
const inherit = const Object();

abstract class Property {
  Property(this.propertySymbol, this.declaration);
  final StyleDeclaration declaration;
  final Symbol propertySymbol;

  bool get inherited => _registeredProperties[propertySymbol].inherited;

  bool get initial => _isInitial();
  void set initial (value) {
    if (value == true)
      return _setInitial();
    throw new ArgumentError(value);
  }

  bool get inherit => _isInherit();
  void set inherit (value) {
    if (value == true)
      return _setInherit();
    throw new ArgumentError(value);
  }

  void setter(dynamic value) {
    if (value == initial)
      return _setInitial();
    if (value == inherit)
      return _setInitial();
    if (value == null)
      return _unset();
    throw new ArgumentError(value);
  }

  external bool _isInitial();
  external void _setInitial();
  external bool _isInherit();
  external void _setInherit();
  external void _unset();
}
```

Sky defines the following properties, currently as part of the core,
but eventually this will be moved to the framework:

```dart
class LengthProperty extends Property {
  LengthProperty(Symbol propertySymbol, StyleDeclaration declaration) : super(propertySymbol, declaration);

  double get pixels => _getPixels();
  void set pixels (value) => _setPixels(value);

  double get inches => _getPixels() / 96.0;
  void set inches (value) => _setPixels(value * 96.0);

  double get em => _getEm();
  void set em (value) => _setEm(value);

  void setter(dynamic value) {
    if (value is num)
      return _setPixels(value.toDouble());
    return super.setter(value);
  }

  external double _getPixels();
  // throws StateError if the value isn't in pixels
  external void _setPixels(double value);

  external double _getEm();
  // throws StateError if the value isn't in pixels
  external void _setEm(double value);
}

const auto = const Object();

class AutoLengthProperty extends LengthProperty {
  AutoLengthProperty(Symbol propertySymbol, StyleDeclaration declaration) : super(propertySymbol, declaration);

  bool get auto => _isAuto();
  void set auto (value) {
    if (value == true)
      _setAuto();
    throw new ArgumentError(value);
  }

  void setter(dynamic value) {
    if (value == auto)
      return _setAuto();
    return super.setter(value);
  }

  external bool _isAuto();
  external void _setAuto();
}

class ColorProperty extends Property {
  ColorProperty(Symbol propertySymbol, StyleDeclaration declaration) : super(propertySymbol, declaration);

  int get alpha => _getRGBA() & 0xFF000000 >> 24;
  void set alpha (int value) => _setRGBA(_getRGBA() & 0x00FFFFFF + value << 24);
  int get red => _getRGBA() & 0x00FF0000 >> 16;
  void set red (int value) => _setRGBA(_getRGBA() & 0xFF00FFFF + value << 16);
  int get green => _getRGBA() & 0x0000FF00 >> 8;
  void set green (int value) => _setRGBA(_getRGBA() & 0xFFFF00FF + value << 8);
  int get blue => _getRGBA() & 0x000000FF >> 0;
  void set blue (int value) => _setRGBA(_getRGBA() & 0xFFFFFF00 + value << 0);

  int get rgba => _getRGBA();
  void set rgba (int value) => _setRGBA(value);

  void setter(dynamic value) {
    if (value is int)
      return _setRGBA(value);
    return super.setter(value);
  }

  external int _getRGBA();
  // throws StateError if the value isn't a color
  external void _setRGBA(int value);
}

class Matrix {
  const Matrix(this.a, this.b, this.c, this.d, this.e, this.f);

  // +-     -+
  // | a c e |
  // | b d f |
  // | 0 0 1 |
  // +-     -+
  
  final double a;
  final double b;
  final double c;
  final double d;
  final double e;
  final double f;
}

class TransformProperty extends Property {
  TransformProperty(Symbol propertySymbol, StyleDeclaration declaration) : super(propertySymbol, declaration);

  void reset() => setTransform(1.0, 0.0, 0.0, 1.0, 0.0, 0.0);

  void translate(double dx, double dy) => transform(1.0, 0.0, 0.0, 1.0, dx, dy);
  void scale(double dw, double dh) => transform(dw, 0.0, 0.0, dh, 0.0, 0.0);
  void rotate(double theta) => transform(cos(theta), -sin(theta), sin(theta), cos(theta), 0.0, 0.0);

  // there's no "transform" getter since it would always return a new Matrix
  // such that foo.transform == foo.transform would never be true
  // and foo.transform = bar; bar == foo.transform would also never be true
  // which is bad API

  external Matrix getTransform();
  // throws StateError if the value isn't a matrix
  // returns a new matrix each time
  external void setTransform(a, b, c, d, e, f);
  external void transform(a, b, c, d, e, f);
  // throws StateError if the value isn't a matrix
}

external void autoLengthPropertyStringSetter(Symbol propertySymbol, StyleDeclaration declaration, String value);
external String autoLengthPropertyStringGetter(Symbol propertySymbol, StyleDeclaration declaration);
external void colorPropertyStringSetter(Symbol propertySymbol, StyleDeclaration declaration, String value);
external String colorPropertyStringGetter(Symbol propertySymbol, StyleDeclaration declaration);
external void transformPropertyStringSetter(Symbol propertySymbol, StyleDeclaration declaration, String value);
external String transformPropertyStringGetter(Symbol propertySymbol, StyleDeclaration declaration);

void _init() {
  registerProperty(new PropertyTable(   
    symbol: #height,
    inherited: false,
    stringSetter: autoLengthPropertyStringSetter,
    stringGetter: autoLengthPropertyStringGetter,
    objectConstructor: (Symbol propertySymbol, StyleDeclaration declaration) =>
                         new AutoLengthProperty(propertySymbol, declaration)));
  registerProperty(new PropertyTable(   
    symbol: #width,
    inherited: false,
    stringSetter: autoLengthPropertyStringSetter,
    stringGetter: autoLengthPropertyStringGetter,
    objectConstructor: (Symbol propertySymbol, StyleDeclaration declaration) =>
                         new AutoLengthProperty(propertySymbol, declaration)));
  registerProperty(new PropertyTable(   
    symbol: #color,
    inherited: false,
    stringSetter: colorPropertyStringSetter,
    stringGetter: colorPropertyStringGetter,
    objectConstructor: (Symbol propertySymbol, StyleDeclaration declaration) =>
                         new ColorProperty(propertySymbol, declaration)));
  registerProperty(new PropertyTable(   
    symbol: #transform,
    inherited: false,
    stringSetter: transformPropertyStringSetter,
    stringGetter: transformPropertyStringGetter,
    objectConstructor: (Symbol propertySymbol, StyleDeclaration declaration) =>
                         new TransformProperty(propertySymbol, declaration)));
}
```

