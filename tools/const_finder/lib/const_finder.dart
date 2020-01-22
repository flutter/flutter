// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:kernel/kernel.dart' hide MapEntry;
import 'package:meta/meta.dart';

class _ConstVisitor extends RecursiveVisitor<void> {
  _ConstVisitor(
    this.kernelFilePath,
    this.classLibraryUri,
    this.className,
  )  : assert(kernelFilePath != null),
        assert(classLibraryUri != null),
        assert(className != null),
        _visitedInstnaces = <String>{},
        constantInstances = <Map<String, dynamic>>[],
        nonConstantLocations = <Map<String, dynamic>>[];

  /// The path to the file to open.
  final String kernelFilePath;

  /// The library URI for the class to find.
  final String classLibraryUri;

  /// The name of the class to find.
  final String className;

  final Set<String> _visitedInstnaces;
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
      return;
    }
    nonConstantLocations.add(<String, dynamic>{
      'file': node.location.file.toString(),
      'line': node.location.line,
      'column': node.location.column,
    });
  }

  @override
  void visitInstanceConstantReference(InstanceConstant node) {
    node.fieldValues.values.whereType<InstanceConstant>().forEach(visitInstanceConstantReference);
    if (!_matches(node.classNode)) {
      super.visitInstanceConstantReference(node);
      return;
    }
    final Map<String, dynamic> instance = <String, dynamic>{};
    for (MapEntry<Reference, Constant> kvp in node.fieldValues.entries) {
      if (kvp.value is! PrimitiveConstant<dynamic>) {
        continue;
      }
      final PrimitiveConstant<dynamic> value = kvp.value as PrimitiveConstant<dynamic>;
      instance[kvp.key.canonicalName.name] = value.value;
    }
    if (_visitedInstnaces.add(instance.toString())) {
      constantInstances.add(instance);
    }
  }
}

/// A kernel AST visitor that finds const references.
class ConstFinder {
  /// Creates a new ConstFinder class.  All arguments are required and must not
  /// be null.
  ///
  /// The `kernelFilePath` is the path to a dill (kernel) file to process.
  ConstFinder({
    @required String kernelFilePath,
    @required String classLibraryUri,
    @required String className,
  })  : _visitor = _ConstVisitor(
                    kernelFilePath,
                    classLibraryUri,
                    className,
                  );

  final _ConstVisitor _visitor;

  /// Finds all instances
  Map<String, dynamic> findInstances() {
    _visitor._visitedInstnaces.clear();
    for (Library library in loadComponentFromBinary(_visitor.kernelFilePath).libraries) {
      library.visitChildren(_visitor);
    }
    return <String, dynamic>{
      'constantInstances': _visitor.constantInstances,
      'nonConstantLocations': _visitor.nonConstantLocations,
    };
  }
}
