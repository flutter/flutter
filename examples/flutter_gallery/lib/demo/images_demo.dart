import 'package:flutter/material.dart';

import '../gallery/demo.dart';

class ImagesDemo extends StatelessWidget {
  static const String routeName = '/images';

  @override
  Widget build(BuildContext context) {
    return new TabbedComponentDemoScaffold(
      title: 'Animated images',
      demos: <ComponentDemoTabData>[
        new ComponentDemoTabData(
          tabName: 'ANIMATED WEBP',
          description: '',
          exampleCodeTag: 'animated_image',
          demoWidget: new Semantics(
            label: 'Example of animated WEBP',
            child: new Image.asset('packages/flutter_gallery_assets/animated_flutter_stickers.webp'),
          ),
        ),
        new ComponentDemoTabData(
          tabName: 'ANIMATED GIF',
          description: '',
          exampleCodeTag: 'animated_image',
          demoWidget: new Semantics(
            label: 'Example of animated GIF',
            child:new Image.asset('packages/flutter_gallery_assets/animated_flutter_lgtm.gif'),
          ),
        ),
      ]
    );
  }
}
