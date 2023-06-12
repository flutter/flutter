// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:math' as math;

import 'chunk.dart';
import 'dart_formatter.dart';
import 'debug.dart' as debug;
import 'line_writer.dart';
import 'nesting_builder.dart';
import 'nesting_level.dart';
import 'rule/rule.dart';
import 'source_code.dart';
import 'style_fix.dart';
import 'whitespace.dart';

/// Matches if the last character of a string is an identifier character.
final _trailingIdentifierChar = RegExp(r'[a-zA-Z0-9_]$');

/// Matches a JavaDoc-style doc comment that starts with "/**" and ends with
/// "*/" or "**/".
final _javaDocComment = RegExp(r'^/\*\*([^*/][\s\S]*?)\*?\*/$');

/// Matches the leading "*" in a line in the middle of a JavaDoc-style comment.
final _javaDocLine = RegExp(r'^\s*\*(.*)');

/// Matches spaces at the beginning of as string.
final _leadingIndentation = RegExp(r'^(\s*)');

/// Takes the incremental serialized output of [SourceVisitor]--the source text
/// along with any comments and preserved whitespace--and produces a coherent
/// tree of [Chunk]s which can then be split into physical lines.
///
/// Keeps track of leading indentation, expression nesting, and all of the hairy
/// code required to seamlessly integrate existing comments into the pure
/// output produced by [SourceVisitor].
class ChunkBuilder {
  final DartFormatter _formatter;

  /// The builder for the code surrounding the block that this writer is for, or
  /// `null` if this is writing the top-level code.
  final ChunkBuilder? _parent;

  final SourceCode _source;

  final List<Chunk> _chunks;

  /// The whitespace that should be written to [_chunks] before the next
  ///  non-whitespace token.
  ///
  /// This ensures that changes to indentation and nesting also apply to the
  /// most recent split, even if the visitor "creates" the split before changing
  /// indentation or nesting.
  Whitespace _pendingWhitespace = Whitespace.none;

  /// The nested stack of rules that are currently in use.
  ///
  /// New chunks are implicitly split by the innermost rule when the chunk is
  /// ended.
  final _rules = <Rule>[];

  /// The set of rules known to contain hard splits that will in turn force
  /// these rules to harden.
  ///
  /// This is accumulated lazily while chunks are being built. Then, once they
  /// are all done, the rules are all hardened. We do this later because some
  /// rules may not have all of their constraints fully wired up until after
  /// the hard split appears. For example, a hard split in a positional
  /// argument list needs to force the named arguments to split too, but we
  /// don't create that rule until after the positional arguments are done.
  final _hardSplitRules = <Rule>{};

  /// The list of rules that are waiting until the next whitespace has been
  /// written before they start.
  final _lazyRules = <Rule>[];

  /// The nested stack of spans that are currently being written.
  final _openSpans = <OpenSpan>[];

  /// The current state.
  final _nesting = NestingBuilder();

  /// The stack of nesting levels where block arguments may start.
  ///
  /// A block argument's contents will nest at the last level in this stack.
  final _blockArgumentNesting = <NestingLevel>[];

  /// The index of the "current" chunk being written.
  ///
  /// If the last chunk is still being appended to, this is its index.
  /// Otherwise, it is the index of the next chunk which will be created.
  int get _currentChunkIndex {
    if (_chunks.isEmpty) return 0;
    if (_chunks.last.canAddText) return _chunks.length - 1;
    return _chunks.length;
  }

  /// Whether or not there was a leading comment that was flush left before any
  /// other content was written.
  ///
  /// This is used when writing child blocks to make the parent chunk have the
  /// right flush left value when a comment appears immediately inside the
  /// block.
  bool _firstFlushLeft = false;

  /// The number of calls to [preventSplit()] that have not been ended by a
  /// call to [endPreventSplit()].
  ///
  /// Splitting is completely disabled inside string interpolation. We do want
  /// to fix the whitespace inside interpolation, though, so we still format
  /// them. This tracks whether we're inside an interpolation. We can't use a
  /// simple bool because interpolation can nest.
  ///
  /// When this is non-zero, splits are ignored.
  int _preventSplitNesting = 0;

