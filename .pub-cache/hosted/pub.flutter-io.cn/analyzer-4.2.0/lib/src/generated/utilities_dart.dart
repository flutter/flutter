// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart' show AnnotatedNode;
import 'package:analyzer/dart/ast/token.dart' show Token;
import 'package:analyzer/src/dart/element/element.dart' show ElementImpl;

export 'package:_fe_analyzer_shared/src/util/resolve_relative_uri.dart'
    show resolveRelativeUri;

/// If the given [node] has a documentation comment, remember its content
/// and range into the given [element].
void setElementDocumentationComment(ElementImpl element, AnnotatedNode node) {
  var comment = node.documentationComment;
  if (comment != null && comment.isDocumentation) {
    element.documentationComment =
        comment.tokens.map((Token t) => t.lexeme).join('\n');
  }
}

/// Check whether [uri1] starts with (or 'is prefixed by') [uri2] by checking
/// path segments.
bool startsWith(Uri uri1, Uri uri2) {
  List<String> uri1Segments = uri1.pathSegments;
  List<String> uri2Segments = uri2.pathSegments.toList();
  // Punt if empty (https://github.com/dart-lang/sdk/issues/24126)
  if (uri2Segments.isEmpty) {
    return false;
  }
  // Trim trailing empty segments ('/foo/' => ['foo', ''])
  if (uri2Segments.last == '') {
    uri2Segments.removeLast();
  }

  if (uri2Segments.length > uri1Segments.length) {
    return false;
  }

  for (int i = 0; i < uri2Segments.length; ++i) {
    if (uri2Segments[i] != uri1Segments[i]) {
      return false;
    }
  }
  return true;
}

/// The kind of a parameter. A parameter can be either positional or named, and
/// can be either required or optional.
class ParameterKind implements Comparable<ParameterKind> {
  /// A positional required parameter.
  static const ParameterKind REQUIRED = ParameterKind(
    name: 'REQUIRED',
    ordinal: 0,
    isPositional: true,
    isRequiredPositional: true,
    isOptionalPositional: false,
    isNamed: false,
    isRequiredNamed: false,
    isOptionalNamed: false,
    isRequired: true,
    isOptional: false,
  );

  /// A positional optional parameter.
  static const ParameterKind POSITIONAL = ParameterKind(
    name: 'POSITIONAL',
    ordinal: 1,
    isPositional: true,
    isRequiredPositional: false,
    isOptionalPositional: true,
    isNamed: false,
    isRequiredNamed: false,
    isOptionalNamed: false,
    isRequired: false,
    isOptional: true,
  );

  /// A named required parameter.
  static const ParameterKind NAMED_REQUIRED = ParameterKind(
    name: 'NAMED_REQUIRED',
    ordinal: 2,
    isPositional: false,
    isRequiredPositional: false,
    isOptionalPositional: false,
    isNamed: true,
    isRequiredNamed: true,
    isOptionalNamed: false,
    isRequired: true,
    isOptional: false,
  );

  /// A named optional parameter.
  static const ParameterKind NAMED = ParameterKind(
    name: 'NAMED',
    ordinal: 3,
    isPositional: false,
    isRequiredPositional: false,
    isOptionalPositional: false,
    isNamed: true,
    isRequiredNamed: false,
    isOptionalNamed: true,
    isRequired: false,
    isOptional: true,
  );

  static const List<ParameterKind> values = [
    REQUIRED,
    POSITIONAL,
    NAMED_REQUIRED,
    NAMED
  ];

  /// The name of this parameter.
  final String name;

  /// The ordinal value of the parameter.
  final int ordinal;

  /// Return `true` if is a positional parameter.
  ///
  /// Positional parameters can either be required or optional.
  final bool isPositional;

  /// Return `true` if both a required and positional parameter.
  final bool isRequiredPositional;

  /// Return `true` if both an optional and positional parameter.
  final bool isOptionalPositional;

  /// Return `true` if a named parameter.
  ///
  /// Named parameters can either be required or optional.
  final bool isNamed;

  /// Return `true` if both a required and named parameter.
  ///
  /// Note: this will return `false` for a named parameter that is annotated
  /// with the `@required` annotation.
  final bool isRequiredNamed;

  /// Return `true` if both an optional and named parameter.
  final bool isOptionalNamed;

  /// Return `true` if a required parameter.
  ///
  /// Required parameters can either be positional or named.
  ///
  /// Note: this will return `false` for a named parameter that is annotated
  /// with the `@required` annotation.
  final bool isRequired;

  /// Return `true` if an optional parameter.
  ///
  /// Optional parameters can either be positional or named.
  final bool isOptional;

  /// Initialize a newly created kind with the given state.
  const ParameterKind({
    required this.name,
    required this.ordinal,
    required this.isPositional,
    required this.isRequiredPositional,
    required this.isOptionalPositional,
    required this.isNamed,
    required this.isRequiredNamed,
    required this.isOptionalNamed,
    required this.isRequired,
    required this.isOptional,
  });

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(ParameterKind other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}
