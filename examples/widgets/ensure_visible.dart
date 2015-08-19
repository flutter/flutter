// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/animation/animated_value.dart';
import 'package:sky/animation/animation_performance.dart';
import 'package:sky/animation/curves.dart';
import 'package:sky/base/lerp.dart';
import 'package:sky/painting/box_painter.dart';
import 'package:sky/painting/text_style.dart';
import 'package:sky/theme/colors.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/block_viewport.dart';
import 'package:sky/widgets/card.dart';
import 'package:sky/widgets/icon.dart';
import 'package:sky/widgets/scrollable.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/tool_bar.dart';
import 'package:sky/widgets/framework.dart';
import 'package:sky/widgets/task_description.dart';

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
    const TextStyle(color: white, fontSize: 18.0, fontWeight: bold);

  List<CardModel> cardModels;
  BlockViewportLayoutState layoutState = new BlockViewportLayoutState();
  ScrollListener scrollListener;
  ValueAnimation<double> scrollAnimation;

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

    scrollAnimation = new ValueAnimation<double>()
      ..duration = const Duration(milliseconds: 200)
      ..variable = new AnimatedValue<double>(0.0, curve: ease);

    super.initState();
  }

  EventDisposition handleTap(Widget target) {
    ensureWidgetIsVisible(target, animation: scrollAnimation);
    return EventDisposition.processed;
  }

  Widget builder(int index) {
    if (index >= cardModels.length)
      return null;
    CardModel cardModel = cardModels[index];
    Widget card = new Card(
      color: cardModel.color,
      child: new Container(
        height: cardModel.height,
        padding: const EdgeDims.all(8.0),
        child: new Center(child: new Text(cardModel.label, style: cardLabelStyle))
      )
    );
    return new Listener(
      key: cardModel.key,
      onGestureTap: (_) { return handleTap(card); },
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
          primarySwatch: Blue,
          accentColor: RedAccent[200]
        ),
        child: new TaskDescription(
          label: 'Cards',
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
