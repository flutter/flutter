Frameworks
----------

Sky is intended to support multiple frameworks. Here is one way you
could register a custom element using Dart annotations:

```dart
// @tagname annotation for registering elements
// only useful when placed on classes that inherit from Element
class tagname extends AutomaticMetadata {
  const tagname(this.name);
  final String name;
  void init(DeclarationMirror target, Module module, ScriptElement script) {
    assert(target is ClassMirror);
    if (!(target as ClassMirror).isSubclassOf(reflectClass(Element)))
      throw new UnsupportedError('@tagname can only be used on descendants of Element');
    module.registerElement(name, (target as ClassMirror).reflectedType);
  }
}
```

A framework that used the above code could use the following code to
get the tag name of an element:

```dart
String getTagName(Element element) { // O(N) in number of annotations on the class
  // throws a StateError if the class doesn't have an @tagname annotation
  var tagnameClass = reflectClass(tagname);
  return (reflectClass(element.runtimeType).metadata.singleWhere((mirror) => mirror.type == tagnameClass).reflectee as tagname).name;
}
```
