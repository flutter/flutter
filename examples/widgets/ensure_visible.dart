// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class CardModel {
  CardModel(this.value, this.height, this.color);
  int value;
  double height;
  Color color;
  String get label => "Card $value";
  Key get key => new ObjectKey(this);
}

typedef void TappableCardCallback(BuildContext context);

class TappableCard extends StatelessComponent {
  TappableCard({ CardModel cardModel, this.selected, this.onTap })
    : cardModel = cardModel, super(key: cardModel.key);
  final CardModel cardModel;
  final bool selected;
  final TappableCardCallback onTap;

  static const TextStyle cardLabelStyle = const TextStyle(
    color: Colors.white,
    fontSize: 18.0,
    fontWeight: FontWeight.bold
  );

  static const TextStyle selectedCardLabelStyle = const TextStyle(
    color: Colors.white,
    fontSize: 24.0,
    fontWeight: FontWeight.bold
  );

  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: () => onTap(context),
      child: new Card(
        color: cardModel.color,
        child: new Container(
          height: cardModel.height,
          padding: const EdgeDims.all(8.0),
          child: new Center(
            child: new Text(
              cardModel.label,
              style: selected ? selectedCardLabelStyle : cardLabelStyle
            )
          )
        )
      )
    );
  }

}


class EnsureVisibleApp extends StatefulComponent {
  EnsureVisibleAppState createState() => new EnsureVisibleAppState();
}

class EnsureVisibleAppState extends State<EnsureVisibleApp> {

  List<CardModel> cardModels;
  int selectedCardIndex;

  void initState() {
    List<double> cardHeights = <double>[
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0,
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0,
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0
    ];
    cardModels = new List<CardModel>.generate(cardHeights.length, (int i) {
      Color color = Color.lerp(Colors.red[300], Colors.blue[900], i / cardHeights.length);
      return new CardModel(i, cardHeights[i], color);
    });
    super.initState();
  }

  Widget builder(BuildContext context, int index) {
    if (index >= cardModels.length)
      return null;
    return new TappableCard(
      cardModel: cardModels[index],
      selected: index == selectedCardIndex,
      onTap: (BuildContext context) {
        Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 200))
        .then((_) {
          setState(() { selectedCardIndex = index; });
        });
      }
    );
  }

  Widget build(BuildContext context) {
    return new IconTheme(
      data: const IconThemeData(color: IconThemeColor.white),
      child: new Theme(
        data: new ThemeData(
          brightness: ThemeBrightness.light,
          primarySwatch: Colors.blue,
          accentColor: Colors.redAccent[200]
        ),
        child: new Title(
          title: 'Cards',
          child: new Scaffold(
            toolBar: new ToolBar(center: new Text('Tap a card, any card')),
            body: new Container(
              padding: const EdgeDims.symmetric(vertical: 12.0, horizontal: 8.0),
              decoration: new BoxDecoration(backgroundColor: Theme.of(context).primarySwatch[50]),
              child: new ScrollableMixedWidgetList(
                builder: builder,
                token: cardModels.length
              )
            )
          )
        )
      )
    );
  }
}

void main() {
  runApp(new EnsureVisibleApp());
}
