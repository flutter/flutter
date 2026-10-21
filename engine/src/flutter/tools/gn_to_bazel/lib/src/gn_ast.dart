// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The GN syntax tree, as `gn format --dump-tree=json` describes it.
///
/// GN's own parser is the only parser: the converter never tokenizes GN
/// text itself. This library turns the JSON dump into typed nodes that keep
/// their source locations, so that every later complaint can name a file
/// and line.
library;

import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// A position in a GN file.
@immutable
final class GnLocation {
  const GnLocation(this.file, this.line, this.column);

  final String file;
  final int line;
  final int column;

  @override
  String toString() => '$file:$line:$column';
}

/// An error about a GN construct, with its location.
final class GnError implements Exception {
  GnError(this.location, this.message) : isUnreadImport = false;

  /// An import of a file the converter's policy neither evaluates nor
  /// knows: the file imports a tree the converter does not read (the Dart
  /// runtime's, abseil's), which is all a dependency resolver needs to know
  /// about it (dependency_resolver.dart), where any other error is the
  /// converter's own.
  GnError.unreadImport(this.location, this.message) : isUnreadImport = true;

  final GnLocation location;
  final String message;
  final bool isUnreadImport;

  @override
  String toString() => '$location: $message';
}

/// A node of the GN syntax tree.
sealed class GnNode {
  GnNode(this.location);

  final GnLocation location;

  /// Comments on the lines before this node (`# ...`, without indentation).
  List<String> beforeComments = const <String>[];

  /// A comment on the same line, after the node.
  List<String> suffixComments = const <String>[];
}

/// `{ ... }` or a whole file.
final class GnBlock extends GnNode {
  GnBlock(super.location, this.statements);

  final List<GnNode> statements;
}

/// `name(args) { block }` -- a target, template invocation, `import`,
/// `foreach`, `assert`, ...
final class GnFunctionCall extends GnNode {
  GnFunctionCall(super.location, this.name, this.args, this.block);

  final String name;
  final List<GnNode> args;
  final GnBlock? block;
}

/// `if (condition) { then } else <orElse>` where `orElse` is a block or a
/// nested condition (`else if`).
final class GnCondition extends GnNode {
  GnCondition(super.location, this.condition, this.thenBlock, this.orElse);

  final GnNode condition;
  final GnBlock thenBlock;
  final GnNode? orElse;
}

/// A binary operator, including the assignments `=`, `+=` and `-=`.
final class GnBinary extends GnNode {
  GnBinary(super.location, this.op, this.left, this.right);

  final String op;
  final GnNode left;
  final GnNode right;

  bool get isAssignment => op == '=' || op == '+=' || op == '-=';
}

/// `!x` or `-x`.
final class GnUnary extends GnNode {
  GnUnary(super.location, this.op, this.operand);

  final String op;
  final GnNode operand;
}

final class GnIdentifier extends GnNode {
  GnIdentifier(super.location, this.name);

  final String name;
}

/// A string, boolean or integer literal.
final class GnLiteral extends GnNode {
  GnLiteral(super.location, this.raw);

  /// The literal as written: strings keep their quotes.
  final String raw;

  bool get isString => raw.startsWith('"');

  bool get isBool => raw == 'true' || raw == 'false';

  bool get isInteger => !isString && !isBool;

  /// The string value without quotes, with GN escapes resolved but `$`
  /// expansions kept verbatim.
  String get stringValue {
    if (!isString) {
      throw GnError(location, 'not a string literal: $raw');
    }
    final String body = raw.substring(1, raw.length - 1);
    final out = StringBuffer();
    for (var i = 0; i < body.length; i++) {
      final String c = body[i];
      if (c == r'\' && i + 1 < body.length) {
        final String next = body[i + 1];
        if (next == '"' || next == r'$' || next == r'\') {
          out.write(next);
          i++;
          continue;
        }
      }
      out.write(c);
    }
    return out.toString();
  }

  /// Whether the string contains a `$` expansion (an unescaped `$`).
  bool get hasExpansion => isString && RegExp(r'(^|[^\\])(\\\\)*\$').hasMatch(raw);

  bool get boolValue => raw == 'true';

  int get intValue => int.parse(raw);
}

