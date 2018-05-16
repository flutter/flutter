import 'dart:collection';

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
    // if (index >= items.length) {
    //   return new MergeSemantics(child: new _DraggableListItem<int>(index: index, child: null, onSwap: onSwap, ensureVisible: scrollTo, isDraggable: false));
    // }
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
      key: new Key(item),
      child: listTile,
    );
  }

  bool scrolling = false;

  void scrollTo(BuildContext context) {
    if (scrolling)
      return;
    // We can't use scrollable.ensureVisible because in a built list, one of the items may go out of context.
    scrolling = true;
    final ScrollController controller = Scrollable.of(context).widget.controller;
    
    const Duration scrollDuration = const Duration(milliseconds: 100);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    

    Scrollable.ensureVisible(context, alignment: 0.5, duration: scrollDuration).then((_) {
      setState(() {
        scrolling = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    void onSwap(int oldIndex, int newIndex) {
      setState(() {
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        final String item = items.removeAt(oldIndex);
        items.insert(newIndex, item);
      });
    }
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

    final List<MergeSemantics> listTiles = <MergeSemantics>[];
    for (int i = 0; i < items.length; i++) {
      listTiles.add(buildListTile(context, i));
    }
    // listTiles.add(buildListTile(context, items.length));
    // print('$items, ${listTiles.map((MergeSemantics w) => ((w.child) as _DraggableListItem).index)}, ${listTiles.length}, ${items.length}');
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
        child: new DraggableList(
          onSwap: onSwap,
          axis: Axis.vertical,
          children: listTiles,
          padding: new EdgeInsets.symmetric(vertical: _dense ? 4.0 : 8.0),
        ),
      ),
    );
  }
}

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
  // This controls the entrance of the dragging widget into a new place.
  AnimationController entranceController;
  // This controls the 'ghost' of the dragging widget, which is left behind where the widget used to be.
  AnimationController ghostController;

  static const double whenDragHeight = 100.0;

  Key dragging;
  // The location that the dragging widget last occupied.
  int dragStartIndex = 0;
  int ghostIndex = 0;
  int currentIndex = 0;

  bool scrolling = false;

  @override 
  void initState() {
    super.initState();
    entranceController = new AnimationController(vsync: this, value: 0.0, duration: const Duration(milliseconds: 200));
    ghostController = new AnimationController(vsync: this, value: 0.0, duration: const Duration(milliseconds: 200));
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
        child: dragging == toWrap.key ? const SizedBox() : toWrap,
        // The list will take care of inserting dummy space in the correct place.
        childWhenDragging: const SizedBox(),
        onDragStarted: () {
          setState(() {
            dragging = toWrap.key;
            dragStartIndex = index;
            ghostIndex = index;
            currentIndex = index;
            entranceController.forward(from: 1.0);
          });
        },
        onDraggableCanceled: (_, __) {
          print('Cancelling: $index, $ghostIndex, ${widget.children.map((w) => w.key)}');
          setState(() {
            ghostController.reverse();
            entranceController.reverse();
            dragging = null;
          });
        },
        onDragCompleted: () {
          print('Swapping: $index, $ghostIndex, ${widget.children.map((w) => w.key)}');
          setState(() {
            widget.onSwap(dragStartIndex, currentIndex);
            ghostController.reverse(from: 0.1);
            entranceController.reverse(from: 0.1);
            dragging = null;
          });
        },
      );
      if (currentIndex == index) {
        return new Column(children: <Widget>[
          new SizeTransition(
            sizeFactor: entranceController, 
            child: const SizedBox(height: whenDragHeight),
          ),
          draggable,
        ]);
      }
      if (ghostIndex == index) {
        return new Column(children: <Widget>[
          new SizeTransition(
            sizeFactor: ghostController, 
            child: const SizedBox(height: whenDragHeight),
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
            print('$index, $ghostIndex, $dragging, ${toWrap.key}, ${widget.children.map((w) => w.key)} ${entranceController.value} ${ghostController.value}');
            if (ghostController.isDismissed) {
              currentIndex = index;
              ghostController.reverse(from: 1.0).whenCompleteOrCancel(() {
                // The swap is completed when the ghost controller finishes.
                print('done: $index, $ghostIndex, ${widget.children.map((w) => w.key)}');
                ghostIndex = index;
              });
              entranceController.forward(from: 0.0);
            }
          });
          if (dragging == toAccept && toAccept != toWrap.key) {
            if (!scrolling) {
              setState(() {
                scrolling = true;
                Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 100), alignment: 0.5).then((_) {
                  setState(() {
                    scrolling = false;
                  });
                });
              });
            }
            print('Will accept');
            return true;
          }
          print('Wont accept');
          return false;
        },
        onAccept: (Key accepted) {
          print('Accepted');
        },
        onLeave: (Key leaving) {
          print('Left');
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> wrappedChildren = <Widget>[];
    assert(widget.children.every((w) => w.key != null), 'All children of this widget must have a key.');
    for (int i=0; i<widget.children.length; i++) {
      wrappedChildren.add(_wrap(widget.children[i], i));
    }

    return new ListView(children: wrappedChildren, padding: widget.padding);
  }
}