  /// Whether there is pending whitespace that depends on the number of
  /// newlines in the source.
  ///
  /// This is used to avoid calculating the newlines between tokens unless
  /// actually needed since doing so is slow when done between every single
  /// token pair.
  bool get needsToPreserveNewlines =>
      _pendingWhitespace == Whitespace.oneOrTwoNewlines ||
      _pendingWhitespace == Whitespace.splitOrTwoNewlines ||
      _pendingWhitespace == Whitespace.splitOrNewline;

  /// The number of characters of code that can fit in a single line.
  int get pageWidth => _formatter.pageWidth;

  /// The current innermost rule.
  Rule get rule => _rules.last;

  ChunkBuilder(this._formatter, this._source)
      : _parent = null,
        _chunks = [] {
    indent(_formatter.indent);
    startBlockArgumentNesting();
  }

  ChunkBuilder._(this._parent, this._formatter, this._source, this._chunks) {
    startBlockArgumentNesting();
  }

  /// Writes [string], the text for a single token, to the output.
  ///
  /// By default, this also implicitly adds one level of nesting if we aren't
  /// currently nested at all. We do this here so that if a comment appears
  /// after any token within a statement or top-level form and that comment
  /// leads to splitting, we correctly nest. Even pathological cases like:
  ///
  ///
  ///     import // comment
  ///         "this_gets_nested.dart";
  ///
  /// If we didn't do this here, we'd have to call [nestExpression] after the
  /// first token of practically every grammar production.
  void write(String string) {
    _emitPendingWhitespace();
    _writeText(string);

    _lazyRules.forEach(_activateRule);
    _lazyRules.clear();

    _nesting.commitNesting();
  }

  /// Writes a [WhitespaceChunk] of [type].
  void writeWhitespace(Whitespace type) {
    _pendingWhitespace = type;
  }

  /// Write a split owned by the current innermost rule.
  ///
  /// If [flushLeft] is `true`, then forces the next line to start at column
  /// one regardless of any indentation or nesting.
  ///
  /// If [isDouble] is passed, forces the split to either be a single or double
  /// newline. Otherwise, leaves it indeterminate.
  ///
  /// If [nest] is `false`, ignores any current expression nesting. Otherwise,
  /// uses the current nesting level. If unsplit, it expands to a space if
  /// [space] is `true`.
  Chunk split({bool? flushLeft, bool? isDouble, bool? nest, bool? space}) {
    space ??= false;

    // If we are not allowed to split at all, don't. Returning null for the
    // chunk is safe since the rule that uses the chunk will itself get
    // discarded because no chunk references it.
    if (_preventSplitNesting > 0) {
      if (space) _pendingWhitespace = Whitespace.space;
      return Chunk.dummy();
    }

    return _writeSplit(_rules.last,
        flushLeft: flushLeft, isDouble: isDouble, nest: nest, space: space);
  }

