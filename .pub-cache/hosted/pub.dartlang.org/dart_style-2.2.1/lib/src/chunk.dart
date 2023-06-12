// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'fast_hash.dart';
import 'nesting_level.dart';
import 'rule/rule.dart';

/// Tracks where a selection start or end point may appear in some piece of
/// text.
abstract class Selection {
  /// The chunk of text.
  String get text;

  /// The offset from the beginning of [text] where the selection starts, or
  /// `null` if the selection does not start within this chunk.
  int? get selectionStart => _selectionStart;
  int? _selectionStart;

  /// The offset from the beginning of [text] where the selection ends, or
  /// `null` if the selection does not start within this chunk.
  int? get selectionEnd => _selectionEnd;
  int? _selectionEnd;

  /// Sets [selectionStart] to be [start] characters into [text].
  void startSelection(int start) {
    _selectionStart = start;
  }

  /// Sets [selectionStart] to be [fromEnd] characters from the end of [text].
  void startSelectionFromEnd(int fromEnd) {
    _selectionStart = text.length - fromEnd;
  }

  /// Sets [selectionEnd] to be [end] characters into [text].
  void endSelection(int end) {
    _selectionEnd = end;
  }

  /// Sets [selectionEnd] to be [fromEnd] characters from the end of [text].
  void endSelectionFromEnd(int fromEnd) {
    _selectionEnd = text.length - fromEnd;
  }
}

/// A chunk of non-breaking output text terminated by a hard or soft newline.
///
/// Chunks are created by [LineWriter] and fed into [LineSplitter]. Each
/// contains some text, along with the data needed to tell how the next line
/// should be formatted and how desireable it is to split after the chunk.
///
/// Line splitting after chunks comes in a few different forms.
///
/// *   A "hard" split is a mandatory newline. The formatted output will contain
///     at least one newline after the chunk's text.
/// *   A "soft" split is a discretionary newline. If a line doesn't fit within
///     the page width, one or more soft splits may be turned into newlines to
///     wrap the line to fit within the bounds. If a soft split is not turned
///     into a newline, it may instead appear as a space or zero-length string
///     in the output, depending on [spaceWhenUnsplit].
/// *   A "double" split expands to two newlines. In other words, it leaves a
///     blank line in the output. Hard or soft splits may be doubled. This is
///     determined by [isDouble].
///
/// A split controls the leading spacing of the subsequent line, both
/// block-based [indent] and expression-wrapping-based [nesting].
class Chunk extends Selection {
  /// The literal text output for the chunk.
  @override
  String get text => _text;
  String _text;

  /// The number of characters of indentation from the left edge of the block
  /// that contains this chunk.
  ///
  /// For top level chunks that are not inside any block, this also includes
  /// leading indentation.
  int? get indent => _indent;
  int? _indent;

  /// The expression nesting level following this chunk.
  ///
  /// This is used to determine how much to increase the indentation when a
  /// line starts after this chunk. A single statement may be indented multiple
  /// times if the splits occur in more deeply nested expressions, for example:
  ///
  ///     // 40 columns                           |
  ///     someFunctionName(argument, argument,
  ///         argument, anotherFunction(argument,
  ///             argument));
  NestingLevel? get nesting => _nesting;
  NestingLevel? _nesting;

  /// If this chunk marks the beginning of a block, this contains the child
  /// chunks and other data about that nested block.
  ///
  /// This should only be accessed when [isBlock] is `true`.
  ChunkBlock get block => _block!;
  ChunkBlock? _block;

  /// Whether this chunk has a [block].
  bool get isBlock => _block != null;

  /// Whether it's valid to add more text to this chunk or not.
  ///
  /// Chunks are built up by adding text and then "capped off" by having their
  /// split information set by calling [handleSplit]. Once the latter has been
  /// called, no more text should be added to the chunk since it would appear
  /// *before* the split.
  bool get canAddText => _rule == null;

  /// The [Rule] that controls when a split should occur after this chunk.
  ///
  /// Multiple splits may share a [Rule].
  Rule? get rule => _rule;
  Rule? _rule;

  /// Whether or not an extra blank line should be output after this chunk if
  /// it's split.
  ///
  /// Internally, this can be either `true`, `false`, or `null`. The latter is
  /// an indeterminate state that lets later modifications to the split decide
  /// whether it should be double or not.
  ///
  /// However, this getter does not expose that. It will return `false` if the
  /// chunk is still indeterminate.
  bool get isDouble => _isDouble ?? false;
  bool? _isDouble;

