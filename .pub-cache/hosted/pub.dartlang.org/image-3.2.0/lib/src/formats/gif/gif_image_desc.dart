import '../../internal/internal.dart';
import '../../util/input_buffer.dart';
import 'gif_color_map.dart';

class GifImageDesc {
  late int x;
  late int y;
  late int width;
  late int height;
  late bool interlaced;
  GifColorMap? colorMap;
  int duration = 80;
  bool clearFrame = true;

  GifImageDesc(InputBuffer input) {
    x = input.readUint16();
    y = input.readUint16();
    width = input.readUint16();
    height = input.readUint16();

    final b = input.readByte();

    final bitsPerPixel = (b & 0x07) + 1;

    interlaced = (b & 0x40) != 0;

    if (b & 0x80 != 0) {
      colorMap = GifColorMap(1 << bitsPerPixel);

      for (var i = 0; i < colorMap!.numColors; ++i) {
        colorMap!
            .setColor(i, input.readByte(), input.readByte(), input.readByte());
      }
    }

    _inputPosition = input.position;
  }

  /// The position in the file after the ImageDesc for this frame.
  late int _inputPosition;
}

@internal
class InternalGifImageDesc extends GifImageDesc {
  InternalGifImageDesc(InputBuffer input) : super(input);

  int get inputPosition => _inputPosition;
}
