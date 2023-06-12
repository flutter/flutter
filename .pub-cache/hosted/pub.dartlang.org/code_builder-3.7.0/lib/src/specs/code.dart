// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:meta/meta.dart';

import '../allocator.dart';
import '../base.dart';
import '../emitter.dart';
import '../visitors.dart';
import 'expression.dart';
import 'reference.dart';

part 'code.g.dart';

/// Returns a scoped symbol to [Reference], with an import prefix if needed.
///
/// This is short-hand for [Allocator.allocate] in most implementations.
typedef Allocate = String Function(Reference);

/// Represents arbitrary Dart code (either expressions or statements).
///
/// See the various constructors for details.
abstract class Code implements Spec {
  /// Create a simple code body based on a static string.
  const factory Code(String code) = StaticCode._;

  /// Create a code based that may use a provided [Allocator] for scoping:
  ///
  /// ```dart
  /// // Emits `_i123.FooType()`, where `_i123` is the import prefix.
  ///
  /// Code.scope((a) {
  ///   return '${a.allocate(fooType)}()'
  /// });
  /// ```
  const factory Code.scope(
    String Function(Allocate) scope,
  ) = ScopedCode._;

  @override
  R accept<R>(covariant CodeVisitor<R> visitor, [R context]);
}

/// Represents blocks of statements of Dart code.
abstract class Block implements Built<Block, BlockBuilder>, Code, Spec {
  factory Block([void Function(BlockBuilder) updates]) = _$Block;

  factory Block.of(Iterable<Code> statements) =>
      Block((b) => b..statements.addAll(statements));

  Block._();

  @override
  R accept<R>(covariant CodeVisitor<R> visitor, [R context]) =>
      visitor.visitBlock(this, context);

  BuiltList<Code> get statements;
}

abstract class BlockBuilder implements Builder<Block, BlockBuilder> {
  factory BlockBuilder() = _$BlockBuilder;

  BlockBuilder._();

  /// Adds an [expression] to [statements].
  ///
  /// **NOTE**: Not all expressions are _useful_ statements.
  void addExpression(Expression expression) {
    statements.add(expression.statement);
  }

  ListBuilder<Code> statements = ListBuilder<Code>();
}

/// Knowledge of different types of blocks of code in Dart.
///
/// **INTERNAL ONLY**.
abstract class CodeVisitor<T> implements SpecVisitor<T> {
  T visitBlock(Block code, [T context]);

  T visitStaticCode(StaticCode code, [T context]);

  T visitScopedCode(ScopedCode code, [T context]);
}

/// Knowledge of how to write valid Dart code from [CodeVisitor].
abstract class CodeEmitter implements CodeVisitor<StringSink> {
  @protected
  Allocator get allocator;

  @override
  StringSink visitBlock(Block block, [StringSink output]) {
    output ??= StringBuffer();
    return visitAll<Code>(block.statements, output, (statement) {
      statement.accept(this, output);
    }, '\n');
  }

  @override
  StringSink visitStaticCode(StaticCode code, [StringSink output]) {
    output ??= StringBuffer();
    return output..write(code.code);
  }

  @override
  StringSink visitScopedCode(ScopedCode code, [StringSink output]) {
    output ??= StringBuffer();
    return output..write(code.code(allocator.allocate));
  }
}

/// Represents a code block that requires lazy visiting.
class LazyCode implements Code {
  final Spec Function(SpecVisitor) generate;

  const LazyCode._(this.generate);

  @override
  R accept<R>(CodeVisitor<R> visitor, [R context]) =>
      generate(visitor).accept(visitor, context);
}

/// Returns a generic [Code] that is lazily generated when visited.
Code lazyCode(Code Function() generate) => _LazyCode(generate);

class _LazyCode implements Code {
  final Code Function() generate;

  const _LazyCode(this.generate);

  @override
  R accept<R>(CodeVisitor<R> visitor, [R context]) =>
      generate().accept(visitor, context);
}

/// Represents a simple, literal code block to be inserted as-is.
class StaticCode implements Code {
  final String code;

  const StaticCode._(this.code);

  @override
  R accept<R>(CodeVisitor<R> visitor, [R context]) =>
      visitor.visitStaticCode(this, context);

  @override
  String toString() => code;
}

/// Represents a code block that may require scoping.
class ScopedCode implements Code {
  final String Function(Allocate) code;

  const ScopedCode._(this.code);

  @override
  R accept<R>(CodeVisitor<R> visitor, [R context]) =>
      visitor.visitScopedCode(this, context);

  @override
  String toString() => code((ref) => ref.symbol);
}
