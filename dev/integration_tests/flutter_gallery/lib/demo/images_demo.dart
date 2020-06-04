// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../gallery/demo.dart';

class ImagesDemo extends StatelessWidget {
  static const String routeName = '/images';

  @override
  Widget build(BuildContext context) {
    return TabbedComponentDemoScaffold(
      title: 'Animated images',
      demos: <ComponentDemoTabData>[
        ComponentDemoTabData(
          tabName: 'WEBP',
          description: '',
          exampleCodeTag: 'animated_image',
          demoWidget: Semantics(
            label: 'Example of animated WEBP',
            child: Image.asset(
              'animated_images/animated_flutter_stickers.webp',
              package: 'flutter_gallery_assets',
            ),
          ),
        ),
        ComponentDemoTabData(
          tabName: 'GIF',
          description: '',
          exampleCodeTag: 'animated_image',
          demoWidget: Semantics(
            label: 'Example of animated GIF',
            child:Image.asset(
              'animated_images/animated_flutter_lgtm.gif',
              package: 'flutter_gallery_assets',
            ),
          ),
        ),
      ],
    );
  }
}
