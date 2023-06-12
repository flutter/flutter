// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/constant/value.dart';

import '../utils.dart';

/// Attempts to extract what source code could be used to represent [object].
///
/// Returns `null` if it wasn't possible to parse [object], or [object] is a
/// primitive value (such as a number, string, boolean) that does not need to be
/// revived in order to represent it.
///
/// **NOTE**: Some returned [Revivable] instances are not representable as valid
/// Dart source code (such as referencing private constructors). It is up to the
/// build tool(s) using this library to surface error messages to the user.
Revivable reviveInstance(DartObject object, [LibraryElement? origin]) {
  final objectType = object.type;
  Element? element = objectType!.aliasElement;
  if (element == null) {
    if (objectType is InterfaceType) {
      element = objectType.element;
    } else {
      element = object.toFunctionValue();
    }
  }
  origin ??= element!.library;
  var url = Uri.parse(urlOfElement(element!));
  if (element is FunctionElement) {
    return Revivable._(
      source: url.removeFragment(),
      accessor: element.name,
    );
  }
  if (element is MethodElement && element.isStatic) {
    return Revivable._(
      source: url.removeFragment(),
      accessor: '${element.enclosingElement.name}.${element.name}',
    );
  }
  // Enums are not included in .definingCompilationUnit.types.
  final clazz = element as ClassElement;
  if (clazz.isEnum) {
    for (final e in clazz.fields.where(
        (f) => f.isPublic && f.isConst && f.computeConstantValue() == object)) {
      return Revivable._(
        source: url.removeFragment(),
        accessor: '${clazz.name}.${e.name}',
      );
    }
  }

  // We try and return a public accessor/constructor if available.
  final allResults = <Revivable>[];

  /// Returns whether [result] is an acceptable result to immediately return.
  bool tryResult(Revivable result) {
    allResults.add(result);
    return !result.isPrivate;
  }

  // ignore: deprecated_member_use
  for (final type in origin!.definingCompilationUnit.types) {
    for (final e in type.fields
        .where((f) => f.isConst && f.computeConstantValue() == object)) {
      final result = Revivable._(
        source: url.removeFragment(),
        accessor: '${type.name}.${e.name}',
      );
      if (tryResult(result)) {
        return result;
      }
    }
  }
  final i = (object as DartObjectImpl).getInvocation();
  if (i != null) {
    url = Uri.parse(urlOfElement(i.constructor.enclosingElement));
    final result = Revivable._(
      source: url,
      accessor: i.constructor.name,
      namedArguments: i.namedArguments,
      positionalArguments: i.positionalArguments,
    );
    if (tryResult(result)) {
      return result;
    }
  }
  for (final e in origin.definingCompilationUnit.topLevelVariables.where(
    (f) => f.isConst && f.computeConstantValue() == object,
  )) {
    final result = Revivable._(
      source: Uri.parse(urlOfElement(origin)).replace(fragment: ''),
      accessor: e.name,
    );
    if (tryResult(result)) {
      return result;
    }
  }
  // We could try and return the "best" result more intelligently.
  return allResults.first;
}

/// Decoded "instructions" for re-creating a const [DartObject] at runtime.
class Revivable {
  /// A URL pointing to the location and class name.
  ///
  /// For example, `LinkedHashMap` looks like: `dart:collection#LinkedHashMap`.
  ///
  /// An accessor to a top-level field or method does not have a fragment and
  /// is instead represented as just something like `dart:collection`, with the
  /// [accessor] field as the name of the symbol.
  final Uri source;

  /// Constructor or getter name used to invoke `const Class(...)`.
  ///
  /// Optional - if empty string (`''`) then this means the default constructor.
  final String accessor;

  /// Positional arguments used to invoke the constructor.
  final List<DartObject> positionalArguments;

  /// Named arguments used to invoke the constructor.
  final Map<String, DartObject> namedArguments;

  const Revivable._({
    required this.source,
    this.accessor = '',
    this.positionalArguments = const [],
    this.namedArguments = const {},
  });

  /// Whether this instance is visible outside the same library.
  ///
  /// Builds tools may use this to fail when the symbol is expected to be
  /// importable (i.e. isn't used with `part of`).
  bool get isPrivate =>
      source.fragment.startsWith('_') || accessor.startsWith('_');

  @override
  String toString() {
    if (source.fragment.isNotEmpty) {
      if (accessor.isEmpty) {
        return 'const $source';
      }
      return 'const $source.$accessor';
    }
    return '$source::$accessor';
  }
}
