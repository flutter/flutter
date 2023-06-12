// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/// An [AnalysisContext] in which analysis can be performed.
class AnalysisContextImpl implements AnalysisContext {
  final SynchronousSession _synchronousSession;

  @override
  final SourceFactory sourceFactory;

  AnalysisContextImpl(this._synchronousSession, this.sourceFactory);

  @override
  AnalysisOptionsImpl get analysisOptions {
    return _synchronousSession.analysisOptions;
  }

  @override
  set analysisOptions(AnalysisOptions options) {
    throw StateError('Cannot be changed.');
  }

  @override
  DeclaredVariables get declaredVariables {
    return _synchronousSession.declaredVariables;
  }

  bool get hasTypeProvider => _synchronousSession.hasTypeProvider;

  @override
  set sourceFactory(SourceFactory factory) {
    throw StateError('Cannot be changed.');
  }

  TypeProviderImpl get typeProviderLegacy {
    return _synchronousSession.typeProviderLegacy;
  }

  TypeProviderImpl get typeProviderNonNullableByDefault {
    return _synchronousSession.typeProviderNonNullableByDefault;
  }

  TypeSystemImpl get typeSystemLegacy {
    return _synchronousSession.typeSystemLegacy;
  }

  TypeSystemImpl get typeSystemNonNullableByDefault {
    return _synchronousSession.typeSystemNonNullableByDefault;
  }

  void clearTypeProvider() {
    _synchronousSession.clearTypeProvider();
  }

  void setTypeProviders({
    required TypeProviderImpl legacy,
    required TypeProviderImpl nonNullableByDefault,
  }) {
    _synchronousSession.setTypeProviders(
      legacy: legacy,
      nonNullableByDefault: nonNullableByDefault,
    );
  }
}
