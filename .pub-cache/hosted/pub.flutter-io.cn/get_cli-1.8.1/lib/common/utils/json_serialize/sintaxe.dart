// ignore_for_file: lines_longer_than_80_chars

import 'package:collection/collection.dart' show IterableExtension;

import '../pubspec/pubspec_utils.dart';
import 'helpers.dart';
import 'json_ast/json_ast.dart' show Node;

// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

const String emptyListWarn = 'list is empty';
const String ambiguousListWarn = 'list is ambiguous';
const String ambiguousTypeWarn = 'type is ambiguous';

class Warning {
  final String warning;
  final String path;

  Warning(this.warning, this.path);
}

Warning newEmptyListWarn(String path) {
  return Warning(emptyListWarn, path);
}

Warning newAmbiguousListWarn(String path) {
  return Warning(ambiguousListWarn, path);
}

Warning newAmbiguousType(String path) {
  return Warning(ambiguousTypeWarn, path);
}

class WithWarning<T> {
  final T result;
  final List<Warning> warnings;

  WithWarning(this.result, this.warnings);
}

class TypeDefinition {
  String? name;
  String? subtype;
  bool? isAmbiguous = false;
  bool _isPrimitive = false;

  factory TypeDefinition.fromDynamic(dynamic obj, Node? astNode) {
    var isAmbiguous = false;
    final type = getTypeName(obj);
    if (type == 'List') {
      var list = obj as List;
      String elemType;
      if (list.isNotEmpty) {
        elemType = getTypeName(list[0]);
        for (dynamic listVal in list) {
          if (elemType != getTypeName(listVal)) {
            isAmbiguous = true;
            break;
          }
        }
      } else {
        // when array is empty insert Null just to warn the user
        elemType = 'Null';
      }
      return TypeDefinition(type,
          astNode: astNode, subtype: elemType, isAmbiguous: isAmbiguous);
    }
    return TypeDefinition(type, astNode: astNode, isAmbiguous: isAmbiguous);
  }

  TypeDefinition(this.name, {this.subtype, this.isAmbiguous, Node? astNode}) {
    if (subtype == null) {
      _isPrimitive = isPrimitiveType(name);
      if (name == 'int' && isASTLiteralDouble(astNode)) {
        name = 'double';
      }
    } else {
      _isPrimitive = isPrimitiveType('$name<$subtype>');
    }
    isAmbiguous ??= false;
    if (PubspecUtils.nullSafeSupport && name != 'dynamic') {
      if (subtype == null) {
        name = '$name?';
      } else {
        name = '$name';
      }
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (other is TypeDefinition) {
      return name == other.name &&
          subtype == other.subtype &&
          isAmbiguous == other.isAmbiguous &&
          _isPrimitive == other._isPrimitive;
    }
    return false;
  }

  @override
  int get hashCode =>
      name.hashCode ^
      subtype.hashCode ^
      isAmbiguous.hashCode ^
      _isPrimitive.hashCode;

  bool get isPrimitive => _isPrimitive;

  bool get isPrimitiveList => _isPrimitive && name == 'List';

  String _buildParseClass(String expression) {
    final properType = subtype ?? name;
    return '$properType.fromJson($expression)';
  }

  String _buildToJsonClass(String expression, {bool nullSafe = false}) {
    if (nullSafe == true) {
      return '$expression?.toJson()';
    }
    return '$expression.toJson()';
  }

  String jsonParseExpression(String key, bool privateField) {
    final jsonKey = "json['$key']";
    final fieldKey =
        fixFieldName(key, typeDef: this, privateField: privateField);
    if (isPrimitive) {
      if (name == 'List') {
        return "$fieldKey = json['$key'].cast<$subtype>();";
      }
      return "$fieldKey = json['$key'];";
    } else if (name == 'List' && subtype == 'DateTime') {
      return "$fieldKey = json['$key'].map((v) => DateTime.tryParse(v));";
    } else if (name == 'DateTime') {
      return "$fieldKey = DateTime.tryParse(json['$key']);";
    } else if (name == 'List') {
      // list of class
      return "if (json['$key'] != null) {\n\t\t\t$fieldKey = <$subtype>[];"
          "\n\t\t\tjson['$key'].forEach((v) { "
          '$fieldKey${PubspecUtils.nullSafeSupport ? '?' : ''}.add($subtype.fromJson(v)); });\n\t\t}';
    } else {
      // class
      return "$fieldKey = json['$key'] != null ?"
          ' ${_buildParseClass(jsonKey)} : null;';
    }
  }

  String toJsonExpression(String key, bool privateField) {
    final fieldKey =
        fixFieldName(key, typeDef: this, privateField: privateField);
    //final thisKey = 'this.$fieldKey';
    final thisKey = fieldKey;
    if (isPrimitive) {
      return "data['$key'] = $thisKey;";
    } else if (name == 'List') {
      // class list
      return """if ($thisKey != null) {
      data['$key'] = $thisKey${PubspecUtils.nullSafeSupport ? '?' : ''}.map((v) => ${_buildToJsonClass('v', nullSafe: false)}).toList();
    }""";
    } else {
      // class
      return """if ($thisKey != null) {
      data['$key'] = ${_buildToJsonClass(thisKey, nullSafe: PubspecUtils.nullSafeSupport)};
    }""";
    }
  }
}

class Dependency {
  String name;
  final TypeDefinition typeDef;

