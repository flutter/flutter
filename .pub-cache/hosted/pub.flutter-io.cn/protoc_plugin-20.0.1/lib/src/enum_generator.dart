// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../protoc.dart';

class EnumAlias {
  final EnumValueDescriptorProto value;
  final EnumValueDescriptorProto canonicalValue;
  EnumAlias(this.value, this.canonicalValue);
}

class EnumGenerator extends ProtobufContainer {
  @override
  final ProtobufContainer? parent;

  @override
  final String? classname;

  @override
  final String fullName;

  final EnumDescriptorProto _descriptor;
  final List<EnumValueDescriptorProto> _canonicalValues =
      <EnumValueDescriptorProto>[];
  final List<int> _originalCanonicalIndices = <int>[];
  final List<EnumAlias> _aliases = <EnumAlias>[];

  /// Maps the name of an enum value to the Dart name we will use for it.
  final Map<String, String> dartNames = <String, String>{};
  final List<int> _originalAliasIndices = <int>[];
  List<int>? _fieldPath;
  final List<int> _fieldPathSegment;

  /// See [[ProtobufContainer]
  @override
  List<int>? get fieldPath =>
      _fieldPath ??= List.from(parent!.fieldPath!)..addAll(_fieldPathSegment);

  EnumGenerator._(EnumDescriptorProto descriptor, this.parent,
      Set<String> usedClassNames, int repeatedFieldIndex, int fieldIdTag)
      : _fieldPathSegment = [fieldIdTag, repeatedFieldIndex],
        classname = messageOrEnumClassName(descriptor.name, usedClassNames,
            parent: parent!.classname ?? ''),
        fullName = parent.fullName == ''
            ? descriptor.name
            : '${parent.fullName}.${descriptor.name}',
        _descriptor = descriptor {
    final usedNames = {...reservedEnumNames};
    for (var i = 0; i < descriptor.value.length; i++) {
      var value = descriptor.value[i];
      var canonicalValue =
          descriptor.value.firstWhere((v) => v.number == value.number);
      if (value == canonicalValue) {
        _canonicalValues.add(value);
        _originalCanonicalIndices.add(i);
      } else {
        _aliases.add(EnumAlias(value, canonicalValue));
        _originalAliasIndices.add(i);
      }
      dartNames[value.name] = disambiguateName(
          avoidInitialUnderscore(value.name), usedNames, enumSuffixes());
    }
  }

  static const _topLevelFieldTag = 5;
  static const _nestedFieldTag = 4;

  EnumGenerator.topLevel(
      EnumDescriptorProto descriptor,
      ProtobufContainer parent,
      Set<String> usedClassNames,
      int repeatedFieldIndex)
      : this._(descriptor, parent, usedClassNames, repeatedFieldIndex,
            _topLevelFieldTag);

  EnumGenerator.nested(EnumDescriptorProto descriptor, ProtobufContainer parent,
      Set<String> usedClassNames, int repeatedFieldIndex)
      : this._(descriptor, parent, usedClassNames, repeatedFieldIndex,
            _nestedFieldTag);

  @override
  String get package => parent!.package;

  @override
  FileGenerator? get fileGen => parent!.fileGen;

  /// Make this enum available as a field type.
  void register(GenerationContext ctx) {
    ctx.registerFieldType(this);
  }

  /// Returns a const expression that evaluates to the JSON for this message.
  /// [usage] represents the .pb.dart file where the expression will be used.
  String getJsonConstant(FileGenerator usage) {
    var name = '$classname\$json';
    if (usage.protoFileUri == fileGen!.protoFileUri) {
      return name;
    }
    return '$fileImportPrefix.$name';
  }

  static const int _enumValueTag = 2;

  void generate(IndentingWriter out) {
    out.addAnnotatedBlock(
        'class $classname extends $protobufImportPrefix.ProtobufEnum {',
        '}\n', [
      NamedLocation(
          name: classname!,
          fieldPathSegment: fieldPath!,
          start: 'class '.length)
    ], () {
      // -----------------------------------------------------------------
      // Define enum types.
      for (var i = 0; i < _canonicalValues.length; i++) {
        var val = _canonicalValues[i];
        final name = dartNames[val.name]!;
        final conditionalValName = configurationDependent(
            'protobuf.omit_enum_names', quoted(val.name));
        out.printlnAnnotated(
            'static const $classname $name = '
            '$classname._(${val.number}, $conditionalValName);',
            [
              NamedLocation(
                  name: name,
                  fieldPathSegment: List.from(fieldPath!)
                    ..addAll([_enumValueTag, _originalCanonicalIndices[i]]),
                  start: 'static const $classname '.length)
            ]);
      }
      if (_aliases.isNotEmpty) {
        out.println();
        for (var i = 0; i < _aliases.length; i++) {
          var alias = _aliases[i];
          final name = dartNames[alias.value.name]!;
          out.printlnAnnotated(
              'static const $classname $name ='
              ' ${dartNames[alias.canonicalValue.name]};',
              [
                NamedLocation(
                    name: name,
                    fieldPathSegment: List.from(fieldPath!)
                      ..addAll([_enumValueTag, _originalAliasIndices[i]]),
                    start: 'static const $classname '.length)
              ]);
        }
      }
      out.println();

      out.println('static const $coreImportPrefix.List<$classname> values ='
          ' <$classname> [');
      for (var val in _canonicalValues) {
        final name = dartNames[val.name];
        out.println('  $name,');
      }
      out.println('];');
      out.println();

      out.println(
          'static final $coreImportPrefix.Map<$coreImportPrefix.int, $classname> _byValue ='
          ' $protobufImportPrefix.ProtobufEnum.initByValue(values);');
      out.println('static $classname? valueOf($coreImportPrefix.int value) =>'
          ' _byValue[value];');
      out.println();

      out.println(
          'const $classname._($coreImportPrefix.int v, $coreImportPrefix.String n) '
          ': super(v, n);');
    });
  }

  /// Writes a Dart constant containing the JSON for the EnumProtoDescriptor.
  void generateConstants(IndentingWriter out) {
    var name = getJsonConstant(fileGen!);
    var json = _descriptor.writeToJsonMap();

    out.println('@$coreImportPrefix.Deprecated'
        '(\'Use ${toplevelParent!.binaryDescriptorName} instead\')');
    out.print('const $name = ');
    writeJsonConst(out, json);
    out.println(';');
    out.println();
  }
}
