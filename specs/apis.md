APIS
====

The Sky core API
----------------

```
module 'sky:core' {

  // EVENTS

  interface Event {
    constructor (String type, Boolean bubbles, any data); // O(1)
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

  interface EventTarget {
    any dispatchEvent(Event event); // O(N) in total number of listeners for this type in the chain // returns Event.result
    void addEventListener(String type, EventListener listener); // O(1)
    void removeEventListener(String type, EventListener listener); // O(N) in event listeners with that type
  }

  interface CustomEventTarget {
    constructor (); // O(1)
    attribute EventTarget parentNode; // getter O(1), setter O(N) in height of tree, throws if this would make a loop

    // you can inherit from this to make your object into an event target
  }



  // DOM

  typedef ChildNode (Element or Text);
  typedef ChildArgument (Element or Text or String);

  abstract interface Node : EventTarget {
    readonly attribute TreeScope? ownerScope; // O(1)
    
    readonly attribute ParentNode? parentNode; // O(1)
    readonly attribute Element? parentElement; // O(1) // if parentNode isn't an element, returns null
    readonly attribute ChildNode? previousSibling; // O(1)
    readonly attribute ChildNode? nextSibling; // O(1)
    
    // the following all throw is parentNode is null
    void insertBefore(ChildArgument... nodes); // O(N) in number of arguments plus all their descendants
    void insertAfter(ChildArgument... nodes); // O(N) in number of arguments plus all their descendants
    void replaceWith(ChildArgument... nodes); // O(N) in number of descendants plus arguments plus all their descendants
    void remove(); // O(N) in number of descendants
    Node cloneNode(Boolean deep); // O(1) if deep=false, O(N) in the number of descendants if deep=true

    // called when parentNode changes
    virtual void parentChangeCallback(ParentNode? oldParent, ParentNode? newParent, ChildNode? previousSibling, ChildNode? nextSibling); // O(N) in descendants (calls attached/detached)
    virtual void attachedCallback(); // noop
    virtual void detachedCallback(); // noop
  }

  abstract interface ParentNode : Node {
    readonly attribute ChildNode? firstChild; // O(1)
    readonly attribute ChildNode? lastChild; // O(1)
    
    // Returns a new Array every time.
    Array<ChildNode> getChildNodes(); // O(N) in number of child nodes
    Array<Element> getChildElements(); // O(N) in number of child nodes // TODO(ianh): might not be necessary if we have the parser drop unnecessary whitespace text nodes

    void append(ChildArgument... nodes); // O(N) in number of arguments plus all their descendants
    void prepend(ChildArgument... nodes); // O(N) in number of arguments plus all their descendants
    void replaceChildrenWith(ChildArgument... nodes); // O(N) in number of descendants plus arguments plus all their descendants
    
    Element? findId(String id); // O(1)
  }

  interface Attr {
    constructor (String name, String value); // O(1)
    readonly attribute String name; // O(1)
    readonly attribute String value; // O(1)
  }

  interface Element : ParentNode {
    readonly attribute String tagName; // O(1)

    Boolean hasAttribute(String name); // O(N) in arguments
    String getAttribute(String name); // O(N) in arguments
    void setAttribute(String name, String value); // O(N) in arguments
    void removeAttribute(String name); // O(N) in arguments
    
    // Returns a new Array and new Attr instances every time.
    Array<Attr> getAttributes(); // O(N) in arguments

    readonly attribute ShadowRoot? shadowRoot; // O(1) // returns the youngest shadow root
    void addShadowRoot(ShadowRoot root); // O(N) in descendants of argument
    Array<ContentElement> getDestinationInsertionPoints(); // O(N) in number of insertion points the node is in

    virtual void attributeChangeCallback(String name, String? oldValue, String? newValue); // noop
    virtual void shadowRootChangeCallback(ShadowRoot root); // noop
    // TODO(ianh): does a node ever need to know when it's been redistributed?
  }
  Element createElement(String tagName, Dictionary attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  Element createElement(String tagName, Dictionary attributes); // shorthand
  Element createElement(String tagName, ChildArguments... nodes); // shorthand
  Element createElement(String tagName); // shorthand

  Object registerElement(String tagName, Object interfaceObject); // O(N) in number of outstanding elements with that tag name to be upgraded

  interface Text : Node {
    constructor (String value); // O(1)
    attribute String value; // O(1)

    void replaceWith(String node); // O(1) // special case override of Node.replaceWith()

    virtual void valueChangeCallback(String? oldValue, String? newValue); // noop
  }

  interface DocumentFragment : ParentNode {
    constructor (ChildArguments... nodes); // O(N) in number of arguments plus all their descendants
  }

  abstract interface TreeScope : ParentNode {
    readonly attribute Document? ownerDocument; // O(1)
    readonly attribute TreeScope? parentScope; // O(1)
  }

  interface ShadowRoot : TreeScope {
    constructor (ChildArguments... nodes); // O(N) in number of arguments plus all their descendants
    readonly attribute Element? host; // O(1)
    readonly attribute ShadowRoot? olderShadowRoot; // O(1)
    void removeShadowRoot(); // O(N) in descendants
  }

  interface Document : TreeScope {
    constructor (ChildArguments... nodes); // O(N) in number of arguments plus all their descendants
  }
  
  interface SelectorQuery {
    constructor (String selector); // O(F()) where F() is the complexity of the selector

    Boolean matches(Element element); // O(F())
    Element? find(ParentNode root); // O(N*F()) where N is the number of descendants
    Array<Element> findAll(ParentNode root); // O(N*F()) where N is the number of descendants
  }

  // Built-in Elements
  interface ImportElement : Element { }
  interface TemplateElement : Element {
    readonly attribute DocumentFragment content; // O(1)
  }
  interface ScriptElement : Element { }
  interface StyleElement : Element { }
  interface ContentElement : Element {
    Array<Node> getDistributedNodes(); // O(N) in distributed nodes
  }
  interface ShadowElement : Element {
    Array<Node> getDistributedNodes(); // O(N) in distributed nodes
  }
  interface ImgElement : Element { }
  interface IframeElement : Element { }
  interface TElement : Element { }
  interface AElement : Element { }
  interface TitleElement : Element { }



  // MODULES

  interface Module {
    constructor (Application application, Document document); // O(1)
    attribute any exports; // O(1) // defaults to the module's document
    readonly attribute Document document; // O(1) // the module's document
    readonly attribute Application application; // O(1)
  }

  interface Application {
    constructor (Document document); // O(1)
    attribute String title; // O(1)
    readonly attribute Document document; // O(1) // the application's document
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

```
module 'sky:modulename' {

