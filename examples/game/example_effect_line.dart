import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sprites/flutter_sprites.dart';

AssetBundle _initBundle() {
  if (rootBundle != null)
    return rootBundle;
  return new NetworkAssetBundle(Uri.base);
}

final AssetBundle _bundle = _initBundle();

ImageMap _images;
SpriteSheet _spriteSheet;

main() async {
  _images = new ImageMap(_bundle);

  await _images.load(<String>[
    'assets/checker.png',
    'assets/line_effects.png'
  ]);

  assert(_images["assets/checker.png"] != null);

  runApp(new TestApp());
}

class TestApp extends StatefulComponent {
  TestAppState createState() => new TestAppState();
}

final ThemeData _theme = new ThemeData(
  brightness: ThemeBrightness.light,
  primarySwatch: Colors.blue
);

class TestAppState extends State<TestApp> {
  TestApp() {
    _testBed = new TestBed(_labelTexts[_selectedLine]);
  }

  TestBed _testBed;
  int _selectedLine = 0;

  List<String> _labelTexts = <String>[
    "Colored",
    "Smoke",
    "Electric",
    "Rocket Trail"
  ];

  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'EffectLine Demo',
      theme: _theme,
      routes: <String, RouteBuilder>{
        '/': _buildColumn
      }
    );
  }

  Column _buildColumn(RouteArguments args) {
    return new Column(<Widget>[
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
    List<TabLabel> labels = <TabLabel>[];
    for (String text in _labelTexts)
      labels.add(new TabLabel(text: text));
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
        colorSequence: new ColorSequence.fromStartAndEndColor(new Color(0xaaffff00), new Color(0xaaff9900)),
        widthMode: EffectLineWidthMode.barrel,
        minWidth: 10.0,
        maxWidth: 15.0,
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
    } else if (lineType == "Rocket Trail") {
      Texture baseTexture = new Texture(_images['assets/line_effects.png']);
      Texture trailLineTexture = baseTexture.textureFromRect(new Rect.fromLTRB(0.0, 896.0, 1024.0, 1024.0));

      _line = new EffectLine(
        texture: trailLineTexture,
        textureLoopLength: 300.0,
        widthMode: EffectLineWidthMode.barrel,
        minWidth: 20.0,
        maxWidth: 40.0,
        widthGrowthSpeed: 40.0,
        fadeAfterDelay: 0.5,
        fadeDuration: 1.5
      );
    }

    addChild(_line);
  }

  bool handleEvent(SpriteBoxEvent event) {
    if (event.type == "pointerdown")
       _line.points = <Point>[];

    if (event.type == "pointerdown" || event.type == "pointermove") {
      Point pos = convertPointToNodeSpace(event.boxPosition);
      _line.addPoint(pos);
    }
    return true;
  }
}
