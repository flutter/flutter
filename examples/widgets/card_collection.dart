// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/theme/typography.dart' as typography;
import 'package:sky/animation.dart';
import 'package:sky/widgets.dart';

class CardModel {
  CardModel(this.value, this.height, this.color);
  int value;
  double height;
  Color color;
  String get label => "Item $value";
  Key get key => new ObjectKey(this);
}

class CardCollectionApp extends App {

  static const TextStyle cardLabelStyle =
    const TextStyle(color: colors.white, fontSize: 18.0, fontWeight: bold);

  final TextStyle backgroundTextStyle =
    typography.white.title.copyWith(textAlign: TextAlign.center);

  MixedViewportLayoutState _layoutState = new MixedViewportLayoutState();
  List<CardModel> _cardModels;
  DismissDirection _dismissDirection = DismissDirection.horizontal;
  bool _drawerShowing = false;
  AnimationStatus _drawerStatus = AnimationStatus.dismissed;


  void initState() {
    List<double> cardHeights = <double>[
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0,
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0,
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0
    ];
    _cardModels = new List.generate(cardHeights.length, (i) {
      Color color = Color.lerp(colors.Red[300], colors.Blue[900], i / cardHeights.length);
      return new CardModel(i, cardHeights[i], color);
    });
    super.initState();
  }

  void dismissCard(CardModel card) {
    if (_cardModels.contains(card)) {
      setState(() {
        _cardModels.remove(card);
      });
    }
  }

  void _handleOpenDrawer() {
    setState(() {
      _drawerShowing = true;
      _drawerStatus = AnimationStatus.forward;
    });
  }

  void _handleDrawerDismissed() {
    setState(() {
      _drawerStatus = AnimationStatus.dismissed;
    });
  }

  String _dismissDirectionText(DismissDirection direction) {
    String s = direction.toString();
    return "dismiss ${s.substring(s.indexOf('.') + 1)}";
  }

  void changeDismissDirection(DismissDirection newDismissDirection) {
    setState(() {
      _dismissDirection = newDismissDirection;
      _drawerStatus = AnimationStatus.dismissed;
    });
  }

  Widget buildDrawer() {
    if (_drawerStatus == AnimationStatus.dismissed)
      return null;

    Widget buildDrawerItem(DismissDirection direction, String icon) {
      return new DrawerItem(
        icon: icon,
        onPressed: () { changeDismissDirection(direction); },
        child: new Row([
          new Flexible(child: new Text(_dismissDirectionText(direction))),
          new Radio(
            value: direction,
            onChanged: changeDismissDirection,
            groupValue: _dismissDirection
          )
        ])
      );
    }

    return new IconTheme(
      data: const IconThemeData(color: IconThemeColor.black),
      child: new Drawer(
        level: 3,
        showing: _drawerShowing,
        onDismissed: _handleDrawerDismissed,
        children: [
          new DrawerHeader(child: new Text('Dismiss Direction')),
          buildDrawerItem(DismissDirection.horizontal, 'action/code'),
          buildDrawerItem(DismissDirection.left, 'navigation/arrow_back'),
          buildDrawerItem(DismissDirection.right, 'navigation/arrow_forward')
        ]
      )
    );
  }

  Widget buildToolBar() {
    return new ToolBar(
      left: new IconButton(icon: "navigation/menu", onPressed: _handleOpenDrawer),
      center: new Text('Swipe Away'),
      right: [
        new Text(_dismissDirectionText(_dismissDirection))
      ]
    );
  }

  Widget buildCard(int index) {
    if (index >= _cardModels.length)
      return null;

    CardModel cardModel = _cardModels[index];
    Widget card = new Dismissable(
      direction: _dismissDirection,
      onResized: () { _layoutState.invalidate([index]); },
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
            decoration: new BoxDecoration(backgroundColor: Theme.of(this).primaryColor),
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

  Widget build() {
    Widget cardCollection = new Container(
      padding: const EdgeDims.symmetric(vertical: 12.0, horizontal: 8.0),
      decoration: new BoxDecoration(backgroundColor: Theme.of(this).primarySwatch[50]),
      child: new ScrollableMixedWidgetList(
        builder: buildCard,
        token: _cardModels.length,
        layoutState: _layoutState
      )
    );

    return new Theme(
      data: new ThemeData(
        brightness: ThemeBrightness.light,
        primarySwatch: colors.Blue,
        accentColor: colors.RedAccent[200]
      ),
      child: new Title(
        title: 'Cards',
        child: new Scaffold(
          toolbar: buildToolBar(),
          drawer: buildDrawer(),
          body: cardCollection
        )
      )
    );
  }
}

void main() {
  runApp(new CardCollectionApp());
}
