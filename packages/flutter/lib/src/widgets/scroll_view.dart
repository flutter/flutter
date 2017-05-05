// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'primary_scroll_controller.dart';
import 'scroll_controller.dart';
import 'scroll_physics.dart';
import 'scrollable.dart';
import 'sliver.dart';
import 'viewport.dart';

/// A widget that scrolls.
///
/// Scrollable widgets consist of three pieces:
///
///  1. A [Scrollable] widget, which listens for various user gestures and
///     implements the interaction design for scrolling.
///  2. A viewport widget, such as [Viewport] or [ShrinkWrappingViewport], which
///     implements the visual design for scrolling by displaying only a portion
///     of the widgets inside the scroll view.
///  3. One or more slivers, which are widgets that can be composed to created
///     various scrolling effects, such as lists, grids, and expanding headers.
///
/// [ScrollView] helps orchestrate these pieces by creating the [Scrollable] and
/// the viewport and defering to its subclass to create the slivers.
///
/// See also:
///
///  * [ListView], which is a commonly used [ScrollView] that displays a
///    scrolling, linear list of child widgets.
///  * [PageView], which is a scrolling list of child widgets that are each the
///    size of the viewport.
///  * [GridView], which is a [ScrollView] that displays a scrolling, 2D array
///    of child widgets.
///  * [CustomScrollView], which is a [ScrollView] that creates custom scroll
///    effects using slivers.
abstract class ScrollView extends StatelessWidget {
  /// Creates a widget that scrolls.
  ///
  /// If the [primary] argument is true, the [controller] must be null.
  ScrollView({
    Key key,
    this.scrollDirection: Axis.vertical,
    this.reverse: false,
    this.controller,
    bool primary,
    ScrollPhysics physics,
    this.shrinkWrap: false,
  }) : primary = primary ?? controller == null && scrollDirection == Axis.vertical,
       physics = physics ?? (primary == true || (primary == null && controller == null && scrollDirection == Axis.vertical) ? const AlwaysScrollableScrollPhysics() : null),
       super(key: key) {
    assert(reverse != null);
    assert(shrinkWrap != null);
    assert(this.primary != null);
    assert(controller == null || !this.primary,
           'Primary ScrollViews obtain their ScrollController via inheritance from a PrimaryScrollController widget. '
           'You cannot both set primary to true and pass an explicit controller.'
    );
  }

  /// The axis along which the scroll view scrolls.
  ///
  /// Defaults to [Axis.vertical].
  final Axis scrollDirection;

  /// Whether the scroll view scrolls in the reading direction.
  ///
  /// For example, if the reading direction is left-to-right and
  /// [scrollDirection] is [Axis.horizontal], then the scroll view scrolls from
  /// left to right when [reverse] is false and from right to left when
  /// [reverse] is true.
  ///
  /// Similarly, if [scrollDirection] is [Axis.vertical], then the scroll view
  /// scrolls from top to bottom when [reverse] is false and from bottom to top
  /// when [reverse] is true.
  ///
  /// Defaults to false.
  final bool reverse;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  ///
  /// Must be null if [primary] is true.
  final ScrollController controller;

  /// Whether this is the primary scroll view associated with the parent
  /// [PrimaryScrollController].
  ///
  /// When this is true, the scroll view is scrollable even if it does not have
  /// sufficient content to actually scroll. Otherwise, by default the user can
  /// only scroll the view if it has sufficient content. See [physics].
  ///
  /// On iOS, this also identifies the scroll view that will scroll to top in
  /// response to a tap in the status bar.
  ///
  /// Defaults to true when [scrollDirection] is [Axis.vertical] and
  /// [controller] is null.
  final bool primary;

