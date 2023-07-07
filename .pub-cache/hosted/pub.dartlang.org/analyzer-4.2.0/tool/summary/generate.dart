// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file contains code to generate serialization/deserialization logic for
/// summaries based on an "IDL" description of the summary format (written in
/// stylized Dart).
///
/// For each class in the "IDL" input, two corresponding classes are generated:
/// - A class with the same name which represents deserialized summary data in
///   memory.  This class has read-only semantics.
/// - A "builder" class which can be used to generate serialized summary data.
///   This class has write-only semantics.
///
/// Each of the "builder" classes has a single `finish` method which writes
/// the entity being built into the given FlatBuffer and returns the `Offset`
/// reference to it.
import 'dart:convert';
import 'dart:io';

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart';
import 'package:analyzer_utilities/tools.dart';

import 'idl_model.dart' as idl_model;
import 'mini_ast.dart';

main(List<String> args) async {
  if (args.length != 1) {
    print('Error: IDL path is required');
    print('usage: dart generate.dart path/to/idl.dart');
    return;
  }
  String idlPath = args[0];
  await GeneratedContent.generateAll(
      File(idlPath).parent.path, getAllTargets(idlPath));
}

List<GeneratedContent> getAllTargets(String idlPath) {
  final GeneratedFile formatTarget = GeneratedFile('format.dart', (_) async {
    _CodeGenerator codeGenerator = _CodeGenerator(idlPath);
    codeGenerator.generateFormatCode();
    return codeGenerator._outBuffer.toString();
  });

  final GeneratedFile schemaTarget = GeneratedFile('format.fbs', (_) async {
    _CodeGenerator codeGenerator = _CodeGenerator(idlPath);
    codeGenerator.generateFlatBufferSchema();
    return codeGenerator._outBuffer.toString();
  });

  return <GeneratedContent>[formatTarget, schemaTarget];
}

typedef _StringToString = String Function(String s);

class _BaseGenerator {
  static const String _throwDeprecated =
      "throw new UnimplementedError('attempt to access deprecated field')";

  /// Semantic model of the "IDL" input file.
  final idl_model.Idl _idl;

  /// Buffer in which generated code is accumulated.
  final StringBuffer _outBuffer;

  /// Current indentation level.
  String _indentation = '';

  _BaseGenerator(this._idl, this._outBuffer);

  /// Generate a Dart expression representing the default value for a field
  /// having the given [type], or `null` if there is no default value.
  ///
  /// If [builder] is `true`, the returned type should be appropriate for use in
  /// a builder class.
  String? defaultValue(idl_model.FieldType type, bool builder) {
    if (type.isList) {
      if (builder) {
        idl_model.FieldType elementType =
            idl_model.FieldType(type.typeName, false);
        return '<${encodedType(elementType)}>[]';
      } else {
        return 'const <${idlPrefix(type.typeName)}>[]';
      }
    }

    var enum_ = _idl.enums[type.typeName];
    if (enum_ != null) {
      return '${idlPrefix(type.typeName)}.${enum_.values[0].name}';
    } else if (type.typeName == 'double') {
      return '0.0';
    } else if (type.typeName == 'int') {
      return '0';
    } else if (type.typeName == 'String') {
      return "''";
    } else if (type.typeName == 'bool') {
      return 'false';
    } else {
      return null;
    }
  }

  /// Generate a string representing the Dart type which should be used to
  /// represent [type] while building a serialized data structure.
  String encodedType(idl_model.FieldType type) {
    String typeStr;
    if (_idl.classes.containsKey(type.typeName)) {
      typeStr = '${type.typeName}Builder';
    } else {
      typeStr = idlPrefix(type.typeName);
    }
    if (type.isList) {
      return 'List<$typeStr>';
    } else {
      return typeStr;
    }
  }

  /// Return the nullable [encodedType] of the [type].
  String encodedType2(idl_model.FieldType type) {
    return '${encodedType(type)}?';
  }

  /// Add the prefix `idl.` to a type name, unless that type name is the name of
  /// a built-in type.
  String idlPrefix(String s) {
    switch (s) {
      case 'bool':
      case 'double':
      case 'int':
      case 'String':
        return s;
      default:
        return 'idl.$s';
    }
  }

  /// Execute [callback] with two spaces added to [_indentation].
  void indent(void Function() callback) {
    String oldIndentation = _indentation;
    try {
      _indentation += '  ';
      callback();
    } finally {
      _indentation = oldIndentation;
    }
  }

  /// Add the string [s] to the output as a single line, indenting as
  /// appropriate.
  void out([String s = '']) {
    if (s == '') {
      _outBuffer.writeln('');
    } else {
      _outBuffer.writeln('$_indentation$s');
    }
  }

