// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;

import 'utils.dart';

const _separator = 0x2F; // "/"

/// A node in the abstract syntax tree for a glob.
abstract class AstNode {
  /// The cached regular expression that this AST was compiled into.
  RegExp? _regExp;

  /// Whether this node matches case-sensitively or not.
  final bool caseSensitive;

  /// Whether this glob could match an absolute path.
  ///
  /// Either this or [canMatchRelative] or both will be true.
  bool get canMatchAbsolute => false;

  /// Whether this glob could match a relative path.
  ///
  /// Either this or [canMatchRelative] or both will be true.
  bool get canMatchRelative => true;

  AstNode._(this.caseSensitive);

  /// Returns a new glob with all the options bubbled to the top level.
  ///
  /// In particular, this returns a glob AST with two guarantees:
  ///
  /// 1. There are no [OptionsNode]s other than the one at the top level.
  /// 2. It matches the same set of paths as [this].
  ///
  /// For example, given the glob `{foo,bar}/{click/clack}`, this would return
  /// `{foo/click,foo/clack,bar/click,bar/clack}`.
  OptionsNode flattenOptions() => OptionsNode([
        SequenceNode([this], caseSensitive: caseSensitive)
      ], caseSensitive: caseSensitive);

  /// Returns whether this glob matches [string].
  bool matches(String string) =>
      (_regExp ??= RegExp('^${_toRegExp()}\$', caseSensitive: caseSensitive))
          .hasMatch(string);

  /// Subclasses should override this to return a regular expression component.
  String _toRegExp();
}

/// A sequence of adjacent AST nodes.
class SequenceNode extends AstNode {
  /// The nodes in the sequence.
  final List<AstNode> nodes;

  @override
  bool get canMatchAbsolute => nodes.first.canMatchAbsolute;

  @override
  bool get canMatchRelative => nodes.first.canMatchRelative;

  SequenceNode(Iterable<AstNode> nodes, {bool caseSensitive = true})
      : nodes = nodes.toList(),
        super._(caseSensitive);

  @override
  OptionsNode flattenOptions() {
    if (nodes.isEmpty) {
      return OptionsNode([this], caseSensitive: caseSensitive);
    }

    var sequences =
        nodes.first.flattenOptions().options.map((sequence) => sequence.nodes);
    for (var node in nodes.skip(1)) {
      // Concatenate all sequences in the next options node ([nextSequences])
      // onto all previous sequences ([sequences]).
      var nextSequences = node.flattenOptions().options;
      sequences = sequences.expand((sequence) {
        return nextSequences.map((nextSequence) {
          return sequence.toList()..addAll(nextSequence.nodes);
        });
      });
    }

    return OptionsNode(sequences.map((sequence) {
      // Combine any adjacent LiteralNodes in [sequence].
      return SequenceNode(
          sequence.fold<List<AstNode>>([], (combined, node) {
            if (combined.isEmpty ||
                combined.last is! LiteralNode ||
                node is! LiteralNode) {
              return combined..add(node);
            }

            combined[combined.length - 1] = LiteralNode(
                (combined.last as LiteralNode).text + node.text,
                caseSensitive: caseSensitive);
            return combined;
          }),
          caseSensitive: caseSensitive);
    }), caseSensitive: caseSensitive);
  }

