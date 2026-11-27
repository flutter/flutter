// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Lists a hand-written BUILD.bazel repeats from its BUILD.gn, and the check
/// that keeps the two the same.
///
/// The Dart test packages (testing/dart, its vm_service/, the smoke test)
/// are hand-written: GN's file is a `foreach` over a `tests` list, which the
/// evaluator does not unroll, and the run matrix is run_tests.py's, which GN
/// does not have. The macro call carries the same list by hand, so a test
/// added to GN's list would run under GN and not here until someone copied
/// it. [mirroredListMismatches] reads both files and reports a difference,
/// which `gn_to_bazel` counts as a failure in every mode.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'gn_ast.dart';

/// A list a hand-written file repeats: the GN variable it is assigned to at
/// the top of the GN file, and the attribute of the one macro call in the
/// Bazel file that carries it (the same name here).
final class MirroredList {
  const MirroredList(this.name);

  final String name;
}

/// Compares the lists of [lists] (GN package to list) between the GN file
/// and the hand-written BUILD.bazel beside it, both under [tree]'s root.
/// Returns one message per package whose lists differ (or whose files
/// cannot be read as expected); an empty list means they agree.
List<String> mirroredListMismatches(GnSourceTree tree, Map<String, MirroredList> lists) {
  final messages = <String>[];
  for (final MapEntry<String, MirroredList> entry in lists.entries) {
    final String directory = p.join(tree.root, entry.key.substring(2));
    final String gnFile = p.join(directory, 'BUILD.gn');
    final String bazelFile = p.join(directory, 'BUILD.bazel');
    final String name = entry.value.name;
    final List<String>? gnList;
    try {
      gnList = _gnTopLevelList(tree.load(gnFile), name);
    } on GnError catch (e) {
      messages.add('$e');
      continue;
    }
    if (gnList == null) {
      messages.add(
        '${p.relative(gnFile, from: tree.root)}: no top-level `$name = [...]` to mirror',
      );
      continue;
    }
    final bazel = File(bazelFile);
    if (!bazel.existsSync()) {
      messages.add(
        '${p.relative(bazelFile, from: tree.root)}: missing (hand-written; see the manifest)',
      );
      continue;
    }
    final List<String>? bazelList = bazelListAttribute(bazel.readAsStringSync(), name);
    if (bazelList == null) {
      messages.add(
        '${p.relative(bazelFile, from: tree.root)}: expected exactly one `$name = [...]` of '
        'string literals, the list ${p.relative(gnFile, from: tree.root)} assigns `$name`',
      );
      continue;
    }
    final Set<String> missing = gnList.toSet().difference(bazelList.toSet());
    final Set<String> extra = bazelList.toSet().difference(gnList.toSet());
    if (missing.isNotEmpty || extra.isNotEmpty) {
      final parts = <String>[
        if (missing.isNotEmpty) 'missing ${missing.join(', ')}',
        if (extra.isNotEmpty) 'extra ${extra.join(', ')}',
      ];
      messages.add(
        '${p.relative(bazelFile, from: tree.root)}: `$name` differs from '
        "${p.relative(gnFile, from: tree.root)}'s (${parts.join('; ')}); the file is hand-written: "
        'edit its list',
      );
    }
  }
  return messages;
}

/// The strings of the top-level `name = [ "...", ... ]` of [block], or null
/// when there is none.
List<String>? _gnTopLevelList(GnBlock block, String name) {
  for (final GnNode statement in block.statements) {
    if (statement is GnBinary &&
        statement.op == '=' &&
        statement.left is GnIdentifier &&
        (statement.left as GnIdentifier).name == name) {
      final GnNode right = statement.right;
      if (right is! GnList) {
        throw GnError(statement.location, '`$name` is not a list literal');
      }
      return <String>[
        for (final GnNode item in right.items)
          if (item is GnLiteral && item.isString)
            item.stringValue
          else
            throw GnError(item.location, '`$name` holds more than string literals'),
      ];
    }
  }
  return null;
}

/// The string literals of the one `name = [...]` attribute in [starlark]
/// (a hand-written BUILD file, where the list is written out in full), or
/// null when there is not exactly one such attribute or it holds anything
/// but string literals.
List<String>? bazelListAttribute(String starlark, String name) {
  final attribute = RegExp('^\\s*$name\\s*=\\s*\\[', multiLine: true);
  final Iterable<RegExpMatch> matches = attribute.allMatches(starlark);
  if (matches.length != 1) {
    return null;
  }
  final int start = matches.single.end;
  final int end = starlark.indexOf(']', start);
  if (end < 0) {
    return null;
  }
  final String body = starlark.substring(start, end);
  // Items: string literals, commas, whitespace and comments only.
  final item = RegExp(r'"((?:[^"\\]|\\.)*)"|#[^\n]*|[\s,]+');
  final strings = <String>[];
  var position = 0;
  for (final RegExpMatch m in item.allMatches(body)) {
    if (m.start != position) {
      return null;
    }
    position = m.end;
    final String? literal = m.group(1);
    if (literal != null) {
      strings.add(literal);
    }
  }
  if (position != body.length) {
    return null;
  }
  return strings;
}
