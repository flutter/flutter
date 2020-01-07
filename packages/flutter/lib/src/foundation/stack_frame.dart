// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show hashValues;

import 'package:meta/meta.dart';

/// A object representation of a frame from a stack trace.
///
/// {@tool sample}
///
/// For example, a caller that wishes to traverse the stack could use
///
/// ```dart
/// final List<StackFrame> currentFrames = StackFrame.fromStackTrace(StackTrace.current);
/// ```
///
/// To create a traversable parsed stack.
/// {@end-tool}
@immutable
class StackFrame {
  /// Creates a new StackFrame instance.
  ///
  /// All parameters must not be null. The [className] may be the empty string
  /// if there is no class (e.g. for a top level library method).
  const StackFrame({
    @required this.number,
    @required this.column,
    @required this.line,
    @required this.packageScheme,
    @required this.package,
    @required this.packagePath,
    this.className = '',
    @required this.method,
  })  : assert(number != null),
        assert(column != null),
        assert(line != null),
        assert(method != null),
        assert(packageScheme != null),
        assert(package != null),
        assert(packagePath != null),
        assert(className != null);

  /// Parses a list of [StackFrame]s from a [StackTrace] object.
  ///
  /// This is normally useful with [StackTrace.current].
  static List<StackFrame> fromStackTrace(StackTrace stack) {
    assert(stack != null);
    return fromStackString(stack.toString());
  }

  /// Parses a list of [StackFrame]s from the [StackTrace.toString] method.
  static List<StackFrame> fromStackString(String stack) {
    assert(stack != null);
    return stack
        .trim()
        .split('\n')
        .map(fromStackTraceLine)
        .toList();
  }

  /// Parses a single [StackFrame] from a single line of a [StackTrace].
  static StackFrame fromStackTraceLine(String line) {
    assert(line != null);
    final RegExp parser = RegExp(r'^#(\d+) +(.+) \((.+):(\d+):(\d+)\)$');
    final Match match = parser.firstMatch(line);
    assert(match != null);

    String className = '';
    String method = match.group(2);
    if (method.startsWith('new')) {
      className = method.split(' ')[1];
      method = ctor;
    } else if (method.contains('.')) {
      final List<String> parts = method.split('.');
      className = parts[0];
      method = parts[1];
    }

    final Uri packageUri = Uri.parse(match.group(3));
    return StackFrame(
      number: int.parse(match.group(1)),
      className: className,
      method: method,
      packageScheme: packageUri.scheme,
      package: packageUri.pathSegments[0],
      packagePath: packageUri.path.replaceFirst(packageUri.pathSegments[0] + '/', ''),
      line: int.parse(match.group(4)),
      column: int.parse(match.group(5)),
    );
  }

  /// The identifier used for [method] if the method is the class constructor.
  static const String ctor = 'ctor';

  /// The zero-indexed frame number.
  final int number;

  /// The scheme of the package for this frame, e.g. "dart" for
  /// dart:core/errors_patch.dart or "package" for
  /// package:flutter/src/widgets/text.dart.
  ///
  /// The path property refers to the source file.
  final String packageScheme;

  /// The package for this frame, e.g. "core" for
  /// dart:core/errors_patch.dart or "flutter" for
  /// package:flutter/src/widgets/text.dart.
  final String package;

  /// The path of the file for this frame, e.g. "errors_patch.dart" for
  /// dart:core/errors_patch.dart or "src/widgets/text.dart" for
  /// package:flutter/src/widgets/text.dart.
  final String packagePath;

  /// The source line number.
  final int line;

  /// The source column number.
  final int column;

  /// The class name, if any, for this frame.
  ///
  /// This may be null for top level methods in a library.
  final String className;

  /// The method name for this frame.
  ///
  /// This will be [ctor] if the method is a class constructor.
  final String method;

  /// Whether or not this was thrown from a constructor.
  bool get isConstructor => className == ctor;

  @override
  int get hashCode => hashValues(number, package, line, column, className, method);

  @override
  bool operator ==(Object other) {
    return other is StackFrame &&
        number == other.number &&
        package == other.package &&
        line == other.line &&
        column == other.column &&
        className == other.className &&
        method == other.method;
  }

  @override
  String toString() => '$runtimeType{#$number, $packageScheme:$package/$packagePath:$line:$column, className: $className, method: $method}';
}
