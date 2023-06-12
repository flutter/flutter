// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_builder.src.specs.expression;

import 'package:meta/meta.dart';

import '../base.dart';
import '../emitter.dart';
import '../visitors.dart';
import 'code.dart';
import 'method.dart';
import 'reference.dart';
import 'type_function.dart';

part 'expression/binary.dart';
part 'expression/closure.dart';
part 'expression/code.dart';
part 'expression/invoke.dart';
part 'expression/literal.dart';

/// Represents a [code] block that wraps an [Expression].

/// Represents a Dart expression.
///
/// See various concrete implementations for details.
abstract class Expression implements Spec {
  const Expression();

  /// An empty expression.
  static const _empty = CodeExpression(Code(''));

  @override
  R accept<R>(covariant ExpressionVisitor<R> visitor, [R context]);

  /// The expression as a valid [Code] block.
  ///
  /// Also see [statement].
  Code get code => ToCodeExpression(this);

  /// The expression as a valid [Code] block with a trailing `;`.
  Code get statement => ToCodeExpression(this, true);

  /// Returns the result of `this` `&&` [other].
  Expression and(Expression other) =>
      BinaryExpression._(expression, other, '&&');

  /// Returns the result of `this` `||` [other].
  Expression or(Expression other) =>
      BinaryExpression._(expression, other, '||');

  /// Returns the result of `!this`.
  Expression negate() =>
      BinaryExpression._(_empty, expression, '!', addSpace: false);

  /// Returns the result of `this` `as` [other].
  Expression asA(Expression other) => CodeExpression(Block.of([
        const Code('('),
        BinaryExpression._(
          expression,
          other,
          'as',
        ).code,
        const Code(')')
      ]));

  /// Returns accessing the index operator (`[]`) on `this`.
  Expression index(Expression index) => BinaryExpression._(
        expression,
        CodeExpression(Block.of([
          const Code('['),
          index.code,
          const Code(']'),
        ])),
        '',
      );

  /// Returns the result of `this` `is` [other].
  Expression isA(Expression other) => BinaryExpression._(
        expression,
        other,
        'is',
      );

  /// Returns the result of `this` `is!` [other].
  Expression isNotA(Expression other) => BinaryExpression._(
        expression,
        other,
        'is!',
      );

  /// Returns the result of `this` `==` [other].
  Expression equalTo(Expression other) => BinaryExpression._(
        expression,
        other,
        '==',
      );

  /// Returns the result of `this` `!=` [other].
  Expression notEqualTo(Expression other) => BinaryExpression._(
        expression,
        other,
        '!=',
      );

  /// Returns the result of `this` `>` [other].
  Expression greaterThan(Expression other) => BinaryExpression._(
        expression,
        other,
        '>',
      );

  /// Returns the result of `this` `<` [other].
  Expression lessThan(Expression other) => BinaryExpression._(
        expression,
        other,
        '<',
      );

  /// Returns the result of `this` `>=` [other].
  Expression greaterOrEqualTo(Expression other) => BinaryExpression._(
        expression,
        other,
        '>=',
      );

  /// Returns the result of `this` `<=` [other].
  Expression lessOrEqualTo(Expression other) => BinaryExpression._(
        expression,
        other,
        '<=',
      );

  /// Returns the result of `this` `+` [other].
  Expression operatorAdd(Expression other) => BinaryExpression._(
        expression,
        other,
        '+',
      );

  /// Returns the result of `this` `-` [other].
  Expression operatorSubstract(Expression other) => BinaryExpression._(
        expression,
        other,
        '-',
      );

  /// Returns the result of `this` `/` [other].
  Expression operatorDivide(Expression other) => BinaryExpression._(
        expression,
        other,
        '/',
      );

  /// Returns the result of `this` `*` [other].
  Expression operatorMultiply(Expression other) => BinaryExpression._(
        expression,
        other,
        '*',
      );

  /// Returns the result of `this` `%` [other].
  Expression operatorEuclideanModulo(Expression other) => BinaryExpression._(
        expression,
        other,
        '%',
      );

  Expression conditional(Expression whenTrue, Expression whenFalse) =>
      BinaryExpression._(
        expression,
        BinaryExpression._(whenTrue, whenFalse, ':'),
        '?',
      );

  /// This expression preceded by `await`.
  Expression get awaited => BinaryExpression._(
        _empty,
        this,
        'await',
      );

  /// Return `{other} = {this}`.
  Expression assign(Expression other) => BinaryExpression._(
        this,
        other,
        '=',
      );

  /// Return `{other} ?? {this}`.
  Expression ifNullThen(Expression other) => BinaryExpression._(
        this,
        other,
        '??',
      );

