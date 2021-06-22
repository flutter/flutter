// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:kernel/kernel.dart';

class _ConstVisitor extends RecursiveVisitor<void> {
  _ConstVisitor(
    this.kernelFilePath,
    this.classLibraryUri,
    this.className,
  )  : _visitedInstances = <String>{},
       constantInstances = <Map<String, dynamic>>[],
       nonConstantLocations = <Map<String, dynamic>>[];

  /// The path to the file to open.
  final String kernelFilePath;

  /// The library URI for the class to find.
  final String classLibraryUri;

  /// The name of the class to find.
  final String className;

  final Set<String> _visitedInstances;
  final List<Map<String, dynamic>> constantInstances;
  final List<Map<String, dynamic>> nonConstantLocations;

  // A cache of previously evaluated classes.
  static Map<Class, bool> _classHeirarchyCache = <Class, bool>{};
  bool _matches(Class node) {
    final bool? result = _classHeirarchyCache[node];
    if (result != null) {
      return result;
    }
    final bool exactMatch = node.name == className
        && node.enclosingLibrary.importUri.toString() == classLibraryUri;
    final bool match = exactMatch
        || node.supers.any((Supertype supertype) => _matches(supertype.classNode));
    _classHeirarchyCache[node] = match;
    return match;
  }

  // Avoid visiting the same constant more than once.
  Set<Constant> _cache = LinkedHashSet<Constant>.identity();

  @override
  void defaultConstant(Constant node) {
    if (_cache.add(node)) {
      super.defaultConstant(node);
    }
  }

  @override
  void defaultConstantReference(Constant node) {
    defaultConstant(node);
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    final Class parentClass = node.target.parent! as Class;
    if (_matches(parentClass)) {
      final Location location = node.location!;
      nonConstantLocations.add(<String, dynamic>{
        'file': location.file.toString(),
        'line': location.line,
        'column': location.column,
      });
    }
    super.visitConstructorInvocation(node);
  }

  @override
  void visitInstanceConstantReference(InstanceConstant node) {
    super.visitInstanceConstantReference(node);
    if (!_matches(node.classNode)) {
      return;
    }
    final Map<String, dynamic> instance = <String, dynamic>{};
    for (final MapEntry<Reference, Constant> kvp in node.fieldValues.entries) {
      if (kvp.value is! PrimitiveConstant<dynamic>) {
        continue;
      }
      final PrimitiveConstant<dynamic> value = kvp.value as PrimitiveConstant<dynamic>;
      instance[kvp.key.asField.name.text] = value.value;
    }
    if (_visitedInstances.add(instance.toString())) {
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
    required String kernelFilePath,
    required String classLibraryUri,
    required String className,
  })  : _visitor = _ConstVisitor(
                    kernelFilePath,
                    classLibraryUri,
                    className,
                  );

  final _ConstVisitor _visitor;

  /// Finds all instances
  Map<String, dynamic> findInstances() {
    _visitor._visitedInstances.clear();
    for (final Library library in loadComponentFromBinary(_visitor.kernelFilePath).libraries) {
      library.visitChildren(_visitor);
    }
    return <String, dynamic>{
      'constantInstances': _visitor.constantInstances,
      'nonConstantLocations': _visitor.nonConstantLocations,
    };
  }
}
