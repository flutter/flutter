// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../protoc.dart' show FileGenerator;
import 'code_generator.dart';
import 'options.dart';

/// Resolves all cross-references in a set of proto files.
void link(GenerationOptions? options, Iterable<FileGenerator> files) {
  var ctx = GenerationContext(options);

  // Register the targets of cross-references.
  for (var f in files) {
    ctx.registerProtoFile(f);

    for (var m in f.messageGenerators) {
      m.register(ctx);
    }
    for (var e in f.enumGenerators) {
      e.register(ctx);
    }
  }

  for (var f in files) {
    f.resolve(ctx);
  }

  // Resolve service generators last.
  // (They depend on all messages being resolved.)
  for (var f in files) {
    for (var s in f.serviceGenerators) {
      s.resolve(ctx);
    }
    for (var s in f.grpcGenerators) {
      s.resolve(ctx);
    }
  }
}

class GenerationContext {
  final GenerationOptions? options;

  /// The files available for import.
  final Map<String, FileGenerator> _files = <String, FileGenerator>{};

  /// The types available to proto fields.
  final Map<String, ProtobufContainer> _typeRegistry =
      <String, ProtobufContainer>{};

  GenerationContext(this.options);

  /// Makes info about a .pb.dart file available for reference,
  /// using the filename given to us by protoc.
  void registerProtoFile(FileGenerator f) {
    _files[f.descriptor.name] = f;
  }

  /// Makes a message, group, or enum available for reference.
  void registerFieldType(ProtobufContainer type) {
    // Register the name with a leading '.' to be compatible with input from
    // protoc.
    _typeRegistry[type.dottedName] = type;
  }

  /// Returns info about a .pb.dart being imported,
  /// based on the filename given to us by protoc.
  FileGenerator? getImportedProtoFile(String name) => _files[name];

  /// Returns info about the type of a message, group, or enum field,
  /// based on the fully qualified name given to us by protoc.
  ProtobufContainer? getFieldType(String name) => _typeRegistry[name];
}
