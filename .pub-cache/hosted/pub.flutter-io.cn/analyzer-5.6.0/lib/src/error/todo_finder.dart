// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/error/codes.dart';

/// Instances of the class `ToDoFinder` find to-do comments in Dart code.
class TodoFinder {
  /// The error reporter by which to-do comments will be reported.
  final ErrorReporter _errorReporter;

  /// A regex for whitespace and comment markers to be removed from the text
  /// of multiline TODOs in multiline comments.
  final RegExp _commentNewlineAndMarker = RegExp('\\s*\\n\\s*\\*\\s*');

  /// A regex for any character that is not a comment marker `/` or whitespace
  /// used for finding the first "real" character of a comment to compare its
  /// indentation for wrapped todos.
  final RegExp _nonWhitespaceOrCommentMarker = RegExp('[^/ ]');

  /// Initialize a newly created to-do finder to report to-do comments to the
  /// given reporter.
  ///
  /// @param errorReporter the error reporter by which to-do comments will be
  ///        reported
  TodoFinder(this._errorReporter);

  /// Search the comments in the given compilation unit for to-do comments and
  /// report an error for each.
  ///
  /// @param unit the compilation unit containing the to-do comments
  void findIn(CompilationUnit unit) {
    _gatherTodoComments(unit.beginToken, unit.lineInfo);
  }

  /// Search the comment tokens reachable from the given token and create errors
  /// for each to-do comment.
  ///
  /// @param token the head of the list of tokens being searched
  void _gatherTodoComments(Token? token, LineInfo lineInfo) {
    while (token != null && !token.isEof) {
      Token? commentToken = token.precedingComments;
      while (commentToken != null) {
        if (commentToken.type == TokenType.SINGLE_LINE_COMMENT ||
            commentToken.type == TokenType.MULTI_LINE_COMMENT) {
          commentToken = _scrapeTodoComment(commentToken, lineInfo);
        } else {
          commentToken = commentToken.next;
        }
      }
      token = token.next;
    }
  }

  /// Look for user defined tasks in comments starting [commentToken] and convert
  /// them into info level analysis issues.
  ///
  /// Subsequent comments that are indented with an additional space are
  /// considered continuations and will be included in a single analysis issue.
  ///
  /// Returns the next comment token to begin searching from (skipping over
  /// any continuations).
  Token? _scrapeTodoComment(Token commentToken, LineInfo lineInfo) {
    Iterable<RegExpMatch> matches =
        Todo.TODO_REGEX.allMatches(commentToken.lexeme);
    // Track the comment that will be returned for looking for the next todo.
    // This will be moved along if additional comments are consumed by multiline
    // TODOs.
    var nextComment = commentToken.next;
    final commentLocation = lineInfo.getLocation(commentToken.offset);

    for (RegExpMatch match in matches) {
      int offset = commentToken.offset + match.start + match.group(1)!.length;
      int column =
          commentLocation.columnNumber + match.start + match.group(1)!.length;
      String todoText = match.group(2)!;
      String todoKind = match.namedGroup('kind1') ?? match.namedGroup('kind2')!;
      int end = offset + todoText.length;

      if (commentToken.type == TokenType.MULTI_LINE_COMMENT) {
        // Remove any `*/` and trim any trailing whitespace.
        if (todoText.endsWith('*/')) {
          todoText = todoText.substring(0, todoText.length - 2).trimRight();
          end = offset + todoText.length;
        }

        // Replace out whitespace/comment markers to unwrap multiple lines.
        // Do not reset length after this, as length must include all characters.
        todoText = todoText.replaceAll(_commentNewlineAndMarker, ' ');
      } else if (commentToken.type == TokenType.SINGLE_LINE_COMMENT) {
        // Append any indented lines onto the end.
        var line = commentLocation.lineNumber;
        while (nextComment != null) {
          final nextCommentLocation = lineInfo.getLocation(nextComment.offset);
          final columnOfFirstNoneMarkerOrWhitespace =
              nextCommentLocation.columnNumber +
                  nextComment.lexeme.indexOf(_nonWhitespaceOrCommentMarker);

          final isContinuation =
              nextComment.type == TokenType.SINGLE_LINE_COMMENT &&
                  // Only consider TODOs on the very next line.
                  nextCommentLocation.lineNumber == line++ + 1 &&
                  // Only consider comment tokens starting at the same column.
                  nextCommentLocation.columnNumber ==
                      commentLocation.columnNumber &&
                  // And indented more than the original 'todo' text.
                  columnOfFirstNoneMarkerOrWhitespace == column + 1 &&
                  // And not their own todos.
                  !Todo.TODO_REGEX.hasMatch(nextComment.lexeme);
          if (!isContinuation) {
            break;
          }

          // Track the end of the continuation for the diagnostic range.
          end = nextComment.end;
          final lexemeTextOffset = columnOfFirstNoneMarkerOrWhitespace -
              nextCommentLocation.columnNumber;
          final continuationText =
              nextComment.lexeme.substring(lexemeTextOffset).trimRight();
          todoText = '$todoText $continuationText';
          nextComment = nextComment.next;
        }
      }

      _errorReporter.reportErrorForOffset(
          Todo.forKind(todoKind), offset, end - offset, [todoText]);
    }

    return nextComment;
  }
}
