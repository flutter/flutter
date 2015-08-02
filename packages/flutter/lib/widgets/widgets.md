Sky Widgets: Basic
==================

This document describes the basic widgets available in Sky. These widgets are
general-purpose and don't offer an opinion about the visual style of your app.

Container
---------

`Container` is a general-purpose widget that combines several basic widgets in
order to make them easier to use.

 - `BoxDecoration decoration` Draw the given decoration around this container.
 - `double width` Forces the container to have the given width.
 - `double height` Force the container to have the given height.
 - `EdgeDims margin` Surrounds the container (i.e., outside the container's
    decoration) on the top, right, bottom, and left with the given amount of
    space.
 - `EdgeDims padding` Surrounds the container's child (i.e., inside the
    container's decoration) on the top, right, bottom, and left with the given
    amount of space.
 - `Matrix4 transform` Apply the given matrix before painting the container.
 - `BoxConstraints constraints` Force the width and height of the container to
    respect the given constraints.

Layout models
-------------

 - `Flex` Layout a list of child widgets in either the horizontal or vertical
   `direction`. The direction along which the widgets are laid out is called the
   *main* direction and the other axis is called the *cross* direction. A `Flex`
   widget sizes itself to the maximum size permitted by its parent.

   Each child of a `Flex` widget is either *flexible* or *inflexible*. The flex
   first lays out its inflexible children and subtracts their total length along
   the main direction to determine how much free space is available. The flex
   then divides this free space among the flexible children in a ratio
   determined by their `flex` properties.

   The `alignItems` property determines how children are positioned in the cross
   direction. The `justifyContent` property determines how the remaining free
   space (if any) in the main direction is allocated.

   - `Flexible` Mark this child as being flexible with the given `flex` ratio.

 - `Stack` Layout a list of child widgets on top of each other from back to
   front. Each child of a `Stack` widget is either *positioned* or
   *non-positioned*. The stack sizes itself to the contain all the
   non-positioned children, which are located at the top-left corner of the
   stack. The *positioned* children are then located relative to the stack
   according to their `top`, `right`, `bottom`, and `left` properties.

    - `Positioned` Mark this child as *positioned*. If the `top` property is
      non-null, the top edge of this child will be positioned `top` layout units
      from the top of the stack widget. The `right`, `bottom`, and `right`
      properties work analogously. Note that if the both the `top` and `bottom`
      properties are non-null, then the child will be forced to have exactly the
      height required to satisfy both constraints. Similarly, setting the
      `right` and `left` properties to non-null values will force the child to
      have a particular width.

 - `Block` Layout a list of child widgets in a vertical line. Each child's width
   is set to the widget of the block, and each child is positioned directly
   below the previous child. The block's height is set to the total height of
   all of its children. A block can be used only in locations that offer an
   unbounded amount of vertical space (e.g., inside a `Viewport`). Rather than
   using `Block` directly, most client should use `ScrollableBlock`, which
   combines `Block` with `Viewport` and scrolling physics.

Positioning and sizing
----------------------

 - `Padding` Surround the child with empty space on the top, right, bottom, and
   left according to the given `EdgeDims`.

 - `Center` Center the child widget within the space occupied by this widget.

 - `SizedBox` Force the child widget to have a particular `width` or `height`
   (or both).

 - `ConstrainedBox` Apply the given `BoxConstraints` to the child widget as
   additional constraints during layout. This widget is a generalization of
   `SizedBox`.

 - `AspectRatio` Force the child widget's width and height to have the given
   `aspectRatio`, expressed as a ratio of width to height.

 - `Transform` Apply the given matrix to the child before painting the child.
   This widget is useful for adjusting the visual size and position of a widget
   without affecting layout.

 - `Viewport` Layout the child widget at a larger size than fits in this widget
   and render only the portion of the child that is visually contained by this
   widget. When rendering, add `offset` to the child's vertical position to
   control which part of the child is visible through the viewport.
   TODO(abarth): Add support for horizontal viewporting.

 - `SizeObserver` Whenever the child widget changes size, this widget calls the
   `callback`. Warning: If the callback changes state that affects the size of
   the child widget, it is possible to create an infinite loop.

 - `ShrinkWrapWidth` Force the child widget to have a width equal to its max
   intrinsic width. TODO(abarth): Add a link to the definition of max intrinsic
   width. Optionally, round up the child widget's width or height (or both) to
   a multiple of `stepWidth` or `stepHeight`, respectively. Note: The layout
   performed by `ShrinkWrapWidth` is relatively expensive and should be used
   sparingly.

 - `Baseline` If the child widget has a `TextBaseline` of the given
   `baselineType`, position the child such that its baseline is at `baseline`
   layout units from the top of this widget.

Painting effects
----------------

 - `Opacity` Adjusts the opacity of the child widget, making the child partially
   transparent. The amount of transparency is controlled by `opacity`, with 0.0
   0.0 is fully transparent and 1.0 is fully opaque.

 - `ClipRect` Apply a rectangular clip to the child widget. The dimensions of
   the clip match the dimensions of the child.

 - `ClipRRect` Apply a rounded-rect clip the child widget. The bounds of the
   clip match the bounds of the child widget with `xRadius` and `yRadius`
   controlling the x and y radius of the rounded corner, respectively.

 - `ClipOval` Apply an oval clip to the child widget. The oval will be
   axis-aligned, with its horizontal and vertical bounds matching the bounds of
   the child widget.

 - `DecoratedBox` Draw the given `BoxDecoration` surrounding the child widget.

 - `ColorFilter` Applies a color filter to the child widget, for example to
   tint the child a given color.

 - `CustomPaint` Calls `callback` during the paint phase with the current
   `Canvas` and `Size`. The widget occupies the region of the canvas starting at
   the origin (i.e., `x = 0.0` and `y = 0.0`) and of the given size (i.e.,
   `x = size.width` and `y = size.height`).

   Use the `token` to invalidate the painting. As long as the any new `token`
   is `operator==` the current `token`, the `CustomPaint` widget is permitted
   to retain a recording of the painting produced by the previous `callback`
   call.