  void outDoc(String? documentation) {
    if (documentation != null) {
      documentation.split('\n').forEach(out);
    }
  }

  /// Execute [out] of [s] in [indent].
  void outWithIndent(String s) {
    indent(() {
      out(s);
    });
  }

  /// Enclose [s] in quotes, escaping as necessary.
  String quoted(String s) {
    return json.encode(s);
  }

  bool _isNullable(idl_model.FieldType type) {
    return !type.isList && _idl.classes.containsKey(type.typeName);
  }
}

class _BuilderGenerator extends _BaseGenerator {
  final idl_model.ClassDeclaration cls;
  List<String> constructorParams = <String>[];

  _BuilderGenerator(super.idl, super.outBuffer, this.cls);

  String get builderName => '${name}Builder';

  String get name => cls.name;

  void generate() {
    String mixinName = '_${name}Mixin';
    var implementsClause =
        cls.isDeprecated ? '' : ' implements ${idlPrefix(name)}';
    out('class $builderName extends Object with $mixinName$implementsClause {');
    indent(() {
      _generateFields();
      _generateGettersSetters();
      _generateConstructors();
      _generateFlushInformative();
      _generateCollectApiSignature();
      _generateToBuffer();
      _generateFinish();
    });
    out('}');
  }

  void _generateCollectApiSignature() {
    out();
    out('/// Accumulate non-[informative] data into [signature].');
    out('void collectApiSignature(api_sig.ApiSignature signatureSink) {');

    void writeField(idl_model.FieldDeclaration field) {
      if (field.isInformative) {
        return;
      }
      var type = field.type;
      var name = field.name;
      if (type.isList) {
        var localName = name;
        out('var $name = this._$name;');
        out('if ($localName == null) {');
        indent(() {
          out('signatureSink.addInt(0);');
        });
        out('} else {');
        indent(() {
          out('signatureSink.addInt($localName.length);');
          out('for (var x in $localName) {');
          indent(() {
            _generateSignatureCall(type.typeName, 'x', false);
          });
          out('}');
        });
        out('}');
      } else {
        _generateSignatureCall(type.typeName, 'this._$name', true);
      }
    }

    indent(() {
      List<idl_model.FieldDeclaration> sortedFields = cls.fields.toList()
        ..sort((idl_model.FieldDeclaration a, idl_model.FieldDeclaration b) =>
            a.id.compareTo(b.id));
      for (idl_model.FieldDeclaration field in sortedFields) {
        writeField(field);
      }
    });
    out('}');
  }

  void _generateConstructors() {
    out();
    out('$builderName({${constructorParams.join(', ')}})');
    List<idl_model.FieldDeclaration> fields = cls.fields.toList();
    for (int i = 0; i < fields.length; i++) {
      idl_model.FieldDeclaration field = fields[i];
      String prefix = i == 0 ? '  : ' : '    ';
      String suffix = i == fields.length - 1 ? ';' : ',';
      out('${prefix}_${field.name} = ${field.name}$suffix');
    }
  }

  void _generateFields() {
    for (idl_model.FieldDeclaration field in cls.fields) {
      String fieldName = field.name;
      idl_model.FieldType type = field.type;
      String typeStr = encodedType2(type);
      out('$typeStr _$fieldName;');
    }
  }

