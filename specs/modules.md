Sky Module System
=================

This document describes the Sky module system.

Overview
--------

The Sky module system is based on the ``import`` element. In its
most basic form, you import a module as follows:

```html
<import src="path/to/module.sky" />
```

As these ``import`` elements are inserted into a module's element
tree, the module's list of outstanding dependencies grows. When an
imported module completes, it is removed from the importing module's
list of outstanding dependencies.

Before compiling script or inserting an element that is not already
registered, the parser waits until the list of outstanding
dependencies is empty. After the parser has finished parsing, the
module waits until its list of outstanding dependencies is empty
before marking itself complete.

The ``as`` attribute on the ``import`` element binds a name to the
imported module:

```html
<import src="path/to/chocolate.sky" as="chocolate" />
```


Module API
----------

Each module consists of one or more libraries. The first library in a
module is the *element tree library*, which imports the dart:sky
module and then consists of the following code for a Sky module:

```dart
final Module module = new Module();
```

...and the following code for a Sky application:

```dart
final Module module = new Application();
```

The ``<script>`` elements found in the module's element tree create
the subsequent libraries. Each one first imports the ``dart:mirror``
library, then the ``dart:sky`` module, then the first library
described above, then all the modules referenced by ``<import>``
element up to that ``<script>`` element and all the libraries defined
by ``<script>`` elements up to that point, interleaved so as to
maintain the same relative order as those elements were first seen by
the parser.

When a library imports a module, it actually imports all the libraries
that were declared by that module except the aforementioned element
tree library. If the ``as`` attribute is present on the ``import``
element, all the libraries are bound to the same name.

At the end of the ``<script>`` block's source, if it parsed correctly
and completely, the conceptual equivalent of the following code is
appended (but without affecting the library's list of declarations and
without any possibility of it clashing with identifiers described in
the library itself):

```dart
class _ { }
void main(ScriptElement script) {
  LibraryMirror library = reflectClass(_).owner as LibraryMirror;
  if (library.declarations.containsKey(#_init) && library.declarations[#_init] is MethodMirror)
    _init(script);
  AutomaticMetadata.runLibrary(library, module, script);
}
```

Then, that ``main(script)`` function is called, with ``script`` set to
the ``ScriptElement`` object representing the relevant ``<script>``
element.

TODO(ianh): decide what URL and name we should give the libraries, as
exposed in MirrorSystem.getName(libraryMirror.qualifiedName) etc

The ``Module`` class is defined in ``dart:sky`` as follows:

```dart
abstract class AbstractModule extends EventTarget {
  AbstractModule({this.url, this.elements});

  final String url;

  final Root elements; // O(1)
  // the Root node of the module or application's element tree

  external Future<Module> import(String url); // O(Yikes)
  // load and return the URL at the given Module
  // if it's already loaded, the future will resolve immediately
  // if loading fails, the future will have an error

  external List<Module> getImports(); // O(N)
  // returns the Module objects of all the imported modules

  external void registerElement(String tagname, Type elementClass); // O(1)
  // registers a tag name with the parser
  // only useful during parse time
  // verify that tagname isn't null or empty
  // verify that elementClass is the Type of a class that extends Element (directly or indirectly, but not via "implements" or "with")
  // (see the @tagname code for an example of how to verify that from dart)
  // verify that there's not already a class registered for this tag name
  // if there is, then mark this tagname is broken, so that it acts as if it's not registered in the parser,
  // and, if this is the first time it was marked broken, log a console message regarding the issue
  // (mention the tag name but not the classes, so that it's not observable that this currently happens out of order)
}

class Module extends AbstractModule {
  Module({String url, Root elements, this.application}) :
    super(url: url, elements: elements); // O(1)
  final Application application; // O(1)
}

class Application extends AbstractModule {
  Application({String url, Root elements, this.gestureManager}) :
    super(url: url, elements: elements); // O(1)
  external String get title; // O(1)
  external void set title(String newValue); // O(1)
  final GestureManager gestureManager;
}
```
