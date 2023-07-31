// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:protobuf/meta.dart';

import 'src/generated/dart_options.pb.dart';
import 'src/generated/descriptor.pb.dart';

class MemberNames {
  List<FieldNames> fieldNames;
  List<OneofNames> oneofNames;
  MemberNames(this.fieldNames, this.oneofNames);
}

/// The Dart member names in a GeneratedMessage subclass for one protobuf field.
class FieldNames {
  /// The descriptor of the field these member names apply to.
  final FieldDescriptorProto descriptor;

  /// The index of this field in MessageGenerator.fieldList.
  /// The same index will be stored in FieldInfo.index.
  ///
  /// `null` for extensions.
  final int? index;

  /// The position of this field as it appeared in the original DescriptorProto.
  /// Used to construct metadata.
  ///
  /// `null` for extensions.
  final int? sourcePosition;

  /// Identifier for generated getters/setters.
  final String fieldName;

  /// Identifier for the generated hasX() method, without braces.
  ///
  /// `null` for repeated fields.
  final String? hasMethodName;

  /// Identifier for the generated clearX() method, without braces.
  ///
  /// `null` for repeated fields.
  final String? clearMethodName;

  // Identifier for the generated ensureX() method, without braces.
  //
  // 'null' for scalar, repeated, and map fields.
  final String? ensureMethodName;

  FieldNames(this.descriptor, this.index, this.sourcePosition, this.fieldName,
      {this.hasMethodName, this.clearMethodName, this.ensureMethodName});
}

/// The Dart names associated with a oneof declaration.
class OneofNames {
  final OneofDescriptorProto descriptor;

  /// Index in the containing type's oneof_decl list.
  final int index;

  /// Identifier for the generated whichX() method, without braces.
  final String whichOneofMethodName;

  /// Identifier for the generated clearX() method, without braces.
  final String clearMethodName;

  /// Identifier for the generated enum definition.
  final String oneofEnumName;

  ///  Identifier for the _XByTag map.
  final String byTagMapName;

  OneofNames(this.descriptor, this.index, this.clearMethodName,
      this.whichOneofMethodName, this.oneofEnumName, this.byTagMapName);
}

// For performance reasons, use code units instead of Regex.
bool _startsWithDigit(String input) =>
    input.isNotEmpty && (input.codeUnitAt(0) ^ 0x30) <= 9;

/// Move any initial underscores in [input] to the end.
///
/// According to the spec identifiers cannot start with _, but it seems to be
/// accepted by protoc. These identifiers are private in Dart, so they have to
/// be transformed.
///
/// If [input] starts with a digit after transformation, prefix with an 'x'.
String avoidInitialUnderscore(String input) {
  while (input.startsWith('_')) {
    input = '${input.substring(1)}_';
  }
  if (_startsWithDigit(input)) {
    input = 'x$input';
  }
  return input;
}

/// Returns [input] surrounded by single quotes and with all '$'s escaped.
String singleQuote(String input) {
  return "'${input.replaceAll(r'$', r'\$')}'";
}

/// Chooses the Dart name of an extension.
String extensionName(FieldDescriptorProto descriptor, Set<String> usedNames) {
  return _unusedMemberNames(descriptor, null, null, usedNames).fieldName;
}

Iterable<String> extensionSuffixes() sync* {
  yield 'Ext';
  var i = 2;
  while (true) {
    yield '$i';
    i++;
  }
}

/// Replaces all characters in [imput] that are not valid in a dart identifier
/// with _.
///
/// This function does not take care of leading underscores.
String legalDartIdentifier(String imput) {
  return imput.replaceAll(RegExp(r'[^a-zA-Z0-9$_]'), '_');
}

/// Chooses the name of the Dart class holding top-level extensions.
String extensionClassName(
    FileDescriptorProto descriptor, Set<String> usedNames) {
  var s = avoidInitialUnderscore(
      legalDartIdentifier(_fileNameWithoutExtension(descriptor)));
  var candidate = '${s[0].toUpperCase()}${s.substring(1)}';
  return disambiguateName(candidate, usedNames, extensionSuffixes());
}

String _fileNameWithoutExtension(FileDescriptorProto descriptor) {
  var path = Uri.file(descriptor.name);
  var fileName = path.pathSegments.last;
  var dot = fileName.lastIndexOf('.');
  return dot == -1 ? fileName : fileName.substring(0, dot);
}

// Exception thrown when a field has an invalid 'dart_name' option.
class DartNameOptionException implements Exception {
  final String message;
  DartNameOptionException(this.message);
  @override
  String toString() => message;
}

