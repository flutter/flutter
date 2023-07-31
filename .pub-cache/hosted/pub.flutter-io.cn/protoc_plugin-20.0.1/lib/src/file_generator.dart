// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../protoc.dart';

final _dartIdentifier = RegExp(r'^\w+$');
final _formatter = DartFormatter();
const String _convertImportPrefix = r'$convert';

const String _fixnumImportPrefix = r'$fixnum';
const String _typedDataImportPrefix = r'$typed_data';
const String _protobufImport =
    "import 'package:protobuf/protobuf.dart' as $protobufImportPrefix;";
const String _asyncImport = "import 'dart:async' as $asyncImportPrefix;";
const String _coreImport = "import 'dart:core' as $coreImportPrefix;";
const String _typedDataImport =
    "import 'dart:typed_data' as $_typedDataImportPrefix;";
const String _convertImport = "import 'dart:convert' as $_convertImportPrefix;";

const String _grpcImport =
    "import 'package:grpc/service_api.dart' as $grpcImportPrefix;";

/// Generates code that will evaluate to the empty string if
/// `const bool.fromEnvironment(envName)` is `true` and evaluate to [value]
/// otherwise.
String configurationDependent(String envName, String value) {
  return 'const $coreImportPrefix.bool.fromEnvironment(${quoted(envName)})'
      ' ? \'\' '
      ': $value';
}

enum ProtoSyntax {
  proto2,
  proto3,
}

/// Generates the Dart output files for one .proto input file.
///
/// Outputs include .pb.dart, pbenum.dart, and .pbjson.dart.
class FileGenerator extends ProtobufContainer {
  /// Reads and the declared mixins in the file, keyed by name.
  ///
  /// Performs some basic validation on declared mixins, e.g. whether names
  /// are valid dart identifiers and whether there are cycles in the `parent`
  /// hierarchy.
  /// Does not check for existence of import files or classes.
  static Map<String, PbMixin> _getDeclaredMixins(FileDescriptorProto desc) {
    String mixinError(String error) =>
        'Option "mixins" in ${desc.name}: $error';

    if (!desc.hasOptions() ||
        !desc.options.hasExtension(Dart_options.imports)) {
      return <String, PbMixin>{};
    }
    var dartMixins = <String, DartMixin>{};
    final importedMixins =
        desc.options.getExtension(Dart_options.imports) as Imports;
    for (var mixin in importedMixins.mixins) {
      if (dartMixins.containsKey(mixin.name)) {
        throw mixinError('Duplicate mixin name: "${mixin.name}"');
      }
      if (!mixin.name.startsWith(_dartIdentifier)) {
        throw mixinError(
            '"${mixin.name}" is not a valid dart class identifier');
      }
      if (mixin.hasParent() && !mixin.parent.startsWith(_dartIdentifier)) {
        throw mixinError('Mixin parent "${mixin.parent}" of "${mixin.name}" is '
            'not a valid dart class identifier');
      }
      dartMixins[mixin.name] = mixin;
    }

    // Detect cycles and unknown parents.
    for (var mixin in dartMixins.values) {
      if (!mixin.hasParent()) continue;
      var currentMixin = mixin;
      var parentChain = <String>[];
      while (currentMixin.hasParent()) {
        var parentName = currentMixin.parent;

        var declaredMixin = dartMixins.containsKey(parentName);
        var internalMixin = !declaredMixin && findMixin(parentName) != null;

        if (internalMixin) break; // No further validation of parent chain.

        if (!declaredMixin) {
          throw mixinError('Unknown mixin parent "${mixin.parent}" of '
              '"${currentMixin.name}"');
        }

        if (parentChain.contains(parentName)) {
          var cycle = parentChain.join('->') + '->$parentName';
          throw mixinError('Cycle in parent chain: $cycle');
        }
        parentChain.add(parentName);
        currentMixin = dartMixins[parentName]!;
      }
    }

    // Turn DartMixins into PbMixins.
    final pbMixins = <String, PbMixin>{};
    PbMixin? resolveMixin(String name) {
      if (pbMixins.containsKey(name)) return pbMixins[name];
      if (dartMixins.containsKey(name)) {
        var dartMixin = dartMixins[name]!;
        var pbMixin = PbMixin(dartMixin.name,
            importFrom: dartMixin.importFrom,
            parent: resolveMixin(dartMixin.parent));
        pbMixins[name] = pbMixin;
        return pbMixin;
      }
      return findMixin(name);
    }

    for (var mixin in dartMixins.values) {
      resolveMixin(mixin.name);
    }
    return pbMixins;
  }

