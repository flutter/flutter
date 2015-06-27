Sky Rendering
=============

The Sky render tree is a low-level layout and painting system based on a
retained tree of objects that inherit from [`RenderObject`](object.dart). Most
developers using Sky will not need to interact directly with the rendering tree.
Instead, most developers should use [Sky widgets](../widgets/README.md), which
are built using the render tree.

Overview
--------

### Base Model

The base class for every node in the render tree is
[`RenderObject`](object.dart), which defines the base layout model. The base
layout mode is extremely general and can accomodate a large number of more
concrete layout models that can co-exist in the same tree. For example, the base
model does not commit to a fixed number of dimensions or even a cartesian
coordinate system. In this way, a single render tree can contain render objects
operating in three-dimensional space together with other render objects
operating in two-dimensional space, e.g., on the face of a cube in the three-
dimensional space. Moreover, the two-dimensional layout might be partially
computed in cartesian coordinates and partially computed in polar coordinates.
These distinct models can interact during layout, for example determining the
size of the cube by the height of a block of text on the cube's face.

Not entirely free-wheeling, the base model does impose some structure on the
render tree:

 * Subclasses of `RenderObject` must implement a `performLayout` function that
   takes as input a `constraints` object provided by its parent. `RenderObject`
   has no opinion about the structure of this object and different layout models
   use different types of constraints. However, whatever type they choose must
   implement `operator==` in such a way that `performLayout` produces the same
   output for two `constraints` objects that are `operator==`.

 * Implementations of `performLayout` are expected to call `layout` on their
   children. When calling `layout`, a `RenderObject` must use the
   `parentUsesSize` parameter to declare whether its `performLayout` function
   depends on information read from the child. If the parent doesn't declare
   that it uses the child's size, the edge from the parent to the child becomes
   a _relayout boundary_, which means the child (and its subtree) might undergo
   layout without the parent undergoing layout.

 * Subclasses of `RenderObject` must implement a `paint` function that draws a
   visual representation of the object onto a `RenderCanvas`. If
   the `RenderObject` has children, the `RenderObject` is responsible for
   painting its children using the `paintChild` function on the `RenderCanvas`.

 * Subclasses of `RenderObject` must call `adoptChild` whenever they add a
   child. Similarly, they must call `dropChild` whenever they remove a child.

 * Most subclasses of `RenderObject` will implement a `hitTest` function that
   lets clients query the render tree for objects that intersect with a given
   user input location. `RenderObject` itself does not impose a particular
   type signature on `hitTest`, but most implementations will take an argument
   of type `HitTestResult` (or, more likely, a model-specific subclass of
   `HitTestResult`) as well as an object that describes the location at which
   the user provided input (e.g., a `Point` for a two-dimensional cartesian
   model).

 * Finally, subclasses of `RenderObject` can override the default, do-nothing
   implemenations of `handleEvent` and `rotate` to respond to user input and
   screen rotation, respectively.

The base model also provides two mixins for common child models:

 * `RenderObjectWithChildMixin` is useful for subclasses of `RenderObject` that
   have a unique child.

 * `ContainerRenderObjectMixin` is useful for subclasses of `RenderObject` that
   have a child list.

Subclasses of `RenderObject` are not required to use either of these child
models and are free to invent novel child models for their specific use cases.

### Parent Data

TODO(ianh): Describe the parent data concept.

The `setupParentData()` method is automatically called for each child
when the child's parent is changed. However, if you need to
preinitialise the `parentData` member to set its values before you add
a node to its parent, you can preemptively call that future parent's
`setupParentData()` method with the future child as the argument.

TODO(ianh): Discuss putting per-child configuration information for
the parent on the child's parentData.

If you change a child's parentData dynamically, you must also call
markNeedsLayout() on the parent, otherwise the new information will
not take effect until something else triggers a layout.

### Box Model

#### Dimensions

All dimensions are expressed as logical pixel units. Font sizes are
also in logical pixel units. Logical pixel units are approximately
96dpi, but the precise value varies based on the hardware, in such a
way as to optimise for performance and rendering quality while keeping
interfaces roughly the same size across devices regardless of the
hardware pixel density.

Logical pixel units are automatically converted to device (hardware)
pixels when painting by applying an appropriate scale factor.

TODO(ianh): Define how you actually get the device pixel ratio if you
need it, and document best practices around that.

#### EdgeDims