  /// Outputs the series of [comments] and associated whitespace that appear
  /// before [token] (which is not written by this).
  ///
  /// The list contains each comment as it appeared in the source between the
  /// last token written and the next one that's about to be written.
  ///
  /// [linesBeforeToken] is the number of lines between the last comment (or
  /// previous token if there are no comments) and the next token.
  void writeComments(
      List<SourceComment> comments, int linesBeforeToken, String token) {
    // Edge case: if we require a blank line, but there exists one between
    // some of the comments, or after the last one, then we don't need to
    // enforce one before the first comment. Example:
    //
    //     library foo;
    //     // comment
    //
    //     class Bar {}
    //
    // Normally, a blank line is required after `library`, but since there is
    // one after the comment, we don't need one before it. This is mainly so
    // that commented out directives stick with their preceding group.
    if (_pendingWhitespace == Whitespace.twoNewlines &&
        comments.first.linesBefore < 2) {
      if (linesBeforeToken > 1) {
        _pendingWhitespace = Whitespace.newline;
      } else {
        for (var i = 1; i < comments.length; i++) {
          if (comments[i].linesBefore > 1) {
            _pendingWhitespace = Whitespace.newline;
            break;
          }
        }
      }
    }

    // Edge case: if the previous output was also from a call to
    // [writeComments()] which ended with a line comment, force a newline.
    // Normally, comments are strictly interleaved with tokens and you never
    // get two sequences of comments in a row. However, when applying a fix
    // that removes a token (like `new`), it's possible to get two sets of
    // comments in a row, as in:
    //
    //     // a
    //     new // b
    //     Foo();
    //
    // When that happens, we need to make sure to preserve the split at the end
    // of the first sequence of comments if there is one.
    if (_pendingWhitespace == Whitespace.afterHardSplit) {
      comments.first.linesBefore = 1;
      _pendingWhitespace = Whitespace.none;
    }

    // Edge case: if the comments are completely inline (i.e. just a series of
    // block comments with no newlines before, after, or between them), then
    // they will eat any pending newlines. Make sure that doesn't happen by
    // putting the pending whitespace before the first comment. Turns this:
    //
    //     library foo; /* a */ /* b */ import 'a.dart';
    //
    // into:
    //
    //     library foo;
    //
    //     /* a */ /* b */ import 'a.dart';
    if (linesBeforeToken == 0 &&
        _pendingWhitespace.minimumLines > comments.first.linesBefore &&
        comments.every((comment) => comment.type == CommentType.inlineBlock)) {
      comments.first.linesBefore = _pendingWhitespace.minimumLines;
    }

    // Write each comment and the whitespace between them.
    for (var i = 0; i < comments.length; i++) {
      var comment = comments[i];

      preserveNewlines(comment.linesBefore);

      // Don't emit a space because we'll handle it below. If we emit it here,
      // we may get a trailing space if the comment needs a line before it.
      if (_pendingWhitespace == Whitespace.space) {
        _pendingWhitespace = Whitespace.none;
      }
      _emitPendingWhitespace();

      // See if the comment should follow text on the current line.
      if (comment.linesBefore == 0 || comment.type == CommentType.inlineBlock) {
        // If we're sitting on a split, move the comment before it to adhere it
        // to the preceding text.
        if (_shouldMoveCommentBeforeSplit(comment)) {
          _chunks.last.allowText();
        }

        // The comment follows other text, so we need to decide if it gets a
        // space before it or not.
        if (_needsSpaceBeforeComment(comment)) _writeText(' ');
      } else {
        // The comment is not inline, so start a new line.
        _writeHardSplit(
            flushLeft: comment.flushLeft,
            isDouble: comment.linesBefore > 1,
            nest: true);
      }

      _writeCommentText(comment);

      if (comment.selectionStart != null) {
        startSelectionFromEnd(comment.text.length - comment.selectionStart!);
      }

      if (comment.selectionEnd != null) {
        endSelectionFromEnd(comment.text.length - comment.selectionEnd!);
      }

      // Make sure there is at least one newline after a line comment and allow
      // one or two after a block comment that has nothing after it.
      int linesAfter;
      if (i < comments.length - 1) {
        linesAfter = comments[i + 1].linesBefore;
      } else {
        linesAfter = linesBeforeToken;

        // Always force a newline after multi-line block comments. Prevents
        // mistakes like:
        //
        //     /**
        //      * Some doc comment.
        //      */ someFunction() { ... }
        if (linesAfter == 0 && comments.last.text.contains('\n')) {
          linesAfter = 1;
        }
      }

      if (linesAfter > 0) _writeHardSplit(isDouble: linesAfter > 1, nest: true);
    }

    // If the comment has text following it (aside from a grouping character),
    // it needs a trailing space.
    if (_needsSpaceAfterLastComment(comments, token)) {
      _pendingWhitespace = Whitespace.space;
    }

    preserveNewlines(linesBeforeToken);
  }