  /// How the scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to matching platform conventions. Furthermore, if [primary] is
  /// false, then the user cannot scroll if there is insufficient content to
  /// scroll, while if [primary] is true, they can always attempt to scroll.
  ///
  /// To force the scroll view to always be scrollable even if there is
  /// insufficient content, as if [primary] was true but without necessarily
  /// setting it to true, provide an [AlwaysScrollableScrollPhysics] physics
  /// object, as in:
  ///
  /// ```dart
  ///   physics: const AlwaysScrollableScrollPhysics(),
  /// ```
  ///
  /// To force the scroll view to use the default platform conventions and not
  /// be scrollable if there is insufficient content, regardless of the value of
  /// [primary], provide an explicit [ScrollPhysics] object, as in:
  ///
  /// ```dart
  ///   physics: const ScrollPhysics(),
  /// ```
  ///
  /// The physics can be changed dynamically (by providing a new object in a
  /// subsequent build), but new physics will only take effect if the _class_ of
  /// the provided object changes. Merely constructing a new instance with a
  /// different configuration is insufficient to cause the physics to be
  /// reapplied. (This is because the final object used is generated
  /// dynamically, which can be relatively expensive, and it would be
  /// inefficient to speculatively create this object each frame to see if the
  /// physics should be updated.)
  final ScrollPhysics physics;

  /// Whether the extent of the scroll view in the [scrollDirection] should be
  /// determined by the contents being viewed.
  ///
  /// If the scroll view does not shrink wrap, then the scroll view will expand
  /// to the maximum allowed size in the [scrollDirection]. If the scroll view
  /// has unbounded constraints in the [scrollDirection], then [shrinkWrap] must
  /// be true.
  ///
  /// Shrink wrapping the content of the scroll view is significantly more
  /// expensive than expanding to the maximum allowed size because the content
  /// can expand and contract during scrolling, which means the size of the
  /// scroll view needs to be recomputed whenever the scroll position changes.
  ///
  /// Defaults to false.
  final bool shrinkWrap;

  /// Returns the [AxisDirection] in which the scroll view scrolls.
  ///
  /// Combines the [scrollDirection] with the [reverse] boolean to obtain the
  /// concrete [AxisDirection].
  ///
  /// In the future, this function will also consider the reading direction.
  @protected
  AxisDirection getDirection(BuildContext context) {
    // TODO(abarth): Consider reading direction.
    switch (scrollDirection) {
      case Axis.horizontal:
        return reverse ? AxisDirection.left : AxisDirection.right;
      case Axis.vertical:
        return reverse ? AxisDirection.up : AxisDirection.down;
    }
    return null;
  }

  /// Subclasses should override this method to build the slivers for the inside
  /// of the viewport.
  @protected
  List<Widget> buildSlivers(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final List<Widget> slivers = buildSlivers(context);
    final AxisDirection axisDirection = getDirection(context);

    final ScrollController scrollController = primary
        ? PrimaryScrollController.of(context)
        : controller;
    final Scrollable scrollable = new Scrollable(
      axisDirection: axisDirection,
      controller: scrollController,
      physics: physics,
      viewportBuilder: (BuildContext context, ViewportOffset offset) {
        if (shrinkWrap) {
          return new ShrinkWrappingViewport(
            axisDirection: axisDirection,
            offset: offset,
            slivers: slivers,
          );
        } else {
          return new Viewport(
            axisDirection: axisDirection,
            offset: offset,
            slivers: slivers,
          );
        }
      }
    );
    return primary && scrollController != null
      ? new PrimaryScrollController.none(child: scrollable)
      : scrollable;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$scrollDirection');
    if (reverse)
      description.add('reversed');
    if (controller != null)
      description.add('$controller');
    if (primary)
      description.add('using primary controller');
    if (physics != null)
      description.add('$physics');
    if (shrinkWrap)
      description.add('shrink-wrapping');
  }
}