/// Returns a [name] that is not contained in [usedNames] by suffixing it with
/// the first possible suffix from [suffixes].
///
/// The chosen name is added to [usedNames].
///
/// If [generateVariants] is given, all the variants of a name must be available
/// before that name is chosen, and all the chosen variants will be added to
/// [usedNames].
/// The returned name is that, which will generate the accepted variants.
String disambiguateName(
    String name, Set<String> usedNames, Iterable<String> suffixes,
    {List<String> Function(String candidate)? generateVariants}) {
  generateVariants ??= (String name) => <String>[name];

  bool allVariantsAvailable(List<String> variants) {
    return variants.every((String variant) => !usedNames.contains(variant));
  }

  var usedSuffix = '';
  var candidateVariants = generateVariants(name);

  if (!allVariantsAvailable(candidateVariants)) {
    for (var suffix in suffixes) {
      candidateVariants = generateVariants('$name$suffix');
      if (allVariantsAvailable(candidateVariants)) {
        usedSuffix = suffix;
        break;
      }
    }
  }

  usedNames.addAll(candidateVariants);
  return '$name$usedSuffix';
}

Iterable<String> defaultSuffixes() sync* {
  yield '_';
  var i = 0;
  while (true) {
    yield ('_$i');
    i++;
  }
}

String oneofEnumClassName(
    String descriptorName, Set<String> usedNames, String parentName) {
  descriptorName = '${parentName}_${underscoresToCamelCase(descriptorName)}';
  return disambiguateName(
      avoidInitialUnderscore(descriptorName), usedNames, defaultSuffixes());
}

String oneofEnumMemberName(String fieldName) => disambiguateName(
    fieldName, Set<String>.from(_oneofEnumMemberNames), defaultSuffixes());

/// Chooses the name of the Dart class to generate for a proto message or enum.
///
/// For a nested message or enum, [parent] should be provided
/// with the name of the Dart class for the immediate parent.
String messageOrEnumClassName(String descriptorName, Set<String> usedNames,
    {String parent = ''}) {
  if (parent != '') {
    descriptorName = '${parent}_$descriptorName';
  }
  return disambiguateName(
      avoidInitialUnderscore(descriptorName), usedNames, defaultSuffixes());
}

/// Returns the set of names reserved by the ProtobufEnum class and its
/// generated subclasses.
Set<String> get reservedEnumNames => <String>{}
  ..addAll(ProtobufEnum_reservedNames)
  ..addAll(_dartReservedWords)
  ..addAll(_protobufEnumNames);

Iterable<String> enumSuffixes() sync* {
  var s = '_';
  while (true) {
    yield s;
    s += '_';
  }
}

/// Chooses the GeneratedMessage member names for each field and names
/// associated with each oneof declaration.
///
/// Additional names to avoid can be supplied using [reserved].
/// (This should only be used for mixins.)
///
/// Returns [MemberNames] which holds a list with [FieldNames] and a list with [OneofNames].
///
/// Throws [DartNameOptionException] if a field has this option and
/// it's set to an invalid name.
MemberNames messageMemberNames(DescriptorProto descriptor,
    String parentClassName, Set<String> usedTopLevelNames,
    {Iterable<String> reserved = const []}) {
  var fieldList = List<FieldDescriptorProto>.from(descriptor.field);
  var sourcePositions =
      fieldList.asMap().map((index, field) => MapEntry(field.name, index));
  var sorted = fieldList
    ..sort((FieldDescriptorProto a, FieldDescriptorProto b) {
      if (a.number < b.number) return -1;
      if (a.number > b.number) return 1;
      throw 'multiple fields defined for tag ${a.number} in ${descriptor.name}';
    });

  // Choose indexes first, based on their position in the sorted list.
  var indexes = <String, int>{};
  for (var field in sorted) {
    var index = indexes.length;
    indexes[field.name] = index;
  }

  var existingNames = <String>{...reservedMemberNames, ...reserved};

  var fieldNames = List<FieldNames?>.filled(indexes.length, null);

  void takeFieldNames(FieldNames chosen) {
    fieldNames[chosen.index!] = chosen;

    existingNames.add(chosen.fieldName);
    if (chosen.hasMethodName != null) {
      existingNames.add(chosen.hasMethodName!);
    }
    if (chosen.clearMethodName != null) {
      existingNames.add(chosen.clearMethodName!);
    }
  }

  // Handle fields with a dart_name option.
  // They have higher priority than automatically chosen names.
  // Explicitly setting a name that's already taken is a build error.
  for (var field in sorted) {
    if (_nameOption(field)!.isNotEmpty) {
      takeFieldNames(_memberNamesFromOption(descriptor, field,
          indexes[field.name]!, sourcePositions[field.name]!, existingNames));
    }
  }

  // Then do other fields.
  // They are automatically renamed until we find something unused.
  for (var field in sorted) {
    if (_nameOption(field)!.isEmpty) {
      var index = indexes[field.name]!;
      var sourcePosition = sourcePositions[field.name];
      takeFieldNames(
          _unusedMemberNames(field, index, sourcePosition, existingNames));
    }
  }

  var oneofNames = <OneofNames>[];

  void takeOneofNames(OneofNames chosen) {
    oneofNames.add(chosen);
    existingNames.add(chosen.whichOneofMethodName);
    existingNames.add(chosen.clearMethodName);
    existingNames.add(chosen.byTagMapName);
  }

  List<String> oneofNameVariants(String name) {
    return [_defaultWhichMethodName(name), _defaultClearMethodName(name)];
  }

  final realOneofCount = countRealOneofs(descriptor);
  for (var i = 0; i < realOneofCount; i++) {
    var oneof = descriptor.oneofDecl[i];

    var oneofName = disambiguateName(
        underscoresToCamelCase(oneof.name), existingNames, defaultSuffixes(),
        generateVariants: oneofNameVariants);

    var oneofEnumName =
        oneofEnumClassName(oneof.name, usedTopLevelNames, parentClassName);

    var enumMapName = disambiguateName(
        '_${oneofEnumName}ByTag', existingNames, defaultSuffixes());

    takeOneofNames(OneofNames(oneof, i, _defaultClearMethodName(oneofName),
        _defaultWhichMethodName(oneofName), oneofEnumName, enumMapName));
  }

  return MemberNames(fieldNames.cast<FieldNames>(), oneofNames);
}

