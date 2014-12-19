Sky Style Language
==================

Planed changes
--------------

Add //-to-end-of-line comments to be consistent with the script
language.


Style Parser
------------

(this section is incomplete)

### Tokenisation


#### Value parser


##### **Value** state

If the current character is...

* '``;``': Consume the character and exit the value parser
  successfully.

* '``@``': Consume the character and switch to the **at**
  state.

* '``#``': Consume the character and switch to the **hash**
  state.

* '``$``': Consume the character and switch to the **dollar**
  state.

* '``%``': Consume the character and switch to the **percent**
  state.

* '``&``': Consume the character and switch to the **ampersand**
  state.

* '``'``': Set _value_ to the empty string, consume the character, and
  switch to the **single-quoted string** state.

* '``"``': Set _value_ to the empty string, consume the character, and
  switch to the **double-quoted string** state.

* '``-``': Consume the character, and switch to the **negative
  integer** state.

* '``0``'-'``9``': Set _value_ to the decimal value of the current
  character, consume the character, and switch to the **integer**
  state.

* '``a``'-'``z``', '``A``'-'``Z``': Set _value_ to the current
  character, consume the character, and switch to the **identifier**
  state.

* '``*``', '``^``', '``!``', '``?``', '``,``', '``/``', '``<``',
  '``[``', '``)``', '``>``', '``]``', '``+``': Emit a symbol token
  with the current character as the symbol, consume the character, and
  stay in this state.

* Anything else: Consume the character and switch to the **error**
  state.


##### **At** state

* '``0``'-'``9``', '``a``'-'``z``', '``A``'-'``Z``': Set _value_ to
  the current character, create a literal token with the unit set to
  ``@``, consume the character, and switch to the **literal** state.

* Anything else: Emit a symbol token with ``@`` as the symbol, and
  switch to the **value** state without consuming the character.


##### **Hash** state

* '``0``'-'``9``', '``a``'-'``z``', '``A``'-'``Z``': Set _value_ to
  the current character, create a literal token with the unit set to
  ``@``, consume the character, and switch to the **literal** state.

* Anything else: Emit a symbol token with ``#`` as the symbol, and
  switch to the **value** state without consuming the character.


##### **Dollar** state

* '``0``'-'``9``', '``a``'-'``z``', '``A``'-'``Z``': Set _value_ to
  the current character, create a literal token with the unit set to
  ``@``, consume the character, and switch to the **literal** state.

* Anything else: Emit a symbol token with ``$`` as the symbol, and
  switch to the **value** state without consuming the character.


##### **Percent** state

* '``0``'-'``9``', '``a``'-'``z``', '``A``'-'``Z``': Set _value_ to
  the current character, create a literal token with the unit set to
  ``@``, consume the character, and switch to the **literal** state.

* Anything else: Emit a symbol token with ``%`` as the symbol, and
  switch to the **value** state without consuming the character.


##### **Ampersand** state

* '``0``'-'``9``', '``a``'-'``z``', '``A``'-'``Z``': Set _value_ to
  the current character, create a literal token with the unit set to
  ``@``, consume the character, and switch to the **literal** state.

* Anything else: Emit a symbol token with ``&`` as the symbol, and
  switch to the **value** state without consuming the character.


##### TODO(ianh): more states...


##### **Error** state

If the current character is...

* '``;``': Consume the character and exit the value parser in failure.

* Anything else: Consume the character and stay in this state.



Selectors
---------

Sky Style uses whatever SelectorQuery. Maybe one day we'll make
SelectorQuery support being extended to support arbitrary selectors,
but for now, it supports:

```css
tagname
#id
.class
[attrname]
[attrname=value]
:host                  ("host" string is fixed)
::pseudo-element
```

These can be combined (without whitespace), with at most one tagname
(must be first) and at most one pseudo-element (must be last) as in:

```css
tagname[attrname]#id:host.class.class[attrname=value]::foo
```

In debug mode, giving two IDs, or the same selector twice (e.g. the
same classname), or specifying other redundant or conflicting
selectors (e.g. [foo][foo=bar], or [foo=bar][foo=baz]) will be
flagged.

