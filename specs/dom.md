Sky DOM APIs
============

```dart
abstract class ChildNode { }

abstract class Node extends EventTarget {
  external TreeScope get ownerScope; // O(1) // never null

  external ParentNode get parentNode; // O(1)
  external Element get parentElement; // O(1) // if parentNode isn't an element, returns null
  external ChildNode get previousSibling; // O(1)
  external ChildNode get nextSibling; // O(1)

  @override
  external List</*@nonnull*/ EventTarget> getEventDispatchChain(); // O(N) in number of ancestors across shadow trees
  // implements EventTarget.getEventDispatchChain()
  // returns the event dispatch chain (including handling shadow trees)

  // the following all throw if parentNode is null
  external void insertBefore(List</*@nonnull*/ ChildNode> nodes); // O(N) in number of arguments plus all their descendants
  external void insertAfter(List</*@nonnull*/ ChildNode> nodes); // O(N) in number of arguments plus all their descendants
  external void replaceWith(List</*@nonnull*/ ChildNode> nodes); // O(N) in number of descendants plus arguments plus all their descendants
  external void remove(); // O(N) in number of descendants
  external Node cloneNode({bool deep: false}); // O(1) if deep=false, O(N) in the number of descendants if deep=true

  // called when parentNode changes
  external void parentChangeCallback(ParentNode oldParent, ParentNode newParent, ChildNode previousSibling, ChildNode nextSibling); // O(N) in descendants
  // default implementation calls attached/detached
  void attachedCallback() { }
  void detachedCallback() { }

  external List<ContentElement> getDestinationInsertionPoints(); // O(N) in number of insertion points the node is in
  // returns the <content> elements to which this element was distributed

  external ElementStyleDeclarationList get style; // O(1)
  // for nodes that aren't reachable from the Application Document, returns null
  // (so in particular orphaned subtrees and nodes in module documents don't have one)
  //  -- should be updated when the node's parent chain changes (same time as, e.g.,
  //     the id hashtable is updated)
  // also always returns null for ContentElement elements and ShadowRoot nodes

  external RenderNode get renderNode; // O(1)
  // this will be null until the first time it is rendered
  // it becomes null again when it is taken out of the rendering (see style.md)

  LayoutManagerConstructor getLayoutManager(); // O(1)

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
  external List<ChildNode> getChildNodes(); // O(N) in number of child nodes
  external List<Element> getChildElements(); // O(N) in number of child nodes
  // TODO(ianh): might not be necessary if we have the parser drop unnecessary whitespace text nodes

  external void append(List<ChildNode> nodes); // O(N) in number of arguments plus all their descendants
  external void prepend(List<ChildNode> nodes); // O(N) in number of arguments plus all their descendants
  external void replaceChildrenWith(List<ChildNode> nodes); // O(N) in number of descendants plus arguments plus all their descendants
}

class Attr {
  const Attr (this.name, [this.value = '']); // O(1)
  final String name; // O(1)
  final String value; // O(1)
}

abstract class Element extends ParentNode {
  final String tagName; // O(1)

  external bool hasAttribute(@nonnull String name); // O(N) in number of attributes
  external String getAttribute(@nonnull String name); // O(N) in number of attributes
  external void setAttribute(@nonnull String name, [@nonnull String value = '']); // O(N) in number of attributes
  external void removeAttribute(@nonnull String name); // O(N) in number of attributes

  // Returns a new Array and new Attr instances every time.
  List<Attr> getAttributes(); // O(N) in number of attributes

  external ShadowRoot get shadowRoot; // O(1)
  // returns the shadow root
  // TODO(ianh): Should this be mutable? It would help explain how it gets set...

  void endTagParsedCallback() { }
  void attributeChangeCallback(String name, String oldValue, String newValue) { }
  // name will never be null when this is called by sky

  // TODO(ianh): does a node ever need to know when it's been redistributed?

  @override
  LayoutManagerConstructor getLayoutManager() { // O(1)
    if (renderNode)
      return renderNode.getProperty(phDisplay);
    return super.getLayoutManager();
  }
}

class Text extends Node {
  external Text([String value = '']); // O(1)
  // throws if value is null

  external String get value; // O(1)

  void valueChangeCallback(String oldValue, String newValue) { }

  @override
  LayoutManagerConstructor getLayoutManager() { // O(1)
    return TextLayoutManager;
  }
}

class DocumentFragment extends ParentNode {
  DocumentFragment([List<ChildNode> nodes = null]); // O(N) in number of arguments plus all their descendants
}

abstract class TreeScope extends ParentNode {
  external Document get ownerDocument; // O(1)
  external TreeScope get parentScope; // O(1)

  external Element findId(String id); // O(1)
  // throws if id is null
}

class ShadowRoot extends TreeScope {
  ShadowRoot([this._host]); // O(1)
  // note that there is no way in the API to use a newly created ShadowRoot currently

  Element _host;
  Element get host => _host; // O(1)
}

// DARTIFICATION INCOMPLETE PAST THIS POINT

class Document extends TreeScope {
  constructor (ChildArguments... nodes); // O(N) in number of arguments plus all their descendants
}

class ApplicationDocument extends Document {
  constructor (ChildArguments... nodes); // O(N) in number of /nodes/ arguments plus all their descendants

  virtual LayoutManagerConstructor getLayoutManager(); // O(1)
    // returns sky.rootLayoutManager;
}

attribute LayoutManagerConstructor rootLayoutManager; // O(1)
  // initially configured to return BlockLayoutManager


// BUILT-IN ELEMENTS

class ImportElement extends Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "import"
  constructor attribute Boolean shadow; // O(1) // false

  virtual LayoutManagerConstructor getLayoutManager(); // O(1)
    // returns null
}
class TemplateElement extends Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "template"
  constructor attribute Boolean shadow; // O(1) // false

  readonly attribute DocumentFragment content; // O(1)
  virtual LayoutManagerConstructor getLayoutManager(); // O(1)
    // returns null
}
class ScriptElement extends Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "script"
  constructor attribute Boolean shadow; // O(1) // false

  virtual LayoutManagerConstructor getLayoutManager(); // O(1)
    // returns null
}
class StyleElement extends Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "style"
  constructor attribute Boolean shadow; // O(1) // false

  Array<Rule> getRules(); // O(N) in rules
  virtual LayoutManagerConstructor getLayoutManager(); // O(1)
    // returns null
}
class ContentElement extends Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "content"
  constructor attribute Boolean shadow; // O(1) // false

  Array<Node> getDistributedNodes(); // O(N) in distributed nodes
  virtual LayoutManagerConstructor getLayoutManager(); // O(1)
    // returns null
}
class ImgElement extends Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "img"
  constructor attribute Boolean shadow; // O(1) // false

  virtual LayoutManagerConstructor getLayoutManager(); // O(1)
    // returns ImgElementLayoutManager
}
class DivElement extends Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "div"
  constructor attribute Boolean shadow; // O(1) // false
}
class SpanElement extends Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "span"
  constructor attribute Boolean shadow; // O(1) // false
}
class IframeElement extends Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "iframe"
  constructor attribute Boolean shadow; // O(1) // false

  virtual LayoutManagerConstructor getLayoutManager(); // O(1)
    // returns IframeElementLayoutManager
}
class TElement extends Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "t"
  constructor attribute Boolean shadow; // O(1) // false
}
class AElement extends Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "a"
  constructor attribute Boolean shadow; // O(1) // false
}
class TitleElement extends Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "title"
  constructor attribute Boolean shadow; // O(1) // false

  virtual LayoutManagerConstructor getLayoutManager(); // O(1)
    // returns null
}
class ErrorElement extends Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "error"
  constructor attribute Boolean shadow; // O(1) // false

  virtual LayoutManagerConstructor getLayoutManager(); // O(1)
    // returns ErrorElementLayoutManager
}

interface ElementConstructor {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand

  constructor attribute String tagName;
  constructor attribute Boolean shadow;
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
```
