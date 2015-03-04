Dart Utilities Used By dart:sky
===============================

The classes defined here are used internally by dart:sky but are
pretty generic.

```dart
class Pair<A, B> {
  const Pair(this.a, this.b);
  final A a;
  final B b;
  int get hashCode => a.hashCode ^ b.hashCode;
  bool operator==(other) => other is Pair<A, B> && a == other.a && b == other.b;
}

// MapOfWeakReferences can be implemented in C, using the C Dart API, apparently
class MapOfWeakReferences<Key, Value> {
  external operator[](Key key);
  external operator[]=(Key key, Value value);
  external bool containsKey(Key key);
}
```
