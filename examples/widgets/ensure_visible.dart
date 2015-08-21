// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/base/lerp.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets.dart';

class CardModel {
  CardModel(this.value, this.height, this.color);
  int value;
  double height;
  Color color;
  String get label => "Card $value";
  Key get key => new Key.fromObjectIdentity(this);
}

class EnsureVisibleApp extends App {

  static const TextStyle cardLabelStyle =
    const TextStyle(color: colors.white, fontSize: 18.0, fontWeight: bold);

  static const TextStyle selectedCardLabelStyle =
    const TextStyle(color: colors.white, fontSize: 24.0, fontWeight: bold);

  List<CardModel> cardModels;
  BlockViewportLayoutState layoutState = new BlockViewportLayoutState();
  CardModel selectedCardModel;

  void initState() {
    List<double> cardHeights = <double>[
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0,
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0,
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0
    ];
    cardModels = new List.generate(cardHeights.length, (i) {
      Color color = lerpColor(colors.Red[300], colors.Blue[900], i / cardHeights.length);
      return new CardModel(i, cardHeights[i], color);
    });

    super.initState();
  }

  EventDisposition handleTap(Widget card, CardModel cardModel) {
    ensureWidgetIsVisible(card, duration: const Duration(milliseconds: 200))
    .then((_) {
      setState(() { selectedCardModel = cardModel; });
    });

    return EventDisposition.processed;
  }

  Widget builder(int index) {
    if (index >= cardModels.length)
      return null;
    CardModel cardModel = cardModels[index];
    TextStyle style = (cardModel == selectedCardModel) ? selectedCardLabelStyle : cardLabelStyle;
    Widget card = new Card(
      color: cardModel.color,
      child: new Container(
        height: cardModel.height,
        padding: const EdgeDims.all(8.0),
        child: new Center(child: new Text(cardModel.label, style: style))
      )
    );
    return new Listener(
      key: cardModel.key,
      onGestureTap: (_) { return handleTap(card, cardModel); },
      child: card
    );
  }

  Widget build() {
    Widget cardCollection = new Container(
      padding: const EdgeDims.symmetric(vertical: 12.0, horizontal: 8.0),
      decoration: new BoxDecoration(backgroundColor: Theme.of(this).primarySwatch[50]),
      child: new VariableHeightScrollable(
        builder: builder,
        token: cardModels.length,
        layoutState: layoutState
      )
    );

    return new IconTheme(
      data: const IconThemeData(color: IconThemeColor.white),
      child: new Theme(
        data: new ThemeData(
          brightness: ThemeBrightness.light,
          primarySwatch: colors.Blue,
          accentColor: colors.RedAccent[200]
        ),
        child: new Title(
          title: 'Cards',
          child: new Scaffold(
            toolbar: new ToolBar(center: new Text('Tap a Card')),
            body: cardCollection
          )
        )
      )
    );
  }
}

void main() {
  runApp(new EnsureVisibleApp());
}
