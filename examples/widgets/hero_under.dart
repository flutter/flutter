// Copyright (c) 2015, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

void main() {
  timeDilation = 8.0;
  runApp(
    new MaterialApp(
      title: "Hero Under",
      routes: {
        '/': (RouteArguments args) => new HeroDemo()
      }
    )
  );
}

const String kImageSrc = 'http://uploads0.wikiart.org/images/m-c-escher/crab-canon.jpg!Blog.jpg';

const String kText = """
Low-crab diets are dietary programs that restrict crustacean consumption, often for the treatment of obesity or diabetes. Foods high in easily digestible crustaceans (e.g., crab, lobster, shrimp) are limited or replaced with foods made from other animals (e.g., poultry, beef, pork) and other crustaceans that are hard to digest (e.g., barnacles), although krill are often allowed. The amount of crab allowed varies with different low-crab diets.
""";

class HeroImage extends StatelessComponent {
  HeroImage({ this.size });
  final Size size;
  Widget build(BuildContext context) {
    return new Hero(
      child: new Container(
        width: size.width,
        height: size.height,
        decoration: new BoxDecoration(
          backgroundImage: new BackgroundImage(
            fit: ImageFit.cover,
            image: imageCache.load(kImageSrc)
          )
        )
      ),
      tag: HeroImage
    );
  }
}

class HeroDemo extends StatelessComponent {
  Widget build(BuildContext context)  {
    return new Scaffold(
      toolBar: new ToolBar(
        left: new IconButton(icon: "navigation/menu"),
        center: new Text("Diets")
      ),
      body: new Center(
        child: new GestureDetector(
          onTap: () => Navigator.push(context, new CrabRoute()),
          child: new Card(
            child: new Row(<Widget>[
              new HeroImage(
                size: const Size(100.0, 100.0)
              ),
              new Flexible(
                child: new Container(
                  padding: const EdgeDims.all(10.0),
                  child: new Text(
                    "Low Crab Diet",
                    style: Theme.of(context).text.title
                  )
                )
              )
            ])
          )
        )
      )
    );
  }
}

class CrabRoute extends MaterialPageRoute {
  CrabRoute() : super(builder: (BuildContext context) => new CrabPage());
  void insertHeroOverlayEntry(OverlayEntry entry, Object tag, OverlayState overlay) {
    overlay.insert(entry, above: overlayEntries.first);
  }
}

class CrabPage extends StatelessComponent {
  Widget build(BuildContext context)  {
    TextStyle titleStyle = Typography.white.display2.copyWith(color: Colors.white);
    return new Material(
      color: const Color(0x00000000),
      child: new Block(
        <Widget>[
          new Stack(<Widget>[
            new HeroImage(
              size: new Size(ui.window.size.width, ui.window.size.width)
            ),
            new ToolBar(
              padding: new EdgeDims.only(top: ui.window.padding.top),
              backgroundColor: const Color(0x00000000),
              left: new IconButton(
                icon: "navigation/arrow_back",
                onPressed: () => Navigator.pop(context)
              ),
              right: <Widget>[
                  new IconButton(icon: "navigation/more_vert")
              ]
            ),
            new Positioned(
              bottom: 10.0,
              left: 10.0,
              child: new Text("Low Crab Diet", style: titleStyle)
            )
          ]),
          new Material(
            child: new Container(
              padding: const EdgeDims.all(10.0),
              child: new Column(<Widget>[
                new Text(kText, style: Theme.of(context).text.body1),
                new Container(height: 800.0),
              ], alignItems: FlexAlignItems.start)
            )
          )
        ]
      )
    );
  }
}