Alternatively, a selector can be the special value "@document",
optionally followed by a pseudo-element, as in:

```css
@document::bar
```


Value Parser
------------

```javascript
class StyleToken {
  constructor (String king, String value);
  readonly attribute String kind;
     // string
     // identifier
     // function (identifier + '(')
     // number
     // symbol (one of @#$%& if not immediately following numeric or preceding alphanumeric, or one of *^!?,/<[)>]+ or, if not followed by a digit, -)
     // dimension (number + identifier or number + one of @#$%&)
     // literal (one of @#$%& + alphanumeric)
  readonly attribute String value;
  readonly attribute String unit; // for 'dimension' type, this is the punctuation or identifier that follows the number, for 'literal' type, this is the punctuation that precedes it
}

class TokenSource {
  constructor (Array<StyleToken> tokens);
  IteratorResult next();
  TokenSourceBookmark getBookmark();
  void rewind(TokenSourceBookmark bookmark);
}

class TokenSourceBookmark {
  constructor ();
  // TokenSource stores unforgeable state on this object using symbols or a weakmap or some such
}

callback ParserCallback = AbstractStyleValue (TokenSource tokens); // return if successful, throw if not

class StyleGrammar {
  constructor ();
  void addParser(ParserCallback parser);
  AbstractStyleValue parse(TokenSource tokens, Boolean root = false);
   // for each parser callback that was registered, in reverse
   // order (most recently registered first), run these steps:
   //   let bookmark = tokens.getBookmark();
   //   try { 
   //     let result = parser(tokens);
   //     if (root) {
   //       if (!tokens.next().done)
   //         throw new Error();
   //     }
   //   } except {
   //     tokens.rewind(bookmark);
   //   }
   // (root is set when you need to parse the entire token stream to be valid)
}

/*
StyleNode
 |
 +-- Property
 |
 +-- AbstractStyleValue
     |   
     +-- NumericStyleValue
     |    |
     |    +-- AnimatableNumericStyleValue*
     |   
     +-- LengthStyleValue
     |    |
     |    +-- AnimatableLengthStyleValue*
     |    |
     |    +-- PixelLengthStyleValue
     |    |
     |    +-- EmLengthStyleValue*
     |    |
     |    +-- VHLengthStyleValue*
     |    |
     |    +-- CalcLengthStyleValue*
     |    
     +-- ColorStyleValue
     |    |
     |    +-- RGBColorStyleValue
     |    |
     |    +-- AnimatableColorStyleValue*
     |    
     +-- AbstractOpaqueStyleValue
     |    |
     |    +-- IdentifierStyleValue
     |    |    |
     |    |    +-- AnimatableIdentifierStyleValue*
     |    |    
     |    +-- URLStyleValue*
     |    |    |
     |    |    +-- AnimatableURLStyleValue*
     |    |    
     |    +-- StringStyleValue*
     |    |    |
     |    |    +-- AnimatableStringStyleValue*
     |    |    
     |    +-- ObjectStyleValue
     |    
     +-- PrimitiveValuesListStyleValue*
*/
```

The types marked with * in the list above are not part of sky:core.

