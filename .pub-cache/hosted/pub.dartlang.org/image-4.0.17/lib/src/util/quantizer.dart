import '../color/color.dart';
import '../image/image.dart';
import '../image/palette.dart';

enum QuantizerType { octree, neural }

/// Abstract class for color quantizers, which reduce the total number of colors
/// used by an image to a given maximum, used to convert images to palette
/// images.
abstract class Quantizer {
  Palette get palette;

  /// Find the index of the closest color to [c] in the colorMap.
  Color getQuantizedColor(Color c);

  int getColorIndex(Color c);

  int getColorIndexRgb(int r, int g, int b);

  /// Convert the [image] to a palette image.
  Image getIndexImage(Image image) {
    final target = Image(
        width: image.width,
        height: image.height,
        numChannels: 1,
        palette: palette);

    final ti = target.iterator..moveNext();

    for (final p in image) {
      final t = ti.current;
      t[0] = getColorIndex(p);
      ti.moveNext();
    }

    return target;
  }
}
