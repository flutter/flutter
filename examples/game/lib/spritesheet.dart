part of sprites;

class SpriteSheet {

  Image _image;
  Map<String, Texture> _textures = new Map();

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

  Image get image => _image;

  Texture operator [](String fileName) => _textures[fileName];
}
