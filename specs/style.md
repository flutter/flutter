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
     |    +-- TransitionLengthStyleValue*
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

The types marked with * in the list above are not part of sky:core,
and are only shown here to illustrate what kinds of extensions are
possible and where they would fit.

TODO(ianh): consider removing 'StyleValue' from these class names

```javascript
abstract class StyleNode {
  abstract void markDirty();
}

dictionary StyleValueResolverSettingsSettings {
  Boolean firstTime = false;
  any state = null;
}

class StyleValueResolverSettings {
  // this is used as an "out" parameter for 'resolve()' below
  constructor(StyleValueResolverSettingsSettings initial);
  void reset(StyleValueResolverSettingsSettings initial);
    // sets firstTime and state to given values
    // sets layoutDependent to false
    // sets dependencies to empty set

  readonly attribute Boolean firstTime;
    // true if this is the first time this property is being resolved for this element,
    // or if the last time it was resolved, the value was a different object

  // attribute Boolean layoutDependent
  void setLayoutDependent();
    // call this if the value should be recomputed each time the ownerLayoutManager's dimensions change, rather than being cached
  Boolean getLayoutDependent();
    // returns true if setLayoutDependent has been called since the last reset()

  // attribute "BitField" dependencies; // defaults to no bits set
  void dependsOn(PropertyHandle property);
    // if the given property doesn't have a dependency bit assigned:
    //  - assign the next bit to the property
    //  - if there's no bits left, throw
    // set the bit on this StyleValueResolverSettings's dependencies bitfield
  Array<PropertyHandle> getDependencies();
    // returns an array of the PropertyHandle values for the bits that are set in dependencies

  attribute any state; // initially null, can be set to store value for this RenderNode/property pair
    // for example, TransitioningColorStyleValue would store
    //    {
    //      initial: /* color at time of transition */,
    //      target: /* color at end of transition */,
    //      start: /* time at start of transition */,
    //    }
    // ...which would enable it to update appropriately, and would also
    // let other transitions that come later know that you were half-way
    // through a transition so they can shorten their time accordingly
    //
    // best practices: if you're storing values on the state object,
    // then remove the values once they are no longer needed. For
    // example, when your transition ends, set the object to null.
    //
    // best practices: if you're a style value that contains multiple
    // style values, then before you call their resolve you should
    // replace the state with a state that is specific to them, and
    // when you get it back you should insert that value into your
    // state somehow. For example, in a resolve()r with two child
    // style values a and b:
    //    let ourState;
    //    if (settings.firstTime)
    //      ourState = { a: null, b: null };
    //    else
    //      ourState = settings.state;
    //    settings.state = ourState.a;
    //    let aResult = a.resolve(node, settings);
    //    ourState.a = settings.state;
    //    settings.state = ourState.b;
    //    let aResult = b.resolve(node, settings);
    //    ourState.b = settings.state;
    //    settings.state = ourState;
    //    return a + b; // or whatever
    //
    // best practices: if you're a style value that contains multiple
    // style values, and all those style values are storing null, then
    // store null yourself, instead of storing many nulls of your own.

  // attribute Boolean wasStateSet;
  Boolean getShouldSaveState();
    // returns true if state is not null, and either state was set
    // since the last reset, or firstTime is false.

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
  abstract constructor(StyleNode? parentNode = null);
  attribute StyleNode? parentNode;

  void markDirty();
    // call this.parentNode.markDirty()

  abstract any resolve(PropertyHandle property, RenderNode node, StyleValueResolverSettings? settings = null);
}

abstract class LengthStyleValue : AbstractStyleValue {
  abstract Float resolve(PropertyHandle property, RenderNode node, StyleValueResolverSettings? settings = null);
}

class PixelLengthStyleValue : LengthStyleValue {
  constructor(Float number, StyleNode? parentNode = null);
  attribute Float value;
    // on setting, calls markDirty();
  Float resolve(PropertyHandle property, RenderNode node, StyleValueResolverSettings? settings = null);
    // return value
}

typedef RawColor Float; // TODO(ianh): figure out what Color should be
class ColorStyleValue : LengthStyleValue {
  constructor(Float red, Float green, Float blue, Float alpha, StyleNode? parentNode = null);
  // ... color API ...
  RawColor resolve(PropertyHandle property, RenderNode node, StyleValueResolverSettings? settings = null);
}

class AbstractOpaqueStyleValue : AbstractStyleValue {
  abstract constructor(any value, StyleNode? parentNode = null);
  attribute any value;
    // on setting, calls markDirty();
  any resolve(PropertyHandle property, RenderNode node, StyleValueResolverSettings? settings = null);
    // returns value
}

class IdentifierStyleValue : AbstractOpaqueStyleValue {
  constructor(String value, StyleNode? parentNode = null);
    // calls superclass constructor
}

/*
class AnimatableIdentifierStyleValue : AbstractOpaqueStyleValue {
  constructor(String value, String newValue, AnimationFunction player, StyleNode? parentNode = null);
  readonly attribute String newValue;
  readonly attribute AnimationFunction player;
  any resolve(PropertyHandle property, RenderNode node, StyleValueResolverSettings? settings = null);
}
*/

class ObjectStyleValue : AbstractOpaqueStyleValue {
  constructor(any value, StyleNode? parentNode = null);
    // calls superclass constructor
}

dictionary PropertySettings {
  String? name = null; // null if the property can't be set from a <style> block
  StyleGrammar? grammar = null; // must be non-null if name is non-null; must be null otherwise
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
  // registers a property with the given settings, and returns an integer >= 0
  // that can be used to refer to this property

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
  void addStyles(StyleDeclaration styles, String pseudoElement = ''); // O(1)
  void removeStyles(StyleDeclaration styles, String pseudoElement = ''); // O(N) in number of declarations
  Array<StyleDeclaration> getDeclarations(String pseudoElement = ''); // O(N) in number of declarations
}

class ElementStyleDeclarationList : AbstractStyleDeclarationList {
  constructor (Element? element);

  // there are two batches of styles in an ElementStyleDeclarationList.

  // the first batch is the per-frame styles; these get (conceptually)
  // cleared each frame, after which all the matching rules in relevant
  // <style> blocks get added back in, followed by all the animation-
  // derived rules; scripts can also add styles themselves, but they are
  // dropped after the next frame
  void addFrameStyles(StyleDeclaration styles, String pseudoElement = ''); // O(1)
  void clearFrameStyles();

  // the second batch is the persistent styles, which remain until removed;
  // they are accessed via the AbstractStyleDeclarationList accessors

  // as StyleDeclarations are added and removed, the ElementStyleDeclarationList
  // calls register(element) and unregister(element) respectively on those
  // StyleDeclaration objects, where element is the element that was passed
  // to the constructor, if not null
  // then, it calls element.renderNode.cascadedValueChanged
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
  // then, it calls renderNode.cascadedValueChanged
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

  void register((Element or RenderNode) consumer, String pseudoElement = ''); // O(1)
  void unregister((Element or RenderNode) consumer, String pseudoElement = ''); // O(N)
    // registers an element/pseudoElement or renderNode/pseudoElement pair with
    // this StyleDeclaration so that a property/value on the style declaration
    // is marked dirty, the relevant render node is informed and can then update
    // its property cache accordingly


  getter AbstractStyleValue? (PropertyHandle property);
    // looks up the Property object for /property/, and returns its value
    // null if property is missing

  setter void (PropertyHandle property, AbstractStyleValue value);
    // verify that value.parentNode is null
    // if there is no Property object for /property/, creates one
    // else calls its update() method to change the value
    // update value's parentNode
    // invoke consumer.renderNode.cascadedValueChanged(property); for each
    // currently registered consumer

  void remove(PropertyHandle property);
    // drops the Property object for /property/ from this StyleDeclaration object
    // invoke consumer.renderNode.cascadedValueChanged(property); for each
    // currently registered consumer
}
```

