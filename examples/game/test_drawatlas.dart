import 'dart:sky';

import 'package:sky/mojo/asset_bundle.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets.dart';
import 'package:skysprites/skysprites.dart';

AssetBundle _initBundle() {
  if (rootBundle != null)
    return rootBundle;
  return new NetworkAssetBundle(Uri.base);
}

final AssetBundle _bundle = _initBundle();

ImageMap _images;
SpriteSheet _spriteSheet;
TestDrawAtlasApp _app;

main() async {
  _images = new ImageMap(_bundle);

  await _images.load([
    'assets/sprites.png'
  ]);

  String json = await _bundle.loadString('assets/sprites.json');
  _spriteSheet = new SpriteSheet(_images['assets/sprites.png'], json);

  _app = new TestDrawAtlasApp();
  runApp(_app);
}

class TestDrawAtlasApp extends App {

  Widget build() {
    ThemeData theme = new ThemeData(
      brightness: ThemeBrightness.light,
      primarySwatch: colors.Purple
    );

    return new Theme(
      data: theme,
      child: new Title(
        title: 'Test drawAtlas',
        child: new SpriteWidget(
          new TestDrawAtlas(),
          SpriteBoxTransformMode.fixedWidth
        )
      )
    );
  }
}

class TestDrawAtlas extends NodeWithSize {
  TestDrawAtlas() : super(new Size(1024.0, 1024.0)) {
  }

  void paint(PaintingCanvas canvas) {
    List<RSTransform> transforms = [
      new RSTransform(1.0, 0.0, 100.0, 100.0)
    ];
    List<Rect> rects = [
      _spriteSheet["ship.png"].frame
    ];
    List<Color> colors = [
      new Color(0xffffffff)
    ];

    canvas.drawAtlas(
      _spriteSheet.image,
      transforms,
      rects,
      colors,
      TransferMode.src,
      null,
      new Paint()..setFilterQuality(FilterQuality.low)..isAntiAlias=false
    );
  }
}