  /// Return `{other} ??= {this}`.
  Expression assignNullAware(Expression other) => BinaryExpression._(
        this,
        other,
        '??=',
      );

  /// Return `var {name} = {this}`.
  Expression assignVar(String name, [Reference type]) => BinaryExpression._(
        type == null
            ? LiteralExpression._('var $name')
            : BinaryExpression._(
                type.expression,
                LiteralExpression._(name),
                '',
              ),
        this,
        '=',
      );

  /// Return `final {name} = {this}`.
  Expression assignFinal(String name, [Reference type]) => BinaryExpression._(
        type == null
            ? const LiteralExpression._('final')
            : BinaryExpression._(
                const LiteralExpression._('final'),
                type.expression,
                '',
              ),
        this,
        '$name =',
      );

  /// Return `const {name} = {this}`.
  Expression assignConst(String name, [Reference type]) => BinaryExpression._(
        type == null
            ? const LiteralExpression._('const')
            : BinaryExpression._(
                const LiteralExpression._('const'),
                type.expression,
                '',
              ),
        this,
        '$name =',
        isConst: true,
      );

  /// Call this expression as a method.
  Expression call(
    Iterable<Expression> positionalArguments, [
    Map<String, Expression> namedArguments = const {},
    List<Reference> typeArguments = const [],
  ]) =>
      InvokeExpression._(
        this,
        positionalArguments.toList(),
        namedArguments,
        typeArguments,
      );

  /// Returns an expression accessing `.<name>` on this expression.
  Expression property(String name) => BinaryExpression._(
        this,
        LiteralExpression._(name),
        '.',
        addSpace: false,
      );

  /// Returns an expression accessing `..<name>` on this expression.
  Expression cascade(String name) => BinaryExpression._(
        this,
        LiteralExpression._(name),
        '..',
        addSpace: false,
      );

  /// Returns an expression accessing `?.<name>` on this expression.
  Expression nullSafeProperty(String name) => BinaryExpression._(
        this,
        LiteralExpression._(name),
        '?.',
        addSpace: false,
      );

  /// This expression preceded by `return`.
  Expression get returned => BinaryExpression._(
        const LiteralExpression._('return'),
        this,
        '',
      );

  /// This expression preceded by `throw`.
  Expression get thrown => BinaryExpression._(
        const LiteralExpression._('throw'),
        this,
        '',
      );

  /// May be overridden to support other types implementing [Expression].
  @visibleForOverriding
  Expression get expression => this;
}

/// Creates `typedef {name} =`.
Code createTypeDef(String name, FunctionType type) => BinaryExpression._(
        LiteralExpression._('typedef $name'), type.expression, '=')
    .statement;

class ToCodeExpression implements Code {
  final Expression code;

  /// Whether this code should be considered a _statement_.
  final bool isStatement;

  @visibleForTesting
  const ToCodeExpression(this.code, [this.isStatement = false]);

  @override
  R accept<R>(CodeVisitor<R> visitor, [R context]) =>
      (visitor as ExpressionVisitor<R>).visitToCodeExpression(this, context);

  @override
  String toString() => code.toString();
}

/// Knowledge of different types of expressions in Dart.
///
/// **INTERNAL ONLY**.
abstract class ExpressionVisitor<T> implements SpecVisitor<T> {
  T visitToCodeExpression(ToCodeExpression code, [T context]);
  T visitBinaryExpression(BinaryExpression expression, [T context]);
  T visitClosureExpression(ClosureExpression expression, [T context]);
  T visitCodeExpression(CodeExpression expression, [T context]);
  T visitInvokeExpression(InvokeExpression expression, [T context]);
  T visitLiteralExpression(LiteralExpression expression, [T context]);
  T visitLiteralListExpression(LiteralListExpression expression, [T context]);
  T visitLiteralSetExpression(LiteralSetExpression expression, [T context]);
  T visitLiteralMapExpression(LiteralMapExpression expression, [T context]);
}

/// Knowledge of how to write valid Dart code from [ExpressionVisitor].
///
/// **INTERNAL ONLY**.
abstract class ExpressionEmitter implements ExpressionVisitor<StringSink> {
  @override
  StringSink visitToCodeExpression(ToCodeExpression expression,
      [StringSink output]) {
    output ??= StringBuffer();
    expression.code.accept(this, output);
    if (expression.isStatement) {
      output.write(';');
    }
    return output;
  }

  @override
  StringSink visitBinaryExpression(BinaryExpression expression,
      [StringSink output]) {
    output ??= StringBuffer();
    expression.left.accept(this, output);
    if (expression.addSpace) {
      output.write(' ');
    }
    output.write(expression.operator);
    if (expression.addSpace) {
      output.write(' ');
    }
    startConstCode(expression.isConst, () {
      expression.right.accept(this, output);
    });
    return output;
  }

