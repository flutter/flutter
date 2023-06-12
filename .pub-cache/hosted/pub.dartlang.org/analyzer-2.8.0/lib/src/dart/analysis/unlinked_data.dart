// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';

/// Unlinked information about a compilation unit.
class AnalysisDriverUnlinkedUnit {
  /// Set of class member names defined by the unit.
  final Set<String> definedClassMemberNames;

  /// Set of top-level names defined by the unit.
  final Set<String> definedTopLevelNames;

  /// Set of external names referenced by the unit.
  final Set<String> referencedNames;

  /// Set of names which are used in `extends`, `with` or `implements` clauses
  /// in the file. Import prefixes and type arguments are not included.
  final Set<String> subtypedNames;

  /// Unlinked information for the unit.
  final UnlinkedUnit unit;

  AnalysisDriverUnlinkedUnit({
    required this.definedClassMemberNames,
    required this.definedTopLevelNames,
    required this.referencedNames,
    required this.subtypedNames,
    required this.unit,
  });

  factory AnalysisDriverUnlinkedUnit.fromBytes(Uint8List bytes) {
    return AnalysisDriverUnlinkedUnit.read(
      SummaryDataReader(bytes),
    );
  }

  factory AnalysisDriverUnlinkedUnit.read(SummaryDataReader reader) {
    return AnalysisDriverUnlinkedUnit(
      definedClassMemberNames: reader.readStringUtf8Set(),
      definedTopLevelNames: reader.readStringUtf8Set(),
      referencedNames: reader.readStringUtf8Set(),
      subtypedNames: reader.readStringUtf8Set(),
      unit: UnlinkedUnit.read(reader),
    );
  }

  Uint8List toBytes() {
    var byteSink = ByteSink();
    var sink = BufferedSink(byteSink);
    write(sink);
    return sink.flushAndTake();
  }

  void write(BufferedSink sink) {
    sink.writeStringUtf8Iterable(definedClassMemberNames);
    sink.writeStringUtf8Iterable(definedTopLevelNames);
    sink.writeStringUtf8Iterable(referencedNames);
    sink.writeStringUtf8Iterable(subtypedNames);
    unit.write(sink);
  }
}

/// Unlinked information about a namespace directive.
class UnlinkedNamespaceDirective {
  /// The configurations that control which library will actually be used.
  final List<UnlinkedNamespaceDirectiveConfiguration> configurations;

  /// The URI referenced by this directive, nad used by default when none
  /// of the [configurations] matches.
  final String uri;

  UnlinkedNamespaceDirective({
    required this.configurations,
    required this.uri,
  });

  factory UnlinkedNamespaceDirective.read(SummaryDataReader reader) {
    return UnlinkedNamespaceDirective(
      configurations: reader.readTypedList(
        () => UnlinkedNamespaceDirectiveConfiguration.read(reader),
      ),
      uri: reader.readStringUtf8(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeList<UnlinkedNamespaceDirectiveConfiguration>(
      configurations,
      (x) {
        x.write(sink);
      },
    );
    sink.writeStringUtf8(uri);
  }
}

/// Unlinked information about a namespace directive configuration.
class UnlinkedNamespaceDirectiveConfiguration {
  /// The name of the declared variable used in the condition.
  final String name;

  /// The URI to be used if the condition is true.
  final String uri;

  /// The value to which the value of the declared variable will be compared,
  /// or the empty string if the condition does not include an equality test.
  final String value;

  UnlinkedNamespaceDirectiveConfiguration({
    required this.name,
    required this.uri,
    required this.value,
  });

  factory UnlinkedNamespaceDirectiveConfiguration.read(
    SummaryDataReader reader,
  ) {
    return UnlinkedNamespaceDirectiveConfiguration(
      name: reader.readStringUtf8(),
      uri: reader.readStringUtf8(),
      value: reader.readStringUtf8(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeStringUtf8(name);
    sink.writeStringUtf8(uri);
    sink.writeStringUtf8(value);
  }
}

/// Unlinked information about a compilation unit.
class UnlinkedUnit {
  /// The MD5 hash signature of the API portion of this unit. It depends on all
  /// tokens that might affect APIs of declarations in the unit.
  /// TODO(scheglov) Do we need it?
  final Uint8List apiSignature;

  /// URIs of `export` directives.
  final List<UnlinkedNamespaceDirective> exports;

  /// Is `true` if the unit contains a `library` directive.
  final bool hasLibraryDirective;

  /// Is `true` if the unit contains a `part of` directive.
  final bool hasPartOfDirective;

  /// URIs of `import` directives.
  final List<UnlinkedNamespaceDirective> imports;

  /// Encoded informative data.
  final Uint8List informativeBytes;

  /// Offsets of the first character of each line in the source code.
  final Uint32List lineStarts;

  /// The library name of the `part of my.name;` directive.
  final String? partOfName;

  /// URI of the `part of 'uri';` directive.
  final String? partOfUri;

  /// URIs of `part` directives.
  final List<String> parts;

  UnlinkedUnit({
    required this.apiSignature,
    required this.exports,
    required this.hasLibraryDirective,
    required this.hasPartOfDirective,
    required this.imports,
    required this.informativeBytes,
    required this.lineStarts,
    required this.partOfName,
    required this.partOfUri,
    required this.parts,
  });

  factory UnlinkedUnit.read(SummaryDataReader reader) {
    return UnlinkedUnit(
      apiSignature: reader.readUint8List(),
      exports: reader.readTypedList(
        () => UnlinkedNamespaceDirective.read(reader),
      ),
      hasLibraryDirective: reader.readBool(),
      hasPartOfDirective: reader.readBool(),
      imports: reader.readTypedList(
        () => UnlinkedNamespaceDirective.read(reader),
      ),
      informativeBytes: reader.readUint8List(),
      lineStarts: reader.readUInt30List(),
      partOfName: reader.readOptionalStringUtf8(),
      partOfUri: reader.readOptionalStringUtf8(),
      parts: reader.readStringUtf8List(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeUint8List(apiSignature);
    sink.writeList<UnlinkedNamespaceDirective>(exports, (x) {
      x.write(sink);
    });
    sink.writeBool(hasLibraryDirective);
    sink.writeBool(hasPartOfDirective);
    sink.writeList<UnlinkedNamespaceDirective>(imports, (x) {
      x.write(sink);
    });
    sink.writeUint8List(informativeBytes);
    sink.writeUint30List(lineStarts);
    sink.writeOptionalStringUtf8(partOfName);
    sink.writeOptionalStringUtf8(partOfUri);
    sink.writeStringUtf8Iterable(parts);
  }
}
