
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
/// Note that this widget places its [children] in a [Column] and not a [ListView].
///
/// All [children] must have a key.
class ReorderableListView extends StatefulWidget {

  /// Creates a reorderable list.
  const ReorderableListView({this.children, this.onSwap, this.scrollDirection = Axis.vertical, this.padding});

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

  @override
  State<StatefulWidget> createState() {
    return new _ReorderableListViewState();
  }
}

class _ReorderableListViewState extends State<ReorderableListView> with TickerProviderStateMixin {
  ScrollController scrollController = new ScrollController();
  // This controls the entrance of the dragging widget into a new place.
  AnimationController entranceController;
  // This controls the 'ghost' of the dragging widget, which is left behind where the widget used to be.
  AnimationController ghostController;

  static const double approximateItemHeight = 100.0;

  Key _dragging;

  // The location that the dragging widget occupied before it started to drag.
  int _dragStartIndex = 0;

  // The index that the dragging widget most recently left.
  // This is used to show an animation of the widget's position.
  int _ghostIndex = 0;
  int _currentIndex = 0;
  int _nextIndex = 0;

  bool _scrolling = false;

  @override 
  void initState() {
    super.initState();
    entranceController = new AnimationController(vsync: this, value: 0.0, duration: const Duration(milliseconds: 200));
    ghostController = new AnimationController(vsync: this, value: 0.0, duration: const Duration(milliseconds: 200));
    entranceController.addStatusListener(_onEntranceStatusChanged);
  }

  @override
  void dispose() {
    entranceController.dispose();
    ghostController.dispose();
    super.dispose();
  }

  Widget _wrap(Widget toWrap, int index) {
    assert(toWrap.key != null);

    Widget _buildContainerForAxis({List<Widget> children}) {
      if (widget.scrollDirection == Axis.horizontal) {
        return new Row(children: children);
      } 
      return new Column(children: children);
    }

    Widget _buildDragTarget(BuildContext context, List<Key> acceptedCandidates, List<dynamic> rejectedCandidates) {
      final Widget spacing = widget.scrollDirection == Axis.vertical ? const SizedBox(height: approximateItemHeight) : const SizedBox(width: approximateItemHeight);
      final Widget draggable = new LongPressDraggable<Key>(
        maxSimultaneousDrags: 1,
        axis: widget.scrollDirection,
        data: toWrap.key,
        feedback: new Material(
          elevation: 6.0,
          child: new SizedBox(
            width: widget.scrollDirection == Axis.vertical ? MediaQuery.of(context).size.width : null,
            height: widget.scrollDirection == Axis.horizontal ? MediaQuery.of(context).size.height : null,
            child: toWrap,
          ),
        ),
        child: _dragging == toWrap.key ? const SizedBox() : toWrap,
        // The list will take care of inserting dummy space in the correct place.
        childWhenDragging: const SizedBox(),
        onDragStarted: () {
          setState(() {
            _dragging = toWrap.key;
            _dragStartIndex = index;
            _ghostIndex = index;
            _currentIndex = index;
            entranceController.forward(from: 1.0);
          });
        },
        onDraggableCanceled: (_, __) {
          setState(() {
            widget.onSwap(_dragStartIndex, _currentIndex);
            ghostController.reverse(from: 0.1);
            entranceController.reverse(from: 0.1);
            _dragging = null;
          });
        },
        onDragCompleted: () {
          setState(() {
            if (_dragStartIndex != _currentIndex)
              widget.onSwap(_dragStartIndex, _currentIndex);
            ghostController.reverse(from: 0.1);
            entranceController.reverse(from: 0.1);
            _dragging = null;
          });
        },
      );
      // The target for dropping at the end of the list doesn't need to be draggable or to expand.
      if (index >= widget.children.length) {
        return toWrap;
      }
      if (_currentIndex == index) {
        return _buildContainerForAxis(children: <Widget>[
          new SizeTransition(
            sizeFactor: entranceController, 
            axis: widget.scrollDirection,
            child: spacing
          ),
          draggable,
        ]);
      }
      if (_ghostIndex == index) {
        return _buildContainerForAxis(children: <Widget>[
          new SizeTransition(
            sizeFactor: ghostController, 
            axis: widget.scrollDirection,
            child: spacing,
          ),
          draggable,
        ]);
      }
      return draggable;
    }

    return new Builder(builder: (BuildContext context) {
      return new DragTarget<Key>(
        builder: _buildDragTarget,
        onWillAccept: (Key toAccept) {
          setState(() {
            _nextIndex = index;
            _requestAnimationTo(_nextIndex);
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

  void _requestAnimationTo(int index) {
    if (index == _currentIndex) {
      return;
    }
    if (entranceController.isCompleted) {
      _currentIndex = index;
      ghostController.reverse(from: 1.0).whenCompleteOrCancel(() {
        // The swap is completed when the ghost controller finishes.
        _ghostIndex = index;
      });
      entranceController.forward(from: 0.0);
    }
  }

  void _onEntranceStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // If the next index has changed, then we should animate to it.
      setState(() {
        _requestAnimationTo(_nextIndex);
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
    const double margin = 48.0;
    final double scrollOffset = scrollController.offset;
    final double topOffset = viewport.getOffsetToReveal(contextObject, 0.0).offset - margin;
    final double bottomOffset = viewport.getOffsetToReveal(contextObject, 1.0).offset + margin;
    final bool onScreen = scrollOffset <= topOffset && scrollOffset >= bottomOffset; 
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
      'All children of this widget must have a key.');
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
      controller: scrollController,
    );
  }
}
