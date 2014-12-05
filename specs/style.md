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

dictionary ParsedValue {
  any value = null;
  ValueResolver? resolver = null;
  Boolean relativeDimension = false; // if true, e.g. for % lengths, the callback will be called again if an ancestor's dimensions change
  Painter? painter = null;
}

// best practice convention: if you're creating a property with needsPaint, you should 
// create a new style value type for it so that it can set the paint callback right;
// you should never use such a style type when parsing another property

callback any ParserCallback (TokenSource tokens);

class StyleValueType {
  constructor ();
  void addParser(ParserCallback parser);
  any parse(TokenSource tokens, Boolean root = false);
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

// note: if you define a style value type that uses other style value types, e.g. a "length pair" that accepts two lengths, then
// if any of the subtypes have a resolver, you need to make sure you have a resolver that calls them to compute the final value

dictionary PropertySettings {
  String name;
  StyleValueType type; // the output from the parser is coerced to a ParsedValue
  Boolean inherits = false;
  any initialValue = null;
  Boolean needsLayout = false;
  Boolean needsPaint = false;
}

void registerProperty(PropertySettings propertySettings);
  // when you register a new property, document the format that is expected to be cascaded
  // (the output from the propertySettings.type parser's ParsedValue.value field after the resolver, if any, has been called)

// sky:core exports a bunch of style value types so that people can
// extend them
attribute StyleValueType PositiveLengthOrInfinityStyleValueType;
attribute StyleValueType PositiveLengthOrAutoStyleValueType;
attribute StyleValueType PositiveLengthStyleValueType;
attribute StyleValueType DisplayStyleValueType;
```  

Inline Styles
-------------

```javascript
partial class Element {
  readonly attribute StyleDeclarationList style;
}

class StyleDeclarationList {
  constructor ();

  // There are two batches of styles in a StyleDeclarationList.

  // The first batch is the per-frame styles. These get cleared each
  // frame, after which all the matching rules in relevant <style> blocks
  // get added back in, followed by all the animation-derived rules.
  // Scripts can add styles themselves.
  void addFrameStyles(StyleDeclaration styles, String? pseudoElement = null); // O(1)
  void clearFrameStyles();

  // The second batch is the persistent styles.
  // Once added, they remain forever until removed.
  void addPersistentStyles(StyleDeclaration styles, String? pseudoElement = null); // O(1)
  void removePersistentStyles(StyleDeclaration styles, String? pseudoElement = null); // O(N) in number of declarations

  // This returns all the frame styles followed by all the persistent styles, in insertion order.
  Array<StyleDeclaration> getDeclarations(String? pseudoElement = null); // O(N) in number of declarations
}

typedef StyleDeclaration Dictionary<ParsedValue>;
```

Rule Matching
-------------

```javascript
partial class StyleElement {
  Array<Rule> getRules(); // O(N) in rules
}

class Rule {
  constructor ();
  attribute SelectorQuery selector; // O(1)
  attribute String? pseudoElement; // O(1)
  attribute StyleDeclaration styles; // O(1)
}
```

Each frame, at some defined point relative to requestAnimationFrame():
 - If a rule starts applying to an element, sky:core calls thatElement.style.add(rule.styles, rule.pseudoElement);
 - If a rule stops applying to an element, sky:core calls thatElement.style.remove(rule.styles, rule.pseudoElement);

TODO(ianh): fix the above so that rule order is maintained


Cascade
-------

For each Element, the StyleDeclarationList is conceptually flattened
so that only the last declaration mentioning a property is left.

Create the flattened render tree as a tree of StyleNode objects
(described below). For each one, run the equivalent of the following
code:

```javascript
var display = node.getProperty('display');
if (display) {
  node.layoutManager = new display(node, ownerManager);
  return true;
}
return false;
```

If that code returns false, then that node an all its descendants must
be dropped from the render tree.

If any node is removed in this pass relative to the previous pass, and
it has an ownerLayoutManager, then call

```javascript
node.ownerLayoutManager.release(node)
```

...to notify the layout manager that the node went away, then set the
node's ownerLayoutManager attribute to null.

```javascript
partial class Element {
  readonly attribute StyleNode? layout; // TODO(ianh): come up with a better name (sadly "style" is taken)
   // this will be null until the first time it is rendered
}

callback any ValueResolver (any value, String propertyName, StyleNode node, Float containerWidth, Float containerHeight);

class StyleNode {
  // this is generated before layout
  readonly attribute String text;
  readonly attribute Node? parentNode;
  readonly attribute Node? firstChild;
  readonly attribute Node? nextSibling;

  // access to the results of the cascade
  // only works during layout and painting
  any getProperty(String name, String? pseudoElement = null);
     // throw if this isn't during layout or painting
     //   TODO(ianh): if the implementation of this does allow it to be queried the rest of the time too, relax this constraint
     // looking at the declarations for the given pseudoElement:
     // if there's a cached value, return it
     // otherwise, if there's an applicable ParsedValue, then
     //   if it has a resolver:
     //     call it
     //     cache the value
     //     if relativeDimension is true, then mark the value as provisional
     //     return the value
     //   otherwise use the ParsedValue's value; cache it; return it
     // otherwise, if a pseudo-element was specified, try again without one
     // otherwise, if the property is inherited and there's a parent:
     //   get it from the parent (without pseudo); cache it; return it
     // otherwise, get the default value; cache it; return it

