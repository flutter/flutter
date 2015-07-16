// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/base/lerp.dart';
import 'package:sky/painting/text_style.dart';
import 'package:sky/theme/colors.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/card.dart';
import 'package:sky/widgets/dismissable.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/variable_height_scrollable.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/tool_bar.dart';
import 'package:sky/widgets/widget.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets/task_description.dart';


class CardCollectionApp extends App {

  final TextStyle cardLabelStyle =
    new TextStyle(color: white, fontSize: 18.0, fontWeight: bold);

  final List<double> cardHeights = [
    48.0, 64.0, 82.0, 46.0, 60.0, 55.0, 84.0, 96.0, 50.0,
    48.0, 64.0, 82.0, 46.0, 60.0, 55.0, 84.0, 96.0, 50.0,
    48.0, 64.0, 82.0, 46.0, 60.0, 55.0, 84.0, 96.0, 50.0,
    48.0, 64.0, 82.0, 46.0, 60.0, 55.0, 84.0, 96.0, 50.0
  ];

  List<int> visibleCardIndices;

  void initState() {
    visibleCardIndices = new List.generate(cardHeights.length, (i) => i);
    super.initState();
  }

  void dismissCard(int cardIndex) {
    setState(() {
      visibleCardIndices.remove(cardIndex);
    });
  }

  Widget _builder(int index) {
    if (index >= visibleCardIndices.length)
      return null;

    int cardIndex = visibleCardIndices[index];
    Color color = lerpColor(Red[500], Blue[500], cardIndex / cardHeights.length);
    Widget label = new Text("Item ${cardIndex}", style: cardLabelStyle);
    return new Dismissable(
      key: cardIndex.toString(),
      onDismissed: () { dismissCard(cardIndex); },
      child: new Card(
        color: color,
        child: new Container(
          height: cardHeights[cardIndex],
          padding: const EdgeDims.all(8.0),
          child: new Center(child: label)
        )
      )
    );
  }

  Widget build() {
    Widget cardCollection = new Container(
      padding: const EdgeDims.symmetric(vertical: 12.0, horizontal: 8.0),
      decoration: new BoxDecoration(backgroundColor: Theme.of(this).primarySwatch[50]),
      child: new VariableHeightScrollable(
        builder: _builder,
        token: visibleCardIndices.length
      )
    );

    return new Theme(
      data: new ThemeData(
        brightness: ThemeBrightness.light,
        primarySwatch: colors.Blue,
        accentColor: colors.RedAccent[200]
      ),
      child: new TaskDescription(
        label: 'Cards',
        child: new Scaffold(
          toolbar: new ToolBar(center: new Text('Swipe Away')),
          body: cardCollection
        )
      )
    );
  }
}

void main() {
  runApp(new CardCollectionApp());
}