  void _generateFinish() {
    out();
    out('fb.Offset finish(fb.Builder fbBuilder) {');
    indent(() {
      // Write objects and remember Offset(s).
      for (idl_model.FieldDeclaration field in cls.fields) {
        idl_model.FieldType fieldType = field.type;
        String offsetName = 'offset_${field.name}';
        if (fieldType.isList ||
            fieldType.typeName == 'String' ||
            _idl.classes.containsKey(fieldType.typeName)) {
          out('fb.Offset? $offsetName;');
        }
      }

      for (idl_model.FieldDeclaration field in cls.fields) {
        idl_model.FieldType fieldType = field.type;
        String valueName = field.name;
        String offsetName = 'offset_${field.name}';
        String? condition;
        String? writeCode;
        if (fieldType.isList) {
          condition = ' || $valueName.isEmpty';
          if (_idl.classes.containsKey(fieldType.typeName)) {
            String itemCode = 'b.finish(fbBuilder)';
            String listCode = '$valueName.map((b) => $itemCode).toList()';
            writeCode = '$offsetName = fbBuilder.writeList($listCode);';
          } else if (_idl.enums.containsKey(fieldType.typeName)) {
            String itemCode = 'b.index';
            String listCode = '$valueName.map((b) => $itemCode).toList()';
            writeCode = '$offsetName = fbBuilder.writeListUint8($listCode);';
          } else if (fieldType.typeName == 'bool') {
            writeCode = '$offsetName = fbBuilder.writeListBool($valueName);';
          } else if (fieldType.typeName == 'int') {
            writeCode = '$offsetName = fbBuilder.writeListUint32($valueName);';
          } else if (fieldType.typeName == 'double') {
            writeCode = '$offsetName = fbBuilder.writeListFloat64($valueName);';
          } else {
            assert(fieldType.typeName == 'String');
            String itemCode = 'fbBuilder.writeString(b)';
            String listCode = '$valueName.map((b) => $itemCode).toList()';
            writeCode = '$offsetName = fbBuilder.writeList($listCode);';
          }
        } else if (fieldType.typeName == 'String') {
          writeCode = '$offsetName = fbBuilder.writeString($valueName);';
        } else if (_idl.classes.containsKey(fieldType.typeName)) {
          writeCode = '$offsetName = $valueName.finish(fbBuilder);';
        }
        if (writeCode != null) {
          out('var $valueName = _${field.name};');
          if (condition == null) {
            out('if ($valueName != null) {');
          } else {
            out('if (!($valueName == null$condition)) {');
          }
          outWithIndent(writeCode);
          out('}');
        }
      }

      // Write the table.
      out('fbBuilder.startTable();');
      for (idl_model.FieldDeclaration field in cls.fields) {
        int index = field.id;
        idl_model.FieldType fieldType = field.type;
        String valueName = '_${field.name}';
        if (fieldType.isList ||
            fieldType.typeName == 'String' ||
            _idl.classes.containsKey(fieldType.typeName)) {
          String offsetName = 'offset_${field.name}';
          out('if ($offsetName != null) {');
          outWithIndent('fbBuilder.addOffset($index, $offsetName);');
          out('}');
        } else if (fieldType.typeName == 'bool') {
          out('fbBuilder.addBool($index, $valueName == true);');
        } else if (fieldType.typeName == 'double') {
          var defValue = defaultValue(fieldType, true);
          out('fbBuilder.addFloat64($index, $valueName, $defValue);');
        } else if (fieldType.typeName == 'int') {
          var defValue = defaultValue(fieldType, true);
          out('fbBuilder.addUint32($index, $valueName, $defValue);');
        } else if (_idl.enums.containsKey(fieldType.typeName)) {
          var defValue = '${defaultValue(fieldType, true)}.index';
          out('fbBuilder.addUint8($index, $valueName?.index, $defValue);');
        } else {
          throw UnimplementedError('Writing type ${fieldType.typeName}');
        }
      }
      out('return fbBuilder.endTable();');
    });
    out('}');
  }

  void _generateFlushInformative() {
    out();
    out('/// Flush [informative] data recursively.');
    out('void flushInformative() {');

    void writeField(String name, idl_model.FieldType type, bool isInformative) {
      if (isInformative) {
        out('$name = null;');
      } else if (_idl.classes.containsKey(type.typeName)) {
        if (type.isList) {
          out('$name?.forEach((b) => b.flushInformative());');
        } else {
          out('$name?.flushInformative();');
        }
      }
    }

    indent(() {
      for (idl_model.FieldDeclaration field in cls.fields) {
        writeField('_${field.name}', field.type, field.isInformative);
      }
    });
    out('}');
  }

  void _generateGettersSetters() {
    for (idl_model.FieldDeclaration field in cls.allFields) {
      String fieldName = field.name;
      idl_model.FieldType fieldType = field.type;
      String typeStr = encodedType(fieldType);
      String? def = defaultValue(fieldType, true);
      String defSuffix = def == null ? '' : ' ??= $def';
      out();
      if (field.isDeprecated) {
        out('@override');
        out('Null get $fieldName => ${_BaseGenerator._throwDeprecated};');
      } else {
        var nn = _isNullable(field.type) ? '?' : '';

        out('@override');
        out('$typeStr$nn get $fieldName => _$fieldName$defSuffix;');
        out();

        constructorParams.add('$typeStr? $fieldName');

        outDoc(field.documentation);

        out('set $fieldName($typeStr$nn value) {');
        indent(() {
          _generateNonNegativeInt(fieldType);
          out('this._$fieldName = value;');
        });
        out('}');
      }
    }
  }

  void _generateNonNegativeInt(idl_model.FieldType fieldType) {
    if (fieldType.typeName == 'int') {
      if (!fieldType.isList) {
        out('assert(value >= 0);');
      } else {
        out('assert(value.every((e) => e >= 0));');
      }
    }
  }

