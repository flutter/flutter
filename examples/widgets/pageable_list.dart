// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/base/lerp.dart';
import 'package:sky/theme/colors.dart';
import 'package:sky/widgets.dart';

class CardModel {
  CardModel(this.value, this.size, this.color);
  int value;
  Size size;
  Color color;
  String get label => "Card $value";
  Key get key => new Key.fromObjectIdentity(this);
}

class PageableListApp extends App {

  static const TextStyle cardLabelStyle =
    const TextStyle(color: white, fontSize: 18.0, fontWeight: bold);

  List<CardModel> cardModels;
  Size pageSize = new Size(200.0, 200.0);
  ScrollDirection scrollDirection = ScrollDirection.horizontal;

  void initState() {
    List<Size> cardSizes = [
      [100.0, 300.0], [300.0, 100.0], [200.0, 400.0], [400.0, 400.0], [300.0, 400.0]
    ]
    .map((args) => new Size(args[0], args[1]))
    .toList();

    cardModels = new List.generate(cardSizes.length, (i) {
      Color color = lerpColor(Red[300], Blue[900], i / cardSizes.length);
      return new CardModel(i, cardSizes[i], color);
    });

    super.initState();
  }

  void updatePageSize(Size newSize) {
    setState(() {
      pageSize = newSize;
    });
  }

  Widget buildCard(CardModel cardModel) {
    Widget card = new Card(
      color: cardModel.color,
      child: new Container(
        width: cardModel.size.width,
        height: cardModel.size.height,
        padding: const EdgeDims.all(8.0),
        child: new Center(child: new Text(cardModel.label, style: cardLabelStyle))
      )
    );

    BoxConstraints constraints = (scrollDirection == ScrollDirection.vertical)
      ? new BoxConstraints.tightFor(height: pageSize.height)
      : new BoxConstraints.tightFor(width: pageSize.width);

    return new Container(
      key: cardModel.key,
      constraints: constraints,
      child: new Center(child: card)
    );
  }

  EventDisposition switchScrollDirection() {
    setState(() {
      scrollDirection = (scrollDirection == ScrollDirection.vertical)
        ? ScrollDirection.horizontal
        : ScrollDirection.vertical;
    });
    return EventDisposition.processed;
  }

  bool _drawerShowing = false;
  AnimationStatus _drawerStatus = AnimationStatus.dismissed;

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

  Drawer buildDrawer() {
    if (_drawerStatus == AnimationStatus.dismissed)
      return null;

    return new Drawer(
      level: 3,
      showing: _drawerShowing,
      onDismissed: _handleDrawerDismissed,
      children: [
        new DrawerHeader(child: new Text('Options')),
        new DrawerItem(
          icon: 'navigation/more_horiz',
          selected: scrollDirection == ScrollDirection.horizontal,
          child: new Text('Horizontal Layout'),
          onPressed: switchScrollDirection
        ),
        new DrawerItem(
          icon: 'navigation/more_vert',
          selected: scrollDirection == ScrollDirection.vertical,
          child: new Text('Vertical Layout'),
          onPressed: switchScrollDirection
        )
      ]
    );

  }

  Widget buildToolBar() {
    return new ToolBar(
      left: new IconButton(icon: "navigation/menu", onPressed: _handleOpenDrawer),
      center: new Text('PageableList'),
      right: [
        new Text(scrollDirection == ScrollDirection.horizontal ? "horizontal" : "vertical")
      ]
    );
  }

  Widget buildBody() {
    Widget list = new PageableList<CardModel>(
      items: cardModels,
      itemsWrap: true,
      itemBuilder: buildCard,
      scrollDirection: scrollDirection,
      itemExtent: (scrollDirection == ScrollDirection.vertical)
          ? pageSize.height
          : pageSize.width
    );
    return new SizeObserver(
      callback: updatePageSize,
      child: new Container(
        child: list,
        decoration: new BoxDecoration(backgroundColor: Theme.of(this).primarySwatch[50])
      )
    );
  }

  Widget build() {
    return new IconTheme(
      data: const IconThemeData(color: IconThemeColor.white),
      child: new Theme(
        data: new ThemeData(
          brightness: ThemeBrightness.light,
          primarySwatch: Blue,
          accentColor: RedAccent[200]
        ),
        child: new Title(
          title: 'PageableList',
          child: new Scaffold(
            drawer: buildDrawer(),
            toolbar: buildToolBar(),
            body: buildBody()
          )
        )
      )
    );
  }
}

void main() {
  runApp(new PageableListApp());
}
