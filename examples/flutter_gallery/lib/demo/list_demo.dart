// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class ListDemo extends StatefulWidget {
  ListDemo({ Key key }) : super(key: key);

  static const String routeName = '/list';

  @override
  ListDemoState createState() => new ListDemoState();
}

class ListDemoState extends State<ListDemo> {
  static final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  PersistentBottomSheetController<Null> _bottomSheet;
  MaterialListType _itemType = MaterialListType.threeLine;
  bool _dense = false;
  bool _showAvatars = true;
  bool _showIcons = false;
  bool _showDividers = false;
  bool _reverseSort = false;
  List<String> items = <String>[
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N'
  ];

  void changeItemType(MaterialListType type) {
    setState(() {
      _itemType = type;
    });
    _bottomSheet?.setState(() { });
  }

  void showConfigurationSheet(BuildContext appContext) {
    _bottomSheet = scaffoldKey.currentState.showBottomSheet((BuildContext bottomSheetContext) {
      return new Container(
        decoration: new BoxDecoration(
          border: new Border(top: new BorderSide(color: Colors.black26))
        ),
        child: new ListView(
          shrinkWrap: true,
          children: <Widget>[
            new ListItem(
              dense: true,
              title: new Text('One-line'),
              trailing: new Radio<MaterialListType>(
                value: _showAvatars ? MaterialListType.oneLineWithAvatar : MaterialListType.oneLine,
                groupValue: _itemType,
                onChanged: changeItemType
              )
            ),
            new ListItem(
              dense: true,
              title: new Text('Two-line'),
              trailing: new Radio<MaterialListType>(
                value: MaterialListType.twoLine,
                groupValue: _itemType,
                onChanged: changeItemType
              )
            ),
            new ListItem(
              dense: true,
              title: new Text('Three-line'),
              trailing: new Radio<MaterialListType>(
                value: MaterialListType.threeLine,
                groupValue: _itemType,
                onChanged: changeItemType
              )
            ),
            new ListItem(
              dense: true,
              title: new Text('Show avatar'),
              trailing: new Checkbox(
                value: _showAvatars,
                onChanged: (bool value) {
                  setState(() {
                    _showAvatars = value;
                  });
                  _bottomSheet?.setState(() { });
                }
              )
            ),
            new ListItem(
              dense: true,
              title: new Text('Show icon'),
              trailing: new Checkbox(
                value: _showIcons,
                onChanged: (bool value) {
                  setState(() {
                    _showIcons = value;
                  });
                  _bottomSheet?.setState(() { });
                }
              )
            ),
            new ListItem(
              dense: true,
              title: new Text('Show dividers'),
              trailing: new Checkbox(
                value: _showDividers,
                onChanged: (bool value) {
                  setState(() {
                    _showDividers = value;
                  });
                  _bottomSheet?.setState(() { });
                }
              )
            ),
            new ListItem(
              dense: true,
              title: new Text('Dense layout'),
              trailing: new Checkbox(
                value: _dense,
                onChanged: (bool value) {
                  setState(() {
                    _dense = value;
                  });
                  _bottomSheet?.setState(() { });
                }
              )
            )
          ]
        )
      );
    });
  }

  Widget buildListItem(BuildContext context, String item) {
    Widget secondary;
    if (_itemType == MaterialListType.twoLine) {
      secondary = new Text(
        "Additional item information."
      );
    } else if (_itemType == MaterialListType.threeLine) {
      secondary = new Text(
        "Even more additional list item information appears on line three."
      );
    }
    return new ListItem(
      isThreeLine: _itemType == MaterialListType.threeLine,
      dense: _dense,
      leading: _showAvatars ? new CircleAvatar(child: new Text(item)) : null,
      title: new Text('This item represents $item.'),
      subtitle: secondary,
      trailing: _showIcons ? new Icon(Icons.info, color: Theme.of(context).disabledColor) : null
    );
  }

  @override
  Widget build(BuildContext context) {
    final String layoutText = _dense ? " \u2013 Dense" : "";
    String  itemTypeText;
    switch(_itemType) {
      case MaterialListType.oneLine:
      case MaterialListType.oneLineWithAvatar:
        itemTypeText = 'Single-line';
        break;
      case MaterialListType.twoLine:
        itemTypeText = 'Two-line';
        break;
      case MaterialListType.threeLine:
        itemTypeText = 'Three-line';
        break;
    }

    Iterable<Widget> listItems = items.map((String item) => buildListItem(context, item));
    if (_showDividers)
      listItems = ListItem.divideItems(context: context, items: listItems);

    return new Scaffold(
      key: scaffoldKey,
      appBar: new AppBar(
        title: new Text('Scrolling list\n$itemTypeText$layoutText'),
        actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.sort_by_alpha),
            tooltip: 'Sort',
            onPressed: () {
              setState(() {
                _reverseSort = !_reverseSort;
                items.sort((String a, String b) => _reverseSort ? b.compareTo(a) : a.compareTo(b));
              });
            }
          ),
          new IconButton(
            icon: new Icon(Icons.more_vert),
            tooltip: 'Show menu',
            onPressed: () { showConfigurationSheet(context); }
          )
        ]
      ),
      body: new Scrollbar(
        child: new MaterialList(
          type: _itemType,
          padding: new EdgeInsets.symmetric(vertical: _dense ? 4.0 : 8.0),
          children: listItems
        )
      )
    );
  }
}
