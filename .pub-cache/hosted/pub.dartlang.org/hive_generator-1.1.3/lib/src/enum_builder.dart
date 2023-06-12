import 'package:analyzer/dart/element/element.dart';
import 'package:hive_generator/src/builder.dart';
import 'package:hive_generator/src/helper.dart';

class EnumBuilder extends Builder {
  EnumBuilder(ClassElement cls, List<AdapterField> getters)
      : super(cls, getters);

  @override
  String buildRead() {
    check(getters.isNotEmpty, '${cls.name} does not have any enum value.');

    var code = StringBuffer();
    code.writeln('switch (reader.readByte()) {');

    for (var field in getters) {
      code.writeln('''
        case ${field.index}:
          return ${cls.name}.${field.name};''');
    }

    var defaultField = getters.firstWhere(
        (it) => it.defaultValue?.toBoolValue() == true,
        orElse: () => getters.first);
    code.writeln('''
      default:
        return ${cls.name}.${defaultField.name};
      }''');

    return code.toString();
  }

  @override
  String buildWrite() {
    var code = StringBuffer();
    code.writeln('switch (obj) {');

    for (var field in getters) {
      code.writeln('''
        case ${cls.name}.${field.name}:
          writer.writeByte(${field.index});
          break;''');
    }

    code.writeln('}');

    return code.toString();
  }
}
