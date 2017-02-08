// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show debugDumpRenderTree;

class CardModel {
  CardModel(this.value, this.height) {
    inputValue = new InputValue(text: "Item $value");
  }
  int value;
  double height;
  int get color => ((value % 9) + 1) * 100;
  InputValue inputValue;
  Key get key => new ObjectKey(this);
}

class CardCollection extends StatefulWidget {
  @override
  CardCollectionState createState() => new CardCollectionState();
}

class CardCollectionState extends State<CardCollection> {

  static const TextStyle cardLabelStyle =
    const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold);

  // TODO(hansmuller): need a local image asset
  static const String _sunshineURL = "http://www.walltor.com/images/wallpaper/good-morning-sunshine-58540.jpg";

  static const double kCardMargins = 8.0;
  static const double kFixedCardHeight = 100.0;

  Map<int, Color> _primaryColor = Colors.deepPurple;
  List<CardModel> _cardModels;
  DismissDirection _dismissDirection = DismissDirection.horizontal;
  TextAlign _textAlign = TextAlign.center;
  bool _editable = false;
  bool _snapToCenter = false;
  bool _fixedSizeCards = false;
  bool _sunshine = false;
  bool _varyFontSizes = false;

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
    _cardModels = new List<CardModel>.generate(
      cardCount,
      (int i) => new CardModel(i, kFixedCardHeight)
    );
  }

  void _initCardModels() {
    if (_fixedSizeCards)
      _initFixedSizedCardModels();
    else
      _initVariableSizedCardModels();
  }

  Iterable<int> get _cardIndices sync* {
    for (int i = 0; i < _cardModels.length; i += 1)
      yield i;
  }

  @override
  void initState() {
    super.initState();
    _initCardModels();
  }

  double _variableSizeToSnapOffset(double scrollOffset) {
    double cumulativeHeight = 0.0;
    List<double> cumulativeHeights = _cardModels.map((CardModel card) {
      cumulativeHeight += card.height + kCardMargins;
      return cumulativeHeight;
    })
    .toList();

    double offsetForIndex(int i) {
      return (kCardMargins + _cardModels[i].height) / 2.0 + ((i == 0) ? 0.0 : cumulativeHeights[i - 1]);
    }

    for (int i = 0; i <  cumulativeHeights.length; i++) {
      if (cumulativeHeights[i] >= scrollOffset)
        return offsetForIndex(i);
    }
    return offsetForIndex(cumulativeHeights.length - 1);
  }

  double _fixedSizeToSnapOffset(double scrollOffset) {
    int cardIndex = (scrollOffset.clamp(0.0, kFixedCardHeight * (_cardModels.length - 1)) / kFixedCardHeight).floor();
    return cardIndex * kFixedCardHeight + kFixedCardHeight * 0.5;
  }

  double _toSnapOffset(double scrollOffset, Size containerSize) {
    double halfHeight = containerSize.height / 2.0;
    scrollOffset += halfHeight;
    double result = _fixedSizeCards ? _fixedSizeToSnapOffset(scrollOffset) : _variableSizeToSnapOffset(scrollOffset);
    return result - halfHeight;
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
        data: const IconThemeData(color: Colors.black),
        child: new ListView(
          children: <Widget>[
            new DrawerHeader(child: new Center(child: new Text('Options'))),
            buildDrawerCheckbox("Make card labels editable", _editable, _toggleEditable),
            buildDrawerCheckbox("Snap fling scrolls to center", _snapToCenter, _toggleSnapToCenter),
            buildDrawerCheckbox("Fixed size cards", _fixedSizeCards, _toggleFixedSizeCards),
            buildDrawerCheckbox("Let the sun shine", _sunshine, _toggleSunshine),
            buildDrawerCheckbox("Vary font sizes", _varyFontSizes, _toggleVaryFontSizes, enabled: !_editable),
            new Divider(),
            buildDrawerColorRadioItem("Deep Purple", Colors.deepPurple, _primaryColor, _selectColor),
            buildDrawerColorRadioItem("Green", Colors.green, _primaryColor, _selectColor),
            buildDrawerColorRadioItem("Amber", Colors.amber, _primaryColor, _selectColor),
            buildDrawerColorRadioItem("Teal", Colors.teal, _primaryColor, _selectColor),
            new Divider(),
            buildDrawerDirectionRadioItem("Dismiss horizontally", DismissDirection.horizontal, _dismissDirection, _changeDismissDirection, icon: Icons.code),
            buildDrawerDirectionRadioItem("Dismiss left", DismissDirection.endToStart, _dismissDirection, _changeDismissDirection, icon: Icons.arrow_back),
            buildDrawerDirectionRadioItem("Dismiss right", DismissDirection.startToEnd, _dismissDirection, _changeDismissDirection, icon: Icons.arrow_forward),
            new Divider(),
            buildFontRadioItem("Left-align text", TextAlign.left, _textAlign, _changeTextAlign, icon: Icons.format_align_left, enabled: !_editable),
            buildFontRadioItem("Center-align text", TextAlign.center, _textAlign, _changeTextAlign, icon: Icons.format_align_center, enabled: !_editable),
            buildFontRadioItem("Right-align text", TextAlign.right, _textAlign, _changeTextAlign, icon: Icons.format_align_right, enabled: !_editable),
            new Divider(),
            new DrawerItem(
              icon: new Icon(Icons.dvr),
              onPressed: () { debugDumpApp(); debugDumpRenderTree(); },
              child: new Text('Dump App to Console')
            ),
          ]
        )
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

  void _changeTextAlign(TextAlign newTextAlign) {
    setState(() {
      _textAlign = newTextAlign;
    });
  }

  Widget buildDrawerCheckbox(String label, bool value, void callback(), { bool enabled: true }) {
    return new DrawerItem(
      onPressed: enabled ? callback : null,
      child: new Row(
        children: <Widget>[
          new Expanded(child: new Text(label)),
          new Checkbox(
            value: value,
            onChanged: enabled ? (_) { callback(); } : null
          )
        ]
      )
    );
  }

  Widget buildDrawerColorRadioItem(String label, Map<int, Color> itemValue, Map<int, Color> currentValue, ValueChanged<Map<int, Color>> onChanged, { IconData icon, bool enabled: true }) {
    return new DrawerItem(
      icon: new Icon(icon),
      onPressed: enabled ? () { onChanged(itemValue); } : null,
      child: new Row(
        children: <Widget>[
          new Expanded(child: new Text(label)),
          new Radio<Map<int, Color>>(
            value: itemValue,
            groupValue: currentValue,
            onChanged: enabled ? onChanged : null
          )
        ]
      )
    );
  }

  Widget buildDrawerDirectionRadioItem(String label, DismissDirection itemValue, DismissDirection currentValue, ValueChanged<DismissDirection> onChanged, { IconData icon, bool enabled: true }) {
    return new DrawerItem(
      icon: new Icon(icon),
      onPressed: enabled ? () { onChanged(itemValue); } : null,
      child: new Row(
        children: <Widget>[
          new Expanded(child: new Text(label)),
          new Radio<DismissDirection>(
            value: itemValue,
            groupValue: currentValue,
            onChanged: enabled ? onChanged : null
          )
        ]
      )
    );
  }

  Widget buildFontRadioItem(String label, TextAlign itemValue, TextAlign currentValue, ValueChanged<TextAlign> onChanged, { IconData icon, bool enabled: true }) {
    return new DrawerItem(
      icon: new Icon(icon),
      onPressed: enabled ? () { onChanged(itemValue); } : null,
      child: new Row(
        children: <Widget>[
          new Expanded(child: new Text(label)),
          new Radio<TextAlign>(
            value: itemValue,
            groupValue: currentValue,
            onChanged: enabled ? onChanged : null
          )
        ]
      )
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return new AppBar(
      actions: <Widget>[
        new Text(_dismissDirectionText(_dismissDirection))
      ],
      flexibleSpace: new Container(
        padding: const EdgeInsets.only(left: 72.0),
        height: 128.0,
        alignment: const FractionalOffset(0.0, 0.75),
        child: new Text('Swipe Away: ${_cardModels.length}', style: Theme.of(context).primaryTextTheme.title)
      )
    );
  }

  Widget _buildCard(BuildContext context, int index) {
    if (index >= _cardModels.length)
      return null;

    CardModel cardModel = _cardModels[index];
    Widget card = new Dismissable(
      key: new ObjectKey(cardModel),
      direction: _dismissDirection,
      onDismissed: (DismissDirection direction) { dismissCard(cardModel); },
      child: new Card(
        color: _primaryColor[cardModel.color],
        child: new Container(
          height: cardModel.height,
          padding: const EdgeInsets.all(kCardMargins),
          child: _editable ?
            new Center(
              child: new TextField(
                key: new GlobalObjectKey(cardModel),
                onChanged: (InputValue value) {
                  setState(() {
                    cardModel.inputValue = value;
                  });
                }
              )
            )
          : new DefaultTextStyle.merge(
              context: context,
              style: cardLabelStyle.copyWith(
                fontSize: _varyFontSizes ? 5.0 + index : null
              ),
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new Text(cardModel.inputValue.text, textAlign: _textAlign)
                ]
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
      case DismissDirection.endToStart:
        backgroundMessage = "Swipe left to dismiss";
        break;
      case DismissDirection.startToEnd:
        backgroundMessage = "Swipe right to dismiss";
        break;
      default:
        backgroundMessage = "Unsupported dismissDirection";
    }

    // TODO(abarth): This icon is wrong in RTL.
    Widget leftArrowIcon =  new Icon(Icons.arrow_back, size: 36.0);
    if (_dismissDirection == DismissDirection.startToEnd)
      leftArrowIcon = new Opacity(opacity: 0.1, child: leftArrowIcon);

      // TODO(abarth): This icon is wrong in RTL.
    Widget rightArrowIcon =  new Icon(Icons.arrow_forward, size: 36.0);
    if (_dismissDirection == DismissDirection.endToStart)
      rightArrowIcon = new Opacity(opacity: 0.1, child: rightArrowIcon);

    final ThemeData theme = Theme.of(context);
    final TextStyle backgroundTextStyle = theme.primaryTextTheme.title;

    // The background Widget appears behind the Dismissable card when the card
    // moves to the left or right. The Positioned widget ensures that the
    // size of the background,card Stack will be based only on the card. The
    // Viewport ensures that when the card's resize animation occurs, the
    // background (text and icons) will just be clipped, not resized.
    Widget background = new Positioned.fill(
      child: new Container(
        margin: const EdgeInsets.all(4.0),
        child: new Viewport(
          child: new Container(
            height: cardModel.height,
            decoration: new BoxDecoration(backgroundColor: theme.primaryColor),
            child: new Row(
              children: <Widget>[
                leftArrowIcon,
                new Expanded(
                  child: new Text(backgroundMessage,
                    style: backgroundTextStyle,
                    textAlign: TextAlign.center
                  )
                ),
                rightArrowIcon
              ]
            )
          )
        )
      )
    );

    return new IconTheme(
      key: cardModel.key,
      data: const IconThemeData(color: Colors.white),
      child: new Stack(children: <Widget>[background, card])
    );
  }

  Shader _createShader(Rect bounds) {
    return new LinearGradient(
        begin: FractionalOffset.topLeft,
        end: FractionalOffset.bottomLeft,
        colors: <Color>[const Color(0x00FFFFFF), const Color(0xFFFFFFFF)],
        stops: <double>[0.1, 0.35]
    )
    .createShader(bounds);
  }

  @override
  Widget build(BuildContext context) {
    Widget cardCollection;
    if (_fixedSizeCards) {
      cardCollection = new ScrollableList(
        snapOffsetCallback: _snapToCenter ? _toSnapOffset : null,
        itemExtent: kFixedCardHeight,
        children: _cardIndices.map<Widget>((int index) => _buildCard(context, index))
      );
    } else {
      cardCollection = new LazyBlock(
        delegate: new LazyBlockBuilder(builder: _buildCard),
        snapOffsetCallback: _snapToCenter ? _toSnapOffset : null
      );
    }

    if (_sunshine) {
      cardCollection = new Stack(
        children: <Widget>[
          new Column(children: <Widget>[new Image.network(_sunshineURL)]),
          new ShaderMask(child: cardCollection, shaderCallback: _createShader)
        ]
      );
    }

    Widget body = new Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      decoration: new BoxDecoration(backgroundColor: _primaryColor[50]),
      child: cardCollection
    );

    if (_snapToCenter) {
      Widget indicator = new IgnorePointer(
        child: new Align(
          alignment: FractionalOffset.centerLeft,
          child: new Container(
            height: 1.0,
            decoration: new BoxDecoration(backgroundColor: const Color(0x80FFFFFF))
          )
        )
      );
      body = new Stack(children: <Widget>[body, indicator]);
    }

    return new Theme(
      data: new ThemeData(
        primarySwatch: _primaryColor
      ),
      child: new Scaffold(
        appBar: _buildAppBar(context),
        drawer: _buildDrawer(),
        body: body
      )
    );
  }
}

void main() {
  runApp(new MaterialApp(
    title: 'Cards',
    home: new CardCollection()
  ));
}
