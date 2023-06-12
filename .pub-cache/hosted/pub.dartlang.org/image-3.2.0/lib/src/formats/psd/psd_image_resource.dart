import '../../util/input_buffer.dart';

class PsdImageResource {
  int id;
  String name;
  InputBuffer data;

  PsdImageResource(this.id, this.name, this.data);
}
