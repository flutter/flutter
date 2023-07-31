// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart' show Source;

export 'package:analyzer/dart/analysis/declared_variables.dart';
export 'package:analyzer/dart/constant/value.dart';
export 'package:analyzer/src/dart/constant/evaluation.dart';
export 'package:analyzer/src/dart/constant/utilities.dart';
export 'package:analyzer/src/dart/constant/value.dart';

/// Instances of the class [ConstantEvaluator] evaluate constant expressions to
/// produce their compile-time value.
///
/// According to the Dart Language Specification:
///
/// > A constant expression is one of the following:
/// >
/// > * A literal number.
/// > * A literal boolean.
/// > * A literal string where any interpolated expression is a compile-time
/// >   constant that evaluates to a numeric, string or boolean value or to
/// >   **null**.
/// > * A literal symbol.
/// > * **null**.
/// > * A qualified reference to a static constant variable.
/// > * An identifier expression that denotes a constant variable, class or type
/// >   alias.
/// > * A constant constructor invocation.
/// > * A constant list literal.
/// > * A constant map literal.
/// > * A simple or qualified identifier denoting a top-level function or a
/// >   static method.
/// > * A parenthesized expression _(e)_ where _e_ is a constant expression.
/// > * <span>
/// >   An expression of the form <i>identical(e<sub>1</sub>, e<sub>2</sub>)</i>
/// >   where <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant
/// >   expressions and <i>identical()</i> is statically bound to the predefined
/// >   dart function <i>identical()</i> discussed above.
/// >   </span>
/// > * <span>
/// >   An expression of one of the forms <i>e<sub>1</sub> == e<sub>2</sub></i>
/// >   or <i>e<sub>1</sub> != e<sub>2</sub></i> where <i>e<sub>1</sub></i> and
/// >   <i>e<sub>2</sub></i> are constant expressions that evaluate to a
/// >   numeric, string or boolean value.
/// >   </span>
/// > * <span>
/// >   An expression of one of the forms <i>!e</i>, <i>e<sub>1</sub> &amp;&amp;
/// >   e<sub>2</sub></i> or <i>e<sub>1</sub> || e<sub>2</sub></i>, where
/// >   <i>e</i>, <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant
/// >   expressions that evaluate to a boolean value.
/// >   </span>
/// > * <span>
/// >   An expression of one of the forms <i>~e</i>, <i>e<sub>1</sub> ^
/// >   e<sub>2</sub></i>, <i>e<sub>1</sub> &amp; e<sub>2</sub></i>,
/// >   <i>e<sub>1</sub> | e<sub>2</sub></i>, <i>e<sub>1</sub> &gt;&gt;
/// >   e<sub>2</sub></i> or <i>e<sub>1</sub> &lt;&lt; e<sub>2</sub></i>, where
/// >   <i>e</i>, <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> are constant
/// >   expressions that evaluate to an integer value or to <b>null</b>.
/// >   </span>
/// > * <span>
/// >   An expression of one of the forms <i>-e</i>, <i>e<sub>1</sub> +
/// >   e<sub>2</sub></i>, <i>e<sub>1</sub> -e<sub>2</sub></i>,
/// >   <i>e<sub>1</sub> * e<sub>2</sub></i>, <i>e<sub>1</sub> /
/// >   e<sub>2</sub></i>, <i>e<sub>1</sub> ~/ e<sub>2</sub></i>,
/// >   <i>e<sub>1</sub> &gt; e<sub>2</sub></i>, <i>e<sub>1</sub> &lt;
/// >   e<sub>2</sub></i>, <i>e<sub>1</sub> &gt;= e<sub>2</sub></i>,
/// >   <i>e<sub>1</sub> &lt;= e<sub>2</sub></i> or <i>e<sub>1</sub> %
/// >   e<sub>2</sub></i>, where <i>e</i>, <i>e<sub>1</sub></i> and
/// >   <i>e<sub>2</sub></i> are constant expressions that evaluate to a numeric
/// >   value or to <b>null</b>.
/// >   </span>
/// > * <span>
/// >   An expression of the form <i>e<sub>1</sub> ? e<sub>2</sub> :
/// >   e<sub>3</sub></i> where <i>e<sub>1</sub></i>, <i>e<sub>2</sub></i> and
/// >   <i>e<sub>3</sub></i> are constant expressions, and <i>e<sub>1</sub></i>
/// >   evaluates to a boolean value.
/// >   </span>
///
/// The values returned by instances of this class are therefore `null` and
/// instances of the classes `Boolean`, `BigInteger`, `Double`, `String`, and
/// `DartObject`.
///
/// In addition, this class defines several values that can be returned to
/// indicate various conditions encountered during evaluation. These are
/// documented with the static fields that define those values.
class ConstantEvaluator {
  /// The source containing the expression(s) that will be evaluated.
  final Source _source;

  /// The library containing the expression(s) that will be evaluated.
  final LibraryElementImpl _library;

  ConstantEvaluator(this._source, this._library);

  EvaluationResult evaluate(Expression expression) {
    RecordingErrorListener errorListener = RecordingErrorListener();
    ErrorReporter errorReporter = ErrorReporter(
      errorListener,
      _source,
      isNonNullableByDefault: _library.isNonNullableByDefault,
    );
    var result = expression.accept(ConstantVisitor(
        ConstantEvaluationEngine(
          declaredVariables: DeclaredVariables(),
          isNonNullableByDefault:
              _library.featureSet.isEnabled(Feature.non_nullable),
          configuration: ConstantEvaluationConfiguration(),
        ),
        _library,
        errorReporter));
    List<AnalysisError> errors = errorListener.errors;
    if (errors.isNotEmpty) {
      return EvaluationResult.forErrors(errors);
    }
    if (result != null) {
      return EvaluationResult.forValue(result);
    }
    // We should not get here. Either there should be a valid value or there
    // should be an error explaining why a value could not be generated.
    return EvaluationResult.forErrors(errors);
  }
}