```javascript
abstract class StyleNode {
  abstract void markDirty();
}

class StyleValueResolverSettings {
  // this is used as an "out" parameter for 'resolve()' below
  constructor();
  void reset(); // resets values to defaults so that object can be reused
  attribute Boolean layoutDependent; // default to false
    // set this if the value should be recomputed each time the ownerLayoutManager's dimensions change, rather than being precomputed

  // attribute "BitField" dependencies; // defaults to no bits set
  void dependsOn(PropertyHandle property);
    // if the given property doesn't have a dependency bit assigned:
    //  - assign the next bit to the property
    //  - if there's no bits left, throw
    // set the bit on this StyleValueResolverSettings's dependencies bitfield
}

class Property : StyleNode {
  constructor (AbstractStyleDeclaration parentNode, PropertyHandle property, AbstractStyleValue? initialValue = null);
  readonly attribute AbstractStyleDeclaration parentNode;
  readonly attribute PropertyHandle property;
  readonly attribute AbstractStyleValue value;

  void setValue(AbstractStyleValue? newValue);
    // updates value and calls markDirty()

  void markDirty();
    // call parentNode.markDirty(property);

  abstract any resolve(RenderNode node, StyleValueResolverSettings? settings = null);
    // if value is null, returns null
    // otherwise, returns value.resolve(property, node, settings)
}

abstract class AbstractStyleValue : StyleNode {
  abstract constructor(StyleNode parentNode);
  readonly attribute StyleNode parentNode;

  void markDirty();
    // call this.parentNode.markDirty()

  abstract any resolve(PropertyHandle property, RenderNode node, StyleValueResolverSettings? settings = null);
}

abstract class LengthStyleValue : AbstractStyleValue {
  abstract Float resolve(PropertyHandle property, RenderNode node, StyleValueResolverSettings? settings = null);
}

class PixelLengthStyleValue : LengthStyleValue {
  constructor(StyleNode parentNode, Float number);
  readonly attribute Float value;
  Float resolve(PropertyHandle property, RenderNode node, StyleValueResolverSettings? settings = null);
}

typedef Color Float; // TODO(ianh): figure out what Color should be
class ColorStyleValue : LengthStyleValue {
  constructor(StyleNode parentNode, Float red, Float green, Float blue, Float alpha);
  // ... color API ...
  Color resolve(PropertyHandle property, RenderNode node, StyleValueResolverSettings? settings = null);
}

class AbstractOpaqueStyleValue : AbstractStyleValue {
  abstract constructor(StyleNode parentNode, any value);
  readonly attribute any value;
  any resolve(PropertyHandle property, RenderNode node, StyleValueResolverSettings? settings = null);
    // returns value
}

class IdentifierStyleValue : AbstractOpaqueStyleValue {
  constructor(StyleNode parentNode, String value);
    // calls superclass constructor
}

/*
class AnimatableIdentifierStyleValue : AbstractOpaqueStyleValue {
  constructor(StyleNode parentNode, String value, String newValue, AnimationFunction player);
  readonly attribute String newValue;
  readonly attribute AnimationFunction player;
  any resolve(PropertyHandle property, RenderNode node, StyleValueResolverSettings? settings = null);
}
*/

class ObjectStyleValue : AbstractOpaqueStyleValue {
  constructor(StyleNode parentNode, any value);
    // calls superclass constructor
}

dictionary PropertySettings {
  String name;
  StyleGrammar grammar;
  Boolean inherited = false;
  any initialValue = null;
  Boolean needsManager = false;
  Boolean needsLayout = false;
  Boolean needsPaint = false;
  // PropertyHandle propertyHandle; // assigned by registerProperty
  // Integer dependencyBit; // assigned by StyleValueResolverSettings.dependsOn()
}
typedef PropertyHandle Integer;
PropertyHandle registerProperty(PropertySettings propertySettings);

// sky:core exports a bunch of style grammars so that people can extend them
attribute StyleGrammar PositiveLengthOrInfinityStyleGrammar; // resolves to LengthStyleValue
attribute StyleGrammar PositiveLengthOrAutoStyleGrammar; // resolves to LengthStyleValue or IdentifierStyleValue (with value 'auto')
attribute StyleGrammar PositiveLengthStyleGrammar; // resolves to LengthStyleValue
attribute StyleGrammar NumberGrammar; // resolves to NumericStyleValue
attribute StyleGrammar ColorGrammar; // resolves to ColorStyleValue
attribute StyleGrammar DisplayStyleGrammar; // resolves to ObjectStyleValue
```  

Inline Styles
-------------

