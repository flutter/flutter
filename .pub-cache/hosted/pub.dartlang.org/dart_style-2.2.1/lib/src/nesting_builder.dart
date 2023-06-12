// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_style.src.nesting_builder;

import 'nesting_level.dart';
import 'whitespace.dart';

/// Keeps track of block indentation and expression nesting while the source
/// code is being visited and the chunks are being built.
///
/// This class requires (and verifies) that indentation and nesting are
/// stratified from each other. Expression nesting is always inside block
/// indentation, which means it is an error to try to change the block
/// indentation while any expression nesting is in effect.
class NestingBuilder {
  /// The block indentation levels.
  ///
  /// This is tracked as a stack of numbers, each of which is the total number
  /// of spaces of block indentation. We only store the stack of previous
  /// levels as a convenience to the caller: it spares you from having to pass
  /// the unindent amount to [unindent()].
  final List<int> _stack = [0];

  /// When not `null`, the expression nesting after the next token is written.
  ///
  /// When the nesting is increased, we don't want it to take effect until
  /// after at least one token has been written. That ensures that comments
  /// appearing before the first token are correctly indented. For example, a
  /// binary operator expression increases the nesting before the first operand
  /// to ensure any splits within the left operand are handled correctly. If we
  /// changed the nesting level immediately, then code like:
  ///
  ///     {
  ///       // comment
  ///       foo + bar;
  ///     }
  ///
  /// would incorrectly get indented because the line comment adds a split which
  /// would take the nesting level of the binary operator into account even
  /// though we haven't written any of its tokens yet.
  ///
  /// Likewise, when nesting is decreased, we may want to defer that until
  /// we've written the next token to handle uncommon cases like:
  ///
  ///     do // comment
  ///         {
  ///       ...
  ///     }
  ///
  /// Here, if we discard the expression nesting before we reach the "{", then
  /// it won't get indented as it should.
  NestingLevel? _pendingNesting;

  /// The current number of characters of block indentation.
  int get indentation => _stack.last;

  /// The current nesting, ignoring any pending nesting.
  NestingLevel get nesting => _nesting;
  NestingLevel _nesting = NestingLevel();

  /// The current nesting, including any pending nesting.
  NestingLevel get currentNesting => _pendingNesting ?? _nesting;

  /// Creates a new indentation level [spaces] deeper than the current one.
  ///
  /// If omitted, [spaces] defaults to [Indent.block].
  void indent([int? spaces]) {
    spaces ??= Indent.block;

    // Indentation should only change outside of nesting.
    assert(_pendingNesting == null);
    assert(_nesting.indent == 0);

    _stack.add(_stack.last + spaces);
  }

  /// Discards the most recent indentation level.
  void unindent() {
    // Indentation should only change outside of nesting.
    assert(_pendingNesting == null);
    assert(_nesting.indent == 0);

    // If this fails, an unindent() call did not have a preceding indent() call.
    assert(_stack.isNotEmpty);

    _stack.removeLast();
  }

  /// Begins a new expression nesting level [indent] deeper than the current
  /// one if it splits.
  ///
  /// Expressions that are more nested will get increased indentation when split
  /// if the previous line has a lower level of nesting.
  ///
  /// If [indent] is omitted, defaults to [Indent.expression].
  void nest([int? indent]) {
    indent ??= Indent.expression;

    if (_pendingNesting != null) {
      _pendingNesting = _pendingNesting!.nest(indent);
    } else {
      _pendingNesting = _nesting.nest(indent);
    }
  }

  /// Discards the most recent level of expression nesting.
  void unnest() {
    if (_pendingNesting != null) {
      _pendingNesting = _pendingNesting!.parent;
    } else {
      _pendingNesting = _nesting.parent;
    }

    // If this fails, an unnest() call did not have a preceding nest() call.
    assert(_pendingNesting != null);
  }

  /// Applies any pending nesting now that we are ready for it to take effect.
  void commitNesting() {
    if (_pendingNesting == null) return;

    _nesting = _pendingNesting!;
    _pendingNesting = null;
  }
}
