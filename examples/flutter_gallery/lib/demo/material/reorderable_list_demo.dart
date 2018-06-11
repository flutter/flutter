// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum _ReorderableListType {
  /// A list tile that contains a single line of text.
  horizontalAvatar,

  /// A list tile that contains a [CircleAvatar] followed by a single line of text.
  verticalAvatar,

  /// A list tile that contains three lines of text.
  threeLine,
}

class ReorderableListDemo extends StatefulWidget {
  const ReorderableListDemo({ Key key }) : super(key: key);

  static const String routeName = '/material/reorderable-list';

  @override
  _ListDemoState createState() => new _ListDemoState();
}

class _ListDemoState extends State<ReorderableListDemo> {
  static final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  PersistentBottomSheetController<Null> _bottomSheet;
  _ReorderableListType _itemType = _ReorderableListType.threeLine;
  bool _reverseSort = false;
  List<String> items = <String>[
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
  ];

  void changeItemType(_ReorderableListType type) {
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
                title: const Text('Horizontal Avatars'),
                trailing: new Radio<_ReorderableListType>(
                  value:_ReorderableListType.horizontalAvatar,
                  groupValue: _itemType,
                  onChanged: changeItemType,
                )
              ),
            ),
            new MergeSemantics(
              child: new ListTile(
                dense: true,
                title: const Text('Vertical Avatars'),
                trailing: new Radio<_ReorderableListType>(
                  value: _ReorderableListType.verticalAvatar,
                  groupValue: _itemType,
                  onChanged: changeItemType,
                )
              ),
            ),
            new MergeSemantics(
              child: new ListTile(
                dense: true,
                title: const Text('Three-line'),
                trailing: new Radio<_ReorderableListType>(
                  value: _ReorderableListType.threeLine,
                  groupValue: _itemType,
                  onChanged: changeItemType,
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
    final String item = items[index];
    const Widget secondary = const Text(
      'Even more additional list item information appears on line three.',
    );
    Widget listTile;
    if (_itemType == _ReorderableListType.threeLine) {
      listTile = new ListTile(
      isThreeLine: true,
      trailing: new Checkbox(
        value: valueToCheckboxState[item] ?? false, 
        onChanged: (bool newValue) {
          setState(() {
            valueToCheckboxState[item] = newValue;
          });
        },
      ),
      title: new Text('This item represents $item.'),
      subtitle: secondary,
      leading: const Icon(Icons.drag_handle),
    );
    } else {
      listTile = new Container(
        height: 100.0, 
        width: 100.0, 
        child: new CircleAvatar(child: new Text(item), 
          backgroundColor: Colors.green,
        ),
      );
    }
    
    return new MergeSemantics(
      key: new Key(item),
      child: listTile,
    );
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

    final List<MergeSemantics> listTiles = <MergeSemantics>[];
    for (int i = 0; i < items.length; i++) {
      listTiles.add(buildListTile(context, i));
    }

    return new Scaffold(
      key: scaffoldKey,
      appBar: new AppBar(
        title: const Text('Reorderable list'),
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
        child: new ReorderableListView(
          onSwap: onSwap,
          scrollDirection: _itemType == _ReorderableListType.horizontalAvatar ? Axis.horizontal : Axis.vertical,
          children: listTiles,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
        ),
      ),
    );
  }
}