  /// Writes the text of [comment].
  ///
  /// If it's a JavaDoc comment that should be fixed to use `///`, fixes it.
  void _writeCommentText(SourceComment comment) {
    if (!_formatter.fixes.contains(StyleFix.docComments)) {
      _writeText(comment.text);
      return;
    }

    // See if it's a JavaDoc comment.
    var match = _javaDocComment.firstMatch(comment.text);
    if (match == null) {
      _writeText(comment.text);
      return;
    }

    var lines = match[1]!.split('\n').toList();
    var leastIndentation = comment.text.length;

    for (var i = 0; i < lines.length; i++) {
      // Trim trailing whitespace and turn any all-whitespace lines to "".
      var line = lines[i].trimRight();

      // Remove any leading "*" from the middle lines.
      if (i > 0 && i < lines.length - 1) {
        var match = _javaDocLine.firstMatch(line);
        if (match != null) {
          line = match[1]!;
        }
      }

      // Find the line with the least indentation.
      if (line.isNotEmpty) {
        var indentation = _leadingIndentation.firstMatch(line)![1]!.length;
        leastIndentation = math.min(leastIndentation, indentation);
      }

      lines[i] = line;
    }

    // Trim the first and last lines if empty.
    if (lines.first.isEmpty) lines.removeAt(0);
    if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();

    // Don't completely eliminate an empty block comment.
    if (lines.isEmpty) lines.add('');

    for (var line in lines) {
      _writeText('///');
      if (line.isNotEmpty) {
        // Discard any indentation shared by all lines.
        line = line.substring(leastIndentation);
        _writeText(' $line');
      }
      _pendingWhitespace = Whitespace.newline;
      _emitPendingWhitespace();
    }
  }

  /// If the current pending whitespace allows some source discretion, pins
  /// that down given that the source contains [numLines] newlines at that
  /// point.
  void preserveNewlines(int numLines) {
    // If we didn't know how many newlines the user authored between the last
    // token and this one, now we do.
    switch (_pendingWhitespace) {
      case Whitespace.splitOrNewline:
        if (numLines > 0) {
          _pendingWhitespace = Whitespace.nestedNewline;
        } else {
          _pendingWhitespace = Whitespace.none;
          split(space: true);
        }
        break;

      case Whitespace.splitOrTwoNewlines:
        if (numLines > 1) {
          _pendingWhitespace = Whitespace.twoNewlines;
        } else {
          _pendingWhitespace = Whitespace.none;
          split(space: true);
        }
        break;

      case Whitespace.oneOrTwoNewlines:
        if (numLines > 1) {
          _pendingWhitespace = Whitespace.twoNewlines;
        } else {
          _pendingWhitespace = Whitespace.newline;
        }
        break;
      default:
        break;
    }
  }

  /// Creates a new indentation level [spaces] deeper than the current one.
  ///
  /// If omitted, [spaces] defaults to [Indent.block].
  void indent([int? spaces]) {
    _nesting.indent(spaces);
  }

  /// Discards the most recent indentation level.
  void unindent() {
    _nesting.unindent();
  }

  /// Starts a new span with [cost].
  ///
  /// Each call to this needs a later matching call to [endSpan].
  void startSpan([int cost = Cost.normal]) {
    _openSpans.add(OpenSpan(_currentChunkIndex, cost));
  }

  /// Ends the innermost span.
  void endSpan() {
    var openSpan = _openSpans.removeLast();

    // A span that just covers a single chunk can't be split anyway.
    var end = _currentChunkIndex;
    if (openSpan.start == end) return;

    // Add the span to every chunk that can split it.
    var span = Span(openSpan.cost);
    for (var i = openSpan.start; i < end; i++) {
      var chunk = _chunks[i];
      if (!chunk.rule!.isHardened) chunk.spans.add(span);
    }
  }