/// `[ a, b, ... ]`, or the argument list of a call.
final class GnList extends GnNode {
  GnList(super.location, this.items);

  final List<GnNode> items;
}

/// `base.member` (index is an identifier) or `base[index]`.
final class GnAccessor extends GnNode {
  GnAccessor(super.location, this.base, this.index);

  final String base;
  final GnNode index;
}

/// A comment that stands on its own lines.
final class GnComment extends GnNode {
  GnComment(super.location, this.text);

  final String text;
}

/// Reads the JSON that `gn format --dump-tree=json` wrote for [file].
GnBlock parseGnTree(Object? json, {required String file}) {
  final GnNode node = _GnTreeReader(file).read(json);
  if (node is! GnBlock) {
    throw GnError(node.location, 'expected a BLOCK at the root, got ${node.runtimeType}');
  }
  return node;
}

/// Runs `gn format --dump-tree=json` on [path] and parses the result.
Future<GnBlock> loadGnFile(String path, {required String gnBinary}) async {
  final ProcessResult result = await Process.run(gnBinary, <String>[
    'format',
    '--dump-tree=json',
    path,
  ]);
  if (result.exitCode != 0) {
    throw GnError(GnLocation(path, 0, 0), 'gn format failed: ${result.stderr}');
  }
  return parseGnTree(jsonDecode(result.stdout as String), file: path);
}

/// A GN source tree: resolves `//` paths against the root and loads files
/// (synchronously, as the evaluator needs them for imports), remembering
/// every file read so that a depfile can name them.
///
/// GN's secondary source root (`secondary_source` in `.gn`, the engine's
/// `//flutter/build/secondary/`) is a parallel tree of build files for
/// directories that cannot hold their own; a `BUILD.gn` there stands in for
/// the directory at the same path under the primary root, and `.gni` files
/// there are found when the primary tree lacks them.
final class GnSourceTree {
  GnSourceTree(String root, {required this.gnBinary})
    : root = p.canonicalize(root),
      secondarySource = _secondarySource(p.canonicalize(root));

  /// The directory holding `.gn`.
  final String root;
  final String gnBinary;

  /// The secondary source root as a GN directory (`//flutter/build/secondary`),
  /// or null when `.gn` declares none.
  final String? secondarySource;

  final Map<String, GnBlock> _cache = <String, GnBlock>{};
  final Set<String> _loaded = <String>{};

  /// Every file loaded so far, in load order.
  List<String> get loadedFiles => List<String>.unmodifiable(_loaded);

  static String? _secondarySource(String root) {
    final dotGn = File(p.join(root, '.gn'));
    if (!dotGn.existsSync()) {
      return null;
    }
    final Match? match = RegExp(
      r'^\s*secondary_source\s*=\s*"(//[^"]*?)/?"',
      multiLine: true,
    ).firstMatch(dotGn.readAsStringSync());
    return match?.group(1);
  }

  /// The file for a GN path (`//flutter/fml/BUILD.gn`): under the root, or
  /// under the secondary source root when the root has no such file.
  String resolve(String gnPath) {
    if (!gnPath.startsWith('//')) {
      throw ArgumentError.value(gnPath, 'gnPath', 'not a GN path');
    }
    final String primary = p.join(root, gnPath.substring(2));
    final String? secondary = secondarySource;
    if (secondary == null || File(primary).existsSync()) {
      return primary;
    }
    final String fallback = p.join(root, secondary.substring(2), gnPath.substring(2));
    return File(fallback).existsSync() ? fallback : primary;
  }

  /// The GN path of a file under the root; a file under the secondary
  /// source root is at the path it stands in for.
  String gnPath(String file) {
    final String absolute = p.canonicalize(file);
    if (!p.isWithin(root, absolute)) {
      throw GnError(GnLocation(file, 0, 0), 'not under the GN root $root');
    }
    String relative = p.posix.joinAll(p.split(p.relative(absolute, from: root)));
    final String? secondary = secondarySource;
    if (secondary != null && relative.startsWith('${secondary.substring(2)}/')) {
      relative = relative.substring(secondary.length - 2 + 1);
    }
    return '//$relative';
  }

  /// The GN directory (`//flutter/fml`) of a file under the root.
  String gnDirectory(String file) => p.posix.dirname(gnPath(file));

