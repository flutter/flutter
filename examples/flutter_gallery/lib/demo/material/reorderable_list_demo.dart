// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum _ReorderableListType {
  /// A list tile that contains a [CircleAvatar].
  horizontalAvatar,

  /// A list tile that contains a [CircleAvatar].
  verticalAvatar,

  /// A list tile that contains three lines of text and a checkbox.
  threeLine,
}

class ReorderableListDemo extends StatefulWidget {
  const ReorderableListDemo({ Key key }) : super(key: key);

  static const String routeName = '/material/reorderable-list';

  @override
  _ListDemoState createState() => new _ListDemoState();
}

class _ListItem {
  _ListItem(this.value, this.checkState);

  final String value;

  bool checkState;
}

class _ListDemoState extends State<ReorderableListDemo> {
  static final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  PersistentBottomSheetController<Null> _bottomSheet;
  _ReorderableListType _itemType = _ReorderableListType.threeLine;
  bool _reverseSort = false;
  List<_ListItem> _items = <String>[
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
  ].map((String item) => new _ListItem(item, false)).toList();

  void changeItemType(_ReorderableListType type) {
    setState(() {
      _itemType = type;
    });
    _bottomSheet?.setState(() { });
  }

  void _showConfigurationSheet() {
    final PersistentBottomSheetController<Null> bottomSheet = scaffoldKey.currentState.showBottomSheet((BuildContext bottomSheetContext) {
      return new DecoratedBox(
        decoration: const BoxDecoration(
          border: const Border(top: const BorderSide(color: Colors.black26)),
        ),
        child: new ListView(
          shrinkWrap: true,
          primary: false,
          children: <Widget>[
            new RadioListTile<_ReorderableListType>(
              dense: true,
              title: const Text('Horizontal Avatars'),
              value:_ReorderableListType.horizontalAvatar,
              groupValue: _itemType,
              onChanged: changeItemType,
            ),
            new RadioListTile<_ReorderableListType>(
              dense: true,
              title: const Text('Vertical Avatars'),
              value: _ReorderableListType.verticalAvatar,
              groupValue: _itemType,
              onChanged: changeItemType,
            ),
            new RadioListTile<_ReorderableListType>(
              dense: true,
              title: const Text('Three-line'),
              value: _ReorderableListType.threeLine,
              groupValue: _itemType,
              onChanged: changeItemType,
            ),
          ],
        ),
      );
    });

    setState(() {
      _bottomSheet = bottomSheet;
    });

    // Garbage collect the bottom sheet when it closes.
    bottomSheet.closed.whenComplete(() {
      if (mounted) {
        setState(() {
          _bottomSheet = null;
        });
      }
    });
  }

  Widget buildListTile(_ListItem item) {
    const Widget secondary = const Text(
      'Even more additional list item information appears on line three.',
    );
    Widget listTile;
    switch (_itemType) {
      case _ReorderableListType.threeLine:
        listTile = new CheckboxListTile(
          key: new Key(item.value),
          isThreeLine: true,
          value: item.checkState ?? false, 
          onChanged: (bool newValue) {
            setState(() {
              item.checkState = newValue;
            });
          },
          title: new Text('This item represents ${item.value}.'),
          subtitle: secondary,
          secondary: const Icon(Icons.drag_handle),
        );
        break;
      case _ReorderableListType.horizontalAvatar:
      case _ReorderableListType.verticalAvatar:
        listTile = new Container(
          key: new Key(item.value),
          height: 100.0, 
          width: 100.0, 
          child: new CircleAvatar(child: new Text(item.value), 
            backgroundColor: Colors.green,
          ),
        );
        break;
    }
    
    return listTile;
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final _ListItem item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }


  @override
  Widget build(BuildContext context) {
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
                _items.sort((_ListItem a, _ListItem b) => _reverseSort ? b.value.compareTo(a.value) : a.value.compareTo(b.value));
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
          onReorder: _onReorder,
          scrollDirection: _itemType == _ReorderableListType.horizontalAvatar ? Axis.horizontal : Axis.vertical,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: _items.map(buildListTile).toList(),
        ),
      ),
    );
  }
}