```javascript
abstract class AbstractStyleDeclarationList {
  void addStyles(StyleDeclaration styles, String? pseudoElement = null); // O(1)
  void removeStyles(StyleDeclaration styles, String? pseudoElement = null); // O(N) in number of declarations
  Array<StyleDeclaration> getDeclarations(String? pseudoElement = null); // O(N) in number of declarations
}

class ElementStyleDeclarationList : AbstractStyleDeclarationList {
  constructor (Element? element);

  // there are two batches of styles in an ElementStyleDeclarationList.

  // the first batch is the per-frame styles; these get (conceptually)
  // cleared each frame, after which all the matching rules in relevant
  // <style> blocks get added back in, followed by all the animation-
  // derived rules; scripts can also add styles themselves, but they are
  // dropped after the next frame
  void addFrameStyles(StyleDeclaration styles, String? pseudoElement = null); // O(1)
  void clearFrameStyles();

  // the second batch is the persistent styles, which remain until removed;
  // they are accessed via the AbstractStyleDeclarationList accessors

  // as StyleDeclarations are added and removed, the ElementStyleDeclarationList
  // calls register(element) and unregister(element) respectively on those
  // StyleDeclaration objects, where element is the element that was passed
  // to the constructor, if not null
  // then, it calls element.renderNode.cascadedValueAdded/cascadedValueRemoved
  // for each property on the object

  // the inherited getDeclarations() method returns all the frame
  // styles followed by all the persistent styles, in insertion order
}

class RenderNodeStyleDeclarationList : AbstractStyleDeclarationList {
  constructor (RenderNode? renderNode);

  // as StyleDeclarations are added and removed, the RenderNodeStyleDeclarationList
  // calls register(renderNode) and unregister(renderNode) respectively on those
  // StyleDeclaration objects, where renderNode is the RenderNode that was passed
  // to the constructor, if not null
  // then, it calls renderNode.cascadedValueAdded/cascadedValueRemoved
  // for each property on the object
}

class StyleDeclaration {
  constructor ();

  void markDirty(PropertyHandle property);
    // this indicates that the cascaded value of the property thinks
    // it will now have a different result (as opposed to the cascaded
    // value itself having changed)
    // invoke element.renderNode.cascadedValueDirty(property, pseudoElement); for each
    // currently registered consumer element/pseudoElement pair

  void register((Element or RenderNode) consumer, String? pseudoElement = null); // O(1)
  void unregister((Element or RenderNode) consumer, String? pseudoElement = null); // O(N)
    // registers an element/pseudoElement or renderNode/pseudoElement pair with
    // this StyleDeclaration so that a property/value on the style declaration
    // is marked dirty, the relevant render node is informed and can then update
    // its property cache accordingly

  getter AbstractStyleValue? (PropertyHandle property);
    // looks up the Property object for /property/, and returns its value
    // null if property is missing

  setter void (PropertyHandle property, AbstractStyleValue value);
    // if there is no Property object for /property/, creates one
    // else calls its update() method to change the value
    // if the value changed:
    // invoke consumer.renderNode.cascadedValueChanged(property); for each
    // currently registered consumer
    // if the value is new:
    // invoke consumer.renderNode.cascadedValueAdded(property); for each
    // currently registered consumer

  void remove(PropertyHandle property);
    // drops the Property object for /property/ from this StyleDeclaration object
    // invoke consumer.renderNode.cascadedValueRemoved(property); for each
    // currently registered consumer
}
```

Rule Matching
-------------

```javascript
class Rule {
  constructor ();
  attribute SelectorQuery selector; // O(1)
  attribute String? pseudoElement; // O(1)
  attribute StyleDeclaration styles; // O(1)
}
```

Each frame, at some defined point relative to requestAnimationFrame(),
if a Rule has started applying, or a Rule stopped applying, to an
element, sky:core calls thatElement.style.clearFrameStyles() and then,
for each Rule that now applies, calls
thatElement.style.addFrameStyles() with the relevant StyleDeclaration
and pseudoElement from each such Rule.


Cascade
-------

Simultaneously walk the tree rooted at the application Document,
taking into account shadow trees and child distribution, and the tree
rooted at the document's RenderNode.

If you come across a node that doesn't have an assigned RenderNode,
then create one, placing it in the appropriate place in the RenderTree
tree, after any nodes marked isGhost=true, with ownerLayoutManager
pointing to the parent RenderNode's layoutManager, and then, if
autoreap is false on the ownerLayoutManager, mark it "isNew".