  /// Generate a call to the appropriate method of [ApiSignature] for the type
  /// [typeName], using the data named by [ref].  If [couldBeNull] is `true`,
  /// generate code to handle the possibility that [ref] is `null` (substituting
  /// in the appropriate default value).
  void _generateSignatureCall(String typeName, String ref, bool couldBeNull) {
    if (_idl.enums.containsKey(typeName)) {
      if (couldBeNull) {
        out('signatureSink.addInt($ref?.index ?? 0);');
      } else {
        out('signatureSink.addInt($ref.index);');
      }
    } else if (_idl.classes.containsKey(typeName)) {
      if (couldBeNull) {
        out('signatureSink.addBool($ref != null);');
        out('$ref?.collectApiSignature(signatureSink);');
      } else {
        out('$ref.collectApiSignature(signatureSink);');
      }
    } else {
      switch (typeName) {
        case 'String':
          if (couldBeNull) {
            ref += " ?? ''";
          }
          out("signatureSink.addString($ref);");
          break;
        case 'int':
          if (couldBeNull) {
            ref += ' ?? 0';
          }
          out('signatureSink.addInt($ref);');
          break;
        case 'bool':
          if (couldBeNull) {
            ref += ' == true';
          }
          out('signatureSink.addBool($ref);');
          break;
        case 'double':
          if (couldBeNull) {
            ref += ' ?? 0.0';
          }
          out('signatureSink.addDouble($ref);');
          break;
        default:
          throw "Don't know how to generate signature call for $typeName";
      }
    }
  }

  void _generateToBuffer() {
    if (cls.isTopLevel) {
      out();
      out('typed_data.Uint8List toBuffer() {');
      indent(() {
        out('fb.Builder fbBuilder = fb.Builder();');
        var idOrNull = cls.fileIdentifier;
        var fileId = idOrNull == null ? '' : ', ${quoted(idOrNull)}';
        out('return fbBuilder.finish(finish(fbBuilder)$fileId);');
      });
      out('}');
    }
  }
}

class _CodeGenerator {
  /// Buffer in which generated code is accumulated.
  final StringBuffer _outBuffer = StringBuffer();

  /// Semantic model of the "IDL" input file.
  final idl_model.Idl _idl = idl_model.Idl();

  _CodeGenerator(String idlPath) {
    // Parse the input "IDL" file.
    File idlFile = File(idlPath);
    String idlText =
        idlFile.readAsStringSync().replaceAll(RegExp('\r\n?'), '\n');
    // Extract a description of the IDL and make sure it is valid.
    var startingToken = scanString(idlText, includeComments: true).tokens;
    var listener = MiniAstBuilder();
    var parser = MiniAstParser(listener);
    parser.parseUnit(startingToken);
    extractIdl(listener.compilationUnit);
    checkIdl();
  }

  /// Perform basic sanity checking of the IDL (over and above that done by
  /// [extractIdl]).
  void checkIdl() {
    _idl.classes.forEach((String name, idl_model.ClassDeclaration cls) {
      var fileIdentifier = cls.fileIdentifier;
      if (fileIdentifier != null) {
        if (fileIdentifier.length != 4) {
          throw Exception('$name: file identifier must be 4 characters');
        }
        for (int i = 0; i < fileIdentifier.length; i++) {
          if (fileIdentifier.codeUnitAt(i) >= 256) {
            throw Exception(
                '$name: file identifier must be encodable as Latin-1');
          }
        }
      }
      Map<int, String> idsUsed = <int, String>{};
      for (idl_model.FieldDeclaration field in cls.allFields) {
        String fieldName = field.name;
        idl_model.FieldType type = field.type;
        if (type.isList) {
          if (_idl.classes.containsKey(type.typeName)) {
            // List of classes is ok
          } else if (_idl.enums.containsKey(type.typeName)) {
            // List of enums is ok
          } else if (type.typeName == 'bool') {
            // List of booleans is ok
          } else if (type.typeName == 'int') {
            // List of ints is ok
          } else if (type.typeName == 'double') {
            // List of doubles is ok
          } else if (type.typeName == 'String') {
            // List of strings is ok
          } else {
            throw Exception(
                '$name.$fieldName: illegal type (list of ${type.typeName})');
          }
        }
        if (idsUsed.containsKey(field.id)) {
          throw Exception('$name.$fieldName: id ${field.id} already used by'
              ' ${idsUsed[field.id]}');
        }
        idsUsed[field.id] = fieldName;
      }
      for (int i = 0; i < idsUsed.length; i++) {
        if (!idsUsed.containsKey(i)) {
          throw Exception('$name: no field uses id $i');
        }
      }
    });
  }

