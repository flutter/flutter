// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/error/codes.dart';

/// Methods useful for [Scope] for resolution, but not belonging to it. This
/// mixin exists to allow code to be more easily shared between separate
/// resolvers.
mixin ScopeHelpers {
  ErrorReporter get errorReporter;

  void reportDeprecatedExportUse({
    required ScopeLookupResult scopeLookupResult,
    required SimpleIdentifier node,
    required bool hasRead,
    required bool hasWrite,
  }) {
    if (hasRead) {
      reportDeprecatedExportUseGetter(
        scopeLookupResult: scopeLookupResult,
        node: node,
      );
    }

    if (hasWrite) {
      reportDeprecatedExportUseSetter(
        scopeLookupResult: scopeLookupResult,
        node: node,
      );
    }
  }

  void reportDeprecatedExportUseGetter({
    required ScopeLookupResult scopeLookupResult,
    required SimpleIdentifier node,
  }) {
    if (scopeLookupResult is PrefixScopeLookupResult &&
        scopeLookupResult.getterIsFromDeprecatedExport) {
      _reportDeprecatedExportUse(
        node: node,
      );
    }
  }

  void reportDeprecatedExportUseSetter({
    required ScopeLookupResult scopeLookupResult,
    required SimpleIdentifier node,
  }) {
    if (scopeLookupResult is PrefixScopeLookupResult &&
        scopeLookupResult.setterIsFromDeprecatedExport) {
      _reportDeprecatedExportUse(
        node: node,
      );
    }
  }

  void _reportDeprecatedExportUse({required SimpleIdentifier node}) {
    errorReporter.reportErrorForNode(
      HintCode.DEPRECATED_EXPORT_USE,
      node,
      [node.name],
    );
  }
}