/// A [ScrollView] that creates custom scroll effects using slivers.
///
/// A [CustomScrollView] lets you supply [slivers] directly to create various
/// scrolling effects, such as lists, grids, and expanding headers. For example,
/// to create a scroll view that contains an expanding app bar followed by a
/// list and a grid, use a list of three slivers: [SliverAppBar], [SliverList],
/// and [SliverGrid].
///
/// See also:
///
///  * [SliverList], which is a sliver that displays linear list of children.
///  * [SliverFixedExtentList], which is a more efficient sliver that displays
///    linear list of children that have the same extent along the scroll axis.
///  * [SliverGrid], which is a sliver that displays a 2D array of children.
///  * [SliverPadding], which is a sliver that adds blank space around another
///    sliver.
///  * [SliverAppBar], which is a sliver that displays a header that can expand
///    and float as the scroll view scrolls.
class CustomScrollView extends ScrollView {
  /// Creates a [ScrollView] that creates custom scroll effects using slivers.
  ///
  /// If the [primary] argument is true, the [controller] must be null.
  CustomScrollView({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    this.slivers: const <Widget>[],
  }) : super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller,
    primary: primary,
    physics: physics,
    shrinkWrap: shrinkWrap,
  );

  /// The slivers to place inside the viewport.
  final List<Widget> slivers;

  @override
  List<Widget> buildSlivers(BuildContext context) => slivers;
}

/// A [ScrollView] uses a single child layout model.
///
/// See also:
///
///  * [ListView], which is a [BoxScrollView] that uses a linear layout model.
///  * [GridView], which is a [BoxScrollView] that uses a 2D layout model.
///  * [CustomScrollView], which can combine multiple child layout models into a
///    single scroll view.
abstract class BoxScrollView extends ScrollView {
  /// Creates a [ScrollView] uses a single child layout model.
  ///
  /// If the [primary] argument is true, the [controller] must be null.
  BoxScrollView({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    this.padding,
  }) : super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller,
    primary: primary,
    physics: physics,
    shrinkWrap: shrinkWrap,
  );

  /// The amount of space by which to inset the children.
  final EdgeInsets padding;

  @override
  List<Widget> buildSlivers(BuildContext context) {
    Widget sliver = buildChildLayout(context);
    if (padding != null)
      sliver = new SliverPadding(padding: padding, sliver: sliver);
    return <Widget>[ sliver ];
  }

  /// Subclasses should override this method to build the layout model.
  @protected
  Widget buildChildLayout(BuildContext context);

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (padding != null)
      description.add('padding: $padding');
  }
}