  @override
  StringSink visitClosureExpression(ClosureExpression expression,
      [StringSink output]) {
    output ??= StringBuffer();
    return expression.method.accept(this, output);
  }

  @override
  StringSink visitCodeExpression(CodeExpression expression,
      [StringSink output]) {
    output ??= StringBuffer();
    final visitor = this as CodeVisitor<StringSink>;
    return expression.code.accept(visitor, output);
  }

  @override
  StringSink visitInvokeExpression(InvokeExpression expression,
      [StringSink output]) {
    output ??= StringBuffer();
    return _writeConstExpression(
        output, expression.type == InvokeExpressionType.constInstance, () {
      expression.target.accept(this, output);
      if (expression.name != null) {
        output..write('.')..write(expression.name);
      }
      if (expression.typeArguments.isNotEmpty) {
        output.write('<');
        visitAll<Reference>(expression.typeArguments, output, (type) {
          type.accept(this, output);
        });
        output.write('>');
      }
      output.write('(');
      visitAll<Spec>(expression.positionalArguments, output, (spec) {
        spec.accept(this, output);
      });
      if (expression.positionalArguments.isNotEmpty &&
          expression.namedArguments.isNotEmpty) {
        output.write(', ');
      }
      visitAll<String>(expression.namedArguments.keys, output, (name) {
        output..write(name)..write(': ');
        expression.namedArguments[name].accept(this, output);
      });
      return output..write(')');
    });
  }

  @override
  StringSink visitLiteralExpression(LiteralExpression expression,
      [StringSink output]) {
    output ??= StringBuffer();
    return output..write(expression.literal);
  }

  void _acceptLiteral(Object literalOrSpec, StringSink output) {
    if (literalOrSpec is Spec) {
      literalOrSpec.accept(this, output);
      return;
    }
    literal(literalOrSpec).accept(this, output);
  }

  bool _withInConstExpression = false;

  @override
  StringSink visitLiteralListExpression(
    LiteralListExpression expression, [
    StringSink output,
  ]) {
    output ??= StringBuffer();

    return _writeConstExpression(output, expression.isConst, () {
      if (expression.type != null) {
        output.write('<');
        expression.type.accept(this, output);
        output.write('>');
      }
      output.write('[');
      visitAll<Object>(expression.values, output, (value) {
        _acceptLiteral(value, output);
      });
      return output..write(']');
    });
  }

  @override
  StringSink visitLiteralSetExpression(
    LiteralSetExpression expression, [
    StringSink output,
  ]) {
    output ??= StringBuffer();

    return _writeConstExpression(output, expression.isConst, () {
      if (expression.type != null) {
        output.write('<');
        expression.type.accept(this, output);
        output.write('>');
      }
      output.write('{');
      visitAll<Object>(expression.values, output, (value) {
        _acceptLiteral(value, output);
      });
      return output..write('}');
    });
  }

  @override
  StringSink visitLiteralMapExpression(
    LiteralMapExpression expression, [
    StringSink output,
  ]) {
    output ??= StringBuffer();
    return _writeConstExpression(output, expression.isConst, () {
      if (expression.keyType != null) {
        output.write('<');
        expression.keyType.accept(this, output);
        output.write(', ');
        if (expression.valueType == null) {
          const Reference('dynamic', 'dart:core').accept(this, output);
        } else {
          expression.valueType.accept(this, output);
        }
        output.write('>');
      }
      output.write('{');
      visitAll<Object>(expression.values.keys, output, (key) {
        final value = expression.values[key];
        _acceptLiteral(key, output);
        output.write(': ');
        _acceptLiteral(value, output);
      });
      return output..write('}');
    });
  }

  /// Executes [visit] within a context which may alter the output if [isConst]
  /// is `true`.
  ///
  /// This allows constant expressions to omit the `const` keyword if they
  /// are already within a constant expression.
  void startConstCode(
    bool isConst,
    Null Function() visit,
  ) {
    final previousConstContext = _withInConstExpression;
    if (isConst) {
      _withInConstExpression = true;
    }

    visit();
    _withInConstExpression = previousConstContext;
  }

  /// Similar to [startConstCode], but handles writing `"const "` if [isConst]
  /// is `true` and the invocation is not nested under other invocations where
  /// [isConst] is true.
  StringSink _writeConstExpression(
    StringSink sink,
    bool isConst,
    StringSink Function() visitExpression,
  ) {
    final previousConstContext = _withInConstExpression;
    if (isConst) {
      if (!_withInConstExpression) {
        sink.write('const ');
      }
      _withInConstExpression = true;
    }

    final returnedSink = visitExpression();
    assert(identical(returnedSink, sink));
    _withInConstExpression = previousConstContext;
    return sink;
  }
}
