Sky DOM APIs
============

```dart
// ELEMENT TREE API

abstract class ChildNode {
  @nonnull external TreeScope get ownerScope; // O(1)

  external ParentNode get parentNode; // O(1)
  external Element get parentElement; // O(1) // if parentNode isn't an element, returns null
  external ChildNode get previousSibling; // O(1)
  external ChildNode get nextSibling; // O(1)

  // the following all throw if parentNode is null
  external void insertBefore(@nonnull List</*@nonnull*/ ChildNode> nodes); // O(N) in number of arguments plus all their descendants
  external void insertAfter(@nonnull List</*@nonnull*/ ChildNode> nodes); // O(N) in number of arguments plus all their descendants
  external void replaceWith(@nonnull List</*@nonnull*/ ChildNode> nodes); // O(N) in number of descendants plus arguments plus all their descendants
  external void remove(); // O(N) in number of descendants

  // called when parentNode changes
  external void parentChangeCallback(ParentNode oldParent, ParentNode newParent, ChildNode previousSibling, ChildNode nextSibling); // O(N) in descendants
  // default implementation calls attached/detached
  void attachedCallback() { }
  void detachedCallback() { }

  external List<ContentElement> getDestinationInsertionPoints(); // O(N) in number of insertion points the node is in
  // returns the <content> elements to which this element was distributed
}

abstract class Node extends EventTarget {
  @override
  external List</*@nonnull*/ EventTarget> getEventDispatchChain(); // O(N) in number of ancestors across shadow trees
  // implements EventTarget.getEventDispatchChain()
  // returns the event dispatch chain (including handling shadow trees)

  external Node cloneNode({bool deep: false}); // O(1) if deep=false, O(N) in the number of descendants if deep=true

  external ElementStyleDeclarationList get style; // O(1)
  // for nodes that aren't reachable from the Application Document, returns null
  // (so in particular orphaned subtrees and nodes in module documents don't have one)
  //  -- should be updated when the node's parent chain changes (same time as, e.g.,
  //     the id hashtable is updated)
  // also always returns null for ContentElement elements and ShadowRoot nodes

  external RenderNode get renderNode; // O(1)
  // this will be null until the first time it is rendered
  // it becomes null again when it is taken out of the rendering (see style.md)

  Type getLayoutManager() => null; // O(1)

  void resetLayoutManager() { // O(1)
    if (renderNode != null) {
      renderNode._layoutManager = null;
      renderNode._needsManager = true;
    }
  }
}

abstract class ParentNode extends Node {
  external ChildNode get firstChild; // O(1)
  external ChildNode get lastChild; // O(1)

  // Returns a new List every time.
  external List</*nonnull*/ ChildNode> getChildNodes(); // O(N) in number of child nodes
  external List<Element> getChildElements(); // O(N) in number of child nodes
  // TODO(ianh): might not be necessary if we have the parser drop unnecessary whitespace text nodes

  external void append(@nonnull List</*nonnull*/ ChildNode> nodes); // O(N) in number of arguments plus all their descendants
  external void prepend(@nonnull List</*nonnull*/ ChildNode> nodes); // O(N) in number of arguments plus all their descendants
  external void replaceChildrenWith(@nonnull List</*nonnull*/ ChildNode> nodes); // O(N) in number of descendants plus arguments plus all their descendants
}

class Attr {
  const Attr (this.name, [this.value = '']); // O(1)
  final String name; // O(1)
  final String value; // O(1)
}

// @tagname annotation for registering elements
// only useful when placed on classes that inherit from Element
class tagname extends AutomaticMetadata {
  const tagname(this.name);
  @nonnull final String name;
  void init(DeclarationMirror target, Module module) {
    assert(target is ClassMirror);
    if (!target.isSubclassOf(reflectClass(Element)))
      throw Error('@tagname can only be used on descendants of Element');
    module.registerElement(name, (target as ClassMirror).reflectedType);
  }
}

abstract class FindRoot { }

abstract class Element extends ParentNode with ChildNode implements FindRoot {
  external Element({Map</*@nonnull*/ String, /*@nonnull*/ String> attributes: null,
                   List</*nonnull*/ ChildNode> nodes: null,
                   Module hostModule: null}); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  // initialises the internal attributes table
  // appends the given child nodes
  // if this.needsShadow, creates a shadow tree

  @nonnull String get tagName { // O(N) in number of annotations on the class
    // throws a StateError if the class doesn't have an @tagname annotation
    var tagnameClass = reflectClass(tagname);
    return (reflectClass(this.runtimeType).metadata.singleWhere((mirror) => mirror.type == tagnameClass).reflectee as tagname).value;
  }

  @nonnull external bool hasAttribute(@nonnull String name); // O(N) in number of attributes
  @nonnull external String getAttribute(@nonnull String name); // O(N) in number of attributes
  external void setAttribute(@nonnull String name, [@nonnull String value = '']); // O(N) in number of attributes
  external void removeAttribute(@nonnull String name); // O(N) in number of attributes

  // Returns a new Array and new Attr instances every time.
  @nonnull external List<Attr> getAttributes(); // O(N) in number of attributes

  get bool needsShadow => false; // O(1)
  external ShadowRoot get shadowRoot; // O(1)
  // returns the shadow root
  // TODO(ianh): Should this be mutable? It would help explain how it gets set...

  void endTagParsedCallback() { }
  void attributeChangeCallback(String name, String oldValue, String newValue) { }
  // name will never be null when this is called by sky

  // TODO(ianh): does a node ever need to know when it's been redistributed?

  @override
  Type getLayoutManager() { // O(1)
    if (renderNode)
      return renderNode.getProperty(phDisplay);
    return super.getLayoutManager();
  }
}

class Text extends Node with ChildNode {
  external Text([@nonnull String value = '']); // O(1)

  @nonnull external String get value; // O(1)
  external void set (@nonnull String value); // O(1)

  void valueChangeCallback(@nonnull String oldValue, @nonnull String newValue) { }

  @override
  Type getLayoutManager() => TextLayoutManager; // O(1)
}

class DocumentFragment extends ParentNode implements FindRoot {
  DocumentFragment([List</*nonnull*/ ChildNode> nodes = null]); // O(N) in number of arguments plus all their descendants
}

abstract class TreeScope extends ParentNode {
  external Document get ownerDocument; // O(1)
  external TreeScope get parentScope; // O(1)

  external Element findId(String id); // O(1)
  // throws if id is null
}

class ShadowRoot extends TreeScope implements FindRoot {
  ShadowRoot([this._host]); // O(1)
  // note that there is no way in the API to use a newly created ShadowRoot currently

  Element _host;
  Element get host => _host; // O(1)
}

class Document extends TreeScope implements FindRoot {
  external Document ([List</*@nonnull*/ ChildNode> nodes = null]); // O(N) in number of arguments plus all their descendants
}

class ApplicationDocument extends Document {
  external ApplicationDocument ([List</*@nonnull*/ ChildNode> nodes = null]); // O(N) in number of /nodes/ arguments plus all their descendants

  @override
  Type getLayoutManager() => rootLayoutManager; // O(1)
}

Type rootLayoutManager = BlockLayoutManager; // O(1)


// BUILT-IN ELEMENTS

@tagname('import')
class ImportElement extends Element {
  //XXX ImportElement = Element;

  @override
  Type getLayoutManager() => null; // O(1)
}

@tagname('template')
class TemplateElement extends Element {
  //XXX TemplateElement = Element;

  // TODO(ianh): convert <template> to using a token stream instead of a DocumentFragment

  @nonnull external DocumentFragment get content; // O(1)

  @override
  Type getLayoutManager() => null; // O(1)
}

@tagname('script')
class ScriptElement extends Element {
  //XXX ScriptElement = Element;

  @override
  Type getLayoutManager() => null; // O(1)
}

@tagname('style')
class StyleElement extends Element {
  //XXX StyleElement = Element;

  @nonnull external List</*@nonnull*/ Rule> getRules(); // O(N) in rules

  @override
  Type getLayoutManager() => null; // O(1)
}

@tagname('content')
class ContentElement extends Element {
  //XXX ContentElement = Element;

  @nonnull external List</*@nonnull*/ Node> getDistributedNodes(); // O(N) in distributed nodes

  @override
  Type getLayoutManager() => null; // O(1)
}

@tagname('img')
class ImgElement extends Element {
  //XXX ImgElement = Element;

  @override
  Type getLayoutManager() => ImgElementLayoutManager; // O(1)
}

@tagname('div')
class DivElement extends Element {
  //XXX DivElement = Element;
}

@tagname('span')
class SpanElement extends Element {
  //XXX SpanElement = Element;
}

@tagname('iframe')
class IframeElement extends Element {
  //XXX IframeElement = Element;

  @override
  Type getLayoutManager() => IframeElementLayoutManager; // O(1)
}

@tagname('t')
class TElement extends Element {
  //XXX TElement = Element;
}

@tagname('a')
class AElement extends Element {
  //XXX AElement = Element;
}

@tagname('title')
class TitleElement extends Element {
  //XXX TitleElement = Element;

  @override
  Type getLayoutManager() => null; // O(1)
}

class ErrorElement extends Element {
  ErrorElement._create();

  @override
  Type getLayoutManager() => ErrorElementLayoutManager; // O(1)
}

class SelectorQuery {
  external SelectorQuery(@nonnull String selector); // O(F()) where F() is the complexity of the selector

  @nonnull external bool matches(@nonnull Element element); // O(F())
  external Element find(@nonnull FindRoot root); // O(N*F())+O(M) where N is the number of descendants and M the average depth of the tree
  @nonnull external List</*@nonnull*/ Element> findAll(FindRoot root); // O(N*F())+O(N*M) where N is the number of descendants and M the average depth of the tree
}
```
