// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sprites/flutter_sprites.dart';

class GalleryHeader extends StatefulWidget {
  @override
  _GalleryHeaderState createState() => new _GalleryHeaderState();
}

class _GalleryHeaderState extends State<GalleryHeader> {
  _FlutterHeaderNode _headerNode;
  ImageMap _images;

  Future<Null> _loadAssets() async {
    final AssetBundle bundle = DefaultAssetBundle.of(context);
    _images = new ImageMap(bundle);
    await _images.load(<String>[
      'packages/flutter_gallery_assets/grain.png',
    ]);
  }

  @override
  void initState() {
    super.initState();
    _loadAssets().then((_) {
      setState(() {
        _headerNode = new _FlutterHeaderNode(_images);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _headerNode == null ? new Container() : new SpriteWidget(_headerNode);
  }
}

const Size _kCanvasSize = const Size(1024.0, 1024.0);
const Point _kCenterPoint = const Point(512.0, 512.0);

class _FlutterHeaderNode extends NodeWithSize {
  _FlutterHeaderNode(this._images) : super(_kCanvasSize) {
    clippingLayer.opacity = 0.0;
    clippingLayer.actions.run(new ActionTween((double a) => clippingLayer.opacity = a, 0.0, 1.0, 0.5));
    addChild(clippingLayer);

    clippingLayer.addChild(new _BackgroundBox());

    paperAnimation.position = _kCenterPoint;
    clippingLayer.addChild(paperAnimation);

    final Sprite grain = new Sprite.fromImage(_images['packages/flutter_gallery_assets/grain.png'])
      ..position = _kCenterPoint;
    clippingLayer.addChild(grain);

    userInteractionEnabled = true;
  }

  final ImageMap _images;
  final Layer clippingLayer = new Layer();
  final _PaperAnimation paperAnimation = new _PaperAnimation();

  @override
  void spriteBoxPerformedLayout() {
    clippingLayer.layerRect = spriteBox.visibleArea;
  }
}

final List<_PaperConfig> _kPaperConfigs = <_PaperConfig>[
  new _PaperConfig(
    color: Colors.deepPurple[500],
    startPosition: const Point(-300.0, -300.0),
    startRotation: -10.0,
    rotationSpeed: -1.0,
    parallaxDepth: 0.0,
    rect: new Rect.fromLTRB(-1024.0, -280.0, 1024.0, 280.0)
  ),
  new _PaperConfig(
    color: Colors.purple[400],
    startPosition: const Point(550.0, 0.0),
    startRotation: 45.0,
    rotationSpeed: 0.7,
    parallaxDepth: 1.0,
    rect: new Rect.fromLTRB(-512.0, -512.0, 512.0, 512.0)
  ),
  new _PaperConfig(
    color: Colors.purple[600],
    startPosition: const Point(550.0, 0.0),
    startRotation: 55.0,
    rotationSpeed: 0.9,
    parallaxDepth: 2.0,
    rect: new Rect.fromLTRB(-512.0, -512.0, 512.0, 512.0)
  ),
  new _PaperConfig(
    color: Colors.purple[700],
    startPosition: const Point(550.0, 0.0),
    startRotation: 65.0,
    rotationSpeed: 1.1,
    parallaxDepth: 3.0,
    rect: new Rect.fromLTRB(-512.0, -512.0, 512.0, 512.0)
  )
];

class _PaperAnimation extends Node {
  _PaperAnimation() {
    for (_PaperConfig config in _kPaperConfigs) {

      final _PaperSheet sheet = new _PaperSheet(config);
      final _PaperSheetShadow shadow = new _PaperSheetShadow(config);

      addChild(shadow);
      addChild(sheet);
      _sheets.add(sheet);

      shadow.constraints = <Constraint>[
        new ConstraintRotationToNodeRotation(sheet),
        new ConstraintPositionToNode(sheet, offset: const Offset(0.0, 10.0))
      ];
    }
  }

  final List<_PaperSheet> _sheets = <_PaperSheet>[];
}

class _PaperConfig {
  _PaperConfig({
    this.color,
    this.startPosition,
    this.startRotation,
    this.rotationSpeed,
    this.parallaxDepth,
    this.rect
  });

  final Color color;
  final Point startPosition;
  final double startRotation;
  final double rotationSpeed;
  final double parallaxDepth;
  final Rect rect;
}

class _PaperSheet extends Node {
  _PaperSheet(this._config) {
    _paperPaint.color = _config.color;

    position = _config.startPosition;
    rotation = _config.startRotation;
  }

  final _PaperConfig _config;
  final Paint _paperPaint = new Paint();

  @override
  void paint(Canvas canvas) {
    canvas.drawRect(_config.rect, _paperPaint);
  }

  @override
  void update(double dt) {
    rotation += _config.rotationSpeed * dt;
  }
}

class _PaperSheetShadow extends Node {
  _PaperSheetShadow(this._config) {
    _paperPaint.color = Colors.black45;
    _paperPaint.maskFilter = new MaskFilter.blur(BlurStyle.normal, 10.0);
  }

  final _PaperConfig _config;
  final Paint _paperPaint = new Paint();

  @override
  void paint(Canvas canvas) {
    canvas.drawRect(_config.rect, _paperPaint);
  }
}

class _BackgroundBox extends Node {
  final Paint _boxPaint = new Paint()..color = Colors.purple[500];

  @override
  void paint(Canvas canvas) {
    canvas.drawRect(new Rect.fromLTWH(0.0, 0.0, _kCanvasSize.width, _kCanvasSize.height), _boxPaint);
  }
}