  /// Process the AST in [idlParsed] and store the resulting semantic model in
  /// [_idl].  Also perform some error checking.
  void extractIdl(CompilationUnit idlParsed) {
    for (CompilationUnitMember decl in idlParsed.declarations) {
      if (decl is ClassDeclaration) {
        bool isTopLevel = false;
        bool isDeprecated = false;
        String? fileIdentifier;
        String clsName = decl.name;
        for (Annotation annotation in decl.metadata) {
          var arguments = annotation.arguments;
          if (arguments != null &&
              annotation.name == 'TopLevel' &&
              annotation.constructorName == null) {
            isTopLevel = true;
            if (arguments.length == 1) {
              Expression arg = arguments[0];
              if (arg is StringLiteral) {
                fileIdentifier = arg.stringValue;
              } else {
                throw Exception(
                    'Class `$clsName`: TopLevel argument must be a string'
                    ' literal');
              }
            } else if (arguments.isNotEmpty) {
              throw Exception(
                  'Class `$clsName`: TopLevel requires 0 or 1 arguments');
            }
          } else if (arguments == null &&
              annotation.name == 'deprecated' &&
              annotation.constructorName == null) {
            isDeprecated = true;
          }
        }
        idl_model.ClassDeclaration cls = idl_model.ClassDeclaration(
          documentation: _getNodeDoc(decl),
          name: clsName,
          isTopLevel: isTopLevel,
          fileIdentifier: fileIdentifier,
          isDeprecated: isDeprecated,
        );
        _idl.classes[clsName] = cls;
        String expectedBase = 'base.SummaryClass';
        var superclass = decl.superclass;
        if (superclass == null || superclass.name != expectedBase) {
          throw Exception('Class `$clsName` needs to extend `$expectedBase`');
        }
        for (ClassMember classMember in decl.members) {
          if (classMember is MethodDeclaration && classMember.isGetter) {
            _addFieldForGetter(cls, classMember);
          } else if (classMember is ConstructorDeclaration &&
              classMember.name.endsWith('fromBuffer')) {
            // Ignore `fromBuffer` declarations; they simply forward to the
            // read functions generated by [_generateReadFunction].
          } else {
            throw Exception('Unexpected class member `$classMember`');
          }
        }
      } else if (decl is EnumDeclaration) {
        var doc = _getNodeDoc(decl);
        idl_model.EnumDeclaration enm =
            idl_model.EnumDeclaration(doc, decl.name);
        _idl.enums[enm.name] = enm;
        for (EnumConstantDeclaration constDecl in decl.constants) {
          var doc = _getNodeDoc(constDecl);
          enm.values.add(idl_model.EnumValueDeclaration(doc, constDecl.name));
        }
      } else {
        throw Exception('Unexpected declaration `$decl`');
      }
    }
  }

  /// Entry point to the code generator when generating the "format.fbs" file.
  void generateFlatBufferSchema() {
    outputHeader();
    _FlatBufferSchemaGenerator(_idl, _outBuffer).generate();
  }

  /// Entry point to the code generator when generating the "format.dart" file.
  void generateFormatCode() {
    outputHeader();
    out("// The generator sometimes generates unnecessary 'this' references.");
    out('// ignore_for_file: unnecessary_this');
    out();
    out('library analyzer.src.summary.format;');
    out();
    out("import 'dart:convert' as convert;");
    out("import 'dart:typed_data' as typed_data;");
    out();
    out("import 'package:analyzer/src/summary/api_signature.dart' as api_sig;");
    out("import 'package:analyzer/src/summary/flat_buffers.dart' as fb;");
    out("import 'package:analyzer/src/summary/idl.dart' as idl;");
    out();
    for (idl_model.EnumDeclaration enum_ in _idl.enums.values) {
      _EnumReaderGenerator(_idl, _outBuffer, enum_).generate();
      out();
    }
    for (idl_model.ClassDeclaration cls in _idl.classes.values) {
      if (!cls.isDeprecated) {
        _BuilderGenerator(_idl, _outBuffer, cls).generate();
        out();
      }
      if (cls.isTopLevel) {
        _ReaderGenerator(_idl, _outBuffer, cls).generateReaderFunction();
        out();
      }
      if (!cls.isDeprecated) {
        _ReaderGenerator(_idl, _outBuffer, cls).generateReader();
        out();
        _ImplGenerator(_idl, _outBuffer, cls).generate();
        out();
        _MixinGenerator(_idl, _outBuffer, cls).generate();
        out();
      }
    }
  }

  /// Add the string [s] to the output as a single line.
  void out([String s = '']) {
    _outBuffer.writeln(s);
  }