  final FileDescriptorProto descriptor;
  final GenerationOptions options;

  // The relative path used to import the .proto file, as a URI.
  final Uri protoFileUri;

  final enumGenerators = <EnumGenerator>[];
  final messageGenerators = <MessageGenerator>[];
  final extensionGenerators = <ExtensionGenerator>[];
  final clientApiGenerators = <ClientApiGenerator>[];
  final serviceGenerators = <ServiceGenerator>[];
  final grpcGenerators = <GrpcServiceGenerator>[];

  /// Used to avoid collisions after names have been mangled to match the Dart
  /// style.
  final Set<String> usedTopLevelNames = <String>{}
    ..addAll(forbiddenTopLevelNames);

  /// Used to avoid collisions in the service file after names have been mangled
  /// to match the dart style.
  final Set<String> usedTopLevelServiceNames = <String>{}
    ..addAll(forbiddenTopLevelNames);

  final Set<String> usedExtensionNames = <String>{}
    ..addAll(forbiddenExtensionNames);

  /// True if cross-references have been resolved.
  bool _linked = false;

  final ProtoSyntax syntax;

  FileGenerator(this.descriptor, this.options)
      : protoFileUri = Uri.file(descriptor.name),
        syntax = descriptor.syntax == 'proto3'
            ? ProtoSyntax.proto3
            : ProtoSyntax.proto2 {
    if (protoFileUri.isAbsolute) {
      // protoc should never generate an import with an absolute path.
      throw 'FAILURE: Import with absolute path is not supported';
    }

    var declaredMixins = _getDeclaredMixins(descriptor);
    var defaultMixinName =
        descriptor.options.getExtension(Dart_options.defaultMixin) as String? ??
            '';
    var defaultMixin =
        declaredMixins[defaultMixinName] ?? findMixin(defaultMixinName);
    if (defaultMixin == null && defaultMixinName.isNotEmpty) {
      throw ('Option default_mixin on file ${descriptor.name}: Unknown mixin '
          '$defaultMixinName');
    }

    // Load and register all enum and message types.
    for (var i = 0; i < descriptor.enumType.length; i++) {
      enumGenerators.add(EnumGenerator.topLevel(
          descriptor.enumType[i], this, usedTopLevelNames, i));
    }
    for (var i = 0; i < descriptor.messageType.length; i++) {
      messageGenerators.add(MessageGenerator.topLevel(descriptor.messageType[i],
          this, declaredMixins, defaultMixin, usedTopLevelNames, i));
    }
    for (var i = 0; i < descriptor.extension.length; i++) {
      extensionGenerators.add(ExtensionGenerator.topLevel(
          descriptor.extension[i], this, usedExtensionNames, i));
    }
    for (var service in descriptor.service) {
      if (options.useGrpc) {
        grpcGenerators.add(GrpcServiceGenerator(service, this));
      } else {
        var serviceGen =
            ServiceGenerator(service, this, usedTopLevelServiceNames);
        serviceGenerators.add(serviceGen);
        clientApiGenerators
            .add(ClientApiGenerator(serviceGen, usedTopLevelNames));
      }
    }
  }

  /// Creates the fields in each message.
  /// Resolves field types and extension targets using the supplied context.
  void resolve(GenerationContext ctx) {
    if (_linked) throw StateError('cross references already resolved');

    for (var m in messageGenerators) {
      m.resolve(ctx);
    }
    for (var x in extensionGenerators) {
      x.resolve(ctx);
    }

    _linked = true;
  }

  @override
  String get package => descriptor.package;

  @override
  String get classname => '';

  @override
  String get fullName => descriptor.package;

  @override
  FileGenerator get fileGen => this;

  @override
  ProtobufContainer? get parent => null;

  @override
  List<int> get fieldPath => [];

