// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets.dart';

class GreenCard extends Component {
  GreenCard({ this.child });

  Widget child;

  Widget build() {
    return new Container(
      decoration: new BoxDecoration(
        backgroundColor: const Color(0xFF0000FF),
        border: new Border.all(
          color: const Color(0xFF00FF00),
          width: 10.0
        )
      ),
      child: new Center(child: child)
    );
  }
}

class CardData {
  final GlobalKey key;
  final String content;

  CardData({ this.key, this.content });
}

class ExampleApp extends App {
  ExampleApp() {
    for (int i = 0; i < 20; ++i) {
      _data.add(new CardData(
        key: new GlobalKey(),
        content: '$i'
      ));
    }
  }

  final List<CardData> _data = new List<CardData>();

  GlobalKey _overlay;

  Widget _buildCard(CardData cardData) {
    return new Listener(
      onGestureTap: (_) {
        setState(() {
          _overlay = cardData.key;
        });
      },
      child: new Container(
        height: 100.0,
        margin: new EdgeDims.symmetric(horizontal: 20.0, vertical: 4.0),
        child: new Mimicable(
          key: cardData.key,
          child: new GreenCard(child: new Text(cardData.content))
        )
      )
    );
  }

  Widget build() {
    List<Widget> cards = new List<Widget>();
    for (int i = 0; i < _data.length; ++i) {
      cards.add(_buildCard(_data[i]));
    }

    return new IconTheme(
      data: const IconThemeData(color: IconThemeColor.white),
      child: new Theme(
        data: new ThemeData(
          brightness: ThemeBrightness.light,
          primarySwatch: colors.Blue,
          accentColor: colors.RedAccent[200]
        ),
        child: new Scaffold(
          toolbar: new ToolBar(
            left: new IconButton(
              icon: "navigation/arrow_back",
              onPressed: () {
                setState(() {
                  _overlay = null;
                });
              }
            )
          ),
          body: new MimicOverlay(
            overlay: _overlay,
            duration: const Duration(milliseconds: 500),
            children: [ new Block(cards) ]
          )
        )
      )
    );
  }
}

void main() {
  runApp(new ExampleApp());
}