  void outputHeader() {
    out('// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file');
    out('// for details. All rights reserved. Use of this source code is governed by a');
    out('// BSD-style license that can be found in the LICENSE file.');
    out();
    out('// This file has been automatically generated.  Please do not edit it manually.');
    out('// To regenerate the file, use the SDK script');
    out('// "pkg/analyzer/tool/summary/generate.dart \$IDL_FILE_PATH",');
    out('// or "pkg/analyzer/tool/generate_files" for the analyzer package IDL/sources.');
    out();
  }

  void _addFieldForGetter(
    idl_model.ClassDeclaration cls,
    MethodDeclaration getter,
  ) {
    var desc = '${cls.name}.${getter.name}';

    var type = getter.returnType;
    if (type == null) {
      throw Exception('Getter needs a type: $desc');
    }

    var isList = false;
    if (type.name == 'List') {
      var typeArguments = type.typeArguments;
      if (typeArguments != null && typeArguments.length == 1) {
        isList = true;
        type = typeArguments[0];
      }
    }
    if (type.typeArguments != null) {
      throw Exception('Cannot handle type arguments in `$type`');
    }

    int? id;
    bool isDeprecated = false;
    bool isInformative = false;

    for (Annotation annotation in getter.metadata) {
      var arguments = annotation.arguments;
      if (annotation.name == 'Id') {
        if (id != null) {
          throw Exception('Duplicate @id annotation ($getter)');
        }
        if (arguments == null) {
          throw Exception('@Id must be passed an argument ($desc)');
        }
        if (arguments.length != 1) {
          throw Exception('@Id must be passed exactly one argument ($desc)');
        }

        var idExpression = arguments[0];
        if (idExpression is IntegerLiteral) {
          id = idExpression.value;
        } else {
          throw Exception(
            '@Id argument must be an integer literal ($desc)',
          );
        }
      } else if (annotation.name == 'deprecated') {
        if (arguments != null) {
          throw Exception('@deprecated does not take args ($desc)');
        }
        isDeprecated = true;
      } else if (annotation.name == 'informative') {
        isInformative = true;
      }
    }
    if (id == null) {
      throw Exception('Missing @id annotation ($desc)');
    }

    var fieldType = idl_model.FieldType(type.name, isList);

    cls.allFields.add(
      idl_model.FieldDeclaration(
        documentation: _getNodeDoc(getter),
        name: getter.name,
        type: fieldType,
        id: id,
        isDeprecated: isDeprecated,
        isInformative: isInformative,
      ),
    );
  }

  /// Return the documentation text of the given [node], or `null` if the [node]
  /// does not have a comment.  Each line is `\n` separated.
  String? _getNodeDoc(AnnotatedNode node) {
    var comment = node.documentationComment;
    if (comment != null && comment.isDocumentation) {
      if (comment.tokens.length == 1 &&
          comment.tokens.first.lexeme.startsWith('/*')) {
        Token token = comment.tokens.first;
        return token.lexeme.split('\n').map((String line) {
          line = line.trimLeft();
          if (line.startsWith('*')) line = ' $line';
          return line;
        }).join('\n');
      } else if (comment.tokens
          .every((token) => token.lexeme.startsWith('///'))) {
        return comment.tokens
            .map((token) => token.lexeme.trimLeft())
            .join('\n');
      }
    }
    return null;
  }
}

class _EnumReaderGenerator extends _BaseGenerator {
  final idl_model.EnumDeclaration enum_;

  _EnumReaderGenerator(super.idl, super.outBuffer, this.enum_);

  void generate() {
    String name = enum_.name;
    String readerName = '_${name}Reader';
    String count = '${idlPrefix(name)}.values.length';
    String def = '${idlPrefix(name)}.${enum_.values[0].name}';
    out('class $readerName extends fb.Reader<${idlPrefix(name)}> {');
    indent(() {
      out('const $readerName() : super();');
      out();
      out('@override');
      out('int get size => 1;');
      out();
      out('@override');
      out('${idlPrefix(name)} read(fb.BufferContext bc, int offset) {');
      indent(() {
        out('int index = const fb.Uint8Reader().read(bc, offset);');
        out('return index < $count ? ${idlPrefix(name)}.values[index] : $def;');
      });
      out('}');
    });
    out('}');
  }
}

class _FlatBufferSchemaGenerator extends _BaseGenerator {
  _FlatBufferSchemaGenerator(super.idl, super.outBuffer);

