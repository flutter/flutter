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

final _pubspec = RegExp(r'^[_]?pubspec\.yaml$');

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

/// Returns `true` if this [fileName] is a Pubspec file.
bool isPubspecFileName(String fileName) => _pubspec.hasMatch(fileName);

class FileSpelunker extends _AbstractSpelunker {
  final String path;
  FileSpelunker(this.path, {super.sink, super.featureSet});
  @override
  String getSource() => File(path).readAsStringSync();
}

@Deprecated('Prefer FileSpelunker')
class Spelunker extends _AbstractSpelunker {
  final String path;
  Spelunker(this.path, {super.sink, super.featureSet});
  @override
  String getSource() => File(path).readAsStringSync();
}

class StringSpelunker extends _AbstractSpelunker {
  final String source;
  StringSpelunker(this.source, {super.sink, super.featureSet});
  @override
  String getSource() => source;
}

abstract class _AbstractSpelunker {
  final IOSink sink;
  FeatureSet featureSet;

  _AbstractSpelunker({IOSink? sink, FeatureSet? featureSet})
      : sink = sink ?? stdout,
        featureSet = featureSet ?? FeatureSet.latestLanguageVersion();

  String getSource();

  void spelunk() {
    var contents = getSource();

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
      '${typeInfo(node.runtimeType)} [${node.toString()}]';

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
    // EOL comments.
    var comments = getPrecedingComments(node.beginToken);
    for (var comment in comments) {
      sink.writeln('${"  " * indent}$comment');
    }

    sink.writeln(
        '${"  " * indent}${asString(node)} ${getTrailingComment(node)}');
  }
}
