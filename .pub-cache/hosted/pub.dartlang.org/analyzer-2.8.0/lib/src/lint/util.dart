// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:path/path.dart' as path;

final _identifier = RegExp(r'^([(_|$)a-zA-Z]+([_a-zA-Z0-9])*)$');

final _lowerCamelCase = RegExp(r'^(_)*[?$a-z][a-z0-9?$]*([A-Z][a-z0-9?$]*)*$');

final _lowerCaseUnderScore = RegExp(r'^([a-z]+([_]?[a-z0-9]+)*)+$');

final _lowerCaseUnderScoreWithDots =
    RegExp(r'^[a-z][_a-z0-9]*(\.[a-z][_a-z0-9]*)*$');

final _pubspec = RegExp(r'^[_]?pubspec\.yaml$');

final _underscores = RegExp(r'^[_]+$');

/// Create a library name prefix based on [libraryPath], [projectRoot] and
/// current [packageName].
String createLibraryNamePrefix(
    {required String libraryPath, String? projectRoot, String? packageName}) {
  // Use the posix context to canonicalize separators (`\`).
  var libraryDirectory = path.posix.dirname(libraryPath);
  var relativePath = path.posix.relative(libraryDirectory, from: projectRoot);
  // Drop 'lib/'.
  var segments = path.split(relativePath);
  if (segments[0] == 'lib') {
    relativePath = path.posix.joinAll(segments.sublist(1));
  }
  // Replace separators.
  relativePath = relativePath.replaceAll('/', '.');
  // Add separator if needed.
  if (relativePath.isNotEmpty) {
    relativePath = '.$relativePath';
  }

  return '$packageName$relativePath';
}

/// Returns `true` if this [fileName] is a Dart file.
bool isDartFileName(String fileName) => fileName.endsWith('.dart');

/// Returns `true` if this [name] is a legal Dart identifier.
@deprecated // Never intended for public use.
bool isIdentifier(String name) => _identifier.hasMatch(name);

/// Returns `true` of the given [name] is composed only of `_`s.
@deprecated // Never intended for public use.
bool isJustUnderscores(String name) => _underscores.hasMatch(name);

/// Returns `true` if this [id] is `lowerCamelCase`.
@deprecated // Never intended for public use.
bool isLowerCamelCase(String id) =>
    id.length == 1 && isUpperCase(id.codeUnitAt(0)) ||
    id == '_' ||
    _lowerCamelCase.hasMatch(id);

/// Returns `true` if this [id] is `lower_camel_case_with_underscores`.
@deprecated // Never intended for public use.
bool isLowerCaseUnderScore(String id) => _lowerCaseUnderScore.hasMatch(id);

/// Returns `true` if this [id] is `lower_camel_case_with_underscores_or.dots`.
@deprecated // Never intended for public use.
bool isLowerCaseUnderScoreWithDots(String id) =>
    _lowerCaseUnderScoreWithDots.hasMatch(id);

/// Returns `true` if this [fileName] is a Pubspec file.
bool isPubspecFileName(String fileName) => _pubspec.hasMatch(fileName);

/// Returns `true` if the given code unit [c] is upper case.
@deprecated // Never intended for public use.
bool isUpperCase(int c) => c >= 0x40 && c <= 0x5A;

class Spelunker {
  final String path;
  final IOSink sink;
  FeatureSet featureSet;

  Spelunker(this.path, {IOSink? sink, FeatureSet? featureSet})
      : sink = sink ?? stdout,
        featureSet = featureSet ?? FeatureSet.latestLanguageVersion();

  void spelunk() {
    var contents = File(path).readAsStringSync();

    var parseResult = parseString(
      content: contents,
      featureSet: featureSet,
    );

    var visitor = _SourceVisitor(sink);
    parseResult.unit.accept(visitor);
  }
}

class _SourceVisitor extends GeneralizingAstVisitor {
  int indent = 0;

  final IOSink sink;

  _SourceVisitor(this.sink);

  String asString(AstNode node) =>
      typeInfo(node.runtimeType) + ' [${node.toString()}]';

  List<CommentToken> getPrecedingComments(Token token) {
    var comments = <CommentToken>[];
    var comment = token.precedingComments;
    while (comment is CommentToken) {
      comments.add(comment);
      comment = comment.next as CommentToken?;
    }
    return comments;
  }

  String getTrailingComment(AstNode node) {
    var successor = node.endToken.next;
    if (successor != null) {
      var precedingComments = successor.precedingComments;
      if (precedingComments != null) {
        return precedingComments.toString();
      }
    }
    return '';
  }

  String typeInfo(Type type) => type.toString();

  @override
  void visitNode(AstNode node) {
    write(node);

    ++indent;
    node.visitChildren(this);
    --indent;
  }

  void write(AstNode node) {
    //EOL comments
    var comments = getPrecedingComments(node.beginToken);
    comments.forEach((c) => sink.writeln('${"  " * indent}$c'));

    sink.writeln(
        '${"  " * indent}${asString(node)} ${getTrailingComment(node)}');
  }
}