  /// Starts a new [Rule].
  ///
  /// If omitted, defaults to a new [Rule].
  void startRule([Rule? rule]) {
    rule ??= Rule();

    // If there are any pending lazy rules, start them now so that the proper
    // stack ordering of rules is maintained.
    _lazyRules.forEach(_activateRule);
    _lazyRules.clear();

    _activateRule(rule);
  }

  void _activateRule(Rule rule) {
    // See if any of the rules that contain this one care if it splits.
    for (var outer in _rules) {
      if (!outer.splitsOnInnerRules) continue;
      rule.imply(outer);
    }
    _rules.add(rule);
  }

  /// Starts a new [Rule] that comes into play *after* the next whitespace
  /// (including comments) is written.
  ///
  /// This is used for operators who want to start a rule before the first
  /// operand but not get forced to split if a comment appears before the
  /// entire expression.
  ///
  /// If [rule] is omitted, defaults to a new [Rule].
  void startLazyRule([Rule? rule]) {
    rule ??= Rule();

    _lazyRules.add(rule);
  }

  /// Ends the innermost rule.
  void endRule() {
    if (_lazyRules.isNotEmpty) {
      _lazyRules.removeLast();
    } else {
      _rules.removeLast();
    }
  }

  /// Pre-emptively forces all of the current rules to become hard splits.
  ///
  /// This is called by [SourceVisitor] when it can determine that a rule will
  /// will always be split. Turning it (and the surrounding rules) into hard
  /// splits lets the writer break the output into smaller pieces for the line
  /// splitter, which helps performance and avoids failing on very large input.
  ///
  /// In particular, it's easy for the visitor to know that collections with a
  /// large number of items must split. Doing that early avoids crashing the
  /// splitter when it tries to recurse on huge collection literals.
  void forceRules() => _handleHardSplit();

  /// Begins a new expression nesting level [indent] spaces deeper than the
  /// current one if it splits.
  ///
  /// If [indent] is omitted, defaults to [Indent.expression]. If [now] is
  /// `true`, commits the nesting change immediately instead of waiting until
  /// after the next chunk of text is written.
  void nestExpression({int? indent, bool? now}) {
    now ??= false;

    _nesting.nest(indent);
    if (now) _nesting.commitNesting();
  }

  /// Discards the most recent level of expression nesting.
  ///
  /// Expressions that are more nested will get increased indentation when split
  /// if the previous line has a lower level of nesting.
  ///
  /// If [now] is `false`, does not commit the nesting change until after the
  /// next chunk of text is written.
  void unnest({bool? now}) {
    now ??= true;

    _nesting.unnest();
    if (now) _nesting.commitNesting();
  }

  /// Marks the selection starting point as occurring [fromEnd] characters to
  /// the left of the end of what's currently been written.
  ///
  /// It counts backwards from the end because this is called *after* the chunk
  /// of text containing the selection has been output.
  void startSelectionFromEnd(int fromEnd) {
    assert(_chunks.isNotEmpty);
    _chunks.last.startSelectionFromEnd(fromEnd);
  }

  /// Marks the selection ending point as occurring [fromEnd] characters to the
  /// left of the end of what's currently been written.
  ///
  /// It counts backwards from the end because this is called *after* the chunk
  /// of text containing the selection has been output.
  void endSelectionFromEnd(int fromEnd) {
    assert(_chunks.isNotEmpty);
    _chunks.last.endSelectionFromEnd(fromEnd);
  }

  /// Captures the current nesting level as marking where subsequent block
  /// arguments should start.
  void startBlockArgumentNesting() {
    _blockArgumentNesting.add(_nesting.currentNesting);
  }

  /// Releases the last nesting level captured by [startBlockArgumentNesting].
  void endBlockArgumentNesting() {
    _blockArgumentNesting.removeLast();
  }

