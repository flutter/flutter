// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';

// It is hard to visually separate each code's _doc comment_ from its published
// _documentation comment_ when each is written as an end-of-line comment.
// ignore_for_file: slash_for_doc_comments

/// Static helper methods and properties for working with [TodoCode]s.
class Todo {
  static const _codes = {
    'TODO': TodoCode.TODO,
    'FIXME': TodoCode.FIXME,
    'HACK': TodoCode.HACK,
    'UNDONE': TodoCode.UNDONE,
  };

  /// This matches the two common Dart task styles
  ///
  /// * TODO:
  /// * TODO(username):
  ///
  /// As well as
  /// * TODO
  ///
  /// But not
  /// * todo
  /// * TODOS
  ///
  /// It also supports wrapped TODOs where the next line is indented by a space:
  ///
  ///   /**
  ///    * TODO(username): This line is
  ///    *  wrapped onto the next line
  ///    */
  ///
  /// The matched kind of the TODO (TODO, FIXME, etc.) is returned in named
  /// captures of "kind1", "kind2" (since it is not possible to reuse a name
  /// across different parts of the regex).
  static RegExp TODO_REGEX = RegExp(
      '([\\s/\\*])(((?<kind1>$_TODO_KIND_PATTERN)[^\\w\\d][^\\r\\n]*(?:\\n\\s*\\*  [^\\r\\n]*)*)'
      '|((?<kind2>$_TODO_KIND_PATTERN):?\$))');

  static final _TODO_KIND_PATTERN = _codes.keys.join('|');

  Todo._() {
    throw UnimplementedError('Do not construct');
  }

  /// Returns the TodoCode for [kind], falling back to [TodoCode.TODO].
  static TodoCode forKind(String kind) => _codes[kind] ?? TodoCode.TODO;
}

/**
 * The error code indicating a marker in code for work that needs to be finished
 * or revisited.
 */
class TodoCode extends ErrorCode {
  /**
   * A standard TODO comment marked as TODO.
   */
  static const TodoCode TODO = TodoCode('TODO');

  /**
   * A TODO comment marked as FIXME.
   */
  static const TodoCode FIXME = TodoCode('FIXME');

  /**
   * A TODO comment marked as HACK.
   */
  static const TodoCode HACK = TodoCode('HACK');

  /**
   * A TODO comment marked as UNDONE.
   */
  static const TodoCode UNDONE = TodoCode('UNDONE');

  /**
   * Initialize a newly created error code to have the given [name].
   */
  const TodoCode(String name)
      : super(
          problemMessage: "{0}",
          name: name,
          uniqueName: 'TodoCode.$name',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.INFO;

  @override
  ErrorType get type => ErrorType.TODO;
}
