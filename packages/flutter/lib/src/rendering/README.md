Flutter Rendering Layer
=======================

This document is intended to describe some of the core designs of the
Flutter rendering layer.

Layout
------

Paint
-----

Compositing
-----------

Semantics
---------

The last phase of a frame is the Semantics phase. This only occurs if
a semantics server has been installed, for example if the user is
using an accessibility tool.

Each frame, the semantics phase starts with a call to the
`PipelineOwner.flushSemantics()` method from the `Renderer` binding's
`beginFrame()` method.

Each node marked as needing semantics (which initially is just the
root node, as scheduled by `scheduleInitialSemantics()`), in depth
order, has its semantics updated by calling `_updateSemantics()`.

The `_updateSemantics()` method calls `_getSemantics()` to obtain an
`_InterestingSemanticsFragment`, and then calls `compile()` on that
fragment to obtain a `SemanticsNode` which becomes the value of the
`RenderObject`'s `_semantics` field. **This is essentially a two-pass
walk of the render tree. The first pass determines the shape of the
output tree, and the second creates the nodes of this tree and hooks
them together.** The second walk is a sparse walk; it only walks the
nodes that are interesting for the purpose of semantics.

`_getSemantics()` is the core function that walks the render tree to
obtain the semantics. It collects semantic annotators for this
`RenderObject`, then walks its children collecting
`_SemanticsFragment`s for them, and then returns an appropriate
`_SemanticsFragment` object that describes the `RenderObject`'s
semantics.

Semantic annotators are functions that, given a `SemanticsNode`, set
some flags or strings on the object. They are obtained from
`getSemanticsAnnotators()`. For example, here is how `RenderParagraph`
annotates the `SemanticsNode` with its text:

```dart
  Iterable<SemanticsAnnotator> getSemanticsAnnotators() sync* {
    yield (SemanticsNode node) {
      node.label = text.toPlainText();
    };
  }
```

A `_SemanticsFragment` object is a node in a short-lived tree which is
used to create the final `SemanticsNode` tree that is sent to the
semantics server. These objects have a list of semantic annotators,
and a list of `_SemanticsFragment` children.

There are several `_SemanticsFragment` classes. The `_getSemantics()`
method picks its return value as follows:

* `_CleanSemanticsFragment` is used to represent a `RenderObject` that
  has a `SemanticsNode` and which is in no way dirty. This class has
  no children and no annotators, and when compiled, it returns the
  `SemanticsNode` that the `RenderObject` already has.

* `_RootSemanticsFragment`* is used to represent the `RenderObject`
  found at the top of the render tree. This class always compiles to a
  `SemanticsNode` with ID 0.

* `_ConcreteSemanticsFragment`* is used to represent a `RenderObject`
  that has `hasSemantics` set to true. It returns the `SemanticsNode`
  for that `RenderObject`.

* `_ImplicitSemanticsFragment`* is used to represent a `RenderObject`
  that does not have `hasSemantics` set to true, but which does have
  some semantic annotators. When it is compiled, if the nearest
  ancestor `_SemanticsFragment` that isn't also an
  `_ImplicitSemanticsFragment` is a `_RootSemanticsFragment` or a
  `_ConcreteSemanticsFragment`, then the `SemanticsNode` from that
  object is reused. Otherwise, a new one is created.

* `_ForkingSemanticsFragment` is used to represent a `RenderObject`
  that introduces no semantics of its own, but which has two or more
  descendants that do introduce semantics (and which are not ancestors
  or descendants of each other).

* For `RenderObject` nodes that introduce no semantics but which have
  a (single) child that does, the `_SemanticsFragment` of the child is
  returned.

* For `RenderObject` nodes that introduce no semantics and have no
  descendants that introduce semantics, `null` is returned.

The classes marked with an asterisk * above are the
`_InterestingSemanticsFragment` classes.

When the `_SemanticsFragment` tree is then compiled, the
`SemanticsNode` objects are created (if necessary), the semantic
annotators are run on each `SemanticsNode`, the geometry (matrix,
size, and clip) is applied, and the children are updated.

As part of this, the code clears out the `_semantics` field of any
`RenderObject` that previously had a `SemanticsNode` but no longer
does. This is done as part of the first walk where possible, and as
part of the second otherwise.
