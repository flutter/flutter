// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

extension DartTypeExtension on DartType {
  bool isAssignableTo(DartType other) {
    final library = element!.library;
    return library == null || library.typeSystem.isAssignableTo(this, other);
  }

  bool get isEnum {
    final myType = this;
    return myType is InterfaceType && myType.element.isEnum;
  }

  bool get isNullableType =>
      isDynamic || nullabilitySuffix == NullabilitySuffix.question;

  /// Returns `true` if `this` is `dynamic` or `Object?`.
  bool get isLikeDynamic => (isDartCoreObject && isNullableType) || isDynamic;

  /// Returns all of the [DartType] types that `this` implements, mixes-in, and
  /// extends, starting with `this` itself.
  Iterable<DartType> get typeImplementations sync* {
    yield this;

    final myType = this;

    if (myType is InterfaceType) {
      yield* myType.interfaces.expand((e) => e.typeImplementations);
      yield* myType.mixins.expand((e) => e.typeImplementations);

      if (myType.superclass != null) {
        yield* myType.superclass!.typeImplementations;
      }
    }
  }

  /// If `this` is the [Type] or implements the [Type] represented by [checker],
  /// returns the generic arguments to the [checker] [Type] if there are any.
  ///
  /// If the [checker] [Type] doesn't have generic arguments, `null` is
  /// returned.
  List<DartType>? typeArgumentsOf(TypeChecker checker) {
    final implementation = _getImplementationType(checker) as InterfaceType?;

    return implementation?.typeArguments;
  }

  DartType? _getImplementationType(TypeChecker checker) =>
      typeImplementations.firstWhereOrNull(checker.isExactlyType);
}
