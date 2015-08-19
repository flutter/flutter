// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/base/lerp.dart';
import 'package:sky/painting/text_style.dart';
import 'package:sky/theme/colors.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/card.dart';
import 'package:sky/widgets/icon.dart';
import 'package:sky/widgets/scrollable.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/tool_bar.dart';
import 'package:sky/widgets/framework.dart';
import 'package:sky/widgets/task_description.dart';

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
      [100.0, 300.0], [300.0, 100.0], [200.0, 400.0], [400.0, 400.0], [300.0, 400.0],
      [100.0, 300.0], [300.0, 100.0], [200.0, 400.0], [400.0, 400.0], [300.0, 400.0],
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

  EventDisposition handleToolbarTap(_) {
    setState(() {
      scrollDirection = (scrollDirection == ScrollDirection.vertical)
        ? ScrollDirection.horizontal
        : ScrollDirection.vertical;
    });
    return EventDisposition.processed;
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

  Widget build() {
    Widget list = new PageableList<CardModel>(
      items: cardModels,
      itemBuilder: buildCard,
      scrollDirection: scrollDirection,
      itemExtent: (scrollDirection == ScrollDirection.vertical)
          ? pageSize.height
          : pageSize.width
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
          label: 'PageableList',
          child: new Scaffold(
            toolbar: new Listener(
              onGestureTap: handleToolbarTap,
              child: new ToolBar(center: new Text('PageableList: ${scrollDirection}'))
            ),
            body: new SizeObserver(
              callback: updatePageSize,
              child: new Container(
                child: list,
                decoration: new BoxDecoration(backgroundColor: Theme.of(this).primarySwatch[50])
              )
            )
          )
        )
      )
    );
  }
}

void main() {
  runApp(new PageableListApp());
}
