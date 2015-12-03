// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';

class CardModel {
  CardModel(this.value, this.height) {
    label = "Item $value";
  }
  int value;
  double height;
  int get color => ((value % 9) + 1) * 100;
  String label;
  Key get key => new ObjectKey(this);
}

class CardCollection extends StatefulComponent {
  CardCollectionState createState() => new CardCollectionState();
}

class CardCollectionState extends State<CardCollection> {

  static const TextStyle cardLabelStyle =
    const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: bold);

  // TODO(hansmuller): need a local image asset
  static const _sunshineURL = "http://www.walltor.com/images/wallpaper/good-morning-sunshine-58540.jpg";

  final TextStyle backgroundTextStyle =
    Typography.white.title.copyWith(textAlign: TextAlign.center);

  Map<int, Color> _primaryColor = Colors.deepPurple;
  List<CardModel> _cardModels;
  DismissDirection _dismissDirection = DismissDirection.horizontal;
  TextStyle _textStyle = new TextStyle(textAlign: TextAlign.center);
  bool _editable = false;
  bool _snapToCenter = false;
  bool _fixedSizeCards = false;
  bool _sunshine = false;
  bool _varyFontSizes = false;
  InvalidatorCallback _invalidator;
  Size _cardCollectionSize = new Size(200.0, 200.0);

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  void _initVariableSizedCardModels() {
    List<double> cardHeights = <double>[
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0,
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0,
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0
    ];
    _cardModels = new List<CardModel>.generate(
      cardHeights.length,
      (int i) => new CardModel(i, cardHeights[i])
    );
  }

  void _initFixedSizedCardModels() {
    const int cardCount = 27;
    const double cardHeight = 100.0;
    _cardModels = new List<CardModel>.generate(
      cardCount,
      (int i) => new CardModel(i, cardHeight)
    );
  }

  void _initCardModels() {
    if (_fixedSizeCards)
      _initFixedSizedCardModels();
    else
      _initVariableSizedCardModels();
  }

  void initState() {
    super.initState();
    _initCardModels();
  }

  double _variableSizeToSnapOffset(double scrollOffset) {
    double cumulativeHeight = 0.0;
    double  margins = 8.0;
    List<double> cumulativeHeights = _cardModels.map((CardModel card) {
      cumulativeHeight += card.height + margins;
      return cumulativeHeight;
    })
    .toList();

    double offsetForIndex(int i) {
      return 12.0 + (margins + _cardModels[i].height) / 2.0 + ((i == 0) ? 0.0 : cumulativeHeights[i - 1]);
    }

    for (int i = 0; i <  cumulativeHeights.length; i++) {
      if (cumulativeHeights[i] >= scrollOffset)
        return offsetForIndex(i);
    }
    return offsetForIndex(cumulativeHeights.length - 1);
  }

  double _fixedSizeToSnapOffset(double scrollOffset) {
    double cardHeight = _cardModels[0].height;
    int cardIndex = (scrollOffset.clamp(0.0, cardHeight * (_cardModels.length - 1)) / cardHeight).floor();
    return 12.0 + cardIndex * cardHeight + cardHeight * 0.5;
  }

  double _toSnapOffset(double scrollOffset) {
    return _fixedSizeCards ? _fixedSizeToSnapOffset(scrollOffset) : _variableSizeToSnapOffset(scrollOffset);
  }

  void dismissCard(CardModel card) {
    if (_cardModels.contains(card)) {
      setState(() {
        _cardModels.remove(card);
      });
    }
  }

  Widget _buildDrawer() {
    return new Drawer(
      child: new IconTheme(
        data: const IconThemeData(color: IconThemeColor.black),
        child: new Block(<Widget>[
          new DrawerHeader(child: new Text('Options')),
          buildDrawerCheckbox("Make card labels editable", _editable, _toggleEditable),
          buildDrawerCheckbox("Snap fling scrolls to center", _snapToCenter, _toggleSnapToCenter),
          buildDrawerCheckbox("Fixed size cards", _fixedSizeCards, _toggleFixedSizeCards),
          buildDrawerCheckbox("Let the sun shine", _sunshine, _toggleSunshine),
          buildDrawerCheckbox("Vary font sizes", _varyFontSizes, _toggleVaryFontSizes, enabled: !_editable),
          new DrawerDivider(),
          buildDrawerColorRadioItem("Deep Purple", Colors.deepPurple, _primaryColor, _selectColor),
          buildDrawerColorRadioItem("Green", Colors.green, _primaryColor, _selectColor),
          buildDrawerColorRadioItem("Amber", Colors.amber, _primaryColor, _selectColor),
          buildDrawerColorRadioItem("Teal", Colors.teal, _primaryColor, _selectColor),
          new DrawerDivider(),
          buildDrawerDirectionRadioItem("Dismiss horizontally", DismissDirection.horizontal, _dismissDirection, _changeDismissDirection, icon: 'action/code'),
          buildDrawerDirectionRadioItem("Dismiss left", DismissDirection.left, _dismissDirection, _changeDismissDirection, icon: 'navigation/arrow_back'),
          buildDrawerDirectionRadioItem("Dismiss right", DismissDirection.right, _dismissDirection, _changeDismissDirection, icon: 'navigation/arrow_forward'),
          new DrawerDivider(),
          buildFontRadioItem("Left-align text", new TextStyle(textAlign: TextAlign.left), _textStyle, _changeTextStyle, icon: 'editor/format_align_left', enabled: !_editable),
          buildFontRadioItem("Center-align text", new TextStyle(textAlign: TextAlign.center), _textStyle, _changeTextStyle, icon: 'editor/format_align_center', enabled: !_editable),
          buildFontRadioItem("Right-align text", new TextStyle(textAlign: TextAlign.right), _textStyle, _changeTextStyle, icon: 'editor/format_align_right', enabled: !_editable),
          new DrawerDivider(),
          new DrawerItem(
            icon: 'device/dvr',
            onPressed: () { debugDumpApp(); debugDumpRenderTree(); },
            child: new Text('Dump App to Console')
          ),
        ])
      )
    );
  }

  String _dismissDirectionText(DismissDirection direction) {
    String s = direction.toString();
    return "dismiss ${s.substring(s.indexOf('.') + 1)}";
  }

  void _toggleEditable() {
    setState(() {
      _editable = !_editable;
    });
  }

  void _toggleFixedSizeCards() {
    setState(() {
      _fixedSizeCards = !_fixedSizeCards;
      _initCardModels();
    });
  }

  void _toggleSnapToCenter() {
    setState(() {
      _snapToCenter = !_snapToCenter;
    });
  }

  void _toggleSunshine() {
    setState(() {
      _sunshine = !_sunshine;
    });
  }

  void _toggleVaryFontSizes() {
    setState(() {
      _varyFontSizes = !_varyFontSizes;
    });
  }

  void _selectColor(Map<int, Color> selection) {
    setState(() {
      _primaryColor = selection;
    });
  }

  void _changeDismissDirection(DismissDirection newDismissDirection) {
    setState(() {
      _dismissDirection = newDismissDirection;
    });
  }

  void _changeTextStyle(TextStyle newTextStyle) {
    setState(() {
      _textStyle = newTextStyle;
    });
  }

  Widget buildDrawerCheckbox(String label, bool value, void callback(), { bool enabled: true }) {
    return new DrawerItem(
      onPressed: enabled ? callback : null,
      child: new Row(<Widget>[
        new Flexible(child: new Text(label)),
        new Checkbox(
          value: value,
          onChanged: enabled ? (_) { callback(); } : null
        )
      ])
    );
  }

  Widget buildDrawerColorRadioItem(String label, Map<int, Color> itemValue, Map<int, Color> currentValue, ValueChanged<Map<int, Color>> onChanged, { String icon, bool enabled: true }) {
    return new DrawerItem(
      icon: icon,
      onPressed: enabled ? () { onChanged(itemValue); } : null,
      child: new Row(<Widget>[
        new Flexible(child: new Text(label)),
        new Radio<Map<int, Color>>(
          value: itemValue,
          groupValue: currentValue,
          onChanged: enabled ? onChanged : null
        )
      ])
    );
  }

  Widget buildDrawerDirectionRadioItem(String label, DismissDirection itemValue, DismissDirection currentValue, ValueChanged<DismissDirection> onChanged, { String icon, bool enabled: true }) {
    return new DrawerItem(
      icon: icon,
      onPressed: enabled ? () { onChanged(itemValue); } : null,
      child: new Row(<Widget>[
        new Flexible(child: new Text(label)),
        new Radio<DismissDirection>(
          value: itemValue,
          groupValue: currentValue,
          onChanged: enabled ? onChanged : null
        )
      ])
    );
  }

  Widget buildFontRadioItem(String label, TextStyle itemValue, TextStyle currentValue, ValueChanged<TextStyle> onChanged, { String icon, bool enabled: true }) {
    return new DrawerItem(
      icon: icon,
      onPressed: enabled ? () { onChanged(itemValue); } : null,
      child: new Row(<Widget>[
        new Flexible(child: new Text(label)),
        new Radio<TextStyle>(
          value: itemValue,
          groupValue: currentValue,
          onChanged: enabled ? onChanged : null
        )
      ])
    );
  }

  Widget _buildToolBar() {
    return new ToolBar(
      left: new IconButton(icon: "navigation/menu", onPressed: () => _scaffoldKey.currentState?.openDrawer()),
      right: <Widget>[
        new Text(_dismissDirectionText(_dismissDirection))
      ],
      bottom: new Padding(
        padding: const EdgeDims.only(left: 72.0),
        child: new Align(
          alignment: const FractionalOffset(0.0, 0.5),
          child: new Text('Swipe Away: ${_cardModels.length}')
        )
      )
    );
  }

  Widget _buildCard(BuildContext context, int index) {
    if (index >= _cardModels.length)
      return null;

    CardModel cardModel = _cardModels[index];
    Widget card = new Dismissable(
      direction: _dismissDirection,
      onResized: () { _invalidator(<int>[index]); },
      onDismissed: () { dismissCard(cardModel); },
      child: new Card(
        color: Theme.of(context).primarySwatch[cardModel.color],
        child: new Container(
          height: cardModel.height,
          padding: const EdgeDims.all(8.0),
          child: _editable ?
            new Center(
              child: new Input(
                key: new GlobalObjectKey(cardModel),
                initialValue: cardModel.label,
                onChanged: (String value) {
                  cardModel.label = value;
                }
              )
            )
          : new DefaultTextStyle(
              style: DefaultTextStyle.of(context).merge(cardLabelStyle).merge(_textStyle).copyWith(
                fontSize: _varyFontSizes ? _cardModels.length.toDouble() : null
              ),
              child: new Column(<Widget>[
                  new Text(cardModel.label)
                ],
                alignItems: FlexAlignItems.stretch,
                justifyContent: FlexJustifyContent.center
              )
            )
        )
      )
    );

    String backgroundMessage;
    switch(_dismissDirection) {
      case DismissDirection.horizontal:
        backgroundMessage = "Swipe in either direction";
        break;
      case DismissDirection.left:
        backgroundMessage = "Swipe left to dismiss";
        break;
      case DismissDirection.right:
        backgroundMessage = "Swipe right to dismiss";
        break;
      default:
        backgroundMessage = "Unsupported dismissDirection";
    }

    Widget leftArrowIcon =  new Icon(icon: 'navigation/arrow_back', size: IconSize.s36);
    if (_dismissDirection == DismissDirection.right)
      leftArrowIcon = new Opacity(opacity: 0.1, child: leftArrowIcon);

    Widget rightArrowIcon =  new Icon(icon: 'navigation/arrow_forward', size: IconSize.s36);
    if (_dismissDirection == DismissDirection.left)
      rightArrowIcon = new Opacity(opacity: 0.1, child: rightArrowIcon);

    // The background Widget appears behind the Dismissable card when the card
    // moves to the left or right. The Positioned widget ensures that the
    // size of the background,card Stack will be based only on the card. The
    // Viewport ensures that when the card's resize animation occurs, the
    // background (text and icons) will just be clipped, not resized.
    Widget background = new Positioned(
      top: 0.0,
      right: 0.0,
      bottom: 0.0,
      left: 0.0,
      child: new Container(
        margin: const EdgeDims.all(4.0),
        child: new Viewport(
          child: new Container(
            height: cardModel.height,
            decoration: new BoxDecoration(backgroundColor: Theme.of(context).primaryColor),
            child: new Row(<Widget>[
              leftArrowIcon,
              new Flexible(child: new Text(backgroundMessage, style: backgroundTextStyle)),
              rightArrowIcon
            ])
          )
        )
      )
    );

    return new IconTheme(
      key: cardModel.key,
      data: const IconThemeData(color: IconThemeColor.white),
      child: new Stack(<Widget>[background, card])
    );
  }

  void _updateCardCollectionSize(Size newSize) {
    setState(() {
      _cardCollectionSize = newSize;
    });
  }

  ui.Shader _createShader(Rect bounds) {
    return new LinearGradient(
        begin: Point.origin,
        end: new Point(0.0, bounds.height),
        colors: <Color>[const Color(0x00FFFFFF), const Color(0xFFFFFFFF)],
        stops: <double>[0.1, 0.35]
    )
    .createShader();
  }

  Widget build(BuildContext context) {
    Widget cardCollection;
    if (_fixedSizeCards) {
      cardCollection = new ScrollableList<CardModel> (
        snapOffsetCallback: _snapToCenter ? _toSnapOffset : null,
        snapAlignmentOffset: _cardCollectionSize.height / 2.0,
        items: _cardModels,
        itemBuilder: (BuildContext context, CardModel card, int index) => _buildCard(context, card.value),
        itemExtent: _cardModels[0].height
      );
    } else {
      cardCollection = new ScrollableMixedWidgetList(
        builder: _buildCard,
        token: _cardModels.length,
        snapOffsetCallback: _snapToCenter ? _toSnapOffset : null,
        snapAlignmentOffset: _cardCollectionSize.height / 2.0,
        onInvalidatorAvailable: (InvalidatorCallback callback) { _invalidator = callback; }
      );
    }

    if (_sunshine)
      cardCollection = new Stack(<Widget>[
        new Column(<Widget>[new NetworkImage(src: _sunshineURL)]),
        new ShaderMask(child: cardCollection, shaderCallback: _createShader)
      ]);

    Widget body = new SizeObserver(
      onSizeChanged: _updateCardCollectionSize,
      child: new Container(
        padding: const EdgeDims.symmetric(vertical: 12.0, horizontal: 8.0),
        decoration: new BoxDecoration(backgroundColor: Theme.of(context).primarySwatch[50]),
        child: cardCollection
      )
    );

    if (_snapToCenter) {
      Widget indicator = new IgnorePointer(
        child: new Align(
          alignment: const FractionalOffset(0.0, 0.5),
          child: new Container(
            height: 1.0,
            decoration: new BoxDecoration(backgroundColor: const Color(0x80FFFFFF))
          )
        )
      );
      body = new Stack(<Widget>[body, indicator]);
    }

    return new Theme(
      data: new ThemeData(
        primarySwatch: _primaryColor
      ),
      child: new Scaffold(
        toolBar: _buildToolBar(),
        drawer: _buildDrawer(),
        body: body
      )
    );
  }
}

void main() {
  runApp(new MaterialApp(
    title: 'Cards',
    routes: <String, RouteBuilder>{
      '/': (RouteArguments args) => new CardCollection(),
    }
  ));
}