For each element, if the node's needsManager is true, call
getLayoutManager() on the element, and if that's not null, and if the
returned class isn't the same class as the current layoutManager, if
any, construct the given class and assign it to the RenderNode's
layoutManager, then set all the child RenderNodes' ownerLayoutManager
to that object; if it returns null, and that node already has a
layoutManager, then set isGhost=true for that node and all its
children (without changing the layoutManager). Otherwise, if it
returned null and there's already no layoutManager, remove the node
from the tree. Then, in any case, clear the needsManager bit.

When an Element or Text node is to be removed from its parent, and it
has a renderNode, and that renderNode has an ownerLayoutManager with
autoreap=false, then before actually removing the node, the node's
renderNode should be marked isGhost=true, and the relevant
ElementStyleDeclarationList should be flattened and the values stored on
the RenderNode's overrideStyles for use later. (Or we can just clone the
StyleDeclarations directly without flattening. That would probably
be faster.)

When an Element is to be removed from its parent, regardless of the
above, the node's renderNode attribute should be nulled out.

When a RenderNode is added with isNew=true, call its parent
RenderNode's LayoutManager's childAdded() callback. When a a
RenderNode has its isGhost property set to true, then call it's parent
RenderNode's LayoutManager's childRemoved() callback.


```javascript
callback any ValueResolver (any value, String propertyName, RenderNode node, Float containerWidth, Float containerHeight);

class RenderNode { // implemented in C++ with no virtual tables
  // this is generated before layout
  readonly attribute String text;
  readonly attribute Node? parentNode;
  readonly attribute Node? firstChild;
  readonly attribute Node? nextSibling;

  any getProperty(PropertyHandle property, String? pseudoElement = null);
     // looking at the cached data for the given pseudoElement:
     // if there's a cached value, return it
     // otherwise, figure out which StyleValue we're going to be using, in this order:
     //   - look out our override declarations (first with the pseudo, if any, then without)
     //   - if there's an element:
     //     - look at this element's StyleDeclarations (first with the pseudo, if any, then without)
     //   - if it's an inherited property and there's a parent:
     //      - call getProperty() on the parent (without the pseudo)
     //   - use the default value
     // resolve the StyleValue giving it the property and node in question
     // cache the value, along with the StyleValueResolverSettings

  readonly attribute RenderNodeStyleDeclarationList overrideStyles;
     // mutable; initially empty
     // this is used when isGhost is true, and can also be used more generally to
     // override styles from the layout manager (e.g. to animate a new node into view)

  private void cascadedValueAdded(PropertyHandle property, String? pseudoElement = null);
  private void cascadedValueRemoved(PropertyHandle property, String? pseudoElement = null);
  private void cascadedValueChanged(PropertyHandle property, String? pseudoElement = null);
  private void cascadedValueDirty(PropertyHandle property, String? pseudoElement = null);
    // - clear the cached data for this property/pseudoElement pair
    // - if the property is needsManager, set needsManager to true
    // - if the property is needsLayout, set needsLayout to true and walk
    //   up the tree setting descendantNeedsLayout
    // - if the property is needsPaint, add the node to the list of nodes that need painting
    // - if the property has a dependencyBit defined, then check the cache of all the
    //   properties on this RenderNode, and the cache for the property in all the child
    //   nodes and (if pseudoElement is null) or the pseudoElements
    //   and if any of them have the relevant dependency bit set then call
    //     thatRenderNode.cascadedValueDirty(thatProperty, thatPseudoElement)
    // - if the property is inherited:
    //     - call this.cascadedValueDirty(property, eachPseudoElement)
    //     - call eachChildRenderNode.cascadedValueDirty(property, null)
    // (these four methods all do the same thing; they might get merged into one. For now
    // they're separate in case we want to make them cleverer later.)

  readonly attribute Boolean needsManager;
    // means that a property with needsManager:true has changed on this node

  readonly attribute Boolean needsLayout;
    // means that either needsManager is true or a property with needsLayout:true has changed on this node
    // needsLayout is set to false by the ownerLayoutManager's default layout() method

  readonly attribute Boolean descendantNeedsLayout;
    // means that some child of this node has needsLayout set to true
    // descendantNeedsLayout is set to false by the ownerLayoutManager's default layout() method

  readonly attribute LayoutManager layoutManager;
  readonly attribute LayoutManager ownerLayoutManager; // defaults to the parentNode.layoutManager
    // if you are not the ownerLayoutManager, then ignore this RenderNode in layout() and paintChildren()
    // using walkChildren() does this for you

  // only the ownerLayoutManager can change these
  readonly attribute Float x; // relative to left edge of ownerLayoutManager
  readonly attribute Float y; // relative to top edge of ownerLayoutManager
  readonly attribute Float width;
  readonly attribute Float height;
  readonly attribute Boolean isNew; // node has just been added (and maybe you want to animate it in)
  readonly attribute Boolean isGhost; // node has just been removed (and maybe you want to animate it away)
}
```

