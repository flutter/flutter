import 'dart:math' as math show PI;

import 'package:flutter/material.dart';

import '../gallery/demo.dart';

class ImagesDemo extends StatelessWidget {
  static const String routeName = '/images';

  @override
  Widget build(BuildContext context) {
    return new TabbedComponentDemoScaffold(
      title: 'Images',
      demos: <ComponentDemoTabData>[
        new ComponentDemoTabData(
          tabName: 'ANIMATED GIF',
          description: '',
          exampleCodeTag: 'animated_image',
          demoWidget: const _ImageDemoWidget(
            // TODO(amirh): replace this with the final asset.
            'https://flutter.io/images/intellij/hot-reload.gif'
          ),
        ),
        new ComponentDemoTabData(
          tabName: 'ANIMATED WEBP',
          description: '',
          exampleCodeTag: 'animated_image',
          demoWidget: const _ImageDemoWidget(
            // TODO(amirh): replace this with the final asset.
            'https://camo.githubusercontent.com/47fb2facc57a6fe832964fc77b01f881291d04c8/687474703a2f2f692e696d6775722e636f6d2f74537156516b782e676966'
          ),
        ),
      ]
    );
  }
}

class _ImageDemoWidget extends StatelessWidget {
  final String _assetPath;

  const _ImageDemoWidget(this._assetPath) : assert(_assetPath != null);

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