  Dependency(this.name, this.typeDef);

  String get className => camelCase(name);
}

class ClassDefinition {
  final String _name;
  final bool _privateFields;
  final bool? _withCopyConstructor;
  final Map<String, TypeDefinition> fields = <String, TypeDefinition>{};

  String get name => _name;

  bool get privateFields => _privateFields;

  bool? get copyConstructor => _withCopyConstructor;

  List<Dependency> get dependencies {
    final dependenciesList = <Dependency>[];
    final keys = fields.keys;
    for (var k in keys) {
      final f = fields[k]!;
      if (!f.isPrimitive) {
        dependenciesList.add(Dependency(k, f));
      }
    }
    return dependenciesList;
  }

  ClassDefinition(this._name,
      [this._privateFields = false, this._withCopyConstructor = false]);

  @override
  bool operator ==(dynamic other) {
    if (other is ClassDefinition) {
      var otherClassDef = other;
      return isSubsetOf(otherClassDef) && otherClassDef.isSubsetOf(this);
    }
    return false;
  }

  bool isSubsetOf(ClassDefinition other) {
    final keys = fields.keys.toList();
    final len = keys.length;
    for (var i = 0; i < len; i++) {
      var otherTypeDef = other.fields[keys[i]];
      if (otherTypeDef != null) {
        var typeDef = fields[keys[i]];
        if (typeDef != otherTypeDef) {
          return false;
        }
      } else {
        return false;
      }
    }
    return true;
  }

  bool hasField(TypeDefinition otherField) {
    return fields.keys.firstWhereOrNull((k) => fields[k] == otherField) != null;
  }

  void addField(String name, TypeDefinition typeDef) {
    fields[name] = typeDef;
  }

  void _addTypeDef(TypeDefinition typeDef, StringBuffer sb) {
    sb.write('${typeDef.name}');
    if (typeDef.subtype != null) {
      sb.write('<${typeDef.subtype}>');
      if (PubspecUtils.nullSafeSupport && typeDef.name != 'dynamic') {
        sb.write('?');
      }
    }
  }

  String _generateFieldList({int indentLevel = 1, String delimiter = ';'}) {
    return fields.keys.map((key) {
      final f = fields[key]!;
      final fieldName =
          fixFieldName(key, typeDef: f, privateField: privateFields);
      final sb = StringBuffer();
      sb.write('\t ' * indentLevel);
      _addTypeDef(f, sb);
      sb.write(' $fieldName$delimiter');
      return sb.toString();
    }).join('\n');
  }

  String get _fieldList {
    return _generateFieldList();
  }

