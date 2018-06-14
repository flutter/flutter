// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import 'material.dart';

/// The callback used by [ReorderableListView] to move an item to a new
/// position in a list.
/// 
/// Implementations should remove the corresponding list item at [oldIndex]
/// and reinsert it at [newIndex].
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
typedef void OnReorderCallback(int oldIndex, int newIndex);

/// A list whose items the user can interactively reorder by dragging.
/// 
/// This class is appropriate for views with a small number of
/// children because constructing the [List] requires doing work for every
/// child that could possibly be displayed in the list view instead of just
/// those children that are actually visible.
///
/// All [children] must have a key.
class ReorderableListView extends StatefulWidget {

  /// Creates a reorderable list.
  ReorderableListView({
    @required this.children, 
    @required this.onReorder, 
    this.scrollDirection = Axis.vertical, 
    this.padding, 
  }): assert(scrollDirection != null),
      assert(onReorder != null),
      assert(children != null),
      assert(
        children.every((Widget w) => w.key != null), 
        'All children of this widget must have a key.',
      );

  /// The widgets to display.
  final List<Widget> children;

  /// The [Axis] along which the list scrolls.
  /// 
  /// List [children] can only drag along this [Axis].
  final Axis scrollDirection;

  /// The amount of space by which to inset the [children].
  final EdgeInsets padding;

  /// Called when a list child is dropped into a new position to shuffle the
  /// underlying list.
  /// 
  /// This [ReorderableListView] calls [onReorder] after a list child is dropped
  /// into a new position.
  final OnReorderCallback onReorder;
  
  @override
  State<StatefulWidget> createState() {
    return new _ReorderableListViewState();
  }
}

class _ReorderableListViewState extends State<ReorderableListView> {
  // We use an inner overlay so that the dragging list item doesn't draw outside of the list itself.
  GlobalKey _overlayKey;

  // This entry contains the scrolling list itself.
  OverlayEntry _bottomOverlayEntry;

