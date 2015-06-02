import 'dart:sky';
import 'lib/game.dart';
import 'lib/sprites.dart';
import 'package:sky/framework/app.dart';

AppView app;

void main() {
  // Create a new app with the sprite box that contains our game world
  app = new AppView(new SpriteBox(new GameWorld(1024.0, 1024.0),SpriteBoxTransformMode.letterbox));
}
