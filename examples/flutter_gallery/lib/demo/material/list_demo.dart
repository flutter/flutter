import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

enum _MaterialListType {
  /// A list tile that contains a single line of text.
  oneLine,

  /// A list tile that contains a [CircleAvatar] followed by a single line of text.
  oneLineWithAvatar,

  /// A list tile that contains two lines of text.
  twoLine,

  /// A list tile that contains three lines of text.
  threeLine,
}

class ListDemo extends StatefulWidget {
  const ListDemo({ Key key }) : super(key: key);

  static const String routeName = '/material/list';

  @override
  _ListDemoState createState() => new _ListDemoState();
}

class _ListDemoState extends State<ListDemo> {
  static final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  PersistentBottomSheetController<Null> _bottomSheet;
  _MaterialListType _itemType = _MaterialListType.threeLine;
  bool _dense = false;
  bool _showAvatars = true;
  bool _showIcons = false;
  bool _showDividers = false;
  bool _reverseSort = false;
  List<String> items = <String>[
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
  ];

  void changeItemType(_MaterialListType type) {
    setState(() {
      _itemType = type;
    });
    _bottomSheet?.setState(() { });
  }

  void _showConfigurationSheet() {
    final PersistentBottomSheetController<Null> bottomSheet = scaffoldKey.currentState.showBottomSheet((BuildContext bottomSheetContext) {
      return new Container(
        decoration: const BoxDecoration(
          border: const Border(top: const BorderSide(color: Colors.black26)),
        ),
        child: new ListView(
          shrinkWrap: true,
          primary: false,
          children: <Widget>[
            new MergeSemantics(
              child: new ListTile(
                dense: true,
                title: const Text('One-line'),
                trailing: new Radio<_MaterialListType>(
                  value: _showAvatars ? _MaterialListType.oneLineWithAvatar : _MaterialListType.oneLine,
                  groupValue: _itemType,
                  onChanged: changeItemType,
                )
              ),
            ),
            new MergeSemantics(
              child: new ListTile(
                dense: true,
                title: const Text('Two-line'),
                trailing: new Radio<_MaterialListType>(
                  value: _MaterialListType.twoLine,
                  groupValue: _itemType,
                  onChanged: changeItemType,
                )
              ),
            ),
            new MergeSemantics(
              child: new ListTile(
                dense: true,
                title: const Text('Three-line'),
                trailing: new Radio<_MaterialListType>(
                  value: _MaterialListType.threeLine,
                  groupValue: _itemType,
                  onChanged: changeItemType,
                ),
              ),
            ),
            new MergeSemantics(
              child: new ListTile(
                dense: true,
                title: const Text('Show avatar'),
                trailing: new Checkbox(
                  value: _showAvatars,
                  onChanged: (bool value) {
                    setState(() {
                      _showAvatars = value;
                    });
                    _bottomSheet?.setState(() { });
                  },
                ),
              ),
            ),
            new MergeSemantics(
              child: new ListTile(
                dense: true,
                title: const Text('Show icon'),
                trailing: new Checkbox(
                  value: _showIcons,
                  onChanged: (bool value) {
                    setState(() {
                      _showIcons = value;
                    });
                    _bottomSheet?.setState(() { });
                  },
                ),
              ),
            ),
            new MergeSemantics(
              child: new ListTile(
                dense: true,
                title: const Text('Show dividers'),
                trailing: new Checkbox(
                  value: _showDividers,
                  onChanged: (bool value) {
                    setState(() {
                      _showDividers = value;
                    });
                    _bottomSheet?.setState(() { });
                  },
                ),
              ),
            ),
            new MergeSemantics(
              child: new ListTile(
                dense: true,
                title: const Text('Dense layout'),
                trailing: new Checkbox(
                  value: _dense,
                  onChanged: (bool value) {
                    setState(() {
                      _dense = value;
                    });
                    _bottomSheet?.setState(() { });
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });

    setState(() {
      _bottomSheet = bottomSheet;
    });

    _bottomSheet.closed.whenComplete(() {
      if (mounted) {
        setState(() {
          _bottomSheet = null;
        });
      }
    });
  }

  Map<String, bool> valueToCheckboxState = <String, bool>{};

  Widget buildListTile(BuildContext context, int index) {
    void onSwap(int oldIndex, int newIndex) {
      setState(() {
        final String item = items.removeAt(oldIndex);
        items.insert(newIndex, item);
      });
    }
    if (index >= items.length) {
      return new _DraggableListItem<int>(index: index, child: null, onSwap: onSwap, isDraggable: false);
    }
    final String item = items[index];
    Widget secondary;
    if (_itemType == _MaterialListType.twoLine) {
      secondary = const Text('Additional item information.');
    } else if (_itemType == _MaterialListType.threeLine) {
      secondary = const Text(
        'Even more additional list item information appears on line three.',
      );
    }
    final Widget listTile = new ListTile(
      isThreeLine: _itemType == _MaterialListType.threeLine,
      dense: _dense,
      trailing: new Checkbox(value: valueToCheckboxState[item] ?? false, onChanged: (bool newValue) {setState(() {valueToCheckboxState[item] = newValue;});},),
      title: new Text('This item represents $item.'),
      subtitle: secondary,
      leading: const Icon(Icons.drag_handle),
    );
    return new MergeSemantics(
      child: new _DraggableListItem<int>(key: new Key(item), index: index, child: listTile, onSwap: onSwap),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String layoutText = _dense ? ' \u2013 Dense' : '';
    String itemTypeText;
    switch (_itemType) {
      case _MaterialListType.oneLine:
      case _MaterialListType.oneLineWithAvatar:
        itemTypeText = 'Single-line';
        break;
      case _MaterialListType.twoLine:
        itemTypeText = 'Two-line';
        break;
      case _MaterialListType.threeLine:
        itemTypeText = 'Three-line';
        break;
    }

    // Iterable<Widget> listTiles = items.map((String item) => buildListTile(context, item));
    // if (_showDividers)
    //   listTiles = ListTile.divideTiles(context: context, tiles: listTiles);

    return new Scaffold(
      key: scaffoldKey,
      appBar: new AppBar(
        title: new Text('Scrolling list\n$itemTypeText$layoutText'),
        actions: <Widget>[
          new IconButton(
            icon: const Icon(Icons.sort_by_alpha),
            tooltip: 'Sort',
            onPressed: () {
              setState(() {
                _reverseSort = !_reverseSort;
                items.sort((String a, String b) => _reverseSort ? b.compareTo(a) : a.compareTo(b));
              });
            },
          ),
          new IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Show menu',
            onPressed: _bottomSheet == null ? _showConfigurationSheet : null,
          ),
        ],
      ),
      body: new Scrollbar(
        child: new AnimatedList(
          itemBuilder: (BuildContext context, int index, Animation<double> animation) {
            return new SizeTransition(sizeFactor: animation, child: buildListTile(context, index));
          },
          initialItemCount: items.length + 1,
          padding: new EdgeInsets.symmetric(vertical: _dense ? 4.0 : 8.0),
        ),
      ),
    );
  }
}

class _DraggableListItem<T> extends StatefulWidget {
  const _DraggableListItem({Key key, @required this.child, @required this.index, @required this.onSwap, this.isDraggable: true}) : super(key: key);

  final Widget child;
  final int index;
  final void Function(int, int) onSwap;
  final bool isDraggable;

  @override
  State<_DraggableListItem<T>> createState() => new _DraggableListItemState<T>();
}
  
class _DraggableListItemState<T> extends State<_DraggableListItem<T>> with TickerProviderStateMixin {
  AnimationController _targetAnimation;
  AnimationController _tileAnimation;

  @override
  void initState() {
    super.initState();
    _targetAnimation = new AnimationController(vsync: this, value: 0.0, duration: const Duration(milliseconds: 200));
    _tileAnimation = new AnimationController(vsync: this, value: 1.0, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _targetAnimation.dispose();
    _tileAnimation.dispose();
    super.dispose();
  }

  void hideTile() {
    _tileAnimation.reverse();
  }

  Widget _buildEmptyTile(BuildContext context) {
    return new ListTile(isThreeLine: (widget?.child as ListTile)?.isThreeLine ?? false, subtitle: const SizedBox(),);
  }

  Widget _buildDragTarget(BuildContext context, List<int> acceptedCandidates, List<dynamic> rejectedCandidates) {
    final Widget child = widget.child ?? _buildEmptyTile(context);
    Widget draggableWidget;
    if (widget.isDraggable) {
      draggableWidget = new ListDraggable<int>(
        data: widget.index,
        axis: Axis.vertical,
        feedback: new Material(
          elevation: 6.0,
          child: new SizedBox(
            width: MediaQuery.of(context).size.width,
            child: child,
          ),
        ),
        child: child,
        childWhenDragging: new SizeTransition(
          sizeFactor: _tileAnimation.view,
          child: _buildEmptyTile(context),
        ),
        dragAnchor: DragAnchor.child,
        onDragStarted: _tileAnimation.reverse,
        onDraggableCanceled: (_, __) => _tileAnimation.forward(),
        onDragCompleted: () {
          _targetAnimation.reverse();
          _tileAnimation.forward(from: 0.0);
        },
      );
    } else {
      draggableWidget = child;
    }
      
    return new Column(children: <Widget>[
      new SizeTransition(
        sizeFactor: _targetAnimation.view,
        child: _buildEmptyTile(context),
      ),
      draggableWidget,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return 
      new DragTarget<int>(
        builder: _buildDragTarget,
        onWillAccept: (int oldIndex) {
          _targetAnimation.forward();
          return true;
        },
        onLeave: (int oldIndex) {
          _targetAnimation.reverse();
        },
        onAccept: (int oldIndex) {
          _targetAnimation.reverse();
          if (oldIndex == widget.index) {
            return;
          }
          _accept(oldIndex);
        },
      );
  }
          
  void _accept(int oldIndex) {
    final AnimatedListState animatedList = AnimatedList.of(context);
    if (oldIndex + 1 == widget.index) {
      return;
    }
    animatedList.removeItem(
      oldIndex, 
      (BuildContext context, Animation<double> animation) => const SizedBox(),
      duration: const Duration(milliseconds: 0),
    );
    final int newIndex = widget.index > oldIndex ? widget.index - 1 : widget.index;
    animatedList.insertItem(newIndex, duration: const Duration(milliseconds: 0));
    widget.onSwap(oldIndex, newIndex);
  }
}

/// [LongPressDraggable] that restricts drag to a single axis.
class ListDraggable<T> extends LongPressDraggable<T> {
  /// Creates a widget that can be dragged starting from long press.
  ///
  /// The [child] and [feedback] arguments must not be null. If
  /// [maxSimultaneousDrags] is non-null, it must be non-negative.
  const ListDraggable({
    Key key,
    @required this.axis,
    @required Widget child,
    @required Widget feedback,
    T data,
    Widget childWhenDragging,
    Offset feedbackOffset: Offset.zero,
    DragAnchor dragAnchor: DragAnchor.child,
    int maxSimultaneousDrags,
    VoidCallback onDragStarted,
    DraggableCanceledCallback onDraggableCanceled,
    VoidCallback onDragCompleted
  }) : assert(axis != null), 
       super(
        key: key,
        child: child,
        feedback: feedback,
        data: data,
        childWhenDragging: childWhenDragging,
        feedbackOffset: feedbackOffset,
        dragAnchor: dragAnchor,
        maxSimultaneousDrags: maxSimultaneousDrags,
        onDragStarted: onDragStarted,
        onDraggableCanceled: onDraggableCanceled,
        onDragCompleted: onDragCompleted
      );


  /// The [Axis] to retrict drag to.
  /// 
  /// An [Axis.vertical] will only drag vertically,
  /// and an [Axis.horizontal] will only drag horizontally.
  final Axis axis;
   
  @override
  DelayedMultiDragGestureRecognizer createRecognizer(GestureMultiDragStartCallback onStart) {
    final DelayedMultiDragGestureRecognizer superRecognizer = super.createRecognizer(onStart);
    return new DelayedMultiDragGestureRecognizer()
      ..onStart = (Offset position) {
        final Drag result = new _SingleAxisDrag(
          axis: axis,
          delegate: superRecognizer.onStart(position),
        );
        return result;
      };
  }
}

// Wraps a [Drag], but restricting its motion delta to only one axis.
class _SingleAxisDrag implements Drag {
  // Creates a [SingleAxisDrag].
  _SingleAxisDrag({@required this.axis, @required this.delegate}) : 
      assert(axis != null), 
      assert(delegate != null);

  /// The [Axis] to retrict this [Drag] to.
  /// 
  /// An [Axis.vertical] will only drag vertically,
  /// and an [Axis.horizontal] will only drag horizontally.
  final Axis axis;

  /// The [Drag] object that actually handles the underlying motion events.
  final Drag delegate;

  @override
  void cancel() {
    delegate.cancel();
  }

  @override
  void end(DragEndDetails details) {
    final DragEndDetails restrictedDetails = new DragEndDetails(
      velocity: _restrictVelocityAxis(details.velocity),
      primaryVelocity: details.primaryVelocity,
    );
    return delegate.end(restrictedDetails);
  }

  @override
  void update(DragUpdateDetails details) {
    final DragUpdateDetails restrictedDetails = new DragUpdateDetails(
      delta: _restrictAxis(details.delta),
      globalPosition: details.globalPosition,
      primaryDelta: details.primaryDelta,
    );
    return delegate.update(restrictedDetails);
  }

  Velocity _restrictVelocityAxis(Velocity velocity) {
    return new Velocity(pixelsPerSecond: _restrictAxis(velocity.pixelsPerSecond));
  }

  Offset _restrictAxis(Offset offset) {
    Offset restrictedOffset;
    if (axis == Axis.horizontal) {
      restrictedOffset = new Offset(offset.dx, 0.0);
    } else {
      restrictedOffset = new Offset(0.0, offset.dy);
    }
    return restrictedOffset;
  }
}