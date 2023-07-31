import 'dart:convert' as convert;
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';

import '../logger/log_utils.dart';
import 'json_ast/json_ast.dart';
import 'sintaxe.dart';

const Map<String, bool> PRIMITIVE_TYPES = {
  'int': true,
  'double': true,
  'String': true,
  'bool': true,
  'DateTime': false,
  'List<DateTime>': false,
  'List<int>': true,
  'List<double>': true,
  'List<String>': true,
  'List<bool>': true,
  'Null': true,
  'dynamic': true,
};

enum ListType { Object, String, Double, Int, Null }

class MergeableListType {
  final ListType? listType;
  final bool isAmbigous;

  MergeableListType(this.listType, this.isAmbigous);
}

MergeableListType mergeableListType(List<dynamic> list) {
  ListType? t = ListType.Null;
  var isAmbigous = false;
  for (var e in list) {
    ListType? inferredType;
    if (e.runtimeType.toString() == 'int') {
      inferredType = ListType.Int;
    } else if (e.runtimeType.toString() == 'double') {
      inferredType = ListType.Double;
    } else if (e.runtimeType.toString() == 'string') {
      inferredType = ListType.String;
    } else if (e is Map) {
      inferredType = ListType.Object;
    }
    if (t != ListType.Null && t != inferredType) {
      isAmbigous = true;
    }
    t = inferredType;
  }
  return MergeableListType(t, isAmbigous);
}

String camelCase(String text) {
  String capitalize(Match m) =>
      m[0]!.substring(0, 1).toUpperCase() + m[0]!.substring(1);
  String skip(String s) => '';
  return text.splitMapJoin(RegExp(r'[a-zA-Z0-9]+'),
      onMatch: capitalize, onNonMatch: skip);
}

String camelCaseFirstLower(String text) {
  final camelCaseText = camelCase(text);
  final firstChar = camelCaseText.substring(0, 1).toLowerCase();
  final rest = camelCaseText.substring(1);
  return '$firstChar$rest';
}

dynamic decodeJSON(String rawJson) {
  try {
    return convert.json.decode(rawJson);
  } on FormatException catch (e) {
    LogService.error('invalid json format: '
        '\n${e.toString().split("FormatException:").last}');
    if (!Platform.isWindows) exit(0);
  } on Exception catch (e) {
    LogService.error('Unexpected error $e');
    if (!Platform.isWindows) exit(0);
  }
}

WithWarning<Map> mergeObj(Map obj, Map other, String path) {
  var warnings = <Warning>[];
  final clone = Map.from(obj);
  other.forEach((k, v) {
    if (clone[k] == null) {
      clone[k] = v;
    } else {
      final otherType = getTypeName(v);
      final t = getTypeName(clone[k]);
      if (t != otherType) {
        if (t == 'int' && otherType == 'double') {
          // if double was found instead of int, assign the double
          clone[k] = v;
        } else if (clone[k].runtimeType.toString() != 'double' &&
            v.runtimeType.toString() != 'int') {
          // if types are not equal, then
          warnings.add(newAmbiguousType('$path/$k'));
        }
      } else if (t == 'List') {
        var l = List.from(clone[k] as Iterable);
        l.addAll(other[k] as Iterable);
        final mergeableType = mergeableListType(l);
        if (ListType.Object == mergeableType.listType) {
          var mergedList = mergeObjectList(l, path);
          warnings.addAll(mergedList.warnings);
          clone[k] = List.filled(1, mergedList.result);
        } else {
          if (l.isNotEmpty) {
            clone[k] = List.filled(1, l[0]);
          }
          if (mergeableType.isAmbigous) {
            warnings.add(newAmbiguousType('$path/$k'));
          }
        }
      } else if (t == 'Class') {
        var mergedObj = mergeObj(clone[k] as Map, other[k] as Map, '$path/$k');
        warnings.addAll(mergedObj.warnings);
        clone[k] = mergedObj.result;
      }
    }
  });
  return WithWarning(clone, warnings);
}

