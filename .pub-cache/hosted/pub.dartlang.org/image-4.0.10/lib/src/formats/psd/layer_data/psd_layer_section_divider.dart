import '../../../util/image_exception.dart';
import '../../../util/input_buffer.dart';
import '../psd_layer_data.dart';

class PsdLayerSectionDivider extends PsdLayerData {
  static const tagName = 'lsct';

  static const normal = 0;
  static const openFolder = 1;
  static const closedFolder = 2;
  static const sectionDivider = 3;

  static const subTypeNormal = 0;
  static const subTypeGroup = 1;

  late int type;
  String? key;
  int subType = subTypeNormal;

  PsdLayerSectionDivider(String tag, InputBuffer data) : super.type(tag) {
    final len = data.length;

    type = data.readUint32();

    if (len >= 12) {
      final sig = data.readString(4);
      if (sig != '8BIM') {
        throw ImageException('Invalid key in layer additional data');
      }
      key = data.readString(4);
    }

    if (len >= 16) {
      subType = data.readUint32();
    }
  }
}
