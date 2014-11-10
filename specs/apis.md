APIs
====

The Sky core API
----------------

```javascript
module 'sky:core' {

  // EVENTS

  class Event {
    constructor (String type, Boolean bubbles = true, any data = null); // O(1)
    readonly attribute String type; // O(1)
    readonly attribute Boolean bubbles; // O(1)
    attribute any data; // O(1)

    readonly attribute EventTarget target; // O(1)
    void preventDefault(); // O(1)
    attribute any result; // O(1) // defaults to undefined

    // TODO(ianh): do events get blocked at scope boundaries, e.g. focus events when both sides are in the scope?
    // TODO(ianh): do events ger retargetted, e.g. focus when leaving a custom element?
  }

  callback EventListener any (Event event); // return value is assigned to Event.result

  abstract class EventTarget {
    any dispatchEvent(Event event); // O(N) in total number of listeners for this type in the chain // returns Event.result
    void addEventListener(String type, EventListener listener); // O(1)
    void removeEventListener(String type, EventListener listener); // O(N) in event listeners with that type
    private Array<String> getRegisteredEventListenerTypes(); // O(N)
    private Array<EventListener> getRegisteredEventListenersForType(String type); // O(N)
  }

  class CustomEventTarget : EventTarget {
    constructor (); // O(1)
    attribute EventTarget parentNode; // getter O(1), setter O(N) in height of tree, throws if this would make a loop

    // you can inherit from this to make your object into an event target
  }



  // DOM

  typedef ChildNode (Element or Text);
  typedef ChildArgument (Element or Text or String);

  abstract class Node : EventTarget {
    readonly attribute TreeScope? ownerScope; // O(1)
    
    readonly attribute ParentNode? parentNode; // O(1)
    readonly attribute Element? parentElement; // O(1) // if parentNode isn't an element, returns null
    readonly attribute ChildNode? previousSibling; // O(1)
    readonly attribute ChildNode? nextSibling; // O(1)
    
    // the following all throw if parentNode is null
    void insertBefore(ChildArgument... nodes); // O(N) in number of arguments plus all their descendants
    void insertAfter(ChildArgument... nodes); // O(N) in number of arguments plus all their descendants
    void replaceWith(ChildArgument... nodes); // O(N) in number of descendants plus arguments plus all their descendants
    void remove(); // O(N) in number of descendants
    Node cloneNode(Boolean deep = false); // O(1) if deep=false, O(N) in the number of descendants if deep=true

    // called when parentNode changes
    virtual void parentChangeCallback(ParentNode? oldParent, ParentNode? newParent, ChildNode? previousSibling, ChildNode? nextSibling); // O(N) in descendants (calls attached/detached)
    virtual void attachedCallback(); // noop
    virtual void detachedCallback(); // noop
  }

  abstract class ParentNode : Node {
    readonly attribute ChildNode? firstChild; // O(1)
    readonly attribute ChildNode? lastChild; // O(1)
    
    // Returns a new Array every time.
    Array<ChildNode> getChildNodes(); // O(N) in number of child nodes
    Array<Element> getChildElements(); // O(N) in number of child nodes // TODO(ianh): might not be necessary if we have the parser drop unnecessary whitespace text nodes

    void append(ChildArgument... nodes); // O(N) in number of arguments plus all their descendants
    void prepend(ChildArgument... nodes); // O(N) in number of arguments plus all their descendants
    void replaceChildrenWith(ChildArgument... nodes); // O(N) in number of descendants plus arguments plus all their descendants
  }

  class Attr {
    constructor (String name, String value = ''); // O(1)
    readonly attribute String name; // O(1)
    readonly attribute String value; // O(1)
  }

  abstract class Element : ParentNode {
    readonly attribute String tagName; // O(1)

    Boolean hasAttribute(String name); // O(N) in number of attributes
    String getAttribute(String name); // O(N) in number of attributes
    void setAttribute(String name, String value = ''); // O(N) in number of attributes
    void removeAttribute(String name); // O(N) in number of attributes
    
    // Returns a new Array and new Attr instances every time.
    Array<Attr> getAttributes(); // O(N) in number of attributes

    readonly attribute ShadowRoot? shadowRoot; // O(1) // returns the shadow root
    Array<ContentElement> getDestinationInsertionPoints(); // O(N) in number of insertion points the node is in

    virtual void endTagParsedCallback(); // noop
    virtual void attributeChangeCallback(String name, String? oldValue, String? newValue); // noop
    // TODO(ianh): does a node ever need to know when it's been redistributed?
  }

  class Text : Node {
    constructor (String value = ''); // O(1)
    attribute String value; // O(1)

    void replaceWith(String node); // O(1) // special case override of Node.replaceWith()

    virtual void valueChangeCallback(String? oldValue, String? newValue); // noop
  }

  class DocumentFragment : ParentNode {
    constructor (ChildArguments... nodes); // O(N) in number of arguments plus all their descendants
  }

  abstract class TreeScope : ParentNode {
    readonly attribute Document? ownerDocument; // O(1)
    readonly attribute TreeScope? parentScope; // O(1)

    Element? findId(String id); // O(1)
  }

  class ShadowRoot : TreeScope {
    constructor (Element host); // O(1) // note that there is no way in the API to use a newly created ShadowRoot
    readonly attribute Element host; // O(1)
  }

  class Document : TreeScope {
    constructor (ChildArguments... nodes); // O(N) in number of arguments plus all their descendants
  }
  
  class SelectorQuery {
    constructor (String selector); // O(F()) where F() is the complexity of the selector

    Boolean matches(Element element); // O(F())
    Element? find(Element root); // O(N*F())+O(M) where N is the number of descendants and M the average depth of the tree
    Element? find(DocumentFragment root); // O(N*F())+O(M) where N is the number of descendants and M the average depth of the tree
    Element? find(TreeScope root); // O(N*F()) where N is the number of descendants
    Array<Element> findAll(Element root); // O(N*F())+O(N*M) where N is the number of descendants and M the average depth of the tree
    Array<Element> findAll(DocumentFragment root); // O(N*F())+O(N*M) where N is the number of descendants and M the average depth of the tree
    Array<Element> findAll(TreeScope root); // O(N*F()) where N is the number of descendants
  }


  // BUILT-IN ELEMENTS

  class ImportElement : Element {
    constructor (Dictionary attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
    constructor (ChildArguments... nodes); // shorthand
    constructor (Dictionary attributes); // shorthand
    constructor (); // shorthand
    constructor attribute String tagName; // O(1) // "import"
    constructor attribute Boolean shadow; // O(1) // false
  }
  class TemplateElement : Element {
    constructor (Dictionary attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
    constructor (ChildArguments... nodes); // shorthand
    constructor (Dictionary attributes); // shorthand
    constructor (); // shorthand
    constructor attribute String tagName; // O(1) // "template"
    constructor attribute Boolean shadow; // O(1) // false

    readonly attribute DocumentFragment content; // O(1)
  }
  class ScriptElement : Element {
    constructor (Dictionary attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
    constructor (ChildArguments... nodes); // shorthand
    constructor (Dictionary attributes); // shorthand
    constructor (); // shorthand
    constructor attribute String tagName; // O(1) // "script"
    constructor attribute Boolean shadow; // O(1) // false
  }
  class StyleElement : Element {
    constructor (Dictionary attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
    constructor (ChildArguments... nodes); // shorthand
    constructor (Dictionary attributes); // shorthand
    constructor (); // shorthand
    constructor attribute String tagName; // O(1) // "style"
    constructor attribute Boolean shadow; // O(1) // false
  }
  class ContentElement : Element {
    constructor (Dictionary attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
    constructor (ChildArguments... nodes); // shorthand
    constructor (Dictionary attributes); // shorthand
    constructor (); // shorthand
    constructor attribute String tagName; // O(1) // "content"
    constructor attribute Boolean shadow; // O(1) // false

    Array<Node> getDistributedNodes(); // O(N) in distributed nodes
  }
  class ImgElement : Element {
    constructor (Dictionary attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
    constructor (ChildArguments... nodes); // shorthand
    constructor (Dictionary attributes); // shorthand
    constructor (); // shorthand
    constructor attribute String tagName; // O(1) // "img"
    constructor attribute Boolean shadow; // O(1) // false
  }
  class DivElement : Element {
    constructor (Dictionary attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
    constructor (ChildArguments... nodes); // shorthand
    constructor (Dictionary attributes); // shorthand
    constructor (); // shorthand
    constructor attribute String tagName; // O(1) // "div"
    constructor attribute Boolean shadow; // O(1) // false
  }
  class SpanElement : Element {
    constructor (Dictionary attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
    constructor (ChildArguments... nodes); // shorthand
    constructor (Dictionary attributes); // shorthand
    constructor (); // shorthand
    constructor attribute String tagName; // O(1) // "span"
    constructor attribute Boolean shadow; // O(1) // false
  }
  class IframeElement : Element {
    constructor (Dictionary attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
    constructor (ChildArguments... nodes); // shorthand
    constructor (Dictionary attributes); // shorthand
    constructor (); // shorthand
    constructor attribute String tagName; // O(1) // "iframe"
    constructor attribute Boolean shadow; // O(1) // false
  }
  class TElement : Element {
    constructor (Dictionary attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
    constructor (ChildArguments... nodes); // shorthand
    constructor (Dictionary attributes); // shorthand
    constructor (); // shorthand
    constructor attribute String tagName; // O(1) // "t"
    constructor attribute Boolean shadow; // O(1) // false
  }
  class AElement : Element {
    constructor (Dictionary attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
    constructor (ChildArguments... nodes); // shorthand
    constructor (Dictionary attributes); // shorthand
    constructor (); // shorthand
    constructor attribute String tagName; // O(1) // "a"
    constructor attribute Boolean shadow; // O(1) // false
  }
  class TitleElement : Element {
    constructor (Dictionary attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
    constructor (ChildArguments... nodes); // shorthand
    constructor (Dictionary attributes); // shorthand
    constructor (); // shorthand
    constructor attribute String tagName; // O(1) // "title"
    constructor attribute Boolean shadow; // O(1) // false
  }
  class ErrorElement : Element {
    constructor (Dictionary attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
    constructor (ChildArguments... nodes); // shorthand
    constructor (Dictionary attributes); // shorthand
    constructor (); // shorthand
    constructor attribute String tagName; // O(1) // "error"
    constructor attribute Boolean shadow; // O(1) // false
  }



  // MODULES

  callback InternalElementConstructor void (Module module);
  dictionary ElementRegistration {
    String tagName;
    Boolean shadow = false;
    InternalElementConstructor? constructor = null;
  }

  interface ElementConstructor {
    constructor (Dictionary attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
    constructor (ChildArguments... nodes); // shorthand
    constructor (Dictionary attributes); // shorthand
    constructor (); // shorthand

    constructor attribute String tagName;
    constructor attribute Boolean shadow;
  }

  abstract class AbstractModule : EventTarget {
    readonly attribute Document document; // O(1) // the Documentof the module or application
    Promise<any> import(String url); // O(Yikes) // returns the module's exports

    readonly attribute String url;

    ElementConstructor registerElement(ElementRegistration options); // O(1)
    // if you call registerElement() with an object that was created by
    // registerElement(), it just returns the object after registering it,
    // rather than creating a new constructor
    // otherwise, it proceeds as follows:
    //  1. let constructor be the constructor passed in, if any
    //  2. let prototype be the constructor's prototype; if there is no
    //     constructor, let prototype be Element
    //  3. create a new Function that:
    //      1. throws if not called as a constructor
    //      2. creates an actual Element object
    //      3. initialises the shadow tree if shadow on the options is true
    //      4. calls constructor, if it's not null, with the module as the argument
    //  4. let that new Function's prototype be the aforementioned prototype
    //  5. let that new Function have tagName and shadow properties set to
    //     the values passed in on options
    //  6. register the new element

    readonly attribute ScriptElement? currentScript; // O(1) // returns the <script> element currently being executed if any, and if it's in this module; else null
  }

  class Module : AbstractModule {
    constructor (Application application, Document document, String url); // O(1)
    readonly attribute Application application; // O(1)

    attribute any exports; // O(1) // defaults to the module's document
  }

  class Application : AbstractModule {
    constructor (Document document, String url); // O(1)
    attribute String title; // O(1)
  }

  // see script.md for a description of the global object, though note that
  // the sky core module doesn't use it or affect it in any way.

}
```

