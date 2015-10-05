// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/material.dart';
import 'package:sky/painting.dart';
import 'package:sky/widgets.dart';

class CardModel {
  CardModel(this.value, this.height, this.color);
  int value;
  double height;
  Color color;
  String get label => "Item $value";
  Key get key => new ObjectKey(this);
}

class CardCollection extends StatefulComponent {
  CardCollection({ this.navigator });

  final NavigatorState navigator;

  CardCollectionState createState() => new CardCollectionState();
}

class CardCollectionState extends State<CardCollection> {

  static const TextStyle cardLabelStyle =
    const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: bold);

  // TODO(hansmuller): need a local image asset
  static const _sunshineURL = "http://www.walltor.com/images/wallpaper/good-morning-sunshine-58540.jpg";

  final TextStyle backgroundTextStyle =
    Typography.white.title.copyWith(textAlign: TextAlign.center);

  List<CardModel> _cardModels;
  DismissDirection _dismissDirection = DismissDirection.horizontal;
  bool _snapToCenter = false;
  bool _fixedSizeCards = false;
  bool _sunshine = false;
  InvalidatorCallback _invalidator;
  Size _cardCollectionSize = new Size(200.0, 200.0);

  void _initVariableSizedCardModels() {
    List<double> cardHeights = <double>[
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0,
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0,
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0
    ];
    _cardModels = new List.generate(cardHeights.length, (i) {
      Color color = Color.lerp(Colors.red[300], Colors.blue[900], i / cardHeights.length);
      return new CardModel(i, cardHeights[i], color);
    });
  }

  void _initFixedSizedCardModels() {
    const int cardCount = 27;
    const double cardHeight = 100.0;
    _cardModels = new List.generate(cardCount, (i) {
      Color color = Color.lerp(Colors.red[300], Colors.blue[900], i / cardCount);
      return new CardModel(i, cardHeight, color);
    });
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
    List<double> cumulativeHeights = _cardModels.map((card) {
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

  void _showDrawer() {
    showDrawer(
      navigator: config.navigator,
      child: new IconTheme(
        data: const IconThemeData(color: IconThemeColor.black),
        child: new Block([
          new DrawerHeader(child: new Text('Options')),
          buildDrawerCheckbox("Snap fling scrolls to center", _snapToCenter, _toggleSnapToCenter),
          buildDrawerCheckbox("Fixed size cards", _fixedSizeCards, _toggleFixedSizeCards),
          buildDrawerCheckbox("Let the sun shine", _sunshine, _toggleSunshine),
          new DrawerDivider(),
          buildDrawerRadioItem(DismissDirection.horizontal, 'action/code'),
          buildDrawerRadioItem(DismissDirection.left, 'navigation/arrow_back'),
          buildDrawerRadioItem(DismissDirection.right, 'navigation/arrow_forward'),
        ])
      )
    );
  }

  String _dismissDirectionText(DismissDirection direction) {
    String s = direction.toString();
    return "dismiss ${s.substring(s.indexOf('.') + 1)}";
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

  void _changeDismissDirection(DismissDirection newDismissDirection) {
    setState(() {
      _dismissDirection = newDismissDirection;
    });
    config.navigator.pop();
  }

  Widget buildDrawerCheckbox(String label, bool value, Function callback) {
    return new DrawerItem(
      onPressed: callback,
      child: new Row([
        new Flexible(child: new Text(label)),
        new Checkbox(value: value, onChanged: (_) { callback(); })
      ])
    );
  }

  Widget buildDrawerRadioItem(DismissDirection direction, String icon) {
    return new DrawerItem(
      icon: icon,
      onPressed: () { _changeDismissDirection(direction); },
      child: new Row([
        new Flexible(child: new Text(_dismissDirectionText(direction))),
        new Radio(
          value: direction,
          onChanged: _changeDismissDirection,
          groupValue: _dismissDirection
        )
      ])
    );
  }

  Widget buildToolBar() {
    return new ToolBar(
      left: new IconButton(icon: "navigation/menu", onPressed: _showDrawer),
      center: new Text('Swipe Away'),
      right: [
        new Text(_dismissDirectionText(_dismissDirection))
      ]
    );
  }

  Widget buildCard(BuildContext context, int index) {
    if (index >= _cardModels.length)
      return null;

    CardModel cardModel = _cardModels[index];
    Widget card = new Dismissable(
      direction: _dismissDirection,
      onResized: () { _invalidator([index]); },
      onDismissed: () { dismissCard(cardModel); },
      child: new Card(
        color: cardModel.color,
        child: new Container(
          height: cardModel.height,
          padding: const EdgeDims.all(8.0),
          child: new Center(child: new Text(cardModel.label, style: cardLabelStyle))
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

    Widget leftArrowIcon =  new Icon(type: 'navigation/arrow_back', size: 36);
    if (_dismissDirection == DismissDirection.right)
      leftArrowIcon = new Opacity(opacity: 0.1, child: leftArrowIcon);

    Widget rightArrowIcon =  new Icon(type: 'navigation/arrow_forward', size: 36);
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
            child: new Row([
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
      child: new Stack([background, card])
    );
  }

  void _updateCardCollectionSize(Size newSize) {
    setState(() {
      _cardCollectionSize = newSize;
    });
  }

  sky.Shader _createShader(Rect bounds) {
    return new LinearGradient(
        begin: Point.origin,
        end: new Point(0.0, bounds.height),
        colors: [const Color(0x00FFFFFF), const Color(0xFFFFFFFF)],
        stops: [0.1, 0.35]
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
        itemBuilder: (BuildContext context, CardModel card) => buildCard(context, card.value),
        itemExtent: _cardModels[0].height
      );
    } else {
      cardCollection = new ScrollableMixedWidgetList(
        builder: buildCard,
        token: _cardModels.length,
        snapOffsetCallback: _snapToCenter ? _toSnapOffset : null,
        snapAlignmentOffset: _cardCollectionSize.height / 2.0,
        onInvalidatorAvailable: (InvalidatorCallback callback) { _invalidator = callback; }
      );
    }

    if (_sunshine)
      cardCollection = new Stack([
        new Column([new NetworkImage(src: _sunshineURL)]),
        new ShaderMask(child: cardCollection, shaderCallback: _createShader)
      ]);

    Widget body = new SizeObserver(
      callback: _updateCardCollectionSize,
      child: new Container(
        padding: const EdgeDims.symmetric(vertical: 12.0, horizontal: 8.0),
        decoration: new BoxDecoration(backgroundColor: Theme.of(context).primarySwatch[50]),
        child: cardCollection
      )
    );

    if (_snapToCenter) {
      Widget indicator = new IgnorePointer(
        child: new Align(
          horizontal: 0.0,
          vertical: 0.5,
          child: new Container(
            height: 1.0,
            decoration: new BoxDecoration(backgroundColor: const Color(0x80FFFFFF))
          )
        )
      );
      body = new Stack([body, indicator]);
    }

    return new Scaffold(
      toolbar: buildToolBar(),
      body: body
    );
  }
}

void main() {
  runApp(new App(
    title: 'Cards',
    theme: new ThemeData(
      brightness: ThemeBrightness.light,
      primarySwatch: Colors.blue,
      accentColor: Colors.redAccent[200]
    ),
    routes: {
      '/': (RouteArguments args) => new CardCollection(navigator: args.navigator),
    }
  ));
}
