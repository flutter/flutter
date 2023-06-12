import '../../util/input_buffer.dart';
import 'layer_data/psd_layer_additional_data.dart';
import 'layer_data/psd_layer_section_divider.dart';

class PsdLayerData {
  String tag;

  factory PsdLayerData(String tag, InputBuffer data) {
    switch (tag) {
      case PsdLayerSectionDivider.tagName:
        return PsdLayerSectionDivider(tag, data);
      default:
        return PsdLayerAdditionalData(tag, data);
    }
  }

  PsdLayerData.type(this.tag);
}