  // this is a comment

  typedef NewType OldType; // useful when OldType is a commonly-used union

  interface InterfaceName {
    // an interface corresponds to a JavaScript prototype
  }

  abstract interface Superinterface {
    // an abstract interface can't have a constructor
    // in every other respect it is the same as a regular interface
  }

  interface Subinterface : Superinterface {
    // properties
    readonly attribute ReturnType attributeName; // getter
    attribute ReturnType attributeName; // getter and setter

    // methods and constructors
    constructor ();
    ReturnType method();
      // When the platform calls this method, it always invokes the "real" method, even if it's been
      // deleted from the prototypes (as if it took a reference to the method at startup, and stored
      // state using Symbols)
    virtual ReturnType methodCallback();
      // when the platform calls this, it actually calls it the way JS would, so author overrides do
      // affect what gets called. Make sure if you override it that you call the superclass implementation!
      // The default implementations of 'virtual' methods all end by calling the identically named method
      // on the superclass, if there is such a method.

    // arguments and overloading are done as follows
    // note that the argument names are only for documentation purposes
    ReturnType method(ArgumentType argumentName1, ArgumentType argumentName2);
    // the last argument's type can have "..." appended to it to indicate a varargs-like situation
    ReturnType method(ArgumentType argumentName1, ArgumentType... allSubsequentArguments);
  }

  // the module can have properties and methods also
  attribute String Foo;
  void method();

}
```

The following types are available:

* ```Integer``` - WebIDL ```long long```
* ```Float``` - WebIDL ```double```
* ```String``` - WebIDL ```USVString```
* ```Boolean``` - WebIDL ```boolean```
# ```Object``` - WebIDL ```object```
* ```InterfaceName``` - an instance of the interface InterfaceName
* ```Promise<Type>``` - WebIDL ```Promise<T>```
* ```Array<Type>``` - WebIDL ```sequence<T>```
* ```Dictionary``` - unordered set of name-value String-String pairs with no duplicate names
* ```Type?``` - union of Type and the singleton type with value "null" (WebIDL nullable)
* ```(Type1 or Type2)``` - union of Type1 and Type2 (WebIDL union)
* ```any``` - union of all types (WebIDL ```any```)

Methods that return nothing (undefined, in JS) use the keyword "void"
instead of a type.

TODO(ianh): Figure out what should happen with omitted and extraneous parameters

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
```
global object = {} // with Math, RegExp, etc

magical imports:
  the core mojo fabric JS API   sky:mojo:fabric:core
  the asyncWait/cancelWait mojo fabric JS API (interface to IPC thread)  sky:mojo:fabric:ipc
  the mojom for the shell, proxying through C++ so that the shell pipe isn't exposed  sky:mojo:shell
  the sky API  sky:core
```

TODO(ianh): determine if we want to separate the "this" from the
Document, especially for Modules, so that exposing a module's element
doesn't expose the module's exports attribute.