  /// Generates all the Dart files for this .proto file.
  List<CodeGeneratorResponse_File> generateFiles(OutputConfiguration config) {
    if (!_linked) throw StateError('not linked');

    CodeGeneratorResponse_File makeFile(String extension, String content) {
      var protoUrl = Uri.file(descriptor.name);
      var dartUrl = config.outputPathFor(protoUrl, extension);
      return CodeGeneratorResponse_File()
        ..name = dartUrl.path
        ..content = content;
    }

    var mainWriter = generateMainFile(config);
    var enumWriter = generateEnumFile(config);

    final files = [
      makeFile('.pb.dart', mainWriter.toString()),
      makeFile('.pbenum.dart', enumWriter.toString()),
      makeFile('.pbjson.dart', generateJsonFile(config)),
    ];

    if (options.generateMetadata) {
      files.addAll([
        makeFile('.pb.dart.meta',
            mainWriter.sourceLocationInfo.writeToJson().toString()),
        makeFile('.pbenum.dart.meta',
            enumWriter.sourceLocationInfo.writeToJson().toString())
      ]);
    }
    if (options.useGrpc) {
      if (grpcGenerators.isNotEmpty) {
        files.add(makeFile('.pbgrpc.dart', generateGrpcFile(config)));
      }
    } else {
      files.add(makeFile('.pbserver.dart', generateServerFile(config)));
    }
    return files;
  }

  /// Creates an IndentingWriter with metadata generation enabled or disabled.
  IndentingWriter makeWriter() => IndentingWriter(
      filename: options.generateMetadata ? descriptor.name : null);

  /// Returns the contents of the .pb.dart file for this .proto file.
  IndentingWriter generateMainFile(
      [OutputConfiguration config = const DefaultOutputConfiguration()]) {
    if (!_linked) throw StateError('not linked');
    var out = makeWriter();

    writeMainHeader(out, config);

    // Generate code.
    for (var m in messageGenerators) {
      m.generate(out);
    }

    // Generate code for extensions defined at top-level using a class
    // name derived from the file name.
    if (extensionGenerators.isNotEmpty) {
      // TODO(antonm): do not generate a class.
      var className = extensionClassName(descriptor, usedTopLevelNames);
      out.addBlock('class $className {', '}\n', () {
        for (var x in extensionGenerators) {
          x.generate(out);
        }
        out.println(
            'static void registerAllExtensions($protobufImportPrefix.ExtensionRegistry '
            'registry) {');
        for (var x in extensionGenerators) {
          out.println('  registry.add(${x.name});');
        }
        out.println('}');
      });
    }

    for (var c in clientApiGenerators) {
      c.generate(out);
    }
    return out;
  }

  /// Writes the header and imports for the .pb.dart file.
  void writeMainHeader(IndentingWriter out,
      [OutputConfiguration config = const DefaultOutputConfiguration()]) {
    _writeHeading(out);

    // We only add the dart:async import if there are generic client API
    // generators for services in the FileDescriptorProto.
    if (clientApiGenerators.isNotEmpty) {
      out.println(_asyncImport);
    }

    out.println(_coreImport);
    out.println();

    if (_needsFixnumImport) {
      out.println(
          "import 'package:fixnum/fixnum.dart' as $_fixnumImportPrefix;");
    }

    if (_needsProtobufImport) {
      out.println(_protobufImport);
      out.println();
    }

    final mixinImports = findMixinImports();
    for (var libraryUri in mixinImports) {
      out.println("import '$libraryUri' as $mixinImportPrefix;");
    }
    if (mixinImports.isNotEmpty) out.println();

    // Import the .pb.dart files we depend on.
    var imports = Set<FileGenerator>.identity();
    var enumImports = Set<FileGenerator>.identity();
    _findProtosToImport(imports, enumImports);

    for (var target in imports) {
      _writeImport(out, config, target, '.pb.dart');
    }
    if (imports.isNotEmpty) out.println();

    for (var target in enumImports) {
      _writeImport(out, config, target, '.pbenum.dart');
    }
    if (enumImports.isNotEmpty) out.println();

    for (var publicDependency in descriptor.publicDependency) {
      _writeExport(out, config,
          Uri.file(descriptor.dependency[publicDependency]), '.pb.dart');
    }

    // Export enums in main file for backward compatibility.
    if (enumCount > 0) {
      var resolvedImport =
          config.resolveImport(protoFileUri, protoFileUri, '.pbenum.dart');
      out.println("export '$resolvedImport';");
      out.println();
    }
  }

  bool get _needsFixnumImport {
    for (var m in messageGenerators) {
      if (m.needsFixnumImport) return true;
    }
    for (var x in extensionGenerators) {
      if (x.needsFixnumImport) return true;
    }
    return false;
  }