  /// Starts a new block as a child of the current chunk.
  ///
  /// Nested blocks are handled using their own independent [LineWriter]. If
  /// [indent] is `false` then the first line of the block will not get a level
  /// of leading indentation. Otherwise it does.
  ChunkBuilder startBlock(Chunk? argumentChunk, {bool indent = true}) {
    var chunk = _chunks.last;
    chunk.makeBlock(argumentChunk, indent: indent);

    var builder = ChunkBuilder._(this, _formatter, _source, chunk.block.chunks);
    if (indent) builder.indent();

    return builder;
  }

  /// Ends this [ChunkBuilder], which must have been created by [startBlock()].
  ///
  /// Forces the chunk that owns the block to split if it can tell that the
  /// block contents will always split. It does that by looking for hard splits
  /// in the block. If [ignoredSplit] is given, that rule will be ignored
  /// when determining if a block contains a hard split. If [forceSplit] is
  /// `true`, the block is considered to always split.
  ///
  /// Returns the previous writer for the surrounding block.
  ChunkBuilder endBlock(Rule? ignoredSplit, {required bool forceSplit}) {
    _divideChunks();

    // If we don't already know if the block is going to split, see if it
    // contains any hard splits or is longer than a page.
    if (!forceSplit) {
      var length = 0;
      for (var chunk in _chunks) {
        length += chunk.length + chunk.unsplitBlockLength;
        if (length > _formatter.pageWidth) {
          forceSplit = true;
          break;
        }

        if (chunk.rule != null &&
            chunk.rule!.isHardened &&
            chunk.rule != ignoredSplit) {
          forceSplit = true;
          break;
        }
      }
    }

    _parent!._endChildBlock(
        firstFlushLeft: _firstFlushLeft, forceSplit: forceSplit);
    return _parent!;
  }

  /// Finishes off the last chunk in a child block of this parent.
  void _endChildBlock({bool? firstFlushLeft, required bool forceSplit}) {
    // If there is a hard newline within the block, force the surrounding rule
    // for it so that we apply that constraint.
    if (forceSplit) forceRules();

    // Write the split for the block contents themselves.
    var chunk = _chunks.last;
    chunk.applySplit(rule, _nesting.indentation, _blockArgumentNesting.last,
        flushLeft: firstFlushLeft);

    if (chunk.rule!.isHardened) _handleHardSplit();
  }

  /// Finishes writing and returns a [SourceCode] containing the final output
  /// and updated selection, if any.
  SourceCode end() {
    assert(_rules.isEmpty);

    _writeHardSplit();
    _divideChunks();

    if (debug.traceChunkBuilder) {
      debug.log(debug.green('\nBuilt:'));
      debug.dumpChunks(0, _chunks);
      debug.log();
    }

    var writer = LineWriter(_formatter, _chunks);
    var result = writer.writeLines(_formatter.indent,
        isCompilationUnit: _source.isCompilationUnit);

    int? selectionStart;
    int? selectionLength;
    if (_source.selectionStart != null) {
      selectionStart = result.selectionStart;
      var selectionEnd = result.selectionEnd;

      // If we haven't hit the beginning and/or end of the selection yet, they
      // must be at the very end of the code.
      selectionStart ??= writer.length;
      selectionEnd ??= writer.length;

      selectionLength = selectionEnd - selectionStart;
    }

    return SourceCode(result.text,
        uri: _source.uri,
        isCompilationUnit: _source.isCompilationUnit,
        selectionStart: selectionStart,
        selectionLength: selectionLength);
  }

  void preventSplit() {
    _preventSplitNesting++;
  }

  void endPreventSplit() {
    _preventSplitNesting--;
    assert(_preventSplitNesting >= 0, 'Mismatched calls.');
  }

