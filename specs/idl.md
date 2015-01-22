Sky IDL
=======

The Sky IDL language is used to describe JS APIs found in Sky, in
particular, the JS APIs exposed by the four magical imports defined in
this document.

Sky IDL definitions are typically compiled to C++ that exposes the C++
implementations of the APIs to JavaScript.

Sky IDL works more or less the same as Web IDL but the syntax is a bit
different.

```javascript
module 'sky:modulename' {

  // this is a comment

  typedef NewType OldType; // useful when OldType is a commonly-used union

  callback CallbackName ReturnType (ArgumentType argumentName);

  class ClassName {
    // a class corresponds to a JavaScript prototype
    // corresponds to a WebIDL 'interface'
  }

  abstract class Superclass {
    // an abstract class can't have a non-abstract constructor
    // an abstract class may have abstract constructors and methods
    // an abstract class may have everything else a class can have

    abstract constructor ();
      // this indicates that non-abstract subclasses must have a constructor with the given arguments

    abstract ReturnType methodCallback();
      // this method does nothing, but is included to describe the interface that subclasses will implement
      // a non-abstract class must have an explicit implementation of all inherited abstract methods
    
  }

  class Subclass : Superclass {
    // properties
    readonly attribute ReturnType attributeName; // getter
    attribute ReturnType attributeName; // getter and setter

    // methods and constructors
    constructor ();
    ReturnType method();
      // When the platform calls this method, it always invokes the "real" method, even if it's been
      // deleted from the prototypes (as if it took a reference to the method at startup, and stored
      // state using Symbols)
      // Calling a method with fewer arguments than defined will throw.
      // Calling a method with more arguments ignores the extra arguments.
    virtual ReturnType methodCallback();
      // when the platform calls this, it actually calls it the way JS would, so author overrides do
      // affect what gets called. Make sure if you override it that you call the superclass implementation!
      // The default implementations of 'virtual' methods all end by calling the identically named method
      // on the superclass, if there is such a method.

    // non-abstract classes cannot have abstract constructors or methods, and in particular, must
    // have explicit non-abstract versions of any inherited abstract constructors or methods

    // properties on the constructor
    constructor readonly attribute ReturnType staticName;

    // private APIs - see below
    private void method();

    // arguments and overloading are done as follows
    // note that the argument names are only for documentation purposes
    ReturnType method(ArgumentType argumentName1, ArgumentType argumentName2);
    // the last argument's type can have "..." appended to it to indicate a varargs-like situation
    ReturnType method(ArgumentType argumentName1, ArgumentType... allSubsequentArguments);
    // trailing arguments can have a default value, which must be a literal of the given type
    ReturnType method(ArgumentType argumentName1, ArgumentType argumentName2 = defaultValue);
  }

  dictionary Options {
    String foo; // if there's no default, the property must be specified or it's a TypeError
    Integer bar = 4; // properties can have default values
  }

  // the module can have properties and methods also
  attribute String Foo;
  void method();

  interface InterfaceName {
    // describes a template of a prototype, in the same syntax as a class
    // not actually exposed in the runtime
  }

}
```

### Private APIs ###

Private APIs are only accessible via Symbol objects, which are then
exposed on the sky:debug module's exports object as the name of the
member given in the IDL.

For example, consider:

```javascript
class Foo {
  private void Bar();
}
```

In a script with a ``foo`` object of type ``Foo``, ``foo.Bar`` is
undefined. However, it can be obtained as follows:

```html
<import src="sky:debug" as="debug"/>
<!-- ... import whatever defines 'foo' ... -->
<script>
  foo[debug.Bar]
</script>
```

### Types ###

The following types are available:

* ``Integer`` - WebIDL ``long long``
* ``Float`` - WebIDL ``double``
* ``Infinity`` - singleton type with value ``Infinity``
* ``String`` - WebIDL ``USVString``
* ``Boolean`` - WebIDL ``boolean``
* ``Object`` - WebIDL ``object`` (``ClassName`` can be used as a literal for this type)
* ``ClassName`` - an instance of the class ClassName
* ``Class<ClassName>`` - a class ClassName or one of its subclasses (not an instance)
* ``DictionaryName`` - an instance of the dictionary DictionaryName
* ``Promise<Type>`` - WebIDL ``Promise<T>``
* ``Generator<Type>`` - An ECMAScript generator function that returns data of the given type
* ``Array<Type>`` - WebIDL ``sequence<T>``
* ``Dictionary<Type>`` - unordered set of name-value String-Type pairs with no duplicate names
* ``Type?`` - union of Type and the singleton type with value ``null`` (WebIDL nullable)
* ``(Type1 or Type2)`` - union of Type1 and Type2 (WebIDL union)
* ``any`` - union of all types (WebIDL ``any``)

Methods that return nothing (undefined, in JS) use the keyword "void"
instead of a type.


TODO(ianh): Define in detail how this actually works


Mojom IDL
---------

The Mojom IDL language is used to describe the APIs exposed over Mojo
pipes.

Mojom IDL definitions are typically compiled to wrappers in each
language, which are then used as imports.

TODO(ianh): Define in detail how this actually works
