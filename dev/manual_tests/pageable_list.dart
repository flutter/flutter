// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class CardModel {
  CardModel(this.value, this.size, this.color);
  int value;
  Size size;
  Color color;
  String get label => "Card $value";
  Key get key => new ObjectKey(this);
}

class PageableListApp extends StatefulWidget {
  @override
  PageableListAppState createState() => new PageableListAppState();
}

class PageableListAppState extends State<PageableListApp> {
  @override
  void initState() {
    super.initState();
    List<Size> cardSizes = <List<double>>[
      <double>[100.0, 300.0],
      <double>[300.0, 100.0],
      <double>[200.0, 400.0],
      <double>[400.0, 400.0],
      <double>[300.0, 400.0]
    ]
    .map((List<double> args) => new Size(args[0], args[1]))
    .toList();

    cardModels = new List<CardModel>.generate(cardSizes.length, (int i) {
      Color color = Color.lerp(Colors.red[300], Colors.blue[900], i / cardSizes.length);
      return new CardModel(i, cardSizes[i], color);
    });
  }

  static const TextStyle cardLabelStyle =
    const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold);

  List<CardModel> cardModels;
  Size pageSize = new Size(200.0, 200.0);
  Axis scrollDirection = Axis.horizontal;
  bool itemsWrap = false;

  Widget buildCard(CardModel cardModel) {
    Widget card = new Card(
      color: cardModel.color,
      child: new Container(
        width: cardModel.size.width,
        height: cardModel.size.height,
        padding: const EdgeInsets.all(8.0),
        child: new Center(child: new Text(cardModel.label, style: cardLabelStyle))
      )
    );

    BoxConstraints constraints = (scrollDirection == Axis.vertical)
      ? new BoxConstraints.tightFor(height: pageSize.height)
      : new BoxConstraints.tightFor(width: pageSize.width);

    return new Container(
      key: cardModel.key,
      constraints: constraints,
      child: new Center(child: card)
    );
  }

  void switchScrollDirection() {
    setState(() {
      scrollDirection = (scrollDirection == Axis.vertical)
        ? Axis.horizontal
        : Axis.vertical;
    });
  }

  void toggleItemsWrap() {
    setState(() {
      itemsWrap = !itemsWrap;
    });
  }

  Widget _buildDrawer() {
    return new Drawer(
      child: new ListView(
        children: <Widget>[
          new DrawerHeader(child: new Center(child: new Text('Options'))),
          new DrawerItem(
            icon: new Icon(Icons.more_horiz),
            selected: scrollDirection == Axis.horizontal,
            child: new Text('Horizontal Layout'),
            onPressed: switchScrollDirection
          ),
          new DrawerItem(
            icon: new Icon(Icons.more_vert),
            selected: scrollDirection == Axis.vertical,
            child: new Text('Vertical Layout'),
            onPressed: switchScrollDirection
          ),
          new DrawerItem(
            onPressed: toggleItemsWrap,
            child: new Row(
              children: <Widget>[
                new Expanded(child: new Text('Scrolling wraps around')),
                // TODO(abarth): Actually make this checkbox change this value.
                new Checkbox(value: itemsWrap, onChanged: null)
              ]
            )
          )
        ]
      )
    );
  }

  Widget _buildAppBar() {
    return new AppBar(
      title: new Text('PageableList'),
      actions: <Widget>[
        new Text(scrollDirection == Axis.horizontal ? "horizontal" : "vertical")
      ]
    );
  }

  Widget _buildBody(BuildContext context) {
    return new PageView(
      children: cardModels.map(buildCard).toList(),
      // TODO(abarth): itemsWrap: itemsWrap,
      scrollDirection: scrollDirection
    );
  }

  @override
  Widget build(BuildContext context) {
    return new IconTheme(
      data: const IconThemeData(color: Colors.white),
      child: new Scaffold(
        appBar: _buildAppBar(),
        drawer: _buildDrawer(),
        body: _buildBody(context)
      )
    );
  }
}

void main() {
  runApp(new MaterialApp(
    title: 'PageableList',
    theme: new ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      accentColor: Colors.redAccent[200],
    ),
    home: new PageableListApp()
  ));
}
