import '../../util/input_buffer.dart';

class PsdMask {
  late int top;
  late int left;
  late int right;
  late int bottom;
  late int defaultColor;
  late int flags;
  int params = 0;

  PsdMask(InputBuffer input) {
    final len = input.length;

    top = input.readUint32();
    left = input.readUint32();
    right = input.readUint32();
    bottom = input.readUint32();
    defaultColor = input.readByte();
    flags = input.readByte();

    if (len == 20) {
      input.skip(2);
    } else {
      flags = input.readByte();

      defaultColor = input.readByte();
      top = input.readUint32();
      left = input.readUint32();
      right = input.readUint32();
      bottom = input.readUint32();
    }
  }

  bool get relative => flags & 1 != 0;

  bool get disabled => flags & 2 != 0;

  bool get invert => flags & 4 != 0;
}