  void generate() {
    for (idl_model.EnumDeclaration enm in _idl.enums.values) {
      out();
      outDoc(enm.documentation);
      out('enum ${enm.name} : byte {');
      indent(() {
        for (int i = 0; i < enm.values.length; i++) {
          idl_model.EnumValueDeclaration value = enm.values[i];
          if (i != 0) {
            out();
          }
          String suffix = i < enm.values.length - 1 ? ',' : '';
          outDoc(value.documentation);
          out('${value.name}$suffix');
        }
      });
      out('}');
    }
    for (idl_model.ClassDeclaration cls in _idl.classes.values) {
      out();
      outDoc(cls.documentation);
      out('table ${cls.name} {');
      indent(() {
        for (int i = 0; i < cls.allFields.length; i++) {
          idl_model.FieldDeclaration field = cls.allFields[i];
          if (i != 0) {
            out();
          }
          outDoc(field.documentation);
          List<String> attributes = <String>['id: ${field.id}'];
          if (field.isDeprecated) {
            attributes.add('deprecated');
          }
          String attrText = attributes.join(', ');
          out('${field.name}:${_fbsType(field.type)} ($attrText);');
        }
      });
      out('}');
    }
    out();
    // Standard flatbuffers only support one root type.  We support multiple
    // root types.  For now work around this by forcing PackageBundle to be the
    // root type.  TODO(paulberry): come up with a better solution.
    final rootType = _idl.classes['AnalysisDriverResolvedUnit']!;
    out('root_type ${rootType.name};');
    var rootFileIdentifier = rootType.fileIdentifier;
    if (rootFileIdentifier != null) {
      out();
      out('file_identifier ${quoted(rootFileIdentifier)};');
    }
  }

  /// Generate a string representing the FlatBuffer schema type which should be
  /// used to represent [type].
  String _fbsType(idl_model.FieldType type) {
    String typeStr;
    switch (type.typeName) {
      case 'bool':
        typeStr = 'bool';
        break;
      case 'double':
        typeStr = 'double';
        break;
      case 'int':
        typeStr = 'uint';
        break;
      case 'String':
        typeStr = 'string';
        break;
      default:
        typeStr = type.typeName;
        break;
    }
    if (type.isList) {
      // FlatBuffers don't natively support a packed list of booleans, so we
      // treat it as a list of unsigned bytes, which is a compatible data
      // structure.
      if (typeStr == 'bool') {
        typeStr = 'ubyte';
      }
      return '[$typeStr]';
    } else {
      return typeStr;
    }
  }
}

class _ImplGenerator extends _BaseGenerator {
  final idl_model.ClassDeclaration cls;

  _ImplGenerator(super.idl, super.outBuffer, this.cls);

  void generate() {
    String name = cls.name;
    String implName = '_${name}Impl';
    String mixinName = '_${name}Mixin';
    out('class $implName extends Object with $mixinName'
        ' implements ${idlPrefix(name)} {');
    indent(() {
      out('final fb.BufferContext _bc;');
      out('final int _bcOffset;');
      out();
      out('$implName(this._bc, this._bcOffset);');
      out();
      // Write cache fields.
      for (idl_model.FieldDeclaration field in cls.fields) {
        String returnType = _dartType(field.type);
        String fieldName = field.name;
        out('$returnType? _$fieldName;');
      }
      // Write getters.
      for (idl_model.FieldDeclaration field in cls.allFields) {
        int index = field.id;
        String fieldName = field.name;
        idl_model.FieldType type = field.type;
        String typeName = type.typeName;
        // Prepare "readCode" + "def"
        String readCode;
        String? def = defaultValue(type, false);
        if (type.isList) {
          if (typeName == 'bool') {
            readCode = 'const fb.BoolListReader()';
          } else if (typeName == 'int') {
            readCode = 'const fb.Uint32ListReader()';
          } else if (typeName == 'double') {
            readCode = 'const fb.Float64ListReader()';
          } else if (typeName == 'String') {
            String itemCode = 'fb.StringReader()';
            readCode = 'const fb.ListReader<String>($itemCode)';
          } else if (_idl.classes.containsKey(typeName)) {
            String itemCode = '_${typeName}Reader()';
            readCode = 'const fb.ListReader<${idlPrefix(typeName)}>($itemCode)';
          } else if (_idl.enums.containsKey(typeName)) {
            String itemCode = '_${typeName}Reader()';
            readCode = 'const fb.ListReader<${idlPrefix(typeName)}>($itemCode)';
          } else {
            throw Exception('$name.$fieldName: illegal type ($type)');
          }
        } else if (typeName == 'bool') {
          readCode = 'const fb.BoolReader()';
        } else if (typeName == 'double') {
          readCode = 'const fb.Float64Reader()';
        } else if (typeName == 'int') {
          readCode = 'const fb.Uint32Reader()';
        } else if (typeName == 'String') {
          readCode = 'const fb.StringReader()';
        } else if (_idl.classes.containsKey(typeName)) {
          readCode = 'const _${typeName}Reader()';
        } else if (_idl.enums.containsKey(typeName)) {
          readCode = 'const _${typeName}Reader()';
        } else {
          throw Exception('$name.$fieldName: illegal type ($type)');
        }
        // Write the getter implementation.
        out();
        String returnType = _dartType(type);
        if (field.isDeprecated) {
          out('@override');
          out('Null get $fieldName => ${_BaseGenerator._throwDeprecated};');
        } else {
          out('@override');
          if (_isNullable(type)) {
            out('$returnType? get $fieldName {');
          } else {
            out('$returnType get $fieldName {');
          }
          indent(() {
            String readExpr;
            if (_isNullable(type)) {
              readExpr = '$readCode.vTableGetOrNull(_bc, _bcOffset, $index)';
            } else {
              readExpr = '$readCode.vTableGet(_bc, _bcOffset, $index, $def)';
            }
            out('return _$fieldName ??= $readExpr;');
          });
          out('}');
        }
      }
    });
    out('}');
  }

