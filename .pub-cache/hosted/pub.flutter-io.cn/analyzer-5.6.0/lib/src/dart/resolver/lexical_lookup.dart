// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/extensions.dart';

/// Class containing static methods for performing lexical resolution of
/// identifiers.
class LexicalLookup {
  /// Do not construct
  LexicalLookup._() {
    assert(false, 'Do not construct instances of LexicalLookup');
  }

  /// Interprets the result of a scope lookup, assuming we are trying to look up
  /// a getter.  If a matching element is found, a [LexicalLookupResult] is
  /// returned.  Otherwise `null` is returned.
  static LexicalLookupResult? resolveGetter(ScopeLookupResult scopeResult) {
    var scopeGetter = scopeResult.getter;
    var scopeSetter = scopeResult.setter;
    if (scopeGetter != null || scopeSetter != null) {
      if (scopeGetter != null) {
        return LexicalLookupResult(requested: scopeGetter);
      }
      if (scopeSetter != null && !scopeSetter.isInstanceMember) {
        return LexicalLookupResult(recovery: scopeSetter);
      }
    }

    return null;
  }

  /// Interprets the result of a scope lookup, assuming we are trying to look up
  /// a setter.  If a matching element is found, a [LexicalLookupResult] is
  /// returned.  Otherwise `null` is returned.
  static LexicalLookupResult? resolveSetter(ScopeLookupResult scopeResult) {
    var scopeGetter = scopeResult.getter;
    var scopeSetter = scopeResult.setter;
    if (scopeGetter != null || scopeSetter != null) {
      if (scopeGetter is VariableElement) {
        return LexicalLookupResult(requested: scopeGetter);
      }
      if (scopeSetter != null) {
        return LexicalLookupResult(requested: scopeSetter);
      }
      if (scopeGetter != null && !scopeGetter.isInstanceMember) {
        return LexicalLookupResult(recovery: scopeGetter);
      }
    }

    return null;
  }
}

class LexicalLookupResult {
  final Element? requested;
  final Element? recovery;

  /// The [FunctionType] referenced with `call`.
  final FunctionType? callFunctionType;

  /// The field referenced in a [RecordType].
  final RecordTypeField? recordField;

  LexicalLookupResult({
    this.requested,
    this.recovery,
    this.callFunctionType,
    this.recordField,
  });
}
