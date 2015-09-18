import 'package:sky/material.dart';
import 'package:sky/rendering.dart';
import 'package:sky/services.dart';
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
TestApp _app;

main() async {
  _images = new ImageMap(_bundle);

  await _images.load([
    'assets/checker.png',
    'assets/line_effects.png'
  ]);

  assert(_images["assets/checker.png"] != null);

  _app = new TestApp();
  runApp(_app);
}

class TestApp extends App {

  TestApp() {
    _testBed = new TestBed(_labelTexts[_selectedLine]);
  }

  TestBed _testBed;
  int _selectedLine = 0;

  List<String> _labelTexts = [
    "Colored",
    "Smoke",
    "Electric"
  ];

  Widget build() {
    ThemeData theme = new ThemeData(
      brightness: ThemeBrightness.light,
      primarySwatch: Colors.purple
    );

    return new Theme(
      data: theme,
      child: new Title(
        title: 'Test drawAtlas',
        child: _buildColumn()
      )
    );
  }

  Column _buildColumn() {
    return new Column([
      new Flexible(child: _buildSpriteWidget()),
      _buildTabBar()
    ]);
  }

  TabBar _buildTabBar() {
    return new TabBar(
      labels: _buildTabLabels(),
      selectedIndex: _selectedLine,
      onChanged: (int selectedLine) {
        setState(() {
          _selectedLine = selectedLine;
        });
      }
    );
  }

  List<TabLabel> _buildTabLabels() {
    List<TabLabel> labels = [];
    for(String text in _labelTexts) {
      labels.add(new TabLabel(text: text));
    }
    return labels;
  }

  SpriteWidget _buildSpriteWidget() {
    _testBed.setupLine(_labelTexts[_selectedLine]);

    return new SpriteWidget(
      _testBed,
      SpriteBoxTransformMode.letterbox
    );
  }
}

class TestBed extends NodeWithSize {
  EffectLine _line;

  TestBed(String lineType) : super(new Size(1024.0, 1024.0)) {
    userInteractionEnabled = true;
    setupLine(lineType);
  }

  void setupLine(String lineType) {
    if (_line != null) {
      _line.removeFromParent();
    }

    if (lineType == "Colored") {
      // Create a line with no texture and a color sequence
      _line = new EffectLine(
        texture: null,
        colorSequence: new ColorSequence.fromStartAndEndColor(new Color(0xffff0000), new Color(0xff0000ff)),
        widthMode: EffectLineWidthMode.barrel,
        minWidth: 20.0,
        maxWidth: 50.0,
        animationMode: EffectLineAnimationMode.scroll,
        fadeAfterDelay: 1.0,
        fadeDuration: 1.0
      );
    } else if (lineType == "Smoke") {
      Texture baseTexture = new Texture(_images['assets/line_effects.png']);
      Texture smokyLineTexture = baseTexture.textureFromRect(new Rect.fromLTRB(0.0, 0.0, 1024.0, 128.0));

      _line = new EffectLine(
        texture: smokyLineTexture,
        textureLoopLength: 300.0,
        colorSequence: new ColorSequence.fromStartAndEndColor(new Color(0xffffffff), new Color(0x00ffffff)),
        widthMode: EffectLineWidthMode.barrel,
        minWidth: 20.0,
        maxWidth: 80.0,
        animationMode: EffectLineAnimationMode.scroll
      );
    } else if (lineType == "Electric") {
      Texture baseTexture = new Texture(_images['assets/line_effects.png']);
      Texture electricLineTexture = baseTexture.textureFromRect(new Rect.fromLTRB(0.0, 384.0, 1024.0, 512.0));

      _line = new EffectLine(
        texture: electricLineTexture,
        textureLoopLength: 300.0,
        widthMode: EffectLineWidthMode.barrel,
        minWidth: 20.0,
        maxWidth: 100.0,
        animationMode: EffectLineAnimationMode.random
      );
    }

    addChild(_line);
  }

  bool handleEvent(SpriteBoxEvent event) {
    if (event.type == "pointerdown") _line.points = [];

    if (event.type == "pointerdown" || event.type == "pointermove") {
      Point pos = convertPointToNodeSpace(event.boxPosition);
      _line.addPoint(pos);
    }
    return true;
  }
}