  /// If `true`, then the line after this chunk should always be at column
  /// zero regardless of any indentation or expression nesting.
  ///
  /// Used for multi-line strings and commented out code.
  bool get flushLeft => _flushLeft;
  bool _flushLeft = false;

  /// If `true`, then the line after this chunk and its contained block should
  /// be flush left.
  bool get flushLeftAfter {
    if (!isBlock) return _flushLeft;

    return block.chunks.last.flushLeftAfter;
  }

  /// Whether this chunk should append an extra space if it does not split.
  ///
  /// This is `true`, for example, in a chunk that ends with a ",".
  bool get spaceWhenUnsplit => _spaceWhenUnsplit;
  bool _spaceWhenUnsplit = false;

  /// Whether this chunk marks the end of a range of chunks that can be line
  /// split independently of the following chunks.
  ///
  /// You must call markDivide() before accessing this.
  bool get canDivide => _canDivide;
  late final bool _canDivide;

  /// The number of characters in this chunk when unsplit.
  int get length => _text.length + (spaceWhenUnsplit ? 1 : 0);

  /// The unsplit length of all of this chunk's block contents.
  ///
  /// Does not include this chunk's own length, just the length of its child
  /// block chunks (recursively).
  int get unsplitBlockLength {
    if (!isBlock) return 0;

    var length = 0;
    for (var chunk in block.chunks) {
      length += chunk.length + chunk.unsplitBlockLength;
    }

    return length;
  }

  /// The [Span]s that contain this chunk.
  final spans = <Span>[];

  /// Creates a new chunk starting with [_text].
  Chunk(this._text);

  /// Creates a dummy chunk.
  ///
  /// This is returned in some places by [ChunkBuilder] when there is no useful
  /// chunk to yield and it will not end up being used by the caller anyway.
  Chunk.dummy() : _text = '(dummy)';

  /// Discard the split for the chunk and put it back into the state where more
  /// text can be appended.
  void allowText() {
    _rule = null;
  }

  /// Append [text] to the end of the split's text.
  void appendText(String text) {
    assert(canAddText);
    _text += text;
  }

  /// Finishes off this chunk with the given [rule] and split information.
  ///
  /// This may be called multiple times on the same split since the splits
  /// produced by walking the source and the splits coming from comments and
  /// preserved whitespace often overlap. When that happens, this has logic to
  /// combine that information into a single split.
  void applySplit(Rule rule, int indent, NestingLevel nesting,
      {bool? flushLeft, bool? isDouble, bool? space}) {
    flushLeft ??= false;
    space ??= false;
    if (rule.isHardened) {
      // A hard split always wins.
      _rule = rule;
    } else {
      _rule ??= rule;
    }

    // Last split settings win.
    _flushLeft = flushLeft;
    _nesting = nesting;
    _indent = indent;

    _spaceWhenUnsplit = space;

    // Pin down the double state, if given and we haven't already.
    _isDouble ??= isDouble;
  }

  /// Turns this chunk into one that can contain a block of child chunks.
  void makeBlock(Chunk? blockArgument, {required bool indent}) {
    assert(_block == null);
    _block = ChunkBlock(blockArgument, indent);
  }

  /// Returns `true` if the block body owned by this chunk should be expression
  /// indented given a set of rule values provided by [getValue].
  bool indentBlock(int Function(Rule) getValue) {
    if (!isBlock) return false;

    var argument = block.argument;
    if (argument == null) return false;

    var rule = argument.rule;

    // There may be no rule if the block occurs inside a string interpolation.
    // In that case, it's not clear if anything will look particularly nice, but
    // expression nesting is probably marginally better.
    if (rule == null) return true;

    return rule.isSplit(getValue(rule), argument);
  }

  // Mark whether this chunk can divide the range of chunks.
  void markDivide(bool canDivide) {
    _canDivide = canDivide;
  }

  @override
  String toString() {
    var parts = [];

    if (text.isNotEmpty) parts.add(text);

    if (_indent != null) parts.add('indent:$_indent');
    if (spaceWhenUnsplit == true) parts.add('space');
    if (_isDouble == true) parts.add('double');
    if (_flushLeft == true) parts.add('flush');

    var rule = _rule;
    if (rule == null) {
      parts.add('(no split)');
    } else {
      parts.add(rule.toString());
      if (rule.isHardened) parts.add('(hard)');

      if (rule.constrainedRules.isNotEmpty) {
        parts.add("-> ${rule.constrainedRules.join(' ')}");
      }
    }

    return parts.join(' ');
  }
}

