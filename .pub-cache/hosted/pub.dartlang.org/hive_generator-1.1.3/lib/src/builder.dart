import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

class AdapterField {
  final int index;
  final String name;
  final DartType type;
  final DartObject? defaultValue;

  AdapterField(this.index, this.name, this.type, this.defaultValue);
}

abstract class Builder {
  final ClassElement cls;
  final List<AdapterField> getters;
  final List<AdapterField> setters;

  Builder(this.cls, this.getters, [this.setters = const <AdapterField>[]]);

  String buildRead();

  String buildWrite();
}
