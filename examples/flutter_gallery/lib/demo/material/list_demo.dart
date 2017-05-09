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
            new ListTile(
              dense: true,
              title: const Text('One-line'),
              trailing: new Radio<_MaterialListType>(
                value: _showAvatars ? _MaterialListType.oneLineWithAvatar : _MaterialListType.oneLine,
                groupValue: _itemType,
                onChanged: changeItemType,
              )
            ),
            new ListTile(
              dense: true,
              title: const Text('Two-line'),
              trailing: new Radio<_MaterialListType>(
                value: _MaterialListType.twoLine,
                groupValue: _itemType,
                onChanged: changeItemType,
              )
            ),
            new ListTile(
              dense: true,
              title: const Text('Three-line'),
              trailing: new Radio<_MaterialListType>(
                value: _MaterialListType.threeLine,
                groupValue: _itemType,
                onChanged: changeItemType,
              ),
            ),
            new ListTile(
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
            new ListTile(
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
            new ListTile(
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
            new ListTile(
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

  Widget buildListTile(BuildContext context, String item) {
    Widget secondary;
    if (_itemType == _MaterialListType.twoLine) {
      secondary = const Text("Additional item information.");
    } else if (_itemType == _MaterialListType.threeLine) {
      secondary = const Text(
        "Even more additional list item information appears on line three.",
      );
    }
    return new ListTile(
      isThreeLine: _itemType == _MaterialListType.threeLine,
      dense: _dense,
      leading: _showAvatars ? new CircleAvatar(child: new Text(item)) : null,
      title: new Text('This item represents $item.'),
      subtitle: secondary,
      trailing: _showIcons ? new Icon(Icons.info, color: Theme.of(context).disabledColor) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String layoutText = _dense ? " \u2013 Dense" : "";
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

    Iterable<Widget> listTiles = items.map((String item) => buildListTile(context, item));
    if (_showDividers)
      listTiles = ListTile.divideTiles(context: context, tiles: listTiles);

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
        child: new ListView(
          padding: new EdgeInsets.symmetric(vertical: _dense ? 4.0 : 8.0),
          children: listTiles.toList(),
        ),
      ),
    );
  }
}
