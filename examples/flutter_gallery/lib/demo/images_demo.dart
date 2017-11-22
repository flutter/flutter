import 'dart:math' as math show PI;

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

class _ImageDemo {
  final String description;
  final String assetPath;

  const _ImageDemo({
    @required this.description,
    @required this.assetPath,
  });
}

class ImagesDemo extends StatelessWidget {
  static const String routeName = '/images';

  static const List<_ImageDemo> _demos = const <_ImageDemo> [
    const _ImageDemo(
      description: 'ANIMATED GIF',
      // TODO(amirh): replace this with the final asset.
      assetPath: 'https://flutter.io/images/intellij/hot-reload.gif'
    ),
    const _ImageDemo(
      description: 'ANIMATED WEBP',
      // TODO(amirh): replace this with the final asset.
      assetPath:
      'https://camo.githubusercontent.com/47fb2facc57a6fe832964fc77b01f881291d04c8/687474703a2f2f692e696d6775722e636f6d2f74537156516b782e676966'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return new DefaultTabController(
      length: _demos.length,
      child: new Scaffold(
        appBar: new AppBar(
          title: const Text('Images'),
          bottom: new TabBar(
            isScrollable: true,
            tabs: _demos.map((_ImageDemo d) => new Tab(text: d.description)).toList(),
          ),
        ),
        body: new TabBarView(
          children: _demos.map(_ImageDemoWidget.fromImageDemo).toList(),
        ),
      )
    );
  }
}

class _ImageDemoWidget extends StatelessWidget {
  final String _assetPath;

  const _ImageDemoWidget(this._assetPath) : assert(_assetPath != null);

  static _ImageDemoWidget fromImageDemo(_ImageDemo demo) {
    return new _ImageDemoWidget(demo.assetPath);
  }

  @override
  Widget build(BuildContext context) {
    // TODO(amirh): replace this with Image.asset once we have the final assets.
    return new Stack(
      alignment: Alignment.center,
      children: <Widget> [
        new Image.network(_assetPath),
        new Transform.rotate(
          angle: math.PI / 8.0,
          child: const Text(
            'Place holder',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 30.0,
            ),
          ),
        )
      ],
    );
  }
}
