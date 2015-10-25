part of flutter_sprites;

/// A sprite sheet packs a number of smaller images into a single large image.
///
/// The placement of the smaller images are defined by a json file. The larger image and json file is typically created
/// by a tool such as TexturePacker. The [SpriteSheet] class will take a reference to a larger image and a json string.
/// From the image and the string the [SpriteSheet] creates a number of [Texture] objects. The names of the frames in
/// the sprite sheet definition are used to reference the different textures.
class SpriteSheet {

  ui.Image _image;
  Map<String, Texture> _textures = new Map<String, Texture>();

  /// Creates a new sprite sheet from an [_image] and a sprite sheet [jsonDefinition].
  ///
  ///     var mySpriteSheet = new SpriteSheet(myImage, jsonString);
  SpriteSheet(this._image, String jsonDefinition) {
    assert(_image != null);
    assert(jsonDefinition != null);

    JsonDecoder decoder = new JsonDecoder();
    Map file = decoder.convert(jsonDefinition);
    assert(file != null);

    List frames = file["frames"];

    for (Map frameInfo in frames) {
      String fileName = frameInfo["filename"];
      Rect frame = _readJsonRect(frameInfo["frame"]);
      bool rotated = frameInfo["rotated"];
      bool trimmed = frameInfo["trimmed"];
      Rect spriteSourceSize = _readJsonRect(frameInfo["spriteSourceSize"]);
      Size sourceSize = _readJsonSize(frameInfo["sourceSize"]);
      Point pivot = _readJsonPoint(frameInfo["pivot"]);

      var texture = new Texture._fromSpriteFrame(_image, fileName, sourceSize, rotated, trimmed, frame,
        spriteSourceSize, pivot);
      _textures[fileName] = texture;
    }
  }

  Rect _readJsonRect(Map data) {
    num x = data["x"];
    num y = data["y"];
    num w = data["w"];
    num h = data["h"];

    return new Rect.fromLTRB(x.toDouble(), y.toDouble(), (x + w).toDouble(), (y + h).toDouble());
  }

  Size _readJsonSize(Map data) {
    num w = data["w"];
    num h = data["h"];

    return new Size(w.toDouble(), h.toDouble());
  }

  Point _readJsonPoint(Map data) {
    num x = data["x"];
    num y = data["y"];

    return new Point(x.toDouble(), y.toDouble());
  }

  /// The image used by the sprite sheet.
  ///
  ///     var spriteSheetImage = mySpriteSheet.image;
  ui.Image get image => _image;

  /// Returns a texture by its name.
  ///
  ///     var myTexture = mySpriteSheet["example.png"];
  Texture operator [](String fileName) => _textures[fileName];
}