  /// Writes the current pending [Whitespace] to the output, if any.
  ///
  /// This should only be called after source lines have been preserved to turn
  /// any ambiguous whitespace into a concrete choice.
  void _emitPendingWhitespace() {
    // Output any pending whitespace first now that we know it won't be
    // trailing.
    switch (_pendingWhitespace) {
      case Whitespace.space:
        _writeText(' ');
        break;

      case Whitespace.newline:
        _writeHardSplit();
        break;

      case Whitespace.nestedNewline:
        _writeHardSplit(nest: true);
        break;

      case Whitespace.newlineFlushLeft:
        _writeHardSplit(flushLeft: true, nest: true);
        break;

      case Whitespace.twoNewlines:
        _writeHardSplit(isDouble: true);
        break;

      case Whitespace.splitOrNewline:
      case Whitespace.splitOrTwoNewlines:
      case Whitespace.oneOrTwoNewlines:
        // We should have pinned these down before getting here.
        assert(false);
        break;
      default:
        break;
    }

    _pendingWhitespace = Whitespace.none;
  }

  /// Returns `true` if the last chunk is a split that should be moved after the
  /// comment that is about to be written.
  bool _shouldMoveCommentBeforeSplit(SourceComment comment) {
    // Not if there is nothing before it.
    if (_chunks.isEmpty) return false;

    // Don't move a comment to a preceding line.
    if (comment.linesBefore != 0) return false;

    // Multi-line comments are always pushed to the next line.
    if (comment.type == CommentType.doc) return false;
    if (comment.type == CommentType.block) return false;

    var text = _chunks.last.text;

    // A block comment following a comma probably refers to the following item.
    if (text.endsWith(',') && comment.type == CommentType.inlineBlock) {
      return false;
    }

    // If the text before the split is an open grouping character, it looks
    // better to keep it with the elements than with the bracket itself.
    return !text.endsWith('(') && !text.endsWith('[') && !text.endsWith('{');
  }

  /// Returns `true` if [comment] appears to be a magic generic method comment.
  ///
  /// Those get spaced a little differently to look more like real syntax:
  ///
  ///     int f/*<S, T>*/(int x) => 3;
  bool _isGenericMethodComment(SourceComment comment) {
    return comment.text.startsWith('/*<') || comment.text.startsWith('/*=');
  }

  /// Returns `true` if a space should be output between the end of the current
  /// output and the subsequent comment which is about to be written.
  ///
  /// This is only called if the comment is trailing text in the unformatted
  /// source. In most cases, a space will be output to separate the comment
  /// from what precedes it. This returns false if:
  ///
  /// *   This comment does begin the line in the output even if it didn't in
  ///     the source.
  /// *   The comment is a block comment immediately following a grouping
  ///     character (`(`, `[`, or `{`). This is to allow `foo(/* comment */)`,
  ///     et. al.
  bool _needsSpaceBeforeComment(SourceComment comment) {
    // Not at the start of the file.
    if (_chunks.isEmpty) return false;

    // Not at the start of a line.
    if (!_chunks.last.canAddText) return false;

    // Always put a space before line comments.
    if (comment.type == CommentType.line) return true;

    // Magic generic method comments like "Foo/*<T>*/" don't get spaces.
    var text = _chunks.last.text;
    if (_isGenericMethodComment(comment) &&
        _trailingIdentifierChar.hasMatch(text)) {
      return false;
    }

    // Block comments do not get a space if following a grouping character.
    return !text.endsWith('(') && !text.endsWith('[') && !text.endsWith('{');
  }

  /// Returns `true` if a space should be output after the last comment which
  /// was just written and the token that will be written.
  bool _needsSpaceAfterLastComment(List<SourceComment> comments, String token) {
    // Not if there are no comments.
    if (comments.isEmpty) return false;

    // Not at the beginning of a line.
    if (!_chunks.last.canAddText) return false;

    // Magic generic method comments like "Foo/*<T>*/" don't get spaces.
    if (_isGenericMethodComment(comments.last) && token == '(') {
      return false;
    }

    // Otherwise, it gets a space if the following token is not a delimiter or
    // the empty string, for EOF.
    return token != ')' &&
        token != ']' &&
        token != '}' &&
        token != ',' &&
        token != ';' &&
        token != '';
  }