TODO(ianh): event loop

TODO(ianh): define the DOM APIs listed above, including firing the
change callbacks

TODO(ianh): schedule microtask, schedule task, requestAnimationFrame,
custom element callbacks...



Appendices
==========

Sky IDL
-------

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
    // an abstract class can't have a constructor
    // in every other respect it is the same as a regular class
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
* ``String`` - WebIDL ``USVString``
* ``Boolean`` - WebIDL ``boolean``
# ``Object`` - WebIDL ``object`` (``ClassName`` can be used as a literal for this type)
* ``ClassName`` - an instance of the class ClassName
* ``DictionaryName`` - an instance of the dictionary DictionaryName
* ``Promise<Type>`` - WebIDL ``Promise<T>``
* ``Array<Type>`` - WebIDL ``sequence<T>``
* ``Dictionary`` - unordered set of name-value String-String pairs with no duplicate names
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


Notes
-----
```javascript
global object = {} // with Math, RegExp, etc

magical imports:
  the core mojo fabric JS API   sky:mojo:fabric:core
  the asyncWait/cancelWait mojo fabric JS API (interface to IPC thread)  sky:mojo:fabric:ipc
  the mojom for the shell, proxying through C++ so that the shell pipe isn't exposed  sky:mojo:shell
  the sky API  sky:core
  the sky debug symbols for private APIs  sky:debug
```

TODO(ianh): determine if we want to separate the "this" from the
Document, especially for Modules, so that exposing a module's element
doesn't expose the module's exports attribute.
