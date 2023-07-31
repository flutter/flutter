// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';
import 'package:analyzer/src/lint/linter.dart';

/// Current linter version.
String? linterVersion;

/// Shared lint registry.
LintRegistry lintRegistry = LintRegistry();

/// Implementers contribute lint warnings via the provided error [reporter].
abstract class Linter implements NodeLintRule {
  /// Used to report lint warnings.
  /// NOTE: this is set by the framework before visit begins.
  late ErrorReporter reporter;

  /// Return the lint code associated with this linter.
  LintCode? get lintCode => null;

  /// Return the lint codes associated with this lint rule.
  List<LintCode> get lintCodes {
    var code = lintCode;
    if (code == null) {
      return const <LintCode>[];
    }
    return <LintCode>[code];
  }

  /// Linter name.
  String get name;

  /// Return a visitor to be passed to compilation units to perform lint
  /// analysis.
  /// Lint errors are reported via this [Linter]'s error [reporter].
  @Deprecated('Use registerNodeProcessors() instead.')
  AstVisitor? getVisitor();

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {}
}

/// Manages lint timing.
class LintRegistry {
  /// Dictionary mapping lints (by name) to timers.
  final Map<String, Stopwatch> timers = HashMap<String, Stopwatch>();

  /// Get a timer associated with the given lint rule (or create one if none
  /// exists).
  Stopwatch getTimer(Linter linter) =>
      timers.putIfAbsent(linter.name, () => Stopwatch());
}
