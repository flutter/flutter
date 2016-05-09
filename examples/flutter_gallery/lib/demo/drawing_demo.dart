// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_sprites/flutter_sprites.dart';

class DrawingDemo extends StatefulWidget {
  static const String routeName = '/drawing';

  @override
  _DrawingDemoState createState() => new _DrawingDemoState();
}

class _DrawingDemoState extends State<DrawingDemo> {
  _LineDrawingNode _rootNode;
  ImageMap _images;

  Future<Null> _loadAssets(AssetBundle bundle) async {
    _images = new ImageMap(bundle);
    await _images.load(<String>[
      'packages/flutter_gallery_assets/fancylines.png'
    ]);
  }

  @override
  void initState() {
    super.initState();
    _loadAssets(DefaultAssetBundle.of(context)).then((_) {
      setState(() {
        _rootNode = new _LineDrawingNode(_images);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_rootNode == null) {
      body = new Center(
        child: new CircularProgressIndicator()
      );
    } else {
      body = new SpriteWidget(_rootNode, SpriteBoxTransformMode.nativePoints);
    }

    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Fancy lines')
      ),
      body: body
    );
  }
}

class _LineDrawingNode extends NodeWithSize {
  _LineDrawingNode(this._images) : super(const Size(1024.0, 1024.0)) {
    userInteractionEnabled = true;
  }

  final ImageMap _images;
  EffectLine _currentLine;

  @override
  bool handleEvent(SpriteBoxEvent event) {
    if (event.type == PointerDownEvent) {
      _currentLine = new EffectLine(
        texture: new Texture(_images['packages/flutter_gallery_assets/fancylines.png']),
        colorSequence: new ColorSequence.fromStartAndEndColor(Colors.purple[500], Colors.purple[600]),
        fadeAfterDelay: 3.0,
        fadeDuration: 1.0
      );
      _currentLine.addPoint(event.boxPosition);
      addChild(_currentLine);
    } else if (event.type == PointerMoveEvent) {
      _currentLine.addPoint(event.boxPosition);
    }

    return true;
  }
}