  String get _gettersSetters {
    return fields.keys.map((key) {
      final f = fields[key]!;
      final publicFieldName =
          fixFieldName(key, typeDef: f, privateField: false);
      final privateFieldName =
          fixFieldName(key, typeDef: f, privateField: true);
      final sb = StringBuffer();
      sb.write('\t');
      _addTypeDef(f, sb);
      sb.write(' get $publicFieldName => $privateFieldName;'
          '\n\tset $publicFieldName(');
      _addTypeDef(f, sb);
      sb.write(' $publicFieldName) => $privateFieldName = $publicFieldName;');
      return sb.toString();
    }).join('\n');
  }

  String get _defaultPrivateConstructor {
    final sb = StringBuffer();
    sb.write('\t$name({');
    var i = 0;
    var len = fields.keys.length - 1;
    for (var key in fields.keys) {
      final f = fields[key]!;
      final publicFieldName =
          fixFieldName(key, typeDef: f, privateField: false);
      _addTypeDef(f, sb);
      sb.write(' $publicFieldName');
      if (i != len) {
        sb.write(', ');
      }
      i++;
    }
    sb.write('}) {\n');
    for (var key in fields.keys) {
      final f = fields[key];
      final publicFieldName =
          fixFieldName(key, typeDef: f, privateField: false);
      final privateFieldName =
          fixFieldName(key, typeDef: f, privateField: true);
      //sb.write('this.$privateFieldName = $publicFieldName;\n');
      sb.write('$privateFieldName = $publicFieldName;\n');
    }

    sb.write('}');
    return sb.toString();
  }

  String get _defaultConstructor {
    final sb = StringBuffer();
    sb.write('\t$name({');
    var i = 0;
    var len = fields.keys.length - 1;
    for (var key in fields.keys) {
      final f = fields[key];
      final fieldName =
          fixFieldName(key, typeDef: f, privateField: privateFields);
      sb.write('this.$fieldName');
      //sb.write('$fieldName');
      if (i != len) {
        sb.write(', ');
      }
      i++;
    }

    sb.write('});');
    return sb.toString();
  }

  String get _copyConstructor {
    final sb = StringBuffer();
    sb.write('\t$name copyWith({');
    sb.write(_generateFieldList(indentLevel: 2, delimiter: ','));
    sb.write('\t}) {');
    sb.write('\t\treturn $name(');

    for (var key in fields.keys) {
      final f = fields[key];
      final fieldName =
          fixFieldName(key, typeDef: f, privateField: privateFields);
      sb.write('$fieldName: $fieldName ?? this.$fieldName,');
    }

    sb.write(');'); // return $name(...
    sb.write('}');
    return sb.toString();
  }

  String get _jsonParseFunc {
    final sb = StringBuffer();
    sb.write('\t$name');
    sb.write('.fromJson(Map<String, dynamic> json) {\n');
    for (var k in fields.keys) {
      sb.write('\t\t${fields[k]!.jsonParseExpression(k, privateFields)}\n');
    }
    sb.write('\t}');
    return sb.toString();
  }

  String get _jsonGenFunc {
    final sb = StringBuffer();
    sb.write('\tMap<String, dynamic> toJson() {\n\t\t'
        'final  data = <String, dynamic>{};\n');
    for (var k in fields.keys) {
      sb.write('\t\t${fields[k]!.toJsonExpression(k, privateFields)}\n');
    }
    sb.write('\t\treturn data;\n');
    sb.write('\t}');
    return sb.toString();
  }

  @override
  String toString() {
    if (privateFields) {
      return 'class $name {\n$_fieldList\n\n$_defaultPrivateConstructor\n\n'
          '$_gettersSetters\n\n$_jsonParseFunc\n\n$_jsonGenFunc\n}\n';
    } else {
      if (copyConstructor!) {
        return 'class $name {\n$_fieldList\n\n$_defaultConstructor'
            '\n\n$_copyConstructor\n\n$_jsonParseFunc\n\n$_jsonGenFunc\n}\n';
      } else {
        return 'class $name {\n$_fieldList\n\n$_defaultConstructor'
            '\n\n$_jsonParseFunc\n\n$_jsonGenFunc\n}\n';
      }
    }
  }

  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
}
