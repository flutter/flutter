// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/link.dart' as graph
    show DependencyWalker, Node;
import 'package:collection/collection.dart';

/// Ensure that the [FileState.libraryCycle] for the [file] and anything it
/// depends on is computed.
void computeLibraryCycle(Uint32List salt, FileState file) {
  var libraryWalker = _LibraryWalker(salt);
  libraryWalker.walk(libraryWalker.getNode(file));
}

/// Information about libraries that reference each other, so form a cycle.
class LibraryCycle {
  /// The libraries that belong to this cycle.
  final List<FileState> libraries;

  /// The library cycles that this cycle references directly.
  final Set<LibraryCycle> directDependencies;

  /// The cycles that use this cycle, used to [invalidate] transitively.
  final List<LibraryCycle> _directUsers = [];

  /// The transitive signature of this cycle.
  ///
  /// It is based on the API signatures of all files of the [libraries], and
  /// transitive signatures of the cycles that the [libraries] reference
  /// directly.  So, indirectly it is based on the transitive closure of all
  /// files that [libraries] reference (but we don't compute these files).
  String transitiveSignature;

  LibraryCycle({
    required this.libraries,
    required this.directDependencies,
    required this.transitiveSignature,
  }) {
    for (var directDependency in directDependencies) {
      directDependency._directUsers.add(this);
    }
  }

  /// Invalidate this cycle and any cycles that directly or indirectly use it.
  ///
  /// Practically invalidation means that we clear the library cycle in all the
  /// [libraries] that share this [LibraryCycle] instance.
  void invalidate() {
    for (var library in libraries) {
      library.internal_setLibraryCycle(null);
    }
    for (var user in _directUsers.toList()) {
      user.invalidate();
    }
    for (var directDependency in directDependencies) {
      directDependency._directUsers.remove(this);
    }
  }

  @override
  String toString() {
    return '[' + libraries.join(', ') + ']';
  }
}

/// Node in [_LibraryWalker].
class _LibraryNode extends graph.Node<_LibraryNode> {
  final _LibraryWalker walker;
  final FileState file;

  _LibraryNode(this.walker, this.file);

  @override
  bool get isEvaluated => file.internal_libraryCycle != null;

  @override
  List<_LibraryNode> computeDependencies() {
    return file.directReferencedLibraries.map(walker.getNode).toList();
  }
}

/// Helper that organizes dependencies of a library into topologically
/// sorted [LibraryCycle]s.
class _LibraryWalker extends graph.DependencyWalker<_LibraryNode> {
  final Uint32List _salt;
  final Map<FileState, _LibraryNode> nodesOfFiles = {};

  _LibraryWalker(this._salt);

  @override
  void evaluate(_LibraryNode v) {
    evaluateScc([v]);
  }

  @override
  void evaluateScc(List<_LibraryNode> scc) {
    var signature = ApiSignature();
    signature.addUint32List(_salt);

    // Sort libraries to produce stable signatures.
    scc.sort((first, second) {
      var firstPath = first.file.path;
      var secondPath = second.file.path;
      return firstPath.compareTo(secondPath);
    });

    // Append direct referenced cycles.
    var directDependencies = <LibraryCycle>{};
    for (var node in scc) {
      var file = node.file;
      _appendDirectlyReferenced(
        directDependencies,
        signature,
        file.directReferencedLibraries.whereNotNull().toList(),
      );
    }

    // Fill the cycle with libraries.
    var libraries = <FileState>[];
    for (var node in scc) {
      libraries.add(node.file);

      signature.addLanguageVersion(node.file.packageLanguageVersion);
      signature.addString(node.file.uriStr);

      signature.addInt(node.file.libraryFiles.length);
      for (var file in node.file.libraryFiles) {
        signature.addBool(file.exists);
        signature.addBytes(file.apiSignature);
      }
    }

    // Create the LibraryCycle instance for the cycle.
    var cycle = LibraryCycle(
      libraries: libraries,
      directDependencies: directDependencies,
      transitiveSignature: signature.toHex(),
    );

    // Set the instance into the libraries.
    for (var node in scc) {
      node.file.internal_setLibraryCycle(cycle);
    }
  }

  _LibraryNode getNode(FileState file) {
    return nodesOfFiles.putIfAbsent(file, () => _LibraryNode(this, file));
  }

  void _appendDirectlyReferenced(
    Set<LibraryCycle> directDependencies,
    ApiSignature signature,
    List<FileState> directlyReferenced,
  ) {
    signature.addInt(directlyReferenced.length);
    for (var referencedLibrary in directlyReferenced) {
      var referencedCycle = referencedLibrary.internal_libraryCycle;

      // We get null when the library is a part of the cycle being build.
      if (referencedCycle == null) continue;

      if (directDependencies.add(referencedCycle)) {
        signature.addString(referencedCycle.transitiveSignature);
      }
    }
  }
}