Rule Matching
-------------

```javascript
class Rule {
  constructor ();
  attribute SelectorQuery selector; // O(1)
  attribute String pseudoElement; // O(1)
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
pointing to the parent RenderNode's layoutManager, if it has one, and,
if it has one and autoreap is false on that layout manager, mark the
new node "isNew". (This means that when a node is marked isNew, the
layout manager has already laid out at least one frame.)

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
dictionary PropertySettings {
  String? name = null; // null if the property can't be set from a <style> block
  StyleGrammar? grammar = null; // must be non-null if name is non-null; must be null otherwise
  Boolean inherited = false;
  any initialValue = null;
  Boolean needsManager = false;
  Boolean needsLayout = false;
  Boolean needsPaint = false;
  // PropertyHandle propertyHandle; // assigned by registerProperty
  // Integer dependencyBit; // assigned by StyleValueResolverSettings.dependsOn()
}

dictionary GetPropertySettings {
  String pseudoElement = '';
  Boolean forceCache = false;
    // if set to true, will return the cached value if any, or null otherwise
    // this is used by transitions to figure out what to transition from
}

class RenderNode { // implemented in C++ with no virtual tables
  // this is generated before layout
  readonly attribute String text;
  readonly attribute Node? parentNode;
  readonly attribute Node? firstChild;
  readonly attribute Node? nextSibling;

  // internal state:
  // - back pointer to backing Node, if we're not a ghost
  // - cache of resolved property values, mapping as follows:
  //    - pseudoElement, property => StyleValue object, resolved value, StyleValueResolverSettings, cascade dirty bit, value dirty bit
  // - property state map (initially empty), as follows:
  //    - pseudoElement, property => object

  any getProperty(PropertyHandle property, GetPropertySettings? settings = null);
     // looking at the cached data for the given pseudoElement:
     // if there's a cached value:
     //   if settings.forceCache is true, return the cached value
     //   if neither dirty bit is set, return the cached value
     //   if the cascade dirty bit is not set (value dirty is set) then
     //     resolve the value using the same StyleValue object
     //      - with firstTime=false on the resolver settings
     //      - with the cached state object if any
     //      - jump to "cache" below
     // if settings.forceCache is true, return null
     // - if there's an override declaration with the property (with
     //   the pseudo or without), then get the value object from there and
     //   jump to "resolve" below.
     // - if there's an element and it has a style declaration with the property
     //   (with the pseudo or without), then get the value object from there
     //   and jump to "resolve" below.
     // - if it's not an inherited property, or if there's no parent, then get the
     //   default value and jump to "resolve" below.
     // - call the parent render node's getProperty() with the same property
     //   but no settings, then cache that value as the value for this element
     //   with the given pseudoElement, with no StyleValue object, no resolver
     //   settings, and set the state to null.
     // resolve:
     //   - get a new resolver settings object
     //   - if the obtained StyleValue object is different than the
     //     cached StyleValue object, or if there is no cached object, then set
     //     the resolver settings to firstTime=true, otherwise it's the same object
     //     and set firstTime=false.
     //   - set the resolver settings' state to the current state for this
     //     pseudoElement/property combination
     //   - using the obtained StyleValue object, call resolve(),
     //     passing it this node and the resolver settings object.
     //   - jump to "cache" below
     // cache:
     //   - update the cache with the obtained value and resolver settings
     //   - reset the dirty bits
     //   - if the resolver settings' getShouldSaveState() method returns false,
     //     then discard any cached state, otherwise, cache the new state

  readonly attribute RenderNodeStyleDeclarationList overrideStyles;
     // mutable; initially empty
     // this is used when isGhost is true, and can also be used more generally to
     // override styles from the layout manager (e.g. to animate a new node into view)

  private void cascadedValueChanged(PropertyHandle property, String pseudoElement = '');
  private void cascadedValueDirty(PropertyHandle property, String pseudoElement = '');
    // - set the appropriate dirty bit on the cached data for this property/pseudoElement pair
    //    - cascade dirty for cascadedValueChanged
    //    - value dirty for cascadedValueDirty
    // - if the property is needsManager, set needsManager to true
    // - if the property is needsLayout, set needsLayout to true and walk up the
    //   tree setting descendantNeedsLayout
    // - if the property is needsPaint, add the node to the list of nodes that need painting
    // - if the property has a dependencyBit defined, then check the cache of all the
    //   properties on this RenderNode, and the cache for the property in all the child
    //   nodes and, if pseudoElement is '', the pseudoElements of this node, and,
    //   if any of them have the relevant dependency bit set, then call
    //     thatRenderNode.cascadedValueDirty(thatProperty, thatPseudoElement)
    // - if the property is inherited, then for each child node, and, if pseudoElement
    //   is '', the pseudoElements of this node, if the cached value for this property
    //   is present but has no StyleValue, call thatNode.cascadedValueChanged(property, thatPseudoElement)

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
callback LayoutManagerConstructor LayoutManager (RenderNode node);

class LayoutManager : EventTarget {
  readonly attribute RenderNode node;
  constructor LayoutManager(RenderNode node);
    // sets needsManager to false on the node

  readonly attribute Boolean autoreap;
    // defaults to true
    // when true, any children that are isNew are automatically welcomed by the default layout()
    // when true, children that are removed don't get set to isGhost=true, they're just removed

  virtual Array<EventTarget> getEventDispatchChain(); // O(N) in number of this.node's ancestors // implements EventTarget.getEventDispatchChain()
    // let result = [];
    // let node = this.node;
    // while (node && node.layoutManager) {
    //   result.push(node.layoutManager);
    //   node = node.parentNode;
    // }
    // return result;

  void setProperty(RenderNode node, PropertyHandle property, any value, String pseudoElement = ''); // O(1)
    // if called from an adjustProperties() method during the property adjustment phase,
    // replaces the value that getProperty() would return on that node with /value/
    // this also clears the dependency bits and sets the property state to null

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

* ``span``
* ``a``
  These all add to themselves the same declaration as follows:
```javascript
let d = new StyleDeclaration();
d[pDisplay] = new ObjectStyleValue(InlineLayoutManager);
this.style.addStyles(d);
```

* ``t``
  This adds to itself the declaration as follows:
```javascript
let d = new StyleDeclaration();
d[pDisplay] = new ObjectStyleValue(ParagraphLayoutManager);
this.style.addStyles(d);
```

The other elements don't have any default styles.

These declarations are all shared between all the elements (so e.g. if
you reach in and change the declaration that was added to a ``span``
element, you're going to change the styles of all the other
default-hidden elements). (In other words, in the code snippets above,
the ``d`` variable is initialised in shared code, and only the
addStyles() call is per-element.)
