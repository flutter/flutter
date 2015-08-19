import 'dart:sky' as sky;

import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/image.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/rendering/proxy_box.dart';
import 'package:sky/rendering/shifted_box.dart';

import '../resources/display_list.dart';
import '../resources/third_party/unittest/unittest.dart';
import '../resources/unit.dart';

class SquareImage implements sky.Image {
  int get width => 10;
  int get height => 10;
}

class WideImage implements sky.Image {
  int get width => 20;
  int get height => 10;
}

class TallImage implements sky.Image {
  int get width => 10;
  int get height => 20;
}

void _layout(RenderImage image, BoxConstraints constraints) {
  new TestView(
    child: new RenderPositionedBox(
      child: new RenderConstrainedBox(
        additionalConstraints: constraints,
        child: image
      )
    )
  );
}

void main() {
  initUnit();

  test('Image sizing', () {
    RenderImage image;

    image = new RenderImage(image: new SquareImage());
    _layout(image,
            new BoxConstraints(
              minWidth: 25.0,
              minHeight: 25.0,
              maxWidth: 100.0,
              maxHeight: 100.0));
    expect(image.size.width, equals(25.0));
    expect(image.size.height, equals(25.0));

    image = new RenderImage(image: new WideImage());
    _layout(image,
            new BoxConstraints(
              minWidth: 5.0,
              minHeight: 30.0,
              maxWidth: 100.0,
              maxHeight: 100.0));
    expect(image.size.width, equals(60.0));
    expect(image.size.height, equals(30.0));

    image = new RenderImage(image: new TallImage());
    _layout(image,
            new BoxConstraints(
              minWidth: 50.0,
              minHeight: 5.0,
              maxWidth: 75.0,
              maxHeight: 75.0));
    expect(image.size.width, equals(50.0));
    expect(image.size.height, equals(75.0));

    image = new RenderImage(image: new WideImage());
    _layout(image,
            new BoxConstraints(
              minWidth: 5.0,
              minHeight: 5.0,
              maxWidth: 100.0,
              maxHeight: 100.0));
    expect(image.size.width, equals(20.0));
    expect(image.size.height, equals(10.0));

    image = new RenderImage(image: new WideImage());
    _layout(image,
            new BoxConstraints(
              minWidth: 5.0,
              minHeight: 5.0,
              maxWidth: 16.0,
              maxHeight: 16.0));
    expect(image.size.width, equals(16.0));
    expect(image.size.height, equals(8.0));

    image = new RenderImage(image: new TallImage());
    _layout(image,
            new BoxConstraints(
              minWidth: 5.0,
              minHeight: 5.0,
              maxWidth: 16.0,
              maxHeight: 16.0));
    expect(image.size.width, equals(8.0));
    expect(image.size.height, equals(16.0));

    image = new RenderImage(image: new SquareImage());
    _layout(image,
            new BoxConstraints(
              minWidth: 4.0,
              minHeight: 4.0,
              maxWidth: 8.0,
              maxHeight: 8.0));
    expect(image.size.width, equals(8.0));
    expect(image.size.height, equals(8.0));

    image = new RenderImage(image: new WideImage());
    _layout(image,
            new BoxConstraints(
              minWidth: 20.0,
              minHeight: 20.0,
              maxWidth: 30.0,
              maxHeight: 30.0));
    expect(image.size.width, equals(30.0));
    expect(image.size.height, equals(20.0));

    image = new RenderImage(image: new TallImage());
    _layout(image,
            new BoxConstraints(
              minWidth: 20.0,
              minHeight: 20.0,
              maxWidth: 30.0,
              maxHeight: 30.0));
    expect(image.size.width, equals(20.0));
    expect(image.size.height, equals(30.0));
  });

  test('Null image sizing', () {
    RenderImage image;

    image = new RenderImage();
    _layout(image,
            new BoxConstraints(
              minWidth: 25.0,
              minHeight: 25.0,
              maxWidth: 100.0,
              maxHeight: 100.0));
    expect(image.size.width, equals(25.0));
    expect(image.size.height, equals(25.0));

    image = new RenderImage(width: 50.0);
    _layout(image,
            new BoxConstraints(
              minWidth: 25.0,
              minHeight: 25.0,
              maxWidth: 100.0,
              maxHeight: 100.0));
    expect(image.size.width, equals(50.0));
    expect(image.size.height, equals(25.0));

    image = new RenderImage(height: 50.0);
    _layout(image,
            new BoxConstraints(
              minWidth: 25.0,
              minHeight: 25.0,
              maxWidth: 100.0,
              maxHeight: 100.0));
    expect(image.size.width, equals(25.0));
    expect(image.size.height, equals(50.0));

    image = new RenderImage(width: 100.0, height: 100.0);
    _layout(image,
            new BoxConstraints(
              minWidth: 25.0,
              minHeight: 25.0,
              maxWidth: 75.0,
              maxHeight: 75.0));
    expect(image.size.width, equals(75.0));
    expect(image.size.height, equals(75.0));
  });
}
