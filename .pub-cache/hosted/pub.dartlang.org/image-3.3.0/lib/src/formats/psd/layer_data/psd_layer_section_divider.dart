import '../../../image_exception.dart';
import '../../../util/input_buffer.dart';
import '../psd_layer_data.dart';

class PsdLayerSectionDivider extends PsdLayerData {
  static const String TAG = 'lsct';

  static const NORMAL = 0;
  static const OPEN_FOLDER = 1;
  static const CLOSED_FOLDER = 2;
  static const SECTION_DIVIDER = 3;

  static const SUBTYPE_NORMAL = 0;
  static const SUBTYPE_SCENE_GROUP = 1;

  late int type;
  String? key;
  int subType = SUBTYPE_NORMAL;

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