/// A scrollable, linear list of widgets.
///
/// [ListView] is the most commonly used scrolling widget. It displays its
/// children one after another in the scroll direction. In the cross axis, the
/// children are required to fill the [ListView].
///
/// If non-null, the [itemExtent] forces the children to have the given extent
/// in the scroll direction. Specifying an [itemExtent] is more efficient than
/// letting the children determine their own extent because the scrolling
/// machinery can make use of the foreknowledge of the children's extent to save
/// work, for example when the scroll position changes drastically.
///
/// There are three options for constructing a [ListView]:
///
///  1. The default constuctor takes an explict [List<Widget>] of children. This
///     constructor is appropriate for list views with a small number of
///     children because constructing the [List] requires doing work for every
///     child that could possibly be displayed in the list view instead of just
///     those children that are actually visible.
///
///  2. The [ListView.builder] takes an [IndexedWidgetBuilder], which builds the
///     children on demand. This constructor is appropriate for list views with
///     a large (or infinite) number of children because the builder is called
///     only for those children that are actually visible.
///
///  3. The [ListView.custom] takes a [SliverChildDelegate], which provides the
///     ability to customize additional aspects of the child model. For example,
///     a [SliverChildDelegate] can control the algorithm used to estimate the
///     size of children that are not actually visible.
///
/// See also:
///
///  * [SingleChildScrollView], which is a scrollable widget that has a single
///    child.
///  * [PageView], which is a scrolling list of child widgets that are each the
///    size of the viewport.
///  * [GridView], which is scrollable, 2D array of widgets.
///  * [CustomScrollView], which is a scrollable widget that creates custom
///    scroll effects using slivers.
class ListView extends BoxScrollView {
  /// Creates a scrollable, linear array of widgets from an explicit [List].
  ///
  /// This constructor is appropriate for list views with a small number of
  /// children because constructing the [List] requires doing work for every
  /// child that could possibly be displayed in the list view instead of just
  /// those children that are actually visible.
  ListView({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsets padding,
    this.itemExtent,
    List<Widget> children: const <Widget>[],
  }) : childrenDelegate = new SliverChildListDelegate(children), super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller,
    primary: primary,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  );

  /// Creates a scrollable, linear array of widgets that are created on demand.
  ///
  /// This constructor is appropriate for list views with a large (or infinite)
  /// number of children because the builder is called only for those children
  /// that are actually visible.
  ///
  /// Providing a non-null [itemCount] improves the ability of the [ListView] to
  /// estimate the maximum scroll extent.
  ///
  /// [itemBuilder] will be called only with indices greater than or equal to
  /// zero and less than [itemCount].
  ListView.builder({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsets padding,
    this.itemExtent,
    @required IndexedWidgetBuilder itemBuilder,
    int itemCount,
  }) : childrenDelegate = new SliverChildBuilderDelegate(itemBuilder, childCount: itemCount), super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller,
    primary: primary,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  );

  /// Creates a scrollable, linear array of widgets with a custom child model.
  ///
  /// For example, a custom child model can control the algorithm used to
  /// estimate the size of children that are not actually visible.
  ListView.custom({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsets padding,
    this.itemExtent,
    @required this.childrenDelegate,
  }) : super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller,
    primary: primary,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  ) {
    assert(childrenDelegate != null);
  }

  /// If non-null, forces the children to have the given extent in the scroll
  /// direction.
  ///
  /// Specifying an [itemExtent] is more efficient than letting the children
  /// determine their own extent because the scrolling machinery can make use of
  /// the foreknowledge of the children's extent to save work, for example when
  /// the scroll position changes drastically.
  final double itemExtent;

  /// A delegate that provides the children for the [ListView].
  ///
  /// The [ListView.custom] constructor lets you specify this delegate
  /// explicitly. The [ListView] and [ListView.builder] constructors create a
  /// [childrenDelegate] that wraps the given [List] and [IndexedWidgetBuilder],
  /// respectively.
  final SliverChildDelegate childrenDelegate;

  @override
  Widget buildChildLayout(BuildContext context) {
    if (itemExtent != null) {
      return new SliverFixedExtentList(
        delegate: childrenDelegate,
        itemExtent: itemExtent,
      );
    }
    return new SliverList(delegate: childrenDelegate);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (itemExtent != null)
      description.add('itemExtent: $itemExtent');
  }
}