#### BoxConstraints

### Bespoke Models


Using the provided subclasses
-----------------------------

### render_box.dart
#### RenderConstrainedBox
#### RenderShrinkWrapWidth
#### RenderOpacity
#### RenderColorFilter
#### RenderClipRect
#### RenderClipOval
#### RenderPadding
#### RenderPositionedBox
#### RenderImage
#### RenderDecoratedBox
#### RenderTransform
#### RenderSizeObserver
#### RenderCustomPaint
### RenderBlock (render_block.dart)
### RenderFlex (render_flex.dart)
### RenderParagraph (render_paragraph.dart)
### RenderStack (render_stack.dart)

Writing new subclasses
----------------------

### The RenderObject contract

If you want to define a `RenderObject` that uses a new coordinate
system, then you should inherit straight from `RenderObject`. Examples
of doing this can be found in [`RenderBox`](box.dart), which deals in
rectangles in cartesian space, and in the [sector_layout.dart
example](../../example/rendering/sector_layout.dart), which
implements a toy model based on polar coordinates. The `RenderView`
class, which is used internally to adapt from the host system to this
rendering framework, is another example.

A subclass of `RenderObject` must fulfill the following contract:

* It must fulfill the [AbstractNode contract](../base/README.md) when
  dealing with children. Using `RenderObjectWithChildMixin` or
  `ContainerRenderObjectMixin` can make this easier.

* Information about the child managed by the parent, e.g. typically
  position information and configuration for the parent's layout,
  should be stored on the `parentData` member; to this effect, a
  ParentData subclass should be defined and the `setupParentData()`
  method should be overriden to initialise the child's parent data
  appropriately.

* Layout constraints must be expressed in a Constraints subclass. This
  subclass must implement `operator==` (and `hashCode`).

* Whenever the layout needs updating, the `markNeedsLayout()` method
  should be called.

