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

### Box Model

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

#### The ParentData contract

#### Using RenderObjectWithChildMixin

#### Using ContainerParentDataMixin and ContainerRenderObjectMixin

### The RenderBox contract

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