/// A scrollable, 2D array of widgets.
///
/// The most commonly used grid layouts are [GridView.count], which creates a
/// layout with a fixed number of tiles in the cross axis, and
/// [GridView.extent], which creates a layout with tiles that have a maximum
/// cross-axis extent. A custom [SliverGridDelegate] can produce an aribtrary 2D
/// arrangement of children, including arrangements that are unaligned or
/// overlapping.
///
/// To create a grid with a large (or infinite) number of children, use the
/// [GridView.builder] constructor with either a
/// [SliverGridDelegateWithFixedCrossAxisCount] or a
/// [SliverGridDelegateWithMaxCrossAxisExtent] for the [gridDelegate].
///
/// To use a custom [SliverChildDelegate], use [GridView.custom].
///
/// To create a linear array of children, use a [ListView].
///
/// See also:
///
///  * [SingleChildScrollView], which is a scrollable widget that has a single
///    child.
///  * [ListView], which is scrollable, linear list of widgets.
///  * [PageView], which is a scrolling list of child widgets that are each the
///    size of the viewport.
///  * [CustomScrollView], which is a scrollable widget that creates custom
///    scroll effects using slivers.
///  * [SliverGridDelegateWithFixedCrossAxisCount], which creates a layout with
///    a fixed number of tiles in the cross axis.
///  * [SliverGridDelegateWithMaxCrossAxisExtent], which creates a layout with
///    tiles that have a maximum cross-axis extent.
class GridView extends BoxScrollView {
  /// Creates a scrollable, 2D array of widgets with a custom
  /// [SliverGridDelegate].
  ///
  /// The [gridDelegate] argument must not be null.
  GridView({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsets padding,
    @required this.gridDelegate,
    List<Widget> children: const <Widget>[],
  }) : childrenDelegate = new SliverChildListDelegate(children), super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller,
    primary: primary,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  ) {
    assert(gridDelegate != null);
  }

  /// Creates a scrollable, 2D array of widgets that are created on demand.
  ///
  /// This constructor is appropriate for grid views with a large (or infinite)
  /// number of children because the builder is called only for those children
  /// that are actually visible.
  ///
  /// Providing a non-null [itemCount] improves the ability of the [GridView] to
  /// estimate the maximum scroll extent.
  ///
  /// [itemBuilder] will be called only with indices greater than or equal to
  /// zero and less than [itemCount].
  ///
  /// The [gridDelegate] argument must not be null.
  GridView.builder({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsets padding,
    @required this.gridDelegate,
    @required IndexedWidgetBuilder itemBuilder,
    int itemCount,
  }) : childrenDelegate = new SliverChildBuilderDelegate(itemBuilder, childCount: itemCount), super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller,
    primary: primary,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  ) {
    assert(gridDelegate != null);
  }

  /// Creates a scrollable, 2D array of widgets with both a custom
  /// [SliverGridDelegate] and a custom [SliverChildDelegate].
  ///
  /// To use an [IndexedWidgetBuilder] callback to build children, either use
  /// a [SliverChildBuilderDelegate] or use the [GridView.builder] constructor.
  ///
  /// The [gridDelegate] and [childrenDelegate] arguments must not be null.
  GridView.custom({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsets padding,
    @required this.gridDelegate,
    @required this.childrenDelegate,
  }) : super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller,
    primary: primary,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  ) {
    assert(gridDelegate != null);
    assert(childrenDelegate != null);
  }

  /// Creates a scrollable, 2D array of widgets with a fixed number of tiles in
  /// the cross axis.
  ///
  /// Uses a [SliverGridDelegateWithFixedCrossAxisCount] as the [gridDelegate].
  GridView.count({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsets padding,
    @required int crossAxisCount,
    double mainAxisSpacing: 0.0,
    double crossAxisSpacing: 0.0,
    double childAspectRatio: 1.0,
    List<Widget> children: const <Widget>[],
  }) : gridDelegate = new SliverGridDelegateWithFixedCrossAxisCount(
         crossAxisCount: crossAxisCount,
         mainAxisSpacing: mainAxisSpacing,
         crossAxisSpacing: crossAxisSpacing,
         childAspectRatio: childAspectRatio,
       ),
       childrenDelegate = new SliverChildListDelegate(children), super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller,
    primary: primary,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  );

  /// Creates a scrollable, 2D array of widgets with tiles that have a maximum
  /// cross-axis extent.
  ///
  /// Uses a [SliverGridDelegateWithMaxCrossAxisExtent] as the [gridDelegate].
  GridView.extent({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsets padding,
    @required double maxCrossAxisExtent,
    double mainAxisSpacing: 0.0,
    double crossAxisSpacing: 0.0,
    double childAspectRatio: 1.0,
    List<Widget> children: const <Widget>[],
  }) : gridDelegate = new SliverGridDelegateWithMaxCrossAxisExtent(
         maxCrossAxisExtent: maxCrossAxisExtent,
         mainAxisSpacing: mainAxisSpacing,
         crossAxisSpacing: crossAxisSpacing,
         childAspectRatio: childAspectRatio,
       ),
       childrenDelegate = new SliverChildListDelegate(children), super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller,
    primary: primary,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  );

  /// A delegate that controls the layout of the children within the [GridView].
  ///
  /// The [GridView] and [GridView.custom] constructors let you specify this
  /// delegate explicitly. The other constructors create a [gridDelegate]
  /// implicitly.
  final SliverGridDelegate gridDelegate;

  /// A delegate that provides the children for the [GridView].
  ///
  /// The [GridView.custom] constructor lets you specify this delegate
  /// explicitly. The other constructors create a [childrenDelegate] that wraps
  /// the given child list.
  final SliverChildDelegate childrenDelegate;

  @override
  Widget buildChildLayout(BuildContext context) {
    return new SliverGrid(
      delegate: childrenDelegate,
      gridDelegate: gridDelegate,
    );
  }
}