WithWarning<Map> mergeObjectList(List<dynamic> list, String path,
    [int idx = -1]) {
  var warnings = <Warning>{};
  var obj = {};
  for (var i = 0; i < list.length; i++) {
    final toMerge = list[i];
    if (toMerge is Map) {
      toMerge.forEach((k, v) {
        final t = getTypeName(obj[k]);
        if (obj[k] == null) {
          obj[k] = v;
        } else {
          final otherType = getTypeName(v);
          if (t != otherType) {
            if (t == 'int' && otherType == 'double') {
              // if double was found instead of int, assign the double
              obj[k] = v;
            } else if (t != 'double' && otherType != 'int') {
              // if types are not equal, then
              var realIndex = i;
              if (idx != -1) {
                realIndex = idx - i;
              }
              final ambiguosTypePath = '$path[$realIndex]/$k';
              warnings.add(newAmbiguousType(ambiguosTypePath));
            }
          } else if (t == 'List') {
            var l = List.from(obj[k] as Iterable);
            final beginIndex = l.length;
            l.addAll(v as Iterable);
            // bug is here
            final mergeableType = mergeableListType(l);
            if (ListType.Object == mergeableType.listType) {
              var mergedList = mergeObjectList(l, '$path[$i]/$k', beginIndex);
              warnings.addAll(mergedList.warnings);
              obj[k] = List.filled(1, mergedList.result);
            } else {
              if (l.isNotEmpty) {
                obj[k] = List.filled(1, l[0]);
              }
              if (mergeableType.isAmbigous) {
                warnings.add(newAmbiguousType('$path[$i]/$k'));
              }
            }
          } else if (t == 'Class') {
            var properIndex = i;
            if (idx != -1) {
              properIndex = i - idx;
            }
            var mergedObj = mergeObj(
              obj[k] as Map,
              v as Map,
              '$path[$properIndex]/$k',
            );
            warnings.addAll(mergedObj.warnings);
            obj[k] = mergedObj.result;
          }
        }
      });
    }
  }
  return WithWarning(obj, warnings.toList());
}

bool isPrimitiveType(String? typeName) {
  final isPrimitive = PRIMITIVE_TYPES[typeName!];
  if (isPrimitive == null) {
    return false;
  }
  return isPrimitive;
}

String fixFieldName(String name,
    {TypeDefinition? typeDef, bool privateField = false}) {
  var properName = name;
  if (name.startsWith('_') || name.startsWith(RegExp(r'[0-9]'))) {
    final firstCharType = typeDef!.name!.substring(0, 1).toLowerCase();
    properName = '$firstCharType$name';
  }
  final fieldName = camelCaseFirstLower(properName);
  if (privateField) {
    return '_$fieldName';
  }
  return fieldName;
}

String getTypeName(dynamic obj) {
  if (obj is String) {
    return 'String';
  } else if (obj is int) {
    return 'int';
  } else if (obj is double) {
    return 'double';
  } else if (obj is bool) {
    return 'bool';
  } else if (obj == null) {
    // return 'Null';
    return 'dynamic';
  } else if (obj is List) {
    return 'List';
  } else {
    // assumed class
    return 'Class';
  }
}

Node? navigateNode(Node? astNode, String path) {
  Node? node;
  if (astNode is ObjectNode) {
    final objectNode = astNode;
    final propertyNode = objectNode.children.firstWhereOrNull((final prop) {
      return prop.key!.value == path;
    });
    if (propertyNode != null) {
      node = propertyNode.value;
    }
  }
  if (astNode is ArrayNode) {
    final arrayNode = astNode;
    final index = int.tryParse(path);
    if (index != null && arrayNode.children.length > index) {
      node = arrayNode.children[index];
    }
  }
  return node;
}

final _pattern = RegExp(r'([0-9]+)\.{0,1}([0-9]*)e(([-0-9]+))');

bool isASTLiteralDouble(Node? astNode) {
  if (astNode != null && astNode is LiteralNode) {
    final literalNode = astNode;
    final containsPoint = literalNode.raw!.contains('.');
    final containsExponent = literalNode.raw!.contains('e');
    if (containsPoint || containsExponent) {
      var isDouble = containsPoint;
      if (containsExponent) {
        final matches = _pattern.firstMatch(literalNode.raw!);
        if (matches != null) {
          final integer = matches[1]!;
          final comma = matches[2]!;
          final exponent = matches[3]!;
          isDouble = _isDoubleWithExponential(integer, comma, exponent);
        }
      }
      return isDouble;
    }
  }
  return false;
}

bool _isDoubleWithExponential(String integer, String comma, String exponent) {
  final integerNumber = int.tryParse(integer) ?? 0;
  final exponentNumber = int.tryParse(exponent) ?? 0;
  final commaNumber = int.tryParse(comma) ?? 0;

  if (exponentNumber == 0) {
    return commaNumber > 0;
  }
  if (exponentNumber > 0) {
    return exponentNumber < comma.length && commaNumber > 0;
  }
  return commaNumber > 0 ||
      ((integerNumber.toDouble() * pow(10, exponentNumber)).remainder(1) > 0);
}
