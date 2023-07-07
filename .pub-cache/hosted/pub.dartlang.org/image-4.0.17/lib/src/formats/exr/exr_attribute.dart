import '../../util/_internal.dart';
import '../../util/input_buffer.dart';

@internal
class ExrAttribute {
  String name;
  String type;
  int size;
  InputBuffer data;

  ExrAttribute(this.name, this.type, this.size, this.data);
}