  bool get _needsProtobufImport =>
      messageGenerators.isNotEmpty ||
      extensionGenerators.isNotEmpty ||
      clientApiGenerators.isNotEmpty;

  /// Returns the generator for each .pb.dart file we need to import.
  void _findProtosToImport(
      Set<FileGenerator> imports, Set<FileGenerator> enumImports) {
    for (var m in messageGenerators) {
      m.addImportsTo(imports, enumImports);
    }
    for (var x in extensionGenerators) {
      x.addImportsTo(imports, enumImports);
    }
    // Add imports needed for client-side services.
    for (var x in serviceGenerators) {
      x.addImportsTo(imports);
    }
    // Don't need to import self. (But we may need to import the enums.)
    imports.remove(this);
  }

  /// Returns a sorted list of imports needed to support all mixins.
  List<String> findMixinImports() {
    var mixins = <PbMixin>{};
    for (var m in messageGenerators) {
      m.addMixinsTo(mixins);
    }

    return mixins
        .map((mixin) => mixin.importFrom)
        .toSet()
        .toList(growable: false)
      ..sort();
  }

  /// Returns the contents of the .pbenum.dart file for this .proto file.
  IndentingWriter generateEnumFile(
      [OutputConfiguration config = const DefaultOutputConfiguration()]) {
    if (!_linked) throw StateError('not linked');

    var out = makeWriter();
    _writeHeading(out);

    if (enumCount > 0) {
      // Make sure any other symbols in dart:core don't cause name conflicts
      // with enums that have the same name.
      out.println('// ignore_for_file: UNDEFINED_SHOWN_NAME');
      out.println(_coreImport);
      out.println(_protobufImport);
      out.println();
    }

    for (var e in enumGenerators) {
      e.generate(out);
    }

    for (var m in messageGenerators) {
      m.generateEnums(out);
    }

    return out;
  }

  /// Returns the number of enum types generated in the .pbenum.dart file.
  int get enumCount {
    var count = enumGenerators.length;
    for (var m in messageGenerators) {
      count += m.enumCount;
    }
    return count;
  }

  /// Returns the contents of the .pbserver.dart file for this .proto file.
  String generateServerFile(
      [OutputConfiguration config = const DefaultOutputConfiguration()]) {
    if (!_linked) throw StateError('not linked');
    var out = makeWriter();
    _writeHeading(out,
        extraIgnores: {'deprecated_member_use_from_same_package'});

    if (serviceGenerators.isNotEmpty) {
      out.println(_asyncImport);
      out.println();
      out.println(_protobufImport);
      out.println();
      out.println(_coreImport);
    }

    // Import .pb.dart files needed for requests and responses.
    var imports = <FileGenerator>{};
    for (var x in serviceGenerators) {
      x.addImportsTo(imports);
    }
    for (var target in imports) {
      _writeImport(out, config, target, '.pb.dart');
    }

    // Import .pbjson.dart file needed for $json and $messageJson.
    if (serviceGenerators.isNotEmpty) {
      _writeImport(out, config, this, '.pbjson.dart');
      out.println();
    }

    var resolvedImport =
        config.resolveImport(protoFileUri, protoFileUri, '.pb.dart');
    out.println("export '$resolvedImport';");
    out.println();

    for (var s in serviceGenerators) {
      s.generate(out);
    }

    return out.toString();
  }

  /// Returns the contents of the .pbgrpc.dart file for this .proto file.
  String generateGrpcFile(
      [OutputConfiguration config = const DefaultOutputConfiguration()]) {
    if (!_linked) throw StateError('not linked');
    var out = makeWriter();
    _writeHeading(out);

    out.println(_asyncImport);
    out.println();
    out.println(_coreImport);
    out.println();
    out.println(_grpcImport);

    // Import .pb.dart files needed for requests and responses.
    var imports = <FileGenerator>{};
    for (var generator in grpcGenerators) {
      generator.addImportsTo(imports);
    }
    for (var target in imports) {
      _writeImport(out, config, target, '.pb.dart');
    }

    var resolvedImport =
        config.resolveImport(protoFileUri, protoFileUri, '.pb.dart');
    out.println("export '$resolvedImport';");
    out.println();

    for (var generator in grpcGenerators) {
      generator.generate(out);
    }

    return _formatter.format(out.toString());
  }

