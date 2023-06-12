import '../../util/_internal.dart';
import '../../util/image_exception.dart';
import '../../util/input_buffer.dart';

@internal
enum ExrChannelType { uint, half, float }

@internal
enum ExrChannelName { red, green, blue, alpha, other }

// Standard channel names are:
// A: Alpha/Opacity
// R: Red value of a sample
// G: Green value of a sample
// B: Blue value of a sample
// Y: Luminance
// RY: Chroma RY
// BY: Chroma BY
// AR: Red for colored mattes
// GR: Green for colored mattes
// BR: Blue for colored mattes
// Z: Distance of the front of a sample from the viewer
// ZBack: Distance of the back of a sample from the viewer
// id: A numerical identifier for the object represented by a sample.
@internal
class ExrChannel {
  late String name;
  late ExrChannelName nameType;
  late ExrChannelType dataType;

  ///< The data type of the channel
  late int dataSize;

  ///< bytes per pixel
  late bool pLinear;
  late int xSampling;
  late int ySampling;
  late bool isColorChannel;

  ExrChannel(InputBuffer input) {
    name = input.readString();
    if (name.isEmpty) {
      return;
    }
    dataType = ExrChannelType.values[input.readUint32()];
    final i = input.readByte();
    assert(i == 0 || i == 1);
    pLinear = i == 1;
    input.skip(3);
    xSampling = input.readUint32();
    ySampling = input.readUint32();

    if (name == 'R') {
      isColorChannel = true;
      nameType = ExrChannelName.red;
    } else if (name == 'G') {
      isColorChannel = true;
      nameType = ExrChannelName.green;
    } else if (name == 'B') {
      isColorChannel = true;
      nameType = ExrChannelName.blue;
    } else if (name == 'A') {
      isColorChannel = true;
      nameType = ExrChannelName.alpha;
    } else {
      isColorChannel = false;
      nameType = ExrChannelName.other;
    }

    switch (dataType) {
      case ExrChannelType.uint:
        dataSize = 4;
        break;
      case ExrChannelType.half:
        dataSize = 2;
        break;
      case ExrChannelType.float:
        dataSize = 4;
        break;
      default:
        throw ImageException('EXR Invalid pixel type: $dataType');
    }
  }

  bool get isValid => name.isNotEmpty;
}