  /// Splits this glob into components along its path separators.
  ///
  /// For example, given the glob `foo/*/*.dart`, this would return three globs:
  /// `foo`, `*`, and `*.dart`.
  ///
  /// Path separators within options nodes are not split. For example,
  /// `foo/{bar,baz/bang}/qux` will return three globs: `foo`, `{bar,baz/bang}`,
  /// and `qux`.
  ///
  /// [context] is used to determine what absolute roots look like for this
  /// glob.
  List<SequenceNode> split(p.Context context) {
    var componentsToReturn = <SequenceNode>[];
    List<AstNode>? currentComponent;

    void addNode(AstNode node) {
      (currentComponent ??= []).add(node);
    }

    void finishComponent() {
      if (currentComponent == null) return;
      componentsToReturn
          .add(SequenceNode(currentComponent!, caseSensitive: caseSensitive));
      currentComponent = null;
    }

    for (var node in nodes) {
      if (node is! LiteralNode) {
        addNode(node);
        continue;
      }

      if (!node.text.contains('/')) {
        addNode(node);
        continue;
      }

      var text = node.text;
      if (context.style == p.Style.windows) text = text.replaceAll('/', '\\');
      Iterable<String> components = context.split(text);

      // If the first component is absolute, that means it's a separator (on
      // Windows some non-separator things are also absolute, but it's invalid
      // to have "C:" show up in the middle of a path anyway).
      if (context.isAbsolute(components.first)) {
        // If this is the first component, it's the root.
        if (componentsToReturn.isEmpty && currentComponent == null) {
          var root = components.first;
          if (context.style == p.Style.windows) {
            // Above, we switched to backslashes to make [context.split] handle
            // roots properly. That means that if there is a root, it'll still
            // have backslashes, where forward slashes are required for globs.
            // So we switch it back here.
            root = root.replaceAll('\\', '/');
          }
          addNode(LiteralNode(root, caseSensitive: caseSensitive));
        }
        finishComponent();
        components = components.skip(1);
        if (components.isEmpty) continue;
      }

      // For each component except the last one, add a separate sequence to
      // [sequences] containing only that component.
      for (var component in components.take(components.length - 1)) {
        addNode(LiteralNode(component, caseSensitive: caseSensitive));
        finishComponent();
      }

      // For the final component, only end its sequence (by adding a new empty
      // sequence) if it ends with a separator.
      addNode(LiteralNode(components.last, caseSensitive: caseSensitive));
      if (node.text.endsWith('/')) finishComponent();
    }

    finishComponent();
    return componentsToReturn;
  }

  @override
  String _toRegExp() => nodes.map((node) => node._toRegExp()).join();

  @override
  bool operator ==(Object other) =>
      other is SequenceNode &&
      const IterableEquality().equals(nodes, other.nodes);

  @override
  int get hashCode => const IterableEquality().hash(nodes);

  @override
  String toString() => nodes.join();
}

/// A node matching zero or more non-separator characters.
class StarNode extends AstNode {
  StarNode({bool caseSensitive = true}) : super._(caseSensitive);

  @override
  String _toRegExp() => '[^/]*';

  @override
  bool operator ==(Object other) => other is StarNode;

  @override
  int get hashCode => 0;

  @override
  String toString() => '*';
}

/// A node matching zero or more characters that may be separators.
class DoubleStarNode extends AstNode {
  /// The path context for the glob.
  ///
  /// This is used to determine what absolute paths look like.
  final p.Context _context;

  DoubleStarNode(this._context, {bool caseSensitive = true})
      : super._(caseSensitive);

  @override
  String _toRegExp() {
    // Double star shouldn't match paths with a leading "../", since these paths
    // wouldn't be listed with this glob. We only check for "../" at the
    // beginning since the paths are normalized before being checked against the
    // glob.
    var buffer = StringBuffer()..write(r'(?!^(?:\.\./|');

    // A double star at the beginning of the glob also shouldn't match absolute
    // paths, since those also wouldn't be listed. Which root patterns we look
    // for depends on the style of path we're matching.
    if (_context.style == p.Style.posix) {
      buffer.write(r'/');
    } else if (_context.style == p.Style.windows) {
      buffer.write(r'//|[A-Za-z]:/');
    } else {
      assert(_context.style == p.Style.url);
      buffer.write(r'[a-zA-Z][-+.a-zA-Z\d]*://|/');
    }

    // Use `[^]` rather than `.` so that it matches newlines as well.
    buffer.write(r'))[^]*');

    return buffer.toString();
  }

  @override
  bool operator ==(Object other) => other is DoubleStarNode;

  @override
  int get hashCode => 1;

  @override
  String toString() => '**';
}

/// A node matching a single non-separator character.
class AnyCharNode extends AstNode {
  AnyCharNode({bool caseSensitive = true}) : super._(caseSensitive);

  @override
  String _toRegExp() => '[^/]';

  @override
  bool operator ==(Object other) => other is AnyCharNode;

  @override
  int get hashCode => 2;

