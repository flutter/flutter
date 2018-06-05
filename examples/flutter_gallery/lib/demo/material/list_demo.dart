import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
  ScrollController scrollController = new ScrollController();
  // This controls the entrance of the dragging widget into a new place.
  AnimationController entranceController;
  // This controls the 'ghost' of the dragging widget, which is left behind where the widget used to be.
  AnimationController ghostController;

  static const double approximateItemHeight = 100.0;

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
      Widget draggable = new LongPressDraggable<Key>(
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
          setState(() {
            ghostController.reverse();
            entranceController.reverse();
            dragging = null;
          });
        },
        onDragCompleted: () {
          setState(() {
            widget.onSwap(dragStartIndex, currentIndex);
            ghostController.reverse(from: 0.1);
            entranceController.reverse(from: 0.1);
            dragging = null;
          });
        },
      );
      if (index >= widget.children.length) {
        draggable = toWrap;
      }
      if (currentIndex == index) {
        return new Column(children: <Widget>[
          new SizeTransition(
            sizeFactor: entranceController, 
            child: const SizedBox(height: approximateItemHeight),
          ),
          draggable,
        ]);
      }
      if (ghostIndex == index) {
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
            // print('$index, $ghostIndex, $dragging, ${toWrap.key}, ${widget.children.map((w) => w.key)} ${entranceController.value} ${ghostController.value}');
            if (ghostController.isDismissed) {
              currentIndex = index;
              ghostController.reverse(from: 1.0).whenCompleteOrCancel(() {
                // The swap is completed when the ghost controller finishes.
                ghostIndex = index;
              });
              entranceController.forward(from: 0.0);
            }
          });
          if (dragging == toAccept && toAccept != toWrap.key) {
            print('Checking to see if we should scroll');
            if (!scrolling) {
              final RenderObject contextObject = context.findRenderObject();
              final RenderAbstractViewport viewport = RenderAbstractViewport.of(contextObject);
              assert(viewport != null);
              const double margin = 48.0;
              final double scrollOffset = scrollController.offset;
              final double topOffset = viewport.getOffsetToReveal(contextObject, 0.0) - margin;
              final double bottomOffset = viewport.getOffsetToReveal(contextObject, 1.0) + margin;
              final double viewHeight = (bottomOffset - topOffset).abs();
              final bool onScreen = scrollOffset <= topOffset && scrollOffset >= bottomOffset;
              final double offsetToReveal = max(
                min(
                  scrollOffset < bottomOffset ? bottomOffset : topOffset,
                  scrollController.position.maxScrollExtent,
                ),
                scrollController.position.minScrollExtent
              );
              print('$dragging toWrap: ${toWrap.key} OnScreen: $onScreen, ${topOffset} ${bottomOffset} ${offsetToReveal} ${scrollOffset} ${viewHeight}');
              if (!onScreen && offsetToReveal != scrollOffset) {
                print('Scrolling from ${scrollOffset} to ${offsetToReveal}');
                scrolling = true;
                scrollController.animateTo(offsetToReveal, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut).then((_) {
                  setState(() {
                    scrolling = false;
                  });
                });
              }
            //   setState(() {
            //     scrolling = true;
            //     double targetOffset = scrollController.offset - approximateItemHeight;
            //     if (currentIndex > ghostIndex) {
            //       targetOffset = scrollController.offset + approximateItemHeight;
            //     }
            //     print('Scrolling from ${scrollController.offset} to ${targetOffset}');

            //   });
            }
            return true;
          }
          return false;
        },
        onAccept: (Key accepted) {
        },
        onLeave: (Key leaving) {
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
    wrappedChildren.add(_wrap(
      new SizedBox(
        height: 48.0, 
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