/// Chooses the member names for a field that has the 'dart_name' option.
///
/// If the explicitly-set Dart name is already taken, throw an exception.
/// (Fails the build.)
FieldNames _memberNamesFromOption(
    DescriptorProto message,
    FieldDescriptorProto field,
    int index,
    int sourcePosition,
    Set<String> existingNames) {
  // TODO(skybrian): provide more context in errors (filename).
  var where = '${message.name}.${field.name}';

  void checkAvailable(String name) {
    if (existingNames.contains(name)) {
      throw DartNameOptionException(
          "$where: dart_name option is invalid: '$name' is already used");
    }
  }

  var name = _nameOption(field)!;
  if (name.isEmpty) {
    throw ArgumentError("field doesn't have dart_name option");
  }
  if (!_isDartFieldName(name)) {
    throw DartNameOptionException('$where: dart_name option is invalid: '
        "'$name' is not a valid Dart field name");
  }
  checkAvailable(name);

  if (_isRepeated(field)) {
    return FieldNames(field, index, sourcePosition, name);
  }

  var hasMethod = 'has${_capitalize(name)}';
  checkAvailable(hasMethod);

  var clearMethod = 'clear${_capitalize(name)}';
  checkAvailable(clearMethod);

  String? ensureMethod;

  if (_isGroupOrMessage(field)) {
    ensureMethod = 'ensure${_capitalize(name)}';
    checkAvailable(ensureMethod);
  }
  return FieldNames(field, index, sourcePosition, name,
      hasMethodName: hasMethod,
      clearMethodName: clearMethod,
      ensureMethodName: ensureMethod);
}

Iterable<String> _memberNamesSuffix(int number) sync* {
  var suffix = '_$number';
  while (true) {
    yield suffix;
    suffix = '${suffix}_$number';
  }
}

FieldNames _unusedMemberNames(FieldDescriptorProto field, int? index,
    int? sourcePosition, Set<String> existingNames) {
  if (_isRepeated(field)) {
    return FieldNames(
        field,
        index,
        sourcePosition,
        disambiguateName(_defaultFieldName(_fieldMethodSuffix(field)),
            existingNames, _memberNamesSuffix(field.number)));
  }

  List<String> generateNameVariants(String name) {
    var result = <String>[
      _defaultFieldName(name),
      _defaultHasMethodName(name),
      _defaultClearMethodName(name),
    ];

    // TODO(zarah): Use 'collection if' when sdk dependency is updated.
    if (_isGroupOrMessage(field)) result.add(_defaultEnsureMethodName(name));

    return result;
  }

  var name = disambiguateName(_fieldMethodSuffix(field), existingNames,
      _memberNamesSuffix(field.number),
      generateVariants: generateNameVariants);

  return FieldNames(field, index, sourcePosition,
      avoidInitialUnderscore(_defaultFieldName(name)),
      hasMethodName: _defaultHasMethodName(name),
      clearMethodName: _defaultClearMethodName(name),
      ensureMethodName:
          _isGroupOrMessage(field) ? _defaultEnsureMethodName(name) : null);
}