  /// Generate a string representing the Dart type which should be used to
  /// represent [type] when deserialized.
  String _dartType(idl_model.FieldType type) {
    String baseType = idlPrefix(type.typeName);
    if (type.isList) {
      return 'List<$baseType>';
    } else {
      return baseType;
    }
  }
}

class _MixinGenerator extends _BaseGenerator {
  final idl_model.ClassDeclaration cls;

  _MixinGenerator(super.idl, super.outBuffer, this.cls);

  void generate() {
    String name = cls.name;
    String mixinName = '_${name}Mixin';
    out('abstract class $mixinName implements ${idlPrefix(name)} {');
    indent(() {
      String jsonCondition(idl_model.FieldType type, String name) {
        if (type.isList) {
          return '$name.isNotEmpty';
        } else {
          return '$name != ${defaultValue(type, false)}';
        }
      }

      String jsonStore(
          idl_model.FieldType type, String name, String localName) {
        _StringToString? convertItem;
        if (_idl.classes.containsKey(type.typeName)) {
          convertItem = (String name) => '$name.toJson()';
        } else if (_idl.enums.containsKey(type.typeName)) {
          // TODO(paulberry): it would be better to generate a const list of
          // strings so that we don't have to do this kludge.
          convertItem = (String name) => "$name.toString().split('.')[1]";
        } else if (type.typeName == 'double') {
          convertItem =
              (String name) => '$name.isFinite ? $name : $name.toString()';
        }
        String convertField;
        if (convertItem == null) {
          convertField = localName;
        } else if (type.isList) {
          convertField = '$localName.map((value) =>'
              ' ${convertItem('value')}).toList()';
        } else {
          convertField = convertItem(localName);
        }
        return 'result[${quoted(name)}] = $convertField';
      }

      void writeConditionalStatement(String condition, String statement) {
        out('if ($condition) {');
        out('  $statement;');
        out('}');
      }

      // Write toJson().
      out('@override');
      out('Map<String, Object> toJson() {');
      indent(() {
        out('Map<String, Object> result = <String, Object>{};');

        indent(() {
          for (idl_model.FieldDeclaration field in cls.fields) {
            var localName = 'local_${field.name}';
            out('var $localName = ${field.name};');
            String condition = jsonCondition(field.type, localName);
            String storeField = jsonStore(field.type, field.name, localName);
            writeConditionalStatement(condition, storeField);
          }
        });

        out('return result;');
      });
      out('}');
      out();

      // Write toMap().
      out('@override');
      out('Map<String, Object?> toMap() => {');
      indent(() {
        for (idl_model.FieldDeclaration field in cls.fields) {
          String fieldName = field.name;
          out('${quoted(fieldName)}: $fieldName,');
        }
      });
      out('};');
      out();
      // Write toString().
      out('@override');
      out('String toString() => convert.json.encode(toJson());');
    });
    out('}');
  }
}

class _ReaderGenerator extends _BaseGenerator {
  final idl_model.ClassDeclaration cls;

  _ReaderGenerator(super.idl, super.outBuffer, this.cls);

  void generateReader() {
    String name = cls.name;
    String readerName = '_${name}Reader';
    String implName = '_${name}Impl';
    out('class $readerName extends fb.TableReader<$implName> {');
    indent(() {
      out('const $readerName();');
      out();
      out('@override');
      out('$implName createObject(fb.BufferContext bc, int offset) => $implName(bc, offset);');
    });
    out('}');
  }

  void generateReaderFunction() {
    String name = cls.name;
    out('${idlPrefix(name)} read$name(List<int> buffer) {');
    indent(() {
      out('fb.BufferContext rootRef = fb.BufferContext.fromBytes(buffer);');
      out('return const _${name}Reader().read(rootRef, 0);');
    });
    out('}');
  }
}
