import '../../image_exception.dart';
import '../../util/input_buffer.dart';

class ExrChannel {
  static const TYPE_UINT = 0;
  static const TYPE_HALF = 1;
  static const TYPE_FLOAT = 2;

  // Channel Names

  /// Luminance
  static const String Y = 'Y';

  /// Chroma RY
  static const String RY = 'RY';

  /// Chroma BY
  static const String BY = 'BY';

  /// Red for colored mattes
  static const String AR = 'AR';

  /// Green for colored mattes
  static const String AG = 'AG';

  /// Blue for colored mattes
  static const String AB = 'AB';

  /// Distance of the front of a sample from the viewer
  static const String Z = 'Z';

  /// Distance of the back of a sample from the viewer
  static const String ZBack = 'ZBack';

  /// Alpha/opacity
  static const String A = 'A';

  /// Red value of a sample
  static const String R = 'R';

  /// Green value of a sample
  static const String G = 'G';

  /// Blue value of a sample
  static const String B = 'B';

  /// A numerical identifier for the object represented by a sample.
  static const String ID = 'id';

  String? name;
  late int type;
  late int size;
  late bool pLinear;
  late int xSampling;
  late int ySampling;

  ExrChannel(InputBuffer input) {
    name = input.readString();
    if (name == null || name!.isEmpty) {
      name = null;
      return;
    }
    type = input.readUint32();
    final i = input.readByte();
    assert(i == 0 || i == 1);
    pLinear = i == 1;
    input.skip(3);
    xSampling = input.readUint32();
    ySampling = input.readUint32();

    switch (type) {
      case TYPE_UINT:
        size = 4;
        break;
      case TYPE_HALF:
        size = 2;
        break;
      case TYPE_FLOAT:
        size = 4;
        break;
      default:
        throw ImageException('EXR Invalid pixel type: $type');
    }
  }

  bool get isValid => name != null;
}