The flattened tree is represented as a hierarchy of Node objects. For
any element that only contains text node children, the "text" property
is set accordingly. For elements with mixed text node and non-text
node children, each run of text nodes is represented as a separate
Node with the "text" property set accordingly and the styles set as if
the Node inherited everything inheritable from its parent.


Layout
------

sky:core registers 'display' as follows:

```javascript
  {
    name: 'display',
    grammar: sky.DisplayStyleGrammar,
    inherited: false,
    initialValue: sky.BlockLayoutManager,
    needsManager: true,
  }
```

The following API is then used to add new layout manager types to 'display':

```javascript
void registerLayoutManager(String displayValue, LayoutManagerConstructor? layoutManager);
```

sky:core by default registers:

- 'block': sky.BlockLayoutManager
- 'paragraph': sky.ParagraphLayoutManager
- 'inline': sky.InlineLayoutManager
- 'none': null


Layout managers inherit from the following API:

```javascript
class LayoutManager : EventTarget {
  readonly attribute RenderNode node;
  constructor LayoutManager(RenderNode node);
    // sets needsManager to false on the node

  readonly attribute Boolean autoreap;
    // defaults to true
    // when true, any children that are isNew are automatically welcomed by the default layout()
    // when true, children that are removd don't get set to isGhost=true, they're just removed

  virtual Array<EventTarget> getEventDispatchChain(); // O(N) in number of this.node's ancestors // implements EventTarget.getEventDispatchChain()
    // let result = [];
    // let node = this.node;
    // while (node && node.layoutManager) {
    //   result.push(node.layoutManager);
    //   node = node.parentNode;
    // }
    // return result;

  void setProperty(RenderNode node, PropertyHandle property, any value, String? pseudoElement = null); // O(1)
    // if called from an adjustProperties() method during the property adjustment phase,
    // replaces the value that getProperty() would return on that node with /value/

  void take(RenderNode victim); // sets victim.ownerLayoutManager = this;
    // assert: victim hasn't been take()n yet during this layout
    // assert: victim.needsLayout == true
    // assert: an ancestor of victim has node.layoutManager == this (aka, victim is a descendant of this.node)

  virtual void release(RenderNode victim);
    // called when the RenderNode was removed from the tree

  virtual void childAdded(RenderNode child);
  virtual void childRemoved(RenderNode child);
    // called when a child has its isNew or isGhost attributes set respectively

  void setChildPosition(child, x, y); // sets child.x, child.y
  void setChildX(child, y); // sets child.x
  void setChildY(child, y); // sets child.y
  void setChildSize(child, width, height); // sets child.width, child.height
  void setChildWidth(child, width); // sets child.width
  void setChildHeight(child, height); // sets child.height
    // for setChildSize/Width/Height: if the new dimension is different than the last assumed dimensions, and
    // any RenderNodes with an ownerLayoutManager==this have cached values for getProperty() that are marked
    // as layout-dependent, clear them
  void welcomeChild(child); // resets child.isNew
  void reapChild(child); // resets child.isGhost

  Generator<RenderNode> walkChildren();
    // returns a generator that iterates over the children, skipping any whose ownerLayoutManager is not |this|

  Generator<RenderNode> walkChildrenBackwards();
    // returns a generator that iterates over the children backwards, skipping any whose ownerLayoutManager is not |this|

  void assumeDimensions(Float width, Float height);
    // sets the assumed dimensions for calls to getProperty() on RenderNodes that have this as an ownerLayoutManager
    // if the new dimension is different than the last assumed dimensions, and any RenderNodes with an
    // ownerLayoutManager==this have cached values for getProperty() that are marked as layout-dependent, clear them
    // TODO(ianh): should we force this to match the input to layout(), when called from inside layout() and when
    // layout() has a forced width and/or height?

  virtual LayoutValueRange getIntrinsicWidth(Float? defaultWidth = null);
  /*
     function getIntrinsicWidth(defaultWidth) {
       if (defaultWidth == null) {
         defaultWidth = this.node.getProperty('width');
         if (typeof defaultWidth != 'number')
           defaultWidth = 0;
       }
       let minWidth = this.node.getProperty('min-width');
       if (typeof minWidth != 'number')
         minWidth = 0;
       let maxWidth = this.node.getProperty('max-width');
       if (typeof maxWidth != 'number')
         maxWidth = Infinity;
       if (maxWidth < minWidth)
         maxWidth = minWidth;
       if (defaultWidth > maxWidth)
         defaultWidth = maxWidth;
       if (defaultWidth < minWidth)
         defaultWidth = minWidth;
       return {
         minimum: minWidth,
         value: defaultWidth,
         maximum: maxWidth,
       };
     }
  */

  virtual LayoutValueRange getIntrinsicHeight(Float? defaultHeight = null);
  /*
     function getIntrinsicHeight(defaultHeight) {
       if (defaultHeight == null) {
         defaultHeight = this.node.getProperty('height');
         if (typeof defaultHeight != 'number')
           defaultHeight = 0;
       }
       let minHeight = this.node.getProperty('min-height');
       if (typeof minHeight != 'number')
         minHeight = 0;
       let maxHeight = this.node.getProperty('max-height');
       if (typeof maxHeight != 'number')
         maxHeight = Infinity;
       if (maxHeight < minHeight)
         maxHeight = minHeight;
       if (defaultHeight > maxHeight)
         defaultHeight = maxHeight;
       if (defaultHeight < minHeight)
         defaultHeight = minHeight;
       return {
         minimum: minHeight,
         value: defaultHeight,
         maximum: maxHeight,
       };
     }
  */

  void markAsLaidOut(); // sets this.node.needsLayout and this.node.descendantNeedsLayout to false
  virtual Dimensions layout(Float? width, Float? height);
    // call markAsLaidOut();
    // if autoreap is true: use walkChildren() to call welcomeChild() and reapChild() on each child
    // if width is null, set width to getIntrinsicWidth().value
    // if height is null, set width height getIntrinsicHeight().value
    // call this.assumeDimensions(width, height);
    // call this.layoutChildren(width, height);
    // return { width: width, height: height }
    // - this should always call this.markAsLaidOut() to reset needsLayout
    // - the return value should include the final value for whichever of the width and height arguments
    //   that is null
    // - subclasses that want to make 'auto' values dependent on the children should override this
    //   entirely, rather than overriding layoutChildren

  virtual void layoutChildren(Float width, Float height);
    // default implementation does nothing
    // - override this if you want to lay out children but not have the children affect your dimensions

  virtual void paint(RenderingSurface canvas);
    // set a clip rect on the canvas for rect(0,0,this.width,this.height)
    //   (? we don't really have to do this; consider shadows...)
    // call the painter of each property, in order they were registered, which on this element has a painter
    // call this.paintChildren(canvas)
    // (the default implementation doesn't paint anything on top of the children)
    // unset the clip
    // - this gets called by the system if:
    //    - you are in your parent's current display list and it's in its parent's and so on up to the top, and
    //    - you haven't had paint() called since the last time you were dirtied
    // - the following things make you dirty:
    //    - dimensions of your RenderNode changed
    //    - one of your properties with needsLayout or needsPaint changed

  virtual void paintChildren(RenderingSurface canvas);
    // for each child returned by walkChildren():
    //   if child bounds intersects our bounds:
    //     call canvas.paintChild(child);
    // - you should skip children that will be clipped out of yourself because they're outside your bounds
    // - if you transform the canvas, you'll have to implement your own version of paintChildren() so
    //   that you don't skip the children that are visible in the new coordinate space but wouldn't be
    //   without the transform

  virtual RenderNode hitTest(Float x, Float y);
    // default implementation uses the node's children nodes' x, y,
    // width, and height, skipping any that have width=0 or height=0, or
    // whose ownerLayoutManager is not |this|
    // default implementation walks the tree backwards from its built-in order
    // if no child is hit, then return this.node
    // override this if you changed your children's z-order, or if you used take() to
    // hoist some descendants up to be your responsibility, or if your children aren't
    // rectangular (e.g. you lay them out in a hex grid)
    // make sure to offset the value you pass your children: child.layoutManager.hitTest(x-child.x, y-child.y)
}

dictionary LayoutValueRange {
  // negative values here should be treated as zero
  Float minimum = 0;
  Float value = 0; // ideal desired width; if it's not in the range minimum .. maximum then it overrides minimum and maximum
  (Float or Infinity) maximum = Infinity; 
}

dictionary Dimensions {
  Float width = 0;
  Float height = 0;
}
```


