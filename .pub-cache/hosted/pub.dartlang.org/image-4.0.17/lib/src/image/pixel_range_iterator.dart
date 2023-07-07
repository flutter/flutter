import 'pixel.dart';

class PixelRangeIterator extends Iterator<Pixel> {
  Pixel pixel;
  int x1;
  int y1;
  int x2;
  int y2;

  PixelRangeIterator(this.pixel, int x, int y, int width, int height)
      : x1 = x,
        y1 = y,
        x2 = x + width - 1,
        y2 = y + height - 1 {
    pixel.setPosition(x - 1, y);
  }

  @override
  bool moveNext() {
    if ((pixel.x + 1) > x2) {
      pixel.setPosition(x1, pixel.y + 1);
      return pixel.y <= y2;
    }
    return pixel.moveNext();
  }

  @override
  Pixel get current => pixel;
}
