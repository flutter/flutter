// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

enum ListDemoItemSize {
  oneLine,
  twoLine,
  threeLine
}

class ListDemo extends StatefulWidget {
  ListDemo({ Key key }) : super(key: key);

  @override
  ListDemoState createState() => new ListDemoState();
}

class ListDemoState extends State<ListDemo> {
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  PersistentBottomSheetController<Null> _bottomSheet;
  ListDemoItemSize _itemSize = ListDemoItemSize.threeLine;
  bool _dense = false;
  bool _showAvatars = true;
  bool _showIcons = false;
  bool _showDividers = false;
  bool _reverseSort = false;
  List<String> items = <String>[
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N'
  ];

  void changeItemSize(ListDemoItemSize size) {
    setState(() {
      _itemSize = size;
    });
    _bottomSheet?.setState(() { });
  }

  void showConfigurationSheet(BuildContext appContext) {
    _bottomSheet = scaffoldKey.currentState.showBottomSheet((BuildContext bottomSheetContext) {
      return new Container(
        decoration: new BoxDecoration(
          border: new Border(top: new BorderSide(color: Colors.black26))
        ),
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.collapse,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new ListItem(
              dense: true,
              title: new Text('One-line'),
              trailing: new Radio<ListDemoItemSize>(
                value: ListDemoItemSize.oneLine,
                groupValue: _itemSize,
                onChanged: changeItemSize
              )
            ),
            new ListItem(
              dense: true,
              title: new Text('Two-line'),
              trailing: new Radio<ListDemoItemSize>(
                value: ListDemoItemSize.twoLine,
                groupValue: _itemSize,
                onChanged: changeItemSize
              )
            ),
            new ListItem(
              dense: true,
              title: new Text('Three-line'),
              trailing: new Radio<ListDemoItemSize>(
                value: ListDemoItemSize.threeLine,
                groupValue: _itemSize,
                onChanged: changeItemSize
              )
            ),
            new ListItem(
              dense: true,
              title: new Text('Show Avatar'),
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
              title: new Text('Show Icon'),
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
              title: new Text('Show Dividers'),
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
              title: new Text('Dense Layout'),
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
    if (_itemSize == ListDemoItemSize.twoLine) {
      secondary = new Text(
        "Additional item information."
      );
    } else if (_itemSize == ListDemoItemSize.threeLine) {
      secondary = new Text(
        "Even more additional list item information appears on line three."
      );
    }
    return new ListItem(
      isThreeLine: _itemSize == ListDemoItemSize.threeLine,
      dense: _dense,
      leading: _showAvatars ? new CircleAvatar(child: new Text(item)) : null,
      title: new Text('This item represents $item'),
      subtitle: secondary,
      trailing: _showIcons ? new Icon(icon: Icons.info, color: Theme.of(context).disabledColor) : null
    );
  }

  @override
  Widget build(BuildContext context) {
    final String layoutText = _dense ? " \u2013 Dense" : "";
    String  itemSizeText;
    switch(_itemSize) {
      case ListDemoItemSize.oneLine:
        itemSizeText = 'Single-Line';
        break;
      case ListDemoItemSize.twoLine:
        itemSizeText = 'Two-Line';
        break;
      case ListDemoItemSize.threeLine:
        itemSizeText = 'Three-Line';
        break;
    }

    Iterable<Widget> listItems = items.map((String item) => buildListItem(context, item));
    if (_showDividers)
      listItems = ListItem.divideItems(context: context, items: listItems);

    return new Scaffold(
      key: scaffoldKey,
      appBar: new AppBar(
        title: new Text('Scrolling List\n$itemSizeText$layoutText'),
        actions: <Widget>[
          new IconButton(
            icon: Icons.sort_by_alpha,
            tooltip: 'Sort',
            onPressed: () {
              setState(() {
                _reverseSort = !_reverseSort;
                items.sort((String a, String b) => _reverseSort ? b.compareTo(a) : a.compareTo(b));
              });
            }
          ),
          new IconButton(
            icon: Icons.more_vert,
            tooltip: 'Show menu',
            onPressed: () { showConfigurationSheet(context); }
          )
        ]
      ),
      body: new Block(
        padding: new EdgeInsets.all(_dense ? 4.0 : 8.0),
        children: listItems.toList()
      )
    );
  }
}
