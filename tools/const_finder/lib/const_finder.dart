// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:kernel/kernel.dart' hide MapEntry;
import 'package:meta/meta.dart';

class _ConstVisitor extends RecursiveVisitor<void> {
  _ConstVisitor(
    this.kernelFilePath,
    this.targetLibraryUri,
    this.classLibraryUri,
    this.className,
  )  : assert(kernelFilePath != null),
        assert(targetLibraryUri != null),
        assert(classLibraryUri != null),
        assert(className != null),
        constantInstances = <Map<String, dynamic>>[],
        nonConstantLocations = <Map<String, dynamic>>[];

  /// The path to the file to open.
  final String kernelFilePath;

  /// The library URI for the main entrypoint of the target library.
  final String targetLibraryUri;

  /// The library URI for the class to find.
  final String classLibraryUri;

  /// The name of the class to find.
  final String className;

  final List<Map<String, dynamic>> constantInstances;
  final List<Map<String, dynamic>> nonConstantLocations;

  bool _matches(Class node) {
    return node.enclosingLibrary.canonicalName.name == classLibraryUri &&
      node.name == className;
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    final Class parentClass = node.target.parent as Class;
    if (!_matches(parentClass)) {
      super.visitConstructorInvocation(node);
    }
    nonConstantLocations.add(<String, dynamic>{
      'file': node.location.file.toString(),
      'line': node.location.line,
      'column': node.location.column,
    });
  }

  @override
  void visitInstanceConstantReference(InstanceConstant node) {
    if (!_matches(node.classNode)) {
      return;
    }
    final Map<String, dynamic> instance = <String, dynamic>{};
    for (MapEntry<Reference, Constant> kvp in node.fieldValues.entries) {
      final PrimitiveConstant<dynamic> value = kvp.value as PrimitiveConstant<dynamic>;
      instance[kvp.key.canonicalName.name] = value.value;
    }
    constantInstances.add(instance);
  }
}

/// A kernel AST visitor that finds const references.
class ConstFinder {
  /// Creates a new ConstFinder class.  All arguments are required and must not
  /// be null.
  ///
  /// The `kernelFilePath` is the path to a dill (kernel) file to process.
  ///
  /// The `targetLibraryUri` is the `package:` URI of the main entrypoint to
  /// search from.
  ///
  ///
  ///
  ConstFinder({
    @required String kernelFilePath,
    @required String targetLibraryUri,
    @required String classLibraryUri,
    @required String className,
  })  : _visitor = _ConstVisitor(
                    kernelFilePath,
                    targetLibraryUri,
                    classLibraryUri,
                    className,
                  );

  final _ConstVisitor _visitor;

  Library _getRoot() {
    final Component binary = loadComponentFromBinary(_visitor.kernelFilePath);
    return binary.libraries.firstWhere(
      (Library library) => library.canonicalName.name == _visitor.targetLibraryUri,
      orElse: () => throw LibraryNotFoundException._(_visitor.targetLibraryUri),
    );
  }

  /// Finds all instances
  Map<String, dynamic> findInstances() {
    final Library root = _getRoot();
    root.visitChildren(_visitor);
    return <String, dynamic>{
      'constantInstances': _visitor.constantInstances,
      'nonConstantLocations': _visitor.nonConstantLocations,
    };
  }
}

/// Exception thrown by [ConstFinder.findInstances] when the target library
/// is not found.
class LibraryNotFoundException implements Exception {
  const LibraryNotFoundException._(this.targetLibraryUri);

  /// The library target URI that could not be found.
  final String targetLibraryUri;

  @override
  String toString() => 'Could not find target library for "$targetLibraryUri".';
}
