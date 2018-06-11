
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A callback used by [ReorderableListView] to swap items in a list.
/// 
/// Implementations should remove the corresponding list item at [oldIndex]
/// and insert a new one at [newIndex].
/// 
/// Note that if [oldIndex] is before [newIndex], removing the item at [oldIndex]
/// from the list will reduce the list's length by one. Implementations used
/// by [ReorderableListView] will need to account for this when inserting before
/// [newIndex].
/// 
/// Example implementation:
/// 
/// ```dart
/// final List<MyDataObject> backingList = <MyDataObject>[/* ... */];
/// void onSwap(int oldIndex, int newIndex) {
///   if (oldIndex < newIndex) {
///     // removing the item at oldIndex will shorten the list by 1.
///     newIndex -= 1;
///   }
///   final MyDataObject element = backingList.removeAt(oldIndex);
///   backingList.insert(newIndex, element);
/// }
/// ```
typedef void OnSwapCallback(int oldIndex, int newIndex);

/// A list with draggable content that the user can re-order.
/// 
/// Note that this widget places its [children] in a [Column] or [Row] and not a [ListView].
///
/// All [children] must have a key.
class ReorderableListView extends StatefulWidget {

  /// Creates a reorderable list.
  const ReorderableListView({@required this.children, @required this.onSwap, this.scrollDirection = Axis.vertical, this.padding, this.dropAreaExtent = 96.0})
    : assert(dropAreaExtent != null),
      assert(scrollDirection != null),
      assert(onSwap != null),
      assert(children != null);

  /// The
  final List<Widget> children;

  /// The [Axis] along which the list scrolls.
  /// 
  /// List children also drag along this [Axis].
  final Axis scrollDirection;

  /// The amount of space by which to inset the child.
  final EdgeInsets padding;

  /// Called when a list child is dropped into a new position to shuffle the
  /// underlying list.
  /// 
  /// This [ReorderableListView] calls [onSwap] after a list child is dropped
  /// into a new position.
  final OnSwapCallback onSwap;

  /// The extent along the [scrollDirection] axis to allow a child to drop
  /// into when the user reorders list children.
  /// 
  /// When the user is dragging a child to reorder it, the list will open up a
  /// drop area in the space under the widget being dragged. That area will
  /// have an extent along the main axis of [dropAreaExtent].
  /// 
  /// In a vertical list, this should match the height of the list items.
  /// In a horizontal list, this should match the width of the list items.
  final double dropAreaExtent;

  @override
  State<StatefulWidget> createState() {
    return new _ReorderableListViewState();
  }
}

class _ReorderableListViewState extends State<ReorderableListView> with TickerProviderStateMixin {
  final ScrollController _scrollController = new ScrollController();

  // This controls the entrance of the dragging widget into a new place.
  AnimationController _entranceController;

  // This controls the 'ghost' of the dragging widget, which is left behind where the widget used to be.
  AnimationController _ghostController;

  Key _dragging;

  // The location that the dragging widget occupied before it started to drag.
  int _dragStartIndex = 0;

  // The index that the dragging widget most recently left.
  // This is used to show an animation of the widget's position.
  int _ghostIndex = 0;

  // The index that the dragging widget currently occupies.
  int _currentIndex = 0;

  // The widget to move the dragging widget too after the current index.
  int _nextIndex = 0;

  // Whether or not we are scrolling this view to show a widget.
  bool _scrolling = false;

  @override 
  void initState() {
    super.initState();
    _entranceController = new AnimationController(vsync: this, value: 0.0, duration: const Duration(milliseconds: 200));
    _ghostController = new AnimationController(vsync: this, value: 0.0, duration: const Duration(milliseconds: 200));
    _entranceController.addStatusListener(_onEntranceStatusChanged);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ghostController.dispose();
    super.dispose();
  }

