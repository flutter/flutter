// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

enum ListDemoItemSize {
  oneLine,
  twoLine,
  threeLine
}

class ListDemo extends StatefulComponent {
  ListDemo({ Key key }) : super(key: key);

  ListDemoState createState() => new ListDemoState();
}

class ListDemoState extends State<ListDemo> {
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  ScaffoldFeatureController _bottomSheet;
  ListDemoItemSize _itemSize = ListDemoItemSize.threeLine;
  bool _isDense = true;
  bool _showAvatar = true;
  bool _showIcon = false;
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
          border: new Border(top: new BorderSide(color: Colors.black26, width: 1.0))
        ),
        child: new Column(
          justifyContent: FlexJustifyContent.collapse,
          alignItems: FlexAlignItems.stretch,
          children: <Widget>[
            new ListItem(
              isDense: true,
              primary: new Text('One-line'),
              right: new Radio<ListDemoItemSize>(
                value: ListDemoItemSize.oneLine,
                groupValue: _itemSize,
                onChanged: changeItemSize
              )
            ),
            new ListItem(
              isDense: true,
              primary: new Text('Two-line'),
              right: new Radio<ListDemoItemSize>(
                value: ListDemoItemSize.twoLine,
                groupValue: _itemSize,
                onChanged: changeItemSize
              )
            ),
            new ListItem(
              isDense: true,
              primary: new Text('Three-line'),
              right: new Radio<ListDemoItemSize>(
                value: ListDemoItemSize.threeLine,
                groupValue: _itemSize,
                onChanged: changeItemSize
              )
            ),
            new ListItem(
              isDense: true,
              primary: new Text('Show Avatar'),
              right: new Checkbox(
                value: _showAvatar,
                onChanged: (bool value) {
                  setState(() {
                    _showAvatar = value;
                  });
                  _bottomSheet?.setState(() { });
                }
              )
            ),
            new ListItem(
              isDense: true,
              primary: new Text('Show Icon'),
              right: new Checkbox(
                value: _showIcon,
                onChanged: (bool value) {
                  setState(() {
                    _showIcon = value;
                  });
                  _bottomSheet?.setState(() { });
                }
              )
            ),
            new ListItem(
              isDense: true,
              primary: new Text('Dense Layout'),
              right: new Checkbox(
                value: _isDense,
                onChanged: (bool value) {
                  setState(() {
                    _isDense = value;
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
      isDense: _isDense,
      left: _showAvatar ? new CircleAvatar(child: new Text(item)) : null,
      primary: new Text('This item represents $item'),
      secondary: secondary,
      right: _showIcon ? new Icon(icon: 'action/info', color: Theme.of(context).disabledColor) : null
    );
  }

  Widget build(BuildContext context) {
    final String layoutText = _isDense ? " \u2013 Dense" : "";
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
    return new Scaffold(
      key: scaffoldKey,
      toolBar: new ToolBar(
        center: new Text('Scrolling List\n$itemSizeText$layoutText'),
        right: <Widget>[
          new IconButton(
            icon: "av/sort_by_alpha",
            tooltip: 'Sort',
            onPressed: () {
              setState(() {
                _reverseSort = !_reverseSort;
                items.sort((String a, String b) => _reverseSort ? b.compareTo(a) : a.compareTo(b));
              });
            }
          ),
          new IconButton(
            icon: "navigation/more_vert",
            tooltip: 'Show menu',
            onPressed: () { showConfigurationSheet(context); }
          )
        ]
      ),
      body: new Block(
        padding: new EdgeDims.all(_isDense ? 4.0 : 8.0),
        children: items.map((String item) => buildListItem(context, item)).toList()
      )
    );
  }
}