/// The child chunks owned by a chunk that begins a "block" -- an actual block
/// statement, function expression, or collection literal.
class ChunkBlock {
  /// If this block is for a collection literal in an argument list, this will
  /// be the chunk preceding this literal argument.
  ///
  /// That chunk is owned by the argument list and if it splits, this collection
  /// may need extra expression-level indentation.
  final Chunk? argument;

  /// Whether the first chunk should have a level of indentation before it.
  final bool indent;

  /// The child chunks in this block.
  final List<Chunk> chunks = [];

  ChunkBlock(this.argument, this.indent);
}

/// Constants for the cost heuristics used to determine which set of splits is
/// most desirable.
class Cost {
  /// The cost of splitting after the `=>` in a lambda or arrow-bodied member.
  ///
  /// We make this zero because there is already a span around the entire body
  /// and we generally do prefer splitting after the `=>` over other places.
  static const arrow = 0;

  /// The default cost.
  ///
  /// This isn't zero because we want to ensure all splitting has *some* cost,
  /// otherwise, the formatter won't try to keep things on one line at all.
  /// Most splits and spans use this. Greater costs tend to come from a greater
  /// number of nested spans.
  static const normal = 1;

  /// Splitting after a "=".
  static const assign = 1;

  /// Splitting after a "=" when the right-hand side is a collection or cascade.
  static const assignBlock = 2;

  /// Splitting before the first argument when it happens to be a function
  /// expression with a block body.
  static const firstBlockArgument = 2;

  /// The series of positional arguments.
  static const positionalArguments = 2;

  /// Splitting inside the brackets of a list with only one element.
  static const singleElementList = 2;

  /// Splitting the internals of block arguments.
  ///
  /// Used to prefer splitting at the argument boundary over splitting the block
  /// contents.
  static const splitBlocks = 2;

  /// Splitting on the "." in a named constructor.
  static const constructorName = 4;

  /// Splitting a `[...]` index operator.
  static const index = 4;

  /// Splitting before a type argument or type parameter.
  static const typeArgument = 4;

  /// Split between a formal parameter name and its type.
  static const parameterType = 4;
}

/// The in-progress state for a [Span] that has been started but has not yet
/// been completed.
class OpenSpan {
  /// Index of the first chunk contained in this span.
  final int start;

  /// The cost applied when the span is split across multiple lines or `null`
  /// if the span is for a multisplit.
  final int cost;

  OpenSpan(this.start, this.cost);

  @override
  String toString() => 'OpenSpan($start, \$$cost)';
}

/// Delimits a range of chunks that must end up on the same line to avoid an
/// additional cost.
///
/// These are used to encourage the line splitter to try to keep things
/// together, like parameter lists and binary operator expressions.
///
/// This is a wrapper around the cost so that spans have unique identities.
/// This way we can correctly avoid paying the cost multiple times if the same
/// span is split by multiple chunks.
class Span extends FastHash {
  /// The cost applied when the span is split across multiple lines or `null`
  /// if the span is for a multisplit.
  final int cost;

  Span(this.cost);

  @override
  String toString() => '$id\$$cost';
}

enum CommentType {
  /// A `///` or `/**` doc comment.
  doc,

  /// A non-doc line comment.
  line,

  /// A `/* ... */` comment that should be on its own line.
  block,

  /// A `/* ... */` comment that can share a line with other code.
  inlineBlock,
}

/// A comment in the source, with a bit of information about the surrounding
/// whitespace.
class SourceComment extends Selection {
  /// The text of the comment, including `//`, `/*`, and `*/`.
  @override
  final String text;

  /// What kind of comment this is.
  final CommentType type;

  /// The number of newlines between the comment or token preceding this comment
  /// and the beginning of this one.
  ///
  /// Will be zero if the comment is a trailing one.
  int linesBefore;

  /// Whether this comment starts at column one in the source.
  ///
  /// Comments that start at the start of the line will not be indented in the
  /// output. This way, commented out chunks of code do not get erroneously
  /// re-indented.
  final bool flushLeft;

  SourceComment(this.text, this.type, this.linesBefore,
      {required this.flushLeft});
}