  @override 
  void initState() {
    super.initState();
    _overlayKey = new GlobalKey(debugLabel: '$ReorderableListView overlay key');
    _bottomOverlayEntry = new OverlayEntry(
      opaque: true,
      builder: (BuildContext context) {
        return new _ReorderableListContent(
          children: widget.children,
          scrollDirection: widget.scrollDirection,
          onSwap: widget.onReorder,
          padding: widget.padding,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Overlay(
      key: _overlayKey,
      initialEntries: <OverlayEntry>[
        _bottomOverlayEntry,
    ]);
  }
}

// This widget is responsible for the inside of the Overlay in the
// ReorderableListView.
class _ReorderableListContent extends StatefulWidget {
  const _ReorderableListContent({
    @required this.children,
    @required this.scrollDirection,
    @required this.padding,
    @required this.onSwap,
  });
        
  final List<Widget> children;
  final Axis scrollDirection;
  final EdgeInsets padding;
  final OnReorderCallback onSwap;

  @override
  _ReorderableListContentState createState() => new _ReorderableListContentState();
}

class _ReorderableListContentState extends State<_ReorderableListContent> with TickerProviderStateMixin {
  // The extent along the [widget.scrollDirection] axis to allow a child to
  // drop into when the user reorders list children.
  //
  // This value is used as a fallback when the extents haven't yet been
  // calculated from the currently dragging widget.
  static const double _kDefaultDropAreaExtent = 100.0;

  // The additional margin to place around a computed drop area.
  static const double _kDropAreaMargin = 8.0;

  // How long an animation to reorder an element in the list takes.
  static const Duration _kReorderAnimationDuration = const Duration(milliseconds: 200);

  // How long an animation to scroll to an off-screen element in the
  // list takes.
  static const Duration _kScrollAnimationDuration = const Duration(milliseconds: 200);

  // Controls scrolls and measures scroll progress.
  final ScrollController _scrollController = new ScrollController();

  // This controls the entrance of the dragging widget into a new place.
  AnimationController _entranceController;

  // This controls the 'ghost' of the dragging widget, which is left behind
  // where the widget used to be.
  AnimationController _ghostController;

  // The member of widget.children currently being dragged.
  //
  // Null if no drag is underway.
  Key _dragging;

  // The last computed size of the feedback widget being dragged.
  Size _draggingFeedbackSize;

  // The location that the dragging widget occupied before it started to drag.
  int _dragStartIndex = 0;

  // The index that the dragging widget most recently left.
  // This is used to show an animation of the widget's position.
  int _ghostIndex = 0;

  // The index that the dragging widget currently occupies.
  int _currentIndex = 0;

  // The widget to move the dragging widget too after the current index.
  int _nextIndex = 0;

  // Whether or not we are currently scrolling this view to show a widget.
  bool _scrolling = false;

  double get _dropAreaExtent {
    if (_draggingFeedbackSize == null) {
      return _kDefaultDropAreaExtent;
    }
    final double dropAreaWithoutMargin = widget.scrollDirection == Axis.vertical
        ? _draggingFeedbackSize.height
        : _draggingFeedbackSize.width;
    return dropAreaWithoutMargin + _kDropAreaMargin;
  }

  @override 
  void initState() {
    super.initState();
    _entranceController = new AnimationController(vsync: this, value: 0.0, duration: _kReorderAnimationDuration);
    _ghostController = new AnimationController(vsync: this, value: 0.0, duration: _kReorderAnimationDuration);
    _entranceController.addStatusListener(_onEntranceStatusChanged);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ghostController.dispose();
    super.dispose();
  }

  // Animates the dropable space from _currentIndex to _nextIndex.
  void _requestAnimationToNextIndex() {
    if (_entranceController.isCompleted) {
      _ghostIndex = _currentIndex;
      if (_nextIndex == _currentIndex) {
        return;
      }
      _currentIndex = _nextIndex;
      _ghostController.reverse(from: 1.0);
      _entranceController.forward(from: 0.0);
    }
  }

  // Requests animation to the latest next index if it changes during an animation.
  void _onEntranceStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
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
    final double margin = _dropAreaExtent;
    final double scrollOffset = _scrollController.offset;
    final double topOffset = max(
      _scrollController.position.minScrollExtent, 
      viewport.getOffsetToReveal(contextObject, 0.0).offset - margin,
    );
    final double bottomOffset = min(
      _scrollController.position.maxScrollExtent,
      viewport.getOffsetToReveal(contextObject, 1.0).offset + margin,
    );
    final bool onScreen = scrollOffset <= topOffset && scrollOffset >= bottomOffset;
    // If the context is off screen, then we request a scroll to make it visible.
    if (!onScreen) {
      _scrolling = true;
      _scrollController.position.animateTo(
        scrollOffset < bottomOffset ? bottomOffset : topOffset, 
        duration: _kScrollAnimationDuration, 
        curve: Curves.easeInOut,
      ).then((Null none) {
        setState(() {
          _scrolling = false;
        });
      });
    }
  }

  // Wraps children in Row or Column, so that the children flow in
  // the widget's scrollDirection.
  Widget _buildContainerForScrollDirection({List<Widget> children}) {
    if (widget.scrollDirection == Axis.horizontal) {
      return new Row(children: children);
    } 
    return new Column(children: children);
  }

  // Wraps one of the widget's children in a DragTarget and Draggable.
  // Handles up the logic for dragging and reordering items in the list.
  Widget _wrap(Widget toWrap, int index, BoxConstraints constraints) {
    assert(toWrap.key != null);

    // Starts dragging toWrap.
    void onDragStarted() {
      setState(() {
        _dragging = toWrap.key;
        _dragStartIndex = index;
        _ghostIndex = index;
        _currentIndex = index;
        _entranceController.forward(from: 1.0);
      });
    }

    // Drops toWrap into the last position it was hovering over.
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
      Widget child = new LongPressDraggable<Key>(
        maxSimultaneousDrags: 1,
        axis: widget.scrollDirection,
        data: toWrap.key,
        feedback: new Container(
          alignment: Alignment.topLeft,
          // These constraints will limit the cross axis of the drawn widget.
          constraints: constraints,
          child: new Material(
          elevation: 6.0,
          child: new _SizeDetectingWidget(
              onUpdateSize: (Size newSize) {
                setState(() {
                  _draggingFeedbackSize = newSize;
                });
              },
              child: toWrap,
            ),
          ),
        ),
        child: _dragging == toWrap.key ? const SizedBox() : toWrap,
        childWhenDragging: const SizedBox(),
        dragAnchor: DragAnchor.child,
        onDragStarted: onDragStarted,
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

      // The target for dropping at the end of the list doesn't need to be
      // draggable.
      if (index >= widget.children.length) {
        child = toWrap;
      }

      // Determine the size of the drop area to show under the dragging widget.
      final Widget spacing = (widget.scrollDirection == Axis.vertical)
          ? new SizedBox(height: _dropAreaExtent)
          : new SizedBox(width: _dropAreaExtent);

      // We open up a space under where the dragging widget currently is to
      // show it can be dropped.
      if (_currentIndex == index) {
        return _buildContainerForScrollDirection(children: <Widget>[
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
        return _buildContainerForScrollDirection(children: <Widget>[
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

    // We wrap the drag target in a Builder so that we can scroll to its specific context.
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
        onAccept: (Key accepted) {},
        onLeave: (Key leaving) {},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // We use the layout builder to constrain the cross-axis size of dragging child widgets.
    return new LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
        final List<Widget> wrappedChildren = <Widget>[];
        for (int i=0; i<widget.children.length; i++) {
          wrappedChildren.add(_wrap(widget.children[i], i, constraints));
        }
        wrappedChildren.add(_wrap(
          new SizedBox(
            height: widget.scrollDirection == Axis.horizontal 
                ? constraints.maxHeight : 72.0, 
            width: widget.scrollDirection == Axis.vertical 
                ? constraints.maxWidth : 72.0,
            key: const Key('DraggableList - End Widget'), 
          ),
          widget.children.length,
          constraints),
        );
        return new SingleChildScrollView(
          scrollDirection: widget.scrollDirection,
          child: _buildContainerForScrollDirection(children: wrappedChildren),
          padding: widget.padding, 
          controller: _scrollController,
        );
    });
  }
}

// Notifies its parent when its size has changed.
class _SizeDetectingWidget extends StatefulWidget {
  const _SizeDetectingWidget({Key key, this.child, this.onUpdateSize}) : super(key: key);

  final void Function(Size newSize) onUpdateSize;
  final Widget child;

  @override
  _SizeDetectingWidgetState createState() => new _SizeDetectingWidgetState();
}

class _SizeDetectingWidgetState extends State<_SizeDetectingWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_computeSize);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(_SizeDetectingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback(_computeSize);
  }

  // Computes the widget's size as a post-frame callback.
  void _computeSize([Duration duration]) {
    final RenderBox box = context.findRenderObject();
    widget.onUpdateSize(box.size);
  }

  @override
  Widget build(BuildContext context) {
     return widget.child;
  }
}