import 'dart:sky';
import 'lib/game.dart';
import 'lib/sprites.dart';
import 'package:sky/framework/app.dart';

AppView app;

void main() {
  // Load images
  new ImageMap([
      "https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/resources-auto/BurnTexture.png",
      "https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/Sprites/resources-auto/asteroid_big_002.png",
      "https://raw.githubusercontent.com/slembcke/GalacticGuardian.spritebuilder/GDC/Packages/SpriteBuilder%20Resources.sbpack/Sprites/resources-auto/GG_blueship_Lv3.png",
    ],
    allLoaded);
}

void allLoaded(ImageMap loader) {
  // Create a new app with the sprite box that contains our game world
  //app = new AppView(new GameBox(new GameWorld(loader)));
  //print("hello");
  app = new AppView((new SpriteBox(new GameTests(loader), SpriteBoxTransformMode.letterbox)));
}
