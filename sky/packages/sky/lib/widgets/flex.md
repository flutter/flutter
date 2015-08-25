How To Use Flex In Sky
======================

Background
----------

In Sky, widgets are rendered by render boxes. Render boxes are given
constraints by their parent, and size themselves within those
constraints. Constraints consist of minimum and maximum widths and
heights; sizes consist of a specific width and height.

Generally, there are three kinds of boxes, in terms of how they handle
their constraints:

- Those that try to be as big as possible.
  For example, the boxes used by `Center` and `Block`.
- Those that try to be the same size as their children.
  For example, the boxes used by `Transform` and `Opacity`.
- Those that try to be a particular size.
  For example, the boxes used by `Image` and `Text`.

Some widgets, for example `Container`, vary from type to type based on
their constructor arguments. In the case of `Container`, it defaults
to trying to be as big as possible, but if you give it a `width`, for
instance, it tries to honor that and be that particular size.

The constraints are sometimes "tight", meaning that they leave no room
for the render box to decide on a size (e.g. if the minimum and
maximum width are the same, it is said to have a tight width). The
main example of this is the `App` widget, which is contained by the
`RenderView` class: the box used by the child returned by the
application's `build` function is given a constraint that forces it to
exactly fill the application's content area (typically, the entire
screen).

Unbounded constraints
---------------------

In certain situations, the constraint that is given to a box will be
_unbounded_, or infinite. This means that either the maximum width or
the maximum height is set to `double.INFINITY`.

A box that tries to be as big as possible won't function usefully when
given an unbounded constraint, and in checked mode, will assert.

The most common cases where a render box finds itself with unbounded
constraints are within flex boxes (`Row` and `Column`), and **within
scrollable regions** (mainly `Block`, `ScollableList<T>`, and
`ScrollableMixedWidgetList`).

Flex
----

Flex boxes themselves (`Row` and `Column`) behave differently based on
whether they are in a bounded constraints or unbounded constraints in
their given direction.

In bounded constraints, they try to be as big as possible in that
direction.

In unbounded constraints, they try to fit their children in that
direction. In this case, you cannot set `flex` on the children to
anything other than 0 (the default). In the widget hierarchy, this
means that you cannot use `Flexible` when the flex box is inside
another flex box or inside a scrollable.

In the _cross_ direction, i.e. in their width for `Column` (vertical
flex) and in their height for `Row` (horizontal flex), they must never
be unbounded, otherwise they would not be able to reasonably align
their children.
