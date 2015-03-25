import 'dart:sky';

import 'package:sky/framework/fn.dart';

class TestApp extends App {
  Node build() {
    return new Container(
      inlineStyle: 'background-color: green',
      children: [
        new Text('I am Text'),
        new Image(src: 'foo.jpg'),
        new Anchor(href: 'http://www.google.com')
      ]
    );
  }
}