/// The name to use by default for the Dart getter and setter.
/// (A suffix will be added if there is a conflict.)
String _defaultFieldName(String fieldMethodSuffix) =>
    lowerCaseFirstLetter(fieldMethodSuffix);

String _defaultHasMethodName(String fieldMethodSuffix) =>
    'has$fieldMethodSuffix';

String _defaultClearMethodName(String fieldMethodSuffix) =>
    'clear$fieldMethodSuffix';

String _defaultWhichMethodName(String oneofMethodSuffix) =>
    'which$oneofMethodSuffix';

String _defaultEnsureMethodName(String fieldMethodSuffix) =>
    'ensure$fieldMethodSuffix';

/// The suffix to use for this field in Dart method names.
/// (It should be camelcase and begin with an uppercase letter.)
String _fieldMethodSuffix(FieldDescriptorProto field) {
  var name = _nameOption(field)!;
  if (name.isNotEmpty) return _capitalize(name);

  if (field.type != FieldDescriptorProto_Type.TYPE_GROUP) {
    return underscoresToCamelCase(field.name);
  }

  // For groups, use capitalization of 'typeName' rather than 'name'.
  name = field.typeName;
  var index = name.lastIndexOf('.');
  if (index != -1) {
    name = name.substring(index + 1);
  }
  return underscoresToCamelCase(name);
}

String underscoresToCamelCase(String s) =>
    s.split('_').map(_capitalize).join('');

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

bool _isRepeated(FieldDescriptorProto field) =>
    field.label == FieldDescriptorProto_Label.LABEL_REPEATED;

bool _isGroupOrMessage(FieldDescriptorProto field) =>
    field.type == FieldDescriptorProto_Type.TYPE_MESSAGE ||
    field.type == FieldDescriptorProto_Type.TYPE_GROUP;

String? _nameOption(FieldDescriptorProto field) =>
    field.options.getExtension(Dart_options.dartName) as String?;

bool _isDartFieldName(String name) => name.startsWith(_dartFieldNameExpr);

final _dartFieldNameExpr = RegExp(r'^[a-z]\w+$');

/// Names that would collide as top-level identifiers.
final List<String> forbiddenTopLevelNames = <String>[
  'List',
  'Function',
  'Map',
  ..._dartReservedWords,
];

final List<String> reservedMemberNames = <String>[
  ..._dartReservedWords,
  ...GeneratedMessage_reservedNames,
  ..._generatedMessageNames
];

final List<String> forbiddenExtensionNames = <String>[
  ..._dartReservedWords,
  ...GeneratedMessage_reservedNames,
  ..._generatedMessageNames
];

// List of Dart language reserved words in names which cannot be used in a
// subclass of GeneratedMessage.
const List<String> _dartReservedWords = [
  'assert',
  'bool',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'default',
  'do',
  'double',
  'else',
  'enum',
  'extends',
  'false',
  'final',
  'finally',
  'for',
  'if',
  'in',
  'int',
  'is',
  'new',
  'null',
  'rethrow',
  'return',
  'super',
  'switch',
  'this',
  'throw',
  'true',
  'try',
  'var',
  'void',
  'while',
  'with'
];

// List of names used in the generated message classes.
//
// This is in addition to GeneratedMessage_reservedNames, which are names from
// the base GeneratedMessage class determined by reflection.
const _generatedMessageNames = <String>[
  'create',
  'createRepeated',
  'getDefault',
  'List',
  'notSet'
];

// List of names used in the generated enum classes.
//
// This is in addition to ProtobufEnum_reservedNames, which are names from the
// base ProtobufEnum class determined by reflection.
const _protobufEnumNames = <String>[
  'List',
  'valueOf',
  'values',
];

// List of names used in Dart enums, which can't be used as enum member names.
const _oneofEnumMemberNames = <String>['default', 'index', 'values'];

// Count the number of 'real' oneofs - that is oneofs not created for an
// optional proto3 field.
int countRealOneofs(DescriptorProto descriptor) {
  var highestIndexSeen = -1;
  for (final field in descriptor.field) {
    if (field.hasOneofIndex() && !field.proto3Optional) {
      highestIndexSeen = math.max(highestIndexSeen, field.oneofIndex);
    }
  }
  // The number of entries is one higher than the highest seen index.
  return highestIndexSeen + 1;
}

String lowerCaseFirstLetter(String input) =>
    input[0].toLowerCase() + input.substring(1);