  Widget _wrap(Widget toWrap, int index) {
    assert(toWrap.key != null);

    Widget buildContainerForAxis({List<Widget> children}) {
      if (widget.scrollDirection == Axis.horizontal) {
        return new Row(children: children);
      } 
      return new Column(children: children);
    }

    void onDragEnded() {
      setState(() {
        if (_dragStartIndex != _currentIndex)
          widget.onSwap(_dragStartIndex, _currentIndex);
        _ghostController.reverse(from: 0.1);
        _entranceController.reverse(from: 0.1);
        _dragging = null;
      });
    }

    Widget buildDragTarget(BuildContext context, List<Key> acceptedCandidates, List<dynamic> rejectedCandidates) {
      // We build the draggable inside of a layout builder so that we can
      // constrain the size of the feedback dragging widget.
      Widget child = new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
            return new LongPressDraggable<Key>(
              maxSimultaneousDrags: 1,
              axis: widget.scrollDirection,
              data: toWrap.key,
              feedback:new Container(
                alignment: Alignment.topLeft,
                constraints: constraints,
                child: new Material(
                  elevation: 6.0,
                  child: toWrap,
                ),
              ),
              child: _dragging == toWrap.key ? const SizedBox() : toWrap,
              childWhenDragging: const SizedBox(),
              dragAnchor: DragAnchor.child,
              onDragStarted: () {
                setState(() {
                  _dragging = toWrap.key;
                  _dragStartIndex = index;
                  _ghostIndex = index;
                  _currentIndex = index;
                  _entranceController.forward(from: 1.0);
                });
              },
              // When the drag ends inside a DragTarget widget, the drag
              // succeeds, and we swap the widget into position appropriately.
              onDragCompleted: onDragEnded,
              // When the drag does not end inside a DragTarget widget, the
              // drag fails, but we still swap the widget to the last position it
              // had been dragged to.
              onDraggableCanceled: (Velocity velocity, Offset offset) {
                onDragEnded();
              },
            );
      });
      // The target for dropping at the end of the list doesn't need to be
      // draggable.
      if (index >= widget.children.length) {
        child = toWrap;
      }
      final Widget spacing = widget.scrollDirection == Axis.vertical 
          ? new SizedBox(height: widget.dropAreaExtent) 
          : new SizedBox(width: widget.dropAreaExtent);
      // We open up a space under where the dragging widget currently is to
      // show it can be dropped.
      if (_currentIndex == index) {
        return buildContainerForAxis(children: <Widget>[
          new SizeTransition(
            sizeFactor: _entranceController, 
            axis: widget.scrollDirection,
            child: spacing
          ),
          child,
        ]);
      }
      // We close up the space under where the dragging widget previously was
      // with the ghostController animation.
      if (_ghostIndex == index) {
        return buildContainerForAxis(children: <Widget>[
          new SizeTransition(
            sizeFactor: _ghostController, 
            axis: widget.scrollDirection,
            child: spacing,
          ),
          child,
        ]);
      }
      return child;
    }

    return new Builder(builder: (BuildContext context) {
      return new DragTarget<Key>(
        builder: buildDragTarget,
        onWillAccept: (Key toAccept) {
          setState(() {
            _nextIndex = index;
            _requestAnimationToNextIndex();
          });
          _scrollTo(context);
          // If the target is not the original starting point, then we will accept the drop.
          return _dragging == toAccept && toAccept != toWrap.key;
        },
        onAccept: (Key accepted) {
        },
        onLeave: (Key leaving) {
        },
      );
    });
  }

  void _requestAnimationToNextIndex() {
    if (_nextIndex == _currentIndex) {
      return;
    }
    if (_entranceController.isCompleted) {
      _currentIndex = _nextIndex;
      _ghostController.reverse(from: 1.0).whenCompleteOrCancel(() {
        // The swap is completed when the ghost controller finishes.
        _ghostIndex = _nextIndex;
      });
      _entranceController.forward(from: 0.0);
    }
  }

  void _onEntranceStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // If the next index has changed, then we should animate to it.
      setState(() {
        _requestAnimationToNextIndex();
      });
    }
  }

  // Scrolls to a target context if that context is not on the screen.
  void _scrollTo(BuildContext context) {
    if (_scrolling) 
      return;
    final RenderObject contextObject = context.findRenderObject();
    final RenderAbstractViewport viewport = RenderAbstractViewport.of(contextObject);
    assert(viewport != null);
    // If and only if the current scroll offset falls in-between the offsets
    // necessary to reveal the selected context at the top or bottom of the
    // screen, then it is already on-screen.
    final double margin = widget.dropAreaExtent;
    final double scrollOffset = _scrollController.offset;
    final double topOffset = viewport.getOffsetToReveal(contextObject, 0.0).offset - margin;
    final double bottomOffset = viewport.getOffsetToReveal(contextObject, 1.0).offset + margin;
    final bool onScreen = scrollOffset <= topOffset && scrollOffset >= bottomOffset;
    // If the context is off screen, then we request a scroll to make it visible.
    if (!onScreen) {
      _scrolling = true;
      Scrollable.ensureVisible(
        context, 
        duration: const Duration(milliseconds: 200), 
        alignment: scrollOffset < bottomOffset ? 0.9 : 0.1, 
        curve: Curves.easeInOut,
      ).then((Null none) {
        setState(() {
          _scrolling = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> wrappedChildren = <Widget>[];
    assert(
      widget.children.every((Widget w) => w.key != null), 
      'All children of this widget must have a key.',
    );
    for (int i=0; i<widget.children.length; i++) {
      wrappedChildren.add(_wrap(widget.children[i], i));
    }
    wrappedChildren.add(_wrap(
      new SizedBox(
        height: widget.scrollDirection == Axis.horizontal ? MediaQuery.of(context).size.height : 72.0, 
        width: widget.scrollDirection == Axis.vertical ? MediaQuery.of(context).size.width : 72.0,
        key: const Key('DraggableList - End Widget'), 
      ),
      widget.children.length),
    );

    return new SingleChildScrollView(
      scrollDirection: widget.scrollDirection,
      child: widget.scrollDirection == Axis.vertical 
          ? new Column(children: wrappedChildren) 
          : new Row(children: wrappedChildren),
      padding: widget.padding, 
      controller: _scrollController,
    );
  }
}