Paint
-----

Sky has a list of RenderNodes that need painting. When a RenderNode is
created, it's added to this list. (See also needsPaint for another
time it is added to the list.)

```javascript
callback void Painter (RenderNode node, RenderingSurface canvas);

class RenderingSurface {

  // ... (API similar to <canvas>'s 2D API)

  void paintChild(RenderNode node);
    // inserts a "paint this child" instruction in this canvas's display list.
    // the child's display list, transformed by the child's x and y coordinates, will be inserted into this
    // display list during painting.
}
```


The default framework provides global hooks for extending the painting of:

 - borders
 - backgrounds

These are called during the default framework's layout managers'
paint() functions. They are also made available so that other people
can call them from their paint() functions.



Default Styles
--------------

In the constructors for the default elements, they add to themselves
StyleDeclaration objects as follows:

* ``import``
* ``template``
* ``style``
* ``script``
* ``content``
* ``title``
  These all add to themselves the same declaration as follows:
```javascript
let d = new StyleDeclaration();
d[pDisplay] = new ObjectStyleValue(null);
this.style.addStyles(d);
```

* ``img``
  This adds to itself the declaration as follows:
```javascript
let d = new StyleDeclaration();
d[pDisplay] = new ObjectStyleValue(ImageElementLayoutManager);
this.style.addStyles(d);
```

* ``span``
* ``a``
  These all add to themselves the same declaration as follows:
```javascript
let d = new StyleDeclaration();
d[pDisplay] = new ObjectStyleValue(InlineLayoutManager);
this.style.addStyles(d);
```

* ``iframe``
  This adds to itself the declaration as follows:
```javascript
let d = new StyleDeclaration();
d[pDisplay] = new ObjectStyleValue(IFrameElementLayoutManager);
this.style.addStyles(d);
```

* ``t``
  This adds to itself the declaration as follows:
```javascript
let d = new StyleDeclaration();
d[pDisplay] = new ObjectStyleValue(ParagraphLayoutManager);
this.style.addStyles(d);
```

* ``error``
  This adds to itself the declaration as follows:
```javascript
let d = new StyleDeclaration();
d[pDisplay] = new ObjectStyleValue(ErrorLayoutManager);
this.style.addStyles(d);
```

The ``div`` element doesn't have any default styles.

These declarations are all shared between all the elements (so e.g. if
you reach in and change the declaration that was added to a ``title``
element, you're going to change the styles of all the other
default-hidden elements). (In other words, in the code snippets above,
the ``d`` variable is initialised in shared code, and only the
addStyles() call is per-element.)
