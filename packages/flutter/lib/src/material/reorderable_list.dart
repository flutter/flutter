
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A reorderable list
class DraggableList extends StatefulWidget {

  const DraggableList({this.children, this.onSwap, this.axis : Axis.vertical, this.padding});

  final List<Widget> children;
  final Axis axis;
  final EdgeInsets padding;
  final void Function(int, int) onSwap;

  @override
  State<StatefulWidget> createState() {
    return new DraggableListState();
  }
}

class DraggableListState extends State<DraggableList> with TickerProviderStateMixin {
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
    Widget _buildDragTarget(BuildContext context, List<Key> acceptedCandidates, List<dynamic> rejectedCandidates) {
      final Widget draggable = new LongPressDraggable<Key>(
        maxSimultaneousDrags: 1,
        axis: widget.axis,
        data: toWrap.key,
        feedback: new Material(
          elevation: 6.0,
          child: new SizedBox(
            width: MediaQuery.of(context).size.width,
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
        return new Column(children: <Widget>[
          new SizeTransition(
            sizeFactor: entranceController, 
            child: const SizedBox(height: approximateItemHeight),
          ),
          draggable,
        ]);
      }
      if (_ghostIndex == index) {
        return new Column(children: <Widget>[
          new SizeTransition(
            sizeFactor: ghostController, 
            child: const SizedBox(height: approximateItemHeight),
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

  // Scrolls to a target context if it's not on the screen.
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
    assert(widget.children.every((w) => w.key != null), 'All children of this widget must have a key.');
    for (int i=0; i<widget.children.length; i++) {
      wrappedChildren.add(_wrap(widget.children[i], i));
    }
    wrappedChildren.add(_wrap(
      new SizedBox(
        height: 72.0, 
        width: MediaQuery.of(context).size.width,
        key: const Key('DraggableList - End Widget'), 
      ),
      widget.children.length),
    );

    return new SingleChildScrollView(
      child: new Column(children: wrappedChildren), 
      padding: widget.padding, 
      controller: scrollController,
    );
  }
}
