import '../../../util/input_buffer.dart';
import '../psd_layer_data.dart';

class PsdLayerAdditionalData extends PsdLayerData {
  InputBuffer data;

  PsdLayerAdditionalData(String tag, this.data) : super.type(tag);
}
