// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/base/lerp.dart';
import 'package:sky/painting/text_style.dart';
import 'package:sky/theme/colors.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/block_viewport.dart';
import 'package:sky/widgets/card.dart';
import 'package:sky/widgets/dismissable.dart';
import 'package:sky/widgets/icon.dart';
import 'package:sky/widgets/scrollable.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/tool_bar.dart';
import 'package:sky/theme/typography.dart' as typography;
import 'package:sky/widgets/widget.dart';
import 'package:sky/widgets/task_description.dart';

class CardModel {
  CardModel(this.value, this.height, this.color);
  int value;
  double height;
  Color color;
  String get label => "Item $value";
  Key get key => new Key.fromObjectIdentity(this);
}

class CardCollectionApp extends App {

  static const TextStyle cardLabelStyle =
    const TextStyle(color: white, fontSize: 18.0, fontWeight: bold);

  final TextStyle backgroundTextStyle =
    typography.white.title.copyWith(textAlign: TextAlign.center);

  BlockViewportLayoutState layoutState = new BlockViewportLayoutState();
  List<CardModel> cardModels;

  void initState() {
    List<double> cardHeights = <double>[
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0,
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0,
      48.0, 63.0, 82.0, 146.0, 60.0, 55.0, 84.0, 96.0, 50.0
    ];
    cardModels = new List.generate(cardHeights.length, (i) {
      Color color = lerpColor(Red[300], Blue[900], i / cardHeights.length);
      return new CardModel(i, cardHeights[i], color);
    });
    super.initState();
  }

  void dismissCard(CardModel card) {
    if (cardModels.contains(card)) {
      setState(() {
        cardModels.remove(card);
      });
    }
  }

  Widget builder(int index) {
    if (index >= cardModels.length)
      return null;

    CardModel cardModel = cardModels[index];
    Widget card = new Dismissable(
      onResized: () { layoutState.invalidate([index]); },
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

    Widget backgroundText = new Center(
        child: new Text("Swipe in either direction", style: backgroundTextStyle)
    );

    // The background Widget appears behind the Dismissable card when the card
    // moves to the left or right. The Positioned widget ensures that the
    // size of the background,card Stack will be based only on the card. The
    // Viewport ensures that when the card's resize animation occurs, the
    // background (text and icons) will just be clipped, not resized.
    Widget background = new Positioned(
      top: 0.0,
      left: 0.0,
      child: new Container(
        margin: const EdgeDims.all(4.0),
        child: new Viewport(
          child: new Container(
            height: cardModel.height,
            decoration: new BoxDecoration(backgroundColor: Theme.of(this).primaryColor),
            child: new Flex([
              new Icon(type: 'navigation/arrow_back', size: 36),
              new Flexible(child: backgroundText),
              new Icon(type: 'navigation/arrow_forward', size: 36)
            ])
          )
        )
      )
    );

    return new Stack([background, card], key: cardModel.key);
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
          primarySwatch: Blue,
          accentColor: RedAccent[200]
        ),
        child: new TaskDescription(
          label: 'Cards',
          child: new Scaffold(
            toolbar: new ToolBar(center: new Text('Swipe Away')),
            body: cardCollection
          )
        )
      )
    );
  }
}

void main() {
  runApp(new CardCollectionApp());
}
