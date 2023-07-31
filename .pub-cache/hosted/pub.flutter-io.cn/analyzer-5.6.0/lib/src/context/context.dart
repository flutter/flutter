// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/// An [AnalysisContext] in which analysis can be performed.
class AnalysisContextImpl implements AnalysisContext {
  AnalysisOptionsImpl _analysisOptions;

  @override
  final DeclaredVariables declaredVariables;

  @override
  final SourceFactory sourceFactory;

  TypeProviderImpl? _typeProviderLegacy;
  TypeProviderImpl? _typeProviderNonNullableByDefault;

  TypeSystemImpl? _typeSystemLegacy;
  TypeSystemImpl? _typeSystemNonNullableByDefault;

  AnalysisContextImpl({
    required AnalysisOptionsImpl analysisOptions,
    required this.declaredVariables,
    required this.sourceFactory,
  }) : _analysisOptions = analysisOptions;

  @override
  AnalysisOptionsImpl get analysisOptions {
    return _analysisOptions;
  }

  /// TODO(scheglov) Remove it, exists only for Cider.
  set analysisOptions(AnalysisOptionsImpl analysisOptions) {
    _analysisOptions = analysisOptions;

    // TODO() remove this method as well
    _typeSystemLegacy?.updateOptions(
      implicitCasts: analysisOptions.implicitCasts,
      strictCasts: analysisOptions.strictCasts,
      strictInference: analysisOptions.strictInference,
    );

    _typeSystemNonNullableByDefault?.updateOptions(
      implicitCasts: analysisOptions.implicitCasts,
      strictCasts: analysisOptions.strictCasts,
      strictInference: analysisOptions.strictInference,
    );
  }

  bool get hasTypeProvider {
    return _typeProviderNonNullableByDefault != null;
  }

  TypeProviderImpl get typeProviderLegacy {
    return _typeProviderLegacy!;
  }

  TypeProviderImpl get typeProviderNonNullableByDefault {
    return _typeProviderNonNullableByDefault!;
  }

  TypeSystemImpl get typeSystemLegacy {
    return _typeSystemLegacy!;
  }

  TypeSystemImpl get typeSystemNonNullableByDefault {
    return _typeSystemNonNullableByDefault!;
  }

  void clearTypeProvider() {
    _typeProviderLegacy = null;
    _typeProviderNonNullableByDefault = null;

    _typeSystemLegacy = null;
    _typeSystemNonNullableByDefault = null;
  }

  void setTypeProviders({
    required TypeProviderImpl legacy,
    required TypeProviderImpl nonNullableByDefault,
  }) {
    if (_typeProviderLegacy != null ||
        _typeProviderNonNullableByDefault != null) {
      throw StateError('TypeProvider(s) can be set only once.');
    }

    _typeSystemLegacy = TypeSystemImpl(
      implicitCasts: analysisOptions.implicitCasts,
      isNonNullableByDefault: false,
      strictCasts: analysisOptions.strictCasts,
      strictInference: analysisOptions.strictInference,
      typeProvider: legacy,
    );

    _typeSystemNonNullableByDefault = TypeSystemImpl(
      implicitCasts: analysisOptions.implicitCasts,
      isNonNullableByDefault: true,
      strictCasts: analysisOptions.strictCasts,
      strictInference: analysisOptions.strictInference,
      typeProvider: nonNullableByDefault,
    );

    _typeProviderLegacy = legacy;
    _typeProviderNonNullableByDefault = nonNullableByDefault;
  }
}