  @override
  String toString() => '?';
}

/// A node matching a single character in a range of options.
class RangeNode extends AstNode {
  /// The ranges matched by this node.
  ///
  /// The ends of the ranges are unicode code points.
  final Set<Range> ranges;

  /// Whether this range was negated.
  final bool negated;

  RangeNode(Iterable<Range> ranges,
      {required this.negated, bool caseSensitive = true})
      : ranges = ranges.toSet(),
        super._(caseSensitive);

  @override
  OptionsNode flattenOptions() {
    if (negated || ranges.any((range) => !range.isSingleton)) {
      return super.flattenOptions();
    }

    // If a range explicitly lists a set of characters, return each character as
    // a separate expansion.
    return OptionsNode(ranges.map((range) {
      return SequenceNode([
        LiteralNode(String.fromCharCodes([range.min]),
            caseSensitive: caseSensitive)
      ], caseSensitive: caseSensitive);
    }), caseSensitive: caseSensitive);
  }

  @override
  String _toRegExp() {
    var buffer = StringBuffer();

    var containsSeparator = ranges.any((range) => range.contains(_separator));
    if (!negated && containsSeparator) {
      // Add `(?!/)` because ranges are never allowed to match separators.
      buffer.write('(?!/)');
    }

    buffer.write('[');
    if (negated) {
      buffer.write('^');
      // If the range doesn't itself exclude separators, exclude them ourselves,
      // since ranges are never allowed to match them.
      if (!containsSeparator) buffer.write('/');
    }

    for (var range in ranges) {
      var start = String.fromCharCodes([range.min]);
      buffer.write(regExpQuote(start));
      if (range.isSingleton) continue;
      buffer.write('-');
      buffer.write(regExpQuote(String.fromCharCodes([range.max])));
    }

    buffer.write(']');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      other is RangeNode &&
      other.negated == negated &&
      SetEquality().equals(ranges, other.ranges);

  @override
  int get hashCode => (negated ? 1 : 3) * const SetEquality().hash(ranges);

  @override
  String toString() {
    var buffer = StringBuffer()..write('[');
    for (var range in ranges) {
      buffer.writeCharCode(range.min);
      if (range.isSingleton) continue;
      buffer.write('-');
      buffer.writeCharCode(range.max);
    }
    buffer.write(']');
    return buffer.toString();
  }
}

/// A node that matches one of several options.
class OptionsNode extends AstNode {
  /// The options to match.
  final List<SequenceNode> options;

  @override
  bool get canMatchAbsolute => options.any((node) => node.canMatchAbsolute);

  @override
  bool get canMatchRelative => options.any((node) => node.canMatchRelative);

  OptionsNode(Iterable<SequenceNode> options, {bool caseSensitive = true})
      : options = options.toList(),
        super._(caseSensitive);

  @override
  OptionsNode flattenOptions() =>
      OptionsNode(options.expand((option) => option.flattenOptions().options),
          caseSensitive: caseSensitive);

  @override
  String _toRegExp() =>
      '(?:${options.map((option) => option._toRegExp()).join("|")})';

  @override
  bool operator ==(Object other) =>
      other is OptionsNode &&
      const UnorderedIterableEquality().equals(options, other.options);

  @override
  int get hashCode => const UnorderedIterableEquality().hash(options);

  @override
  String toString() => '{${options.join(',')}}';
}

/// A node that matches a literal string.
class LiteralNode extends AstNode {
  /// The string to match.
  final String text;

  /// The path context for the glob.
  ///
  /// This is used to determine whether this could match an absolute path.
  final p.Context? _context;

  @override
  bool get canMatchAbsolute {
    var nativeText =
        _context!.style == p.Style.windows ? text.replaceAll('/', '\\') : text;
    return _context!.isAbsolute(nativeText);
  }

  @override
  bool get canMatchRelative => !canMatchAbsolute;

  LiteralNode(this.text, {p.Context? context, bool caseSensitive = true})
      : _context = context,
        super._(caseSensitive);

  @override
  String _toRegExp() => regExpQuote(text);

  @override
  bool operator ==(Object other) => other is LiteralNode && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => text;
}