* Whenever the rendering needs updating without changing the layout,
  the `markNeedsPaint()` method should be called. (Calling
  `markNeedsLayout()` implies a call to `markNeedsPaint()`, so you
  don't need to call both.)

* The subclass must override `performLayout()` to perform layout based
  on the constraints given in the `constraints` member. Each object is
  responsible for sizing itself; positioning must be done by the
  object calling `performLayout()`. Whether positioning is done before
  or after the child's layout is a decision to be made by the class.
  TODO(ianh): Document sizedByParent, performResize(), rotate

* TODO(ianh): Document painting, hit testing, debug*

#### The ParentData contract

#### Using RenderObjectWithChildMixin

#### Using ContainerRenderObjectMixin (and ContainerParentDataMixin)

This mixin can be used for classes that have a child list, to manage
the list. It implements the list using linked list pointers in the
`parentData` structure.

TODO(ianh): Document this mixin.

Subclasses must follow the following contract, in addition to the
contracts of any other classes they subclass:

* If the constructor takes a list of children, it must call addAll()
  with that list.

TODO(ianh): Document how to walk the children.

### The RenderBox contract

A `RenderBox` subclass is required to implement the following contract:

* It must fulfill the [AbstractNode contract](../base/README.md) when
  dealing with children. Note that using `RenderObjectWithChildMixin`
  or `ContainerRenderObjectMixin` takes care of this for you, assuming
  you fulfill their contract instead.

* If it has any data to store on its children, it must define a
  BoxParentData subclass and override setupParentData() to initialise
  the child's parent data appropriately, as in the following example.
  (If the subclass has an opinion about what type its children must
  be, e.g. the way that `RenderBlock` wants its children to be
  `RenderBox` nodes, then change the `setupParentData()` signature
  accordingly, to catch misuse of the method.)

```dart
  class FooParentData extends BoxParentData { ... }

  // In RenderFoo
  void setupParentData(RenderObject child) {
    if (child.parentData is! FooParentData)
      child.parentData = new FooParentData();
  }
```

* The class must encapsulate a layout algorithm that has the following
  features:

** It uses as input a set of constraints, described by a
   BoxConstraints object, and a set of zero or more children, as
   determined by the class itself, and has as output a Size (which is
   set on the object's own `size` field), and positions for each child
   (which are set on the children's `parentData.position` field).

** The algorithm can decide the Size in one of two ways: either
   exclusively based on the given constraints (i.e. it is effectively
   sized entirely by its parent), or based on those constraints and
   the dimensions of the children.

   In the former case, the class must have a sizedByParent getter that
   returns true, and it must have a `performResize()` method that uses
   the object's `constraints` member to size itself by setting the
   `size` member. The size must be consistent, a given set of
   constraints must always result in the same size.

   In the latter case, it will inherit the default `sizedByParent`
   getter that returns false, and it will size itself in the
   `performLayout()` function described below.

   The `sizedByParent` distinction is purely a performance
   optimisation. It allows nodes that only set their size based on the
   incoming constraints to skip that logic when they need to be
   re-laid-out, and, more importantly, it allows the layout system to
   treat the node as a _layout boundary_, which reduces the amount of
   work that needs to happen when the node is marked as needing
   layout.

* The following methods must report numbers consistent with the output
  of the layout algorithm used:

** `double getMinIntrinsicWidth(BoxConstraints constraints)` must
   return the width that fits within the given constraints below which
   making the width constraint smaller would not increase the
   resulting height, or, to put it another way, the narrowest width at
   which the box can be rendered without failing to lay the children
   out within itself.

   For example, the minimum intrinsic width of a piece of text like "a
   b cd e", where the text is allowed to wrap at spaces, would be the
   width of "cd".

** `double getMaxIntrinsicWidth(BoxConstraints constraints)` must
   return the width that fits within the given constraints above which
   making the width constraint larger would not decrease the resulting
   height.

   For example, the maximum intrinsic width of a piece of text like "a
   b cd e", where the text is allowed to wrap at spaces, would be the
   width of the whole "a b cd e" string, with no wrapping.

** `double getMinIntrinsicHeight(BoxConstraints constraints)` must
   return the height that fits within the given constraints below
   which making the height constraint smaller would not increase the
   resulting width, or, to put it another way, the shortest height at
   which the box can be rendered without failing to lay the children
   out within itself.

   The minimum intrinsic height of a width-in-height-out algorithm,
   like English text layout, would be the height of the text at the
   width that would be used given the constraints. So for instance,
   given the text "hello world", if the constraints were such that it
   had to wrap at the space, then the minimum intrinsic height would
   be the height of two lines (and the appropriate line spacing). If
   the constraints were such that it all fit on one line, then it
   would be the height of one line.

** `double getMaxIntrinsicHeight(BoxConstraints constraints)` must
   return the height that fits within the given constraints above
   which making the height constraint larger would not decrease the
   resulting width. If the height depends exclusively on the width,
   and the width does not depend on the height, then
   `getMinIntrinsicHeight()` and `getMaxIntrinsicHeight()` will return the
   same number given the same constraints.

   In the case of English text, the maximum intrinsic height is the
   same as the minimum instrinsic height.

* The box must have a `performLayout()` method that encapsulates the
  layout algorithm that this class represents. It is responsible for
  telling the children to lay out, positioning the children, and, if
  sizedByParent is false, sizing the object.

  Specifically, the method must walk over the object's children, if
  any, and for each one call `child.layout()` with a BoxConstraints
  object as the first argument, and a second argument named
  `parentUsesSize` which is set to true if the child's resulting size
  will in any way influence the layout, and omitted (or set to false)
  if the child's resulting size is ignored. The children's positions
  (`child.parentData.position`) must then be set.

  (Calling `layout()` can result in the child's own `performLayout()`
  method being called recursively, if the child also needs to be laid
  out. If the child's constraints haven't changed and the child is not
  marked as needing layout, however, this will be skipped.)

  The parent must not set a child's `size` directly. If the parent
  wants to influence the child's size, it must do so via the
  constraints that it passes to the child's `layout()` method.

  If an object's `sizedByParent` is false, then its `performLayout()`
  must also size the object (by setting `size`), otherwise, the size
  must be left untouched.

* The `size` member must never be set to an infinite value.

* The box must also implement `hitTestChildren()`.
  TODO(ianh): Define this better

* The box must also implement `paint()`.
  TODO(ianh): Define this better

#### Using RenderProxyBox

### The Hit Testing contract


Performance rules of thumb
--------------------------

* Avoid using transforms where mere maths would be sufficient (e.g.
  draw your rectangle at x,y rather than translating by x,y and
  drawing it at 0,0).

* Avoid using save/restore on canvases.


Dependencies
------------

 * [`package:sky/base`](../base)
 * [`package:sky/mojo`](../mojo)
 * [`package:sky/animation`](../mojo)
