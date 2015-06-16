import 'dart:sky';
import 'lib/game_demo.dart';
import 'lib/sprites.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/app/view.dart';
import 'package:sky/widgets/ui_node.dart';
import 'package:sky/widgets/raised_button.dart';

AppView app;

void main() {
  // Load images
  new ImageMap([
      "https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/resources-auto/BurnTexture.png",
      "https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/Sprites/resources-auto/asteroid_big_002.png",
      "https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/Sprites/resources-auto/GG_blueship_Lv3.png",
      "https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/Sprites/resources-auto/laserBlue.png",
      "https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/Sprites/resources-auto/laserFlashPurple.png",
      "https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Source/Resources/NebulaClouds.png",
    ],
    allLoaded);
}

void allLoaded(ImageMap loader) {
  _loader = loader;
  new GameDemoApp();
}

class GameDemoApp extends App {

  UINode build() {
    return new Stack([
      new GameDemo(),
//      new StackPositionedChild(
//        new Flex([
//          new FlexExpandingChild(
//            new RaisedButton(child:new Text("Hello")),
//            key: 1
//          ),
//          new FlexExpandingChild(
//            new RaisedButton(child:new Text("Foo!")),
//            key: 2
//          )
//        ]),
//        right:0.0,
//        top: 20.0
//      )
    ]);
  }
}

ImageMap _loader;

class GameDemo extends OneChildRenderObjectWrapper {

  GameDemo({ UINode child, Object key })
  : super(child: child, key: key);

  GameDemoBox get root { return super.root; }
  GameDemoBox createNode() => new GameDemoBox(new GameDemoWorld(_loader));
}