  /// Loads and parses [file].
  GnBlock load(String file) {
    final String absolute = p.canonicalize(file);
    return _cache.putIfAbsent(absolute, () {
      _loaded.add(absolute);
      final ProcessResult result = Process.runSync(gnBinary, <String>[
        'format',
        '--dump-tree=json',
        absolute,
      ]);
      if (result.exitCode != 0) {
        throw GnError(GnLocation(absolute, 0, 0), 'gn format failed: ${result.stderr}');
      }
      return parseGnTree(jsonDecode(result.stdout as String), file: absolute);
    });
  }
}

final class _GnTreeReader {
  _GnTreeReader(this.file);

  final String file;

  GnNode read(Object? json) {
    if (json is! Map<String, Object?>) {
      throw GnError(GnLocation(file, 0, 0), 'malformed tree node: $json');
    }
    final GnLocation location = _location(json);
    final String type = json['type'] as String? ?? '';
    final String value = json['value'] as String? ?? '';
    final children = <GnNode>[
      for (final Object? child in json['child'] as List<Object?>? ?? const <Object?>[]) read(child),
    ];

    final GnNode node = switch (type) {
      'BLOCK' => GnBlock(location, children),
      'BLOCK_COMMENT' => GnComment(location, value),
      'LIST' => GnList(location, children),
      'LITERAL' => GnLiteral(location, value),
      'IDENTIFIER' => GnIdentifier(location, value),
      'UNARY' => GnUnary(location, value, _single(children, location, 'UNARY')),
      'BINARY' => _binary(location, value, children),
      'ACCESSOR' => GnAccessor(location, value, _single(children, location, 'ACCESSOR')),
      'CONDITION' => _condition(location, children),
      'FUNCTION' => _function(location, value, children),
      _ => throw GnError(location, 'unknown node type $type'),
    };
    node.beforeComments = _comments(json['before_comment']);
    node.suffixComments = _comments(json['suffix_comment']);
    return node;
  }

  GnLocation _location(Map<String, Object?> json) {
    final location = json['location'] as Map<String, Object?>?;
    if (location == null) {
      return GnLocation(file, 0, 0);
    }
    return GnLocation(
      file,
      location['begin_line'] as int? ?? 0,
      location['begin_column'] as int? ?? 0,
    );
  }

  static List<String> _comments(Object? json) {
    if (json is! List<Object?>) {
      return const <String>[];
    }
    return List<String>.unmodifiable(json.cast<String>());
  }

  static GnNode _single(List<GnNode> children, GnLocation location, String type) {
    if (children.length != 1) {
      throw GnError(location, '$type node with ${children.length} children');
    }
    return children.single;
  }

  static GnBinary _binary(GnLocation location, String op, List<GnNode> children) {
    if (children.length != 2) {
      throw GnError(location, 'BINARY node with ${children.length} children');
    }
    return GnBinary(location, op, children[0], children[1]);
  }

  static GnCondition _condition(GnLocation location, List<GnNode> children) {
    if (children.length < 2 || children.length > 3) {
      throw GnError(location, 'CONDITION node with ${children.length} children');
    }
    final GnNode thenBlock = children[1];
    if (thenBlock is! GnBlock) {
      throw GnError(location, 'CONDITION without a block');
    }
    final GnNode? orElse = children.length == 3 ? children[2] : null;
    if (orElse != null && orElse is! GnBlock && orElse is! GnCondition) {
      throw GnError(location, 'else branch is neither a block nor a condition');
    }
    return GnCondition(location, children[0], thenBlock, orElse);
  }

  static GnFunctionCall _function(GnLocation location, String name, List<GnNode> children) {
    if (children.isEmpty || children.first is! GnList) {
      throw GnError(location, 'call of $name without an argument list');
    }
    final List<GnNode> args = (children.first as GnList).items;
    GnBlock? block;
    if (children.length == 2) {
      final GnNode second = children[1];
      if (second is! GnBlock) {
        throw GnError(location, 'call of $name followed by a ${second.runtimeType}');
      }
      block = second;
    } else if (children.length > 2) {
      throw GnError(location, 'call of $name with ${children.length} children');
    }
    return GnFunctionCall(location, name, args, block);
  }
}