  void writeBinaryDescriptor(IndentingWriter out, String identifierName,
      String name, GeneratedMessage descriptor) {
    var descriptorText = base64Encode(descriptor.writeToBuffer());
    out.println('/// Descriptor for `$name`. Decode as a '
        '`${descriptor.info_.qualifiedMessageName}`.');
    out.println('final $_typedDataImportPrefix.Uint8List '
        '$identifierName = '
        '$_convertImportPrefix.base64Decode(\'$descriptorText\');');
  }

  /// Returns the contents of the .pbjson.dart file for this .proto file.
  String generateJsonFile(
      [OutputConfiguration config = const DefaultOutputConfiguration()]) {
    if (!_linked) throw StateError('not linked');
    var out = makeWriter();
    _writeHeading(out,
        extraIgnores: {'deprecated_member_use_from_same_package'});

    out.println(_coreImport);
    out.println(_convertImport);
    out.println(_typedDataImport);
    // Import the .pbjson.dart files we depend on.
    var imports = _findJsonProtosToImport();
    for (var target in imports) {
      _writeImport(out, config, target, '.pbjson.dart');
    }
    if (imports.isNotEmpty) out.println();

    for (var e in enumGenerators) {
      e.generateConstants(out);
      writeBinaryDescriptor(
          out, e.binaryDescriptorName, e._descriptor.name, e._descriptor);
    }
    for (var m in messageGenerators) {
      m.generateConstants(out);
      writeBinaryDescriptor(
          out, m.binaryDescriptorName, m._descriptor.name, m._descriptor);
    }
    for (var s in serviceGenerators) {
      s.generateConstants(out);
      writeBinaryDescriptor(
          out, s.binaryDescriptorName, s._descriptor.name, s._descriptor);
    }

    return out.toString();
  }

  /// Returns the generator for each .pbjson.dart file the generated
  /// .pbjson.dart needs to import.
  Set<FileGenerator> _findJsonProtosToImport() {
    var imports = Set<FileGenerator>.identity();
    for (var m in messageGenerators) {
      m.addConstantImportsTo(imports);
    }
    for (var x in extensionGenerators) {
      x.addConstantImportsTo(imports);
    }
    for (var x in serviceGenerators) {
      x.addConstantImportsTo(imports);
    }
    imports.remove(this); // Don't need to import self.
    return imports;
  }

  /// Writes the header at the top of the dart file.
  void _writeHeading(
    IndentingWriter out, {
    Set<String> extraIgnores = const <String>{},
  }) {
    final ignores = ({
      ..._ignores,
      ...extraIgnores,
    }).toList()
      ..sort();

    out.println('''
///
//  Generated code. Do not modify.
//  source: ${descriptor.name}
//
// @dart = 2.12
// ignore_for_file: ${ignores.join(',')}
''');
  }

  /// Writes an import of a .dart file corresponding to a .proto file.
  /// (Possibly the same .proto file.)
  void _writeImport(IndentingWriter out, OutputConfiguration config,
      FileGenerator target, String extension) {
    var resolvedImport =
        config.resolveImport(target.protoFileUri, protoFileUri, extension);
    out.print("import '$resolvedImport'");

    // .pb.dart files should always be prefixed--the protoFileUri check
    // will evaluate to true not just for the main .pb.dart file based off
    // the proto file, but also for the .pbserver.dart, .pbgrpc.dart files.
    if ((extension == '.pb.dart') || protoFileUri != target.protoFileUri) {
      out.print(' as ${target.fileImportPrefix}');
    }
    out.println(';');
  }

  /// Writes an export of a pb.dart file corresponding to a .proto file.
  /// (Possibly the same .proto file.)
  void _writeExport(IndentingWriter out, OutputConfiguration config, Uri target,
      String extension) {
    var resolvedImport = config.resolveImport(target, protoFileUri, extension);
    out.println("export '$resolvedImport';");
  }
}

const _ignores = {
  'annotate_overrides',
  'directives_ordering',
  'camel_case_types',
  'constant_identifier_names',
  'library_prefixes',
  'non_constant_identifier_names',
  'prefer_final_fields',
  'return_of_invalid_type',
  'unnecessary_const',
  'unnecessary_import',
  'unnecessary_this',
  'unused_import',
  'unused_shown_name',
};
