part of sprites;

class Texture {
  final Image image;
  final Size size;
  String name;
  final bool rotated;
  final bool trimmed;

  Rect frame;
  Rect spriteSourceSize;

  Point pivot;

  Texture(Image image) :
    size = new Size(image.width.toDouble(), image.height.toDouble()),
    image = image,
    trimmed = false,
    rotated = false,
    frame = new Rect.fromLTRB(0.0, 0.0, image.width.toDouble(), image.height.toDouble()),
    spriteSourceSize = new Rect.fromLTRB(0.0, 0.0, image.width.toDouble(), image.height.toDouble()),
    pivot = new Point(0.5, 0.5);


  Texture._fromSpriteFrame(this.image, this.name, this.size, this.rotated, this.trimmed, this.frame,
                           this.spriteSourceSize, this.pivot) {
  }

  Texture textureFromRect(Rect rect, Point offset, bool rotated) {
    // TODO: Implement this
    return null;
  }
}
