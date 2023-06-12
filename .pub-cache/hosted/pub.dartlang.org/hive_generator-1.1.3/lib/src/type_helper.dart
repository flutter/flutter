import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_helper/source_helper.dart';

const bool kConstConstructors = true;

String constantToString(
  DartObject? object, [
  List<String> typeInformation = const [],
]) {
  if (object == null || object.isNull) return 'null';
  final reader = ConstantReader(object);
  return reader.isLiteral
      ? literalToString(object, typeInformation)
      : revivableToString(object, typeInformation);
}

String revivableToString(DartObject? object, List<String> typeInformation) {
  final reader = ConstantReader(object);
  final revivable = reader.revive();

  if (revivable.source.fragment.isEmpty) {
    // Enums
    return revivable.accessor;
  } else {
    // Classes
    final nextTypeInformation = [...typeInformation, '$object'];
    final prefix = kConstConstructors ? 'const ' : '';
    final ctor = revivable.accessor.isEmpty ? '' : '.${revivable.accessor}';
    final arguments = <String>[
      for (var arg in revivable.positionalArguments)
        constantToString(arg, nextTypeInformation),
      for (var kv in revivable.namedArguments.entries)
        '${kv.key}: ${constantToString(kv.value, nextTypeInformation)}'
    ];

    return '$prefix${revivable.source.fragment}$ctor(${arguments.join(', ')})';
  }
}

// The code below is based on code from https://github.com/google/json_serializable.dart/blob/df60c2a95c4c0054d6ab785849937d7f5ade39fe/json_serializable/lib/src/json_key_utils.dart#L43

String literalToString(DartObject object, List<String> typeInformation) {
  final reader = ConstantReader(object);

  String? badType;
  if (reader.isSymbol) {
    badType = 'Symbol';
  } else if (reader.isType) {
    badType = 'Type';
  } else if (object.type is FunctionType) {
    badType = 'Function';
  } else if (!reader.isLiteral) {
    badType = object.type!.element!.name;
  }

  if (badType != null) {
    badType = typeInformation.followedBy([badType]).join(' > ');
    throwUnsupported('`defaultValue` is `$badType`, it must be a literal.');
  }

  if (reader.isDouble || reader.isInt || reader.isString || reader.isBool) {
    final value = reader.literalValue;

    if (value is String) return escapeDartString(value);

    if (value is double) {
      if (value.isNaN) {
        return 'double.nan';
      }

      if (value.isInfinite) {
        if (value.isNegative) {
          return 'double.negativeInfinity';
        }
        return 'double.infinity';
      }
    }

    if (value is bool || value is num) return value.toString();
  }

  if (reader.isList) {
    final listTypeInformation = [...typeInformation, 'List'];
    final listItems = reader.listValue
        .map((it) => constantToString(it, listTypeInformation))
        .join(', ');
    return '[$listItems]';
  }

  if (reader.isSet) {
    final setTypeInformation = [...typeInformation, 'Set'];
    final setItems = reader.setValue
        .map((it) => constantToString(it, setTypeInformation))
        .join(', ');
    return '{$setItems}';
  }

  if (reader.isMap) {
    final mapTypeInformation = [...typeInformation, 'Map'];
    final buffer = StringBuffer('{');

    var first = true;

    reader.mapValue.forEach((key, value) {
      if (first) {
        first = false;
      } else {
        buffer.writeln(',');
      }

      buffer
        ..write(constantToString(key, mapTypeInformation))
        ..write(': ')
        ..write(constantToString(value, mapTypeInformation));
    });

    buffer.write('}');

    return buffer.toString();
  }

  badType = typeInformation.followedBy(['$object']).join(' > ');
  throwUnsupported(
    'The provided value is not supported: $badType. '
    'This may be an error in package:hive_generator. '
    'Please rerun your build with `--verbose` and file an issue.',
  );
}

Never throwUnsupported(String message) =>
    throw InvalidGenerationSourceError('Error with `@HiveField`. $message');