  readonly attribute Boolean needsLayout;
    // means that either needsLayout is true or a property with needsLayout:true has changed on this node
    // needsLayout is set to false by the ownerLayoutManager's default layout() method

  readonly attribute Boolean descendantNeedsLayout;
    // means that some child of this node has needsLayout set to true
    // descendantNeedsLayout is set to false by the ownerLayoutManager's default layout() method

  readonly attribute LayoutManager layoutManager;
  readonly attribute LayoutManager ownerLayoutManager; // defaults to the parentNode.layoutManager
    // if you are not the ownerLayoutManager, then ignore this StyleNode in layout() and paintChildren()
    // using walkChildren() does this for you

  // only the ownerLayoutManager can change these
  readonly attribute Float x; // relative to left edge of ownerLayoutManager
  readonly attribute Float y; // relative to top edge of ownerLayoutManager
  readonly attribute Float width;
  readonly attribute Float height;
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
    type: sky.DisplayStyleValueType,
    inherits: false,
    initialValue: sky.BlockLayoutManager,
    needsLayout: true,
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
class LayoutManager {
  readonly attribute StyleNode node;
  constructor LayoutManager(StyleNode node);

  void take(StyleNode victim); // sets victim.ownerLayoutManager = this;
    // assert: victim hasn't been take()n yet during this layout
    // assert: victim.needsLayout == true
    // assert: an ancestor of victim has node.layoutManager == this (aka, victim is a descendant of this.node)

  virtual void release(StyleNode victim);
    // called when the StyleNode was removed from the tree

  void setChildPosition(child, x, y); // sets child.x, child.y
  void setChildX(child, y); // sets child.x
  void setChildY(child, y); // sets child.y
  void setChildSize(child, width, height); // sets child.width, child.height
  void setChildWidth(child, width); // sets child.width
  void setChildHeight(child, height); // sets child.height
    // for setChildSize/Width/Height: if the new dimension is different than the last assumed dimensions, and
    // any StyleNodes with an ownerLayoutManager==this have cached values for getProperty() that are marked
    // as provisional, clear them

  Generator<StyleNode> walkChildren();
    // returns a generator that iterates over the children, skipping any whose ownerLayoutManager is not |this|

  Generator<StyleNode> walkChildrenBackwards();
    // returns a generator that iterates over the children backwards, skipping any whose ownerLayoutManager is not |this|

  void assumeDimensions(Float width, Float height);
    // sets the assumed dimensions for calls to getProperty() on StyleNodes that have this as an ownerLayoutManager
    // if the new dimension is different than the last assumed dimensions, and any StyleNodes with an
    // ownerLayoutManager==this have cached values for getProperty() that are marked as provisional, clear them
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
  virtual Dimensions layout(Number? width, Number? height);
    // call markAsLaidOut();
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

  virtual void layoutChildren(Number width, Number height);
    // default implementation does nothing
    // - override this if you want to lay out children but not have the children affect your dimensions

  virtual void paint(RenderingSurface canvas);
    // set a clip rect on the canvas for rect(0,0,this.width,this.height)
    // call the painter of each property, in order they were registered, which on this element has a painter
    // call this.paintChildren(canvas)
    // (the default implementation doesn't paint anything on top of the children)
    // unset the clip
    // - this gets called by the system if:
    //    - you are in your parent's current display list and it's in its parent's and so on up to the top, and
    //    - you haven't had paint() called since the last time you were dirtied
    // - the following things make you dirty:
    //    - dimensions of your style node changed
    //    - one of your properties with needsLayout or needsPaint changed

  virtual void paintChildren(RenderingSurface canvas);
    // for each child returned by walkChildren():
    //   if child bounds intersects our bounds:
    //     call canvas.paintChild(child);
    // - you should skip children that will be clipped out of yourself because they're outside your bounds
    // - if you transform the canvas, you'll have to implement your own version of paintChildren() so
    //   that you don't skip the children that are visible in the new coordinate space but wouldn't be
    //   without the transform

  virtual Node hitTest(Float x, Float y);
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

```javascript
callback void Painter (StyleNode node, RenderingSurface canvas);

class RenderingSurface {

  // ... (API similar to <canvas>'s 2D API)

  void paintChild(StyleNode node);
    // inserts a "paint this child" instruction in this canvas's display list.
    // the child's display list, transformed by the child's x and y coordinates, will be inserted into this
    // display list during painting.
}
```


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
  These all add to themselves the same declaration with value:
```javascript
{ display: { value: null } }
```

* ``img``
  This adds to itself the declaration with value:
```javascript
{ display: { value: sky.ImageElementLayoutManager } }
```

* ``span``
* ``a``
  These all add to themselves the same declaration with value:
```javascript
{ display: { value: sky.InlineLayoutManager } }
```

* ``iframe``
  This adds to itself the declaration with value:
```javascript
{ display: { value: sky.IFrameElementLayoutManager } }
```

* ``t``
  This adds to itself the declaration with value:
```javascript
{ display: { value: sky.ParagraphLayoutManager } }
```

* ``error``
  This adds to itself the declaration with value:
```javascript
{ display: { value: sky.ErrorLayoutManager } }
```

The ``div`` element doesn't have any default styles.

These declarations are all shared between all the elements (so e.g. if
you reach in and change the declaration that was added to a ``title``
element, you're going to change the styles of all the other
default-hidden elements).
