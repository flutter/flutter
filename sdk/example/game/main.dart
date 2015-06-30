import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/widget.dart';
import 'package:sky/mojo/net/fetch.dart';

import 'lib/game_demo.dart';
import 'lib/sprites.dart';

void main() {
  // Load images
  new ImageMap([
      "res/nebula.png",
      "res/sprites.png",
    ],
    allImagesLoaded);
}

void allImagesLoaded(ImageMap loader) {
  _loader = loader;

  fetchBody("res/sprites.json").then((Response response) {
    String json = response.bodyAsString();
    _spriteSheet = new SpriteSheet(_loader["res/sprites.png"], json);
    allResourcesLoaded();
  });
}

void allResourcesLoaded() {
  runApp(new GameDemoApp());
}

class GameDemoApp extends App {

  Widget build() {
    return new Stack([
      new SpriteWidget(new GameDemoWorld(_loader, _spriteSheet)),
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
SpriteSheet _spriteSheet;
