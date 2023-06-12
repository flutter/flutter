// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper functions for parsing output of `--print-instructions-sizes-to` flag.
library vm_snapshot_analysis.instruction_sizes;

import 'package:vm_snapshot_analysis/name.dart';
import 'package:vm_snapshot_analysis/program_info.dart';

/// Parse the output of `--print-instructions-sizes-to` saved in the given
/// file [input].
List<SymbolInfo> fromJson(List<dynamic> json) {
  return json
      .cast<Map<String, dynamic>>()
      .map(SymbolInfo._fromJson)
      .toList(growable: false);
}

/// Parse the output of `--print-instructions-sizes-to` saved in the given
/// file [input] into [ProgramInfo] structure representing the sizes
/// of individual functions.
///
/// If [collapseAnonymousClosures] is set to [true] then all anonymous closures
/// within the same scopes are collapsed together. Collapsing closures is
/// helpful when comparing symbol sizes between two versions of the same
/// program because in general there is no reliable way to recognize the same
/// anonymous closures into two independent compilations.
ProgramInfo loadProgramInfo(List<dynamic> json,
    {bool collapseAnonymousClosures = false}) {
  final symbols = fromJson(json);
  return toProgramInfo(symbols,
      collapseAnonymousClosures: collapseAnonymousClosures);
}

/// Information about the size of the instruction object.
class SymbolInfo {
  /// Name of the code object (`Code::QualifiedName`) owning these instructions.
  final Name name;

  /// If this instructions object originated from a function then [libraryUri]
  /// will contain uri of the library of that function.
  final String? libraryUri;

  /// If this instructions object originated from a function then [className]
  /// would contain name of the class owning that function.
  final String? className;

  /// Size of the instructions object in bytes.
  final int size;

  SymbolInfo(
      {required String name,
      this.libraryUri,
      this.className,
      required this.size})
      : name = Name(name);

  static SymbolInfo _fromJson(Map<String, dynamic> map) {
    return SymbolInfo(
        libraryUri: map['l'],
        className: map['c'],
        name: map['n'],
        size: map['s']);
  }
}

/// Restore hierarchical [ProgramInfo] representation from the list of
/// symbols by parsing function names.
///
/// If [collapseAnonymousClosures] is set to [true] then all anonymous closures
/// within the same scopes are collapsed together. Collapsing closures is
/// helpful when comparing symbol sizes between two versions of the same
/// program because in general there is no reliable way to recognize the same
/// anonymous closures into two independent compilations.
ProgramInfo toProgramInfo(List<SymbolInfo> symbols,
    {bool collapseAnonymousClosures = false}) {
  final program = ProgramInfo();
  for (var sym in symbols) {
    final scrubbed = sym.name.scrubbed;
    final libraryUri = sym.libraryUri;

    // Handle stubs specially.
    if (libraryUri == null) {
      assert(sym.name.isStub);
      final node = program.makeNode(
          name: scrubbed, parent: program.stubs, type: NodeType.functionNode);
      assert(node.size == null || sym.name.isTypeTestingStub);
      node.size = (node.size ?? 0) + sym.size;
      continue;
    }

    // Split the name into components (names of individual functions).
    final path = sym.name.components;

    var node = program.root;
    final package = packageOf(libraryUri);
    if (package != libraryUri) {
      node = program.makeNode(
          name: package, parent: node, type: NodeType.packageNode);
    }
    node = program.makeNode(
        name: libraryUri, parent: node, type: NodeType.libraryNode);
    node = program.makeNode(
        name: sym.className!, parent: node, type: NodeType.classNode);
    node = program.makeNode(
        name: path.first, parent: node, type: NodeType.functionNode);
    for (var name in path.skip(1)) {
      if (collapseAnonymousClosures) {
        name = Name.collapse(name);
      }
      node = program.makeNode(
          name: name, parent: node, type: NodeType.functionNode);
    }
    node.size = (node.size ?? 0) + sym.size;
  }

  return program;
}
