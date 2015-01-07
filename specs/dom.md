Sky DOM APIs
============

```javascript

// DOM

typedef ChildNode (Element or Text);
typedef ChildArgument (Element or Text or String);

abstract class Node : EventTarget { // implemented in C++
  readonly attribute TreeScope? ownerScope; // O(1)

  readonly attribute ParentNode? parentNode; // O(1)
  readonly attribute Element? parentElement; // O(1) // if parentNode isn't an element, returns null
  readonly attribute ChildNode? previousSibling; // O(1)
  readonly attribute ChildNode? nextSibling; // O(1)

  virtual Array<EventTarget> getEventDispatchChain(); // O(N) in number of ancestors across shadow trees // implements EventTarget.getEventDispatchChain()
    // returns the event dispatch chain (including handling shadow trees)

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

  readonly attribute ElementStyleDeclarationList? style; // O(1)
    // for nodes that aren't reachable from the Application Document, returns null
    // (so in particular orphaned subtrees and nodes in module documents don't have one)
    //  -- should be updated when the node's parent chain changes (same time as, e.g.,
    //     the id hashtable is updated)
    // also always returns null for ContentElement elements and ShadowRoot nodes
  readonly attribute RenderNode? renderNode; // O(1)
    // this will be null until the first time it is rendered
    // it becomes null again when it is taken out of the rendering (see style.md)
  abstract virtual LayoutManagerConstructor getLayoutManager(); // O(1)
  void resetLayoutManager(); // O(1)
    // if renderNode is non-null:
    //   sets renderNode.layoutManager to null
    //   sets renderNode.needsManager to true
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

  readonly attribute ShadowRoot? shadowRoot; // O(1) // returns the shadow root // TODO(ianh): Should this be mutable? It would help explain how it gets set...
  Array<ContentElement> getDestinationInsertionPoints(); // O(N) in number of insertion points the node is in

  virtual void endTagParsedCallback(); // noop
  virtual void attributeChangeCallback(String name, String? oldValue, String? newValue); // noop
  // TODO(ianh): does a node ever need to know when it's been redistributed?

  virtual LayoutManagerConstructor getLayoutManager(); // O(1)
    // default implementation looks up the 'display' property and returns the value:
    //   if (renderNode)
    //     return renderNode.getProperty(phDisplay);
    //   return null;
}

class Text : Node {
  constructor (String value = ''); // O(1)
  attribute String value; // O(1)

  void replaceWith(String node); // O(1) // special case override of Node.replaceWith()

  virtual void valueChangeCallback(String? oldValue, String? newValue); // noop

  virtual LayoutManagerConstructor getLayoutManager(); // O(1)
    // default implementation returns TextLayoutManager's constructor
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

  virtual LayoutManagerConstructor getLayoutManager(); // O(1)
    // returns sky.rootLayoutManager;
}

attribute LayoutManagerConstructor rootLayoutManager; // O(1)
  // initially configured to return BlockLayoutManager


// BUILT-IN ELEMENTS

class ImportElement : Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "import"
  constructor attribute Boolean shadow; // O(1) // false

  virtual LayoutManagerConstructor getLayoutManager(); // O(1)
    // returns null
}
class TemplateElement : Element {
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
class ScriptElement : Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "script"
  constructor attribute Boolean shadow; // O(1) // false

  virtual LayoutManagerConstructor getLayoutManager(); // O(1)
    // returns null
}
class StyleElement : Element {
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
class ContentElement : Element {
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
class ImgElement : Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "img"
  constructor attribute Boolean shadow; // O(1) // false

  virtual LayoutManagerConstructor getLayoutManager(); // O(1)
    // returns ImgElementLayoutManager
}
class DivElement : Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "div"
  constructor attribute Boolean shadow; // O(1) // false
}
class SpanElement : Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "span"
  constructor attribute Boolean shadow; // O(1) // false
}
class IframeElement : Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "iframe"
  constructor attribute Boolean shadow; // O(1) // false

  virtual LayoutManagerConstructor getLayoutManager(); // O(1)
    // returns IframeElementLayoutManager
}
class TElement : Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "t"
  constructor attribute Boolean shadow; // O(1) // false
}
class AElement : Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "a"
  constructor attribute Boolean shadow; // O(1) // false
}
class TitleElement : Element {
  constructor (Dictionary<String> attributes, ChildArguments... nodes); // O(M+N), M = number of attributes, N = number of nodes plus all their descendants
  constructor (ChildArguments... nodes); // shorthand
  constructor (Dictionary<String> attributes); // shorthand
  constructor (); // shorthand
  constructor attribute String tagName; // O(1) // "title"
  constructor attribute Boolean shadow; // O(1) // false

  virtual LayoutManagerConstructor getLayoutManager(); // O(1)
    // returns null
}
class ErrorElement : Element {
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