class _DraggableListItem<T> extends StatefulWidget {
  const _DraggableListItem({Key key, @required this.child, @required this.index, @required this.onSwap, this.ensureVisible, this.isDraggable: true}) : super(key: key);

  final Widget child;
  final int index;
  final void Function(BuildContext) ensureVisible;
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
  void didUpdateWidget(_DraggableListItem<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.key != widget.key || oldWidget.index != widget.index) {
      // print('Widget key: ${oldWidget.key}, ${widget.key}, ${oldWidget.index}, ${widget.index} ${_tileAnimation.value}');
      _tileAnimation.forward();
    }
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

  bool dragging = false;

  Widget _buildDragTarget(BuildContext context, List<int Function()> acceptedCandidates, List<dynamic> rejectedCandidates) {
    final Widget child = widget.child ?? _buildEmptyTile(context);
    Widget draggableWidget;
    if (widget.isDraggable) {
      draggableWidget = new LongPressDraggable<int Function()>(
        maxSimultaneousDrags: 1,
        key: widget.key,
        data: () => widget.index,
        axis: Axis.vertical,
        feedback: new Material(
          elevation: 6.0,
          child: new SizedBox(
            width: MediaQuery.of(context).size.width,
            child: child,
          ),
        ),
        child: child,
        childWhenDragging: new SizeTransition(sizeFactor: _targetAnimation, child: _buildEmptyTile(context)),
        dragAnchor: DragAnchor.child,
        onDragStarted: () {
          dragging = true;
          _tileAnimation.reverse(from: 1.0);
        },
        onDraggableCanceled: (_, __) {
          dragging = false;
          if (mounted) {
            _tileAnimation.forward(from: 0.0);
          }
        },
        onDragCompleted: () {
          dragging = false;
          if (mounted) {
            print('Placing ${widget.key}, ${widget.index}');
            _targetAnimation.reverse();
            _tileAnimation.forward(from: 0.0);
          }
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
      new DragTarget<int Function()>(
        key: widget.key,
        builder: _buildDragTarget,
        onWillAccept: (int Function() oldIndex) {
          if (widget.ensureVisible != null)
            widget.ensureVisible(context);
          _targetAnimation.forward();
          if (oldIndex == widget.index)
            return true;
          _accept(oldIndex());
          return true;
        },
        onLeave: (int Function() oldIndex) {
          _targetAnimation.reverse();
        },
        onAccept: (int Function() oldIndex) {
          _targetAnimation.reverse();
          if (oldIndex == widget.index) {
            return;
          }
        },
      );
  }
          
  void _accept(int oldIndex) {
    print('Swapping ${oldIndex} and ${widget.index} ');
    // final AnimatedListState animatedList = AnimatedList.of(context);
    if (oldIndex == widget.index) {
      return;
    }
    // animatedList.removeItem(
    //   oldIndex, 
    //   (BuildContext context, Animation<double> animation) => const SizedBox(),
    //   duration: const Duration(milliseconds: 500),
    // );
    final int newIndex = widget.index > oldIndex ? widget.index - 1 : widget.index;
    // animatedList.insertItem(newIndex, duration: const Duration(milliseconds: 500));
    widget.onSwap(oldIndex, newIndex);
  }
}