  /// Appends a hard split with the current indentation and nesting (the latter
  /// only if [nest] is `true`).
  ///
  /// If [double] is `true` or `false`, forces a single or double line to be
  /// output. Otherwise, it is left indeterminate.
  ///
  /// If [flushLeft] is `true`, then the split will always cause the next line
  /// to be at column zero. Otherwise, it uses the normal indentation and
  /// nesting behavior.
  void _writeHardSplit({bool? isDouble, bool? flushLeft, bool nest = false}) {
    // A hard split overrides any other whitespace.
    _pendingWhitespace = Whitespace.afterHardSplit;
    _writeSplit(Rule.hard(),
        flushLeft: flushLeft, isDouble: isDouble, nest: nest);
  }

  /// Ends the current chunk (if any) with the given split information.
  ///
  /// Returns the chunk.
  Chunk _writeSplit(Rule rule,
      {bool? flushLeft, bool? isDouble, bool? nest, bool? space}) {
    nest ??= true;
    space ??= false;

    if (_chunks.isEmpty) {
      if (flushLeft != null) _firstFlushLeft = flushLeft;
      return Chunk.dummy();
    }

    _chunks.last.applySplit(
        rule, _nesting.indentation, nest ? _nesting.nesting : NestingLevel(),
        flushLeft: flushLeft, isDouble: isDouble, space: space);

    if (_chunks.last.rule!.isHardened) _handleHardSplit();
    return _chunks.last;
  }

  /// Writes [text] to either the current chunk or a new one if the current
  /// chunk is complete.
  void _writeText(String text) {
    if (_chunks.isNotEmpty && _chunks.last.canAddText) {
      _chunks.last.appendText(text);
    } else {
      _chunks.add(Chunk(text));
    }
  }

  /// Returns true if we can divide the chunks at [index] and line split the
  /// ones before and after that separately.
  bool _canDivideAt(int i) {
    // Don't divide after the last chunk.
    if (i == _chunks.length - 1) return false;

    var chunk = _chunks[i];
    if (!chunk.rule!.isHardened) return false;
    if (chunk.nesting!.isNested) return false;
    if (chunk.isBlock) return false;

    return true;
  }

  /// Pre-processes the chunks after they are done being written by the visitor
  /// but before they are run through the line splitter.
  ///
  /// Marks ranges of chunks that can be line split independently to keep the
  /// batches we send to [LineSplitter] small.
  void _divideChunks() {
    // Harden all of the rules that we know get forced by containing hard
    // splits, along with all of the other rules they constrain.
    _hardenRules();

    // Now that we know where all of the divided chunk sections are, mark the
    // chunks.
    for (var i = 0; i < _chunks.length; i++) {
      _chunks[i].markDivide(_canDivideAt(i));
    }
  }

  /// Hardens the active rules when a hard split occurs within them.
  void _handleHardSplit() {
    if (_rules.isEmpty) return;

    // If the current rule doesn't care, it will "eat" the hard split and no
    // others will care either.
    if (!_rules.last.splitsOnInnerRules) return;

    // Start with the innermost rule. This will traverse the other rules it
    // constrains.
    _hardSplitRules.add(_rules.last);
  }

  /// Replaces all of the previously hardened rules with hard splits, along
  /// with every rule that those constrain to also split.
  ///
  /// This should only be called after all chunks have been written.
  void _hardenRules() {
    if (_hardSplitRules.isEmpty) return;

    void walkConstraints(Rule rule) {
      rule.harden();

      // Follow this rule's constraints, recursively.
      for (var other in rule.constrainedRules) {
        if (other == rule) continue;

        if (!other.isHardened &&
            rule.constrain(rule.fullySplitValue, other) ==
                other.fullySplitValue) {
          walkConstraints(other);
        }
      }
    }

    for (var rule in _hardSplitRules) {
      walkConstraints(rule);
    }

    // Discard spans in hardened chunks since we know for certain they will
    // split anyway.
    for (var chunk in _chunks) {
      if (chunk.rule != null && chunk.rule!.isHardened) {
        chunk.spans.clear();
      }
    }
  }
}
