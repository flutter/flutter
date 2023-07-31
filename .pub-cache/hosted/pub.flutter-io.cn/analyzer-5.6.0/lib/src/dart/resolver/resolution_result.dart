// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// The result of attempting to resolve an identifier to elements.
class ResolutionResult {
  /// An instance that can be used anywhere that no element was found.
  static const ResolutionResult none =
      ResolutionResult._(_ResolutionResultState.none);

  /// An instance that can be used anywhere that multiple elements were found.
  static const ResolutionResult ambiguous =
      ResolutionResult._(_ResolutionResultState.ambiguous);

  /// The state of the result.
  final _ResolutionResultState state;

  /// Return the element that is invoked for reading.
  final ExecutableElement? getter;

  /// If `true`, then the [getter] is `null`, and this is an error that has
  /// not yet been reported, and the client should report it.
  ///
  /// If `false`, then the [getter] is valid. Usually this means that the
  /// correct target has been found. But the [getter] still might be `null`,
  /// when there was an error, and it has already been reported (e.g. when
  /// ambiguous extension);  or when `null` is the only possible result (e.g.
  /// when `dynamicTarget.foo`, or `functionTyped.call`).
  final bool needsGetterError;

  /// Return the element that is invoked for writing.
  final ExecutableElement? setter;

  /// If `true`, then the [setter] is `null`, and this is an error that has
  /// not yet been reported, and the client should report it.
  ///
  /// If `false`, then the [setter] is valid. Usually this means that the
  /// correct target has been found. But the [setter] still might be `null`,
  /// when there was an error, and it has already been reported (e.g. when
  /// ambiguous extension);  or when `null` is the only possible result (e.g.
  /// when `dynamicTarget.foo`).
  final bool needsSetterError;

  /// The [FunctionType] referenced with `call`.
  final FunctionType? callFunctionType;

  /// The field referenced in a [RecordType].
  final RecordTypeField? recordField;

  /// Initialize a newly created result to represent resolving a single
  /// reading and / or writing result.
  ResolutionResult({
    this.getter,
    this.needsGetterError = true,
    this.setter,
    this.needsSetterError = true,
    this.callFunctionType,
    this.recordField,
  }) : state = _ResolutionResultState.single;

  /// Initialize a newly created result with no elements and the given [state].
  const ResolutionResult._(this.state)
      : getter = null,
        needsGetterError = true,
        setter = null,
        needsSetterError = true,
        callFunctionType = null,
        recordField = null;

  /// Return `true` if this result represents the case where multiple ambiguous
  /// elements were found.
  bool get isAmbiguous => state == _ResolutionResultState.ambiguous;
}

/// The state of a [ResolutionResult].
enum _ResolutionResultState {
  /// Indicates that no element was found.
  none,

  /// Indicates that a single element was found.
  single,

  /// Indicates that multiple ambiguous elements were found.
  ambiguous
}
