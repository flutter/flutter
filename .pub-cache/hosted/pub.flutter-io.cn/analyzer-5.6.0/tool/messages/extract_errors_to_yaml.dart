// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This script extracts data from the analyzer classes derived from `ErrorCode`
// (as well as the comments next to their declarations) and produces a
// `messages.yaml` file capturing the same information.  In the future, we will
// generate the `ErrorCode` derived classes from this `messages.yaml` file.
//
// TODO(paulberry): once code generation is in place, remove this script.

import 'dart:convert';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/error/todo_codes.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer_utilities/package_root.dart' as pkg_root;
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

import 'error_code_info.dart';

main() {
  var errorDeclarations = _findErrorDeclarations();
  var errorCodesByClass = _findErrorCodesByClass();
  _generateYaml(errorCodesByClass, errorDeclarations);
}

/// The path to the `analyzer` package.
final String _analyzerPkgPath =
    normalize(join(pkg_root.packageRoot, 'analyzer'));

/// Encodes [yaml] into a string parseable as YAML.
///
/// YAML is complex and we are just trying to do a good enough job for a one
/// shot generation of a `messages.yaml` file, so instead of trying to
/// exhaustively implement the YAML standard, we have a heuristic
/// implementation, and then we double check that we can parse the result and
/// get back the original data structures.
String _encodeYaml(Map<Object?, Object?> yaml) {
  var out = StringBuffer();
  void visit(Map<Object?, Object?> yaml, String prefix) {
    for (var entry in yaml.entries) {
      var keyPart = '$prefix${entry.key}:';
      var value = entry.value;
      if (value is Map<Object?, Object?>) {
        out.writeln(keyPart);
        visit(value, '$prefix  ');
      } else if (value is String) {
        if (value.contains('\n')) {
          if (value.trim() != value) {
            throw 'TODO(paulberry): handle a string with leading or trailing '
                'whitespace';
          }
          out.writeln('$keyPart |-');
          var indented = value.replaceAll(RegExp('\n(?!\n)'), '\n$prefix  ');
          out.writeln('$prefix  $indented');
        } else if (value.contains('{') ||
            value.contains(':') ||
            value.contains("'") ||
            value.trim() != value) {
          out.writeln('$keyPart ${json.encode(value)}');
        } else {
          out.writeln('$keyPart $value');
        }
      } else if (value is bool) {
        out.writeln('$keyPart $value');
      } else {
        throw 'TODO(paulberry): encode ${value.runtimeType}';
      }
    }
  }

  visit(yaml, '');
  var result = out.toString();

  // Double check that the result parses correctly.
  try {
    var parsedYaml = loadYaml(result);
    if (json.encode(yaml) != json.encode(parsedYaml)) {
      throw 'YAML did match after parsing';
    }
  } on Object {
    print('=== Error in yaml file ===');
    print(result);
    print('===');
    rethrow;
  }
  return result;
}

/// Extract comments from the parsed AST of a field declaration, so that we can
/// include them in the YAML output.
_CommentInfo _extractCommentInfo(FieldDeclaration fieldDeclaration) {
  var firstToken = fieldDeclaration.metadata.beginToken ??
      fieldDeclaration.firstTokenAfterCommentAndMetadata;
  var commentToken = firstToken.precedingComments;
  StringBuffer? documentationComment;
  StringBuffer? otherComment;
  while (commentToken != null) {
    var lexeme = commentToken.lexeme;
    if (lexeme.startsWith('///')) {
      (documentationComment ??= StringBuffer())
          .writeln(lexeme.replaceFirst(RegExp('/// ?'), '').trimRight());
    } else if (lexeme.startsWith('/**')) {
      (documentationComment ??= StringBuffer()).writeln(lexeme
          .substring(0, lexeme.length - 2)
          .replaceFirst(RegExp('/\\*\\*\n?'), '')
          .replaceAll(RegExp(' *\\* ?'), '')
          .trimRight());
    } else if (lexeme.startsWith('//')) {
      (otherComment ??= StringBuffer())
          .writeln(lexeme.replaceFirst(RegExp('// ?'), '').trimRight());
    } else if (lexeme.startsWith('/*')) {
      (otherComment ??= StringBuffer()).writeln(lexeme
          .substring(0, lexeme.length - 2)
          .replaceFirst(RegExp('/\\*(\n| )?'), '')
          .replaceAll(RegExp(' *(\\*|//) ?'), '')
          .trimRight());
    } else {
      throw 'Unexpected comment type: ${json.encode(lexeme)}';
    }
    commentToken = commentToken.next as CommentToken?;
  }
  return _CommentInfo(
      documentationComment: documentationComment?.toString().trim(),
      otherComment: otherComment?.toString().trim());
}

/// Computes a map from class name to a list of all the error codes defined by
/// that class.  Uses the analyzer's global variable `errorCodeValues` to find
/// all the error codes.
Map<String, List<ErrorCode>> _findErrorCodesByClass() {
  var errorCodesByClass = <String, List<ErrorCode>>{};
  for (var errorCode in errorCodeValues) {
    if (errorCode is ScannerErrorCode) {
      continue; // Will deal with later
    }
    if (errorCode is TodoCode) {
      continue; // It's not worth converting these to YAML.
    }
    var className = errorCode.runtimeType.toString();
    (errorCodesByClass[className] ??= []).add(errorCode);
  }
  return errorCodesByClass;
}

/// Finds all the variable declaration ASTs in the analyzer that might represent
/// error codes.  The result is a two-tiered map, indexed first by class name
/// and then by error code name.
Map<String, Map<String, VariableDeclaration>> _findErrorDeclarations() {
  var filePaths = [
    join(_analyzerPkgPath, 'lib', 'src', 'analysis_options', 'error',
        'option_codes.dart'),
    join(_analyzerPkgPath, 'lib', 'src', 'dart', 'error', 'ffi_code.dart'),
    join(_analyzerPkgPath, 'lib', 'src', 'dart', 'error', 'hint_codes.dart'),
    join(_analyzerPkgPath, 'lib', 'src', 'dart', 'error',
        'syntactic_errors.dart'),
    join(_analyzerPkgPath, 'lib', 'src', 'error', 'codes.dart'),
    join(_analyzerPkgPath, 'lib', 'src', 'manifest',
        'manifest_warning_code.dart'),
    join(
        _analyzerPkgPath, 'lib', 'src', 'pubspec', 'pubspec_warning_code.dart'),
  ];
  var result = <String, Map<String, VariableDeclaration>>{};
  for (var filePath in filePaths) {
    var unit = parseFile(
            path: filePath, featureSet: FeatureSet.latestLanguageVersion())
        .unit;
    for (var declaration in unit.declarations) {
      if (declaration is! ClassDeclaration) continue;
      var className = declaration.name.lexeme;
      for (var member in declaration.members) {
        if (member is! FieldDeclaration) continue;
        for (var variable in member.fields.variables) {
          (result[className] ??= {})[variable.name.lexeme] = variable;
        }
      }
    }
  }
  return result;
}

/// Combines the information in [errorCodesByClass] (obtained from
/// [_findErrorCodesByClass]) and [errorDeclarations] (obtained from
/// [_findErrorDeclarations]) into a YAML representation of the errors, and
/// prints the resulting YAML.
void _generateYaml(Map<String, List<ErrorCode>> errorCodesByClass,
    Map<String, Map<String, VariableDeclaration>> errorDeclarations) {
  var yaml = <String, Map<String, Object?>>{};
  for (var entry in errorCodesByClass.entries) {
    var yamlCodes = <String, Object?>{};
    var className = entry.key;
    yaml[className] = yamlCodes;
    entry.value.sort((a, b) => a.name.compareTo(b.name));
    for (var code in entry.value) {
      var name = code.name;
      var uniqueName = code.uniqueName;
      if (!uniqueName.startsWith('$className.')) {
        throw 'Unexpected unique name ${json.encode(uniqueName)}';
      }
      var uniqueNameSuffix = uniqueName.substring(className.length + 1);
      if (uniqueNameSuffix.contains('.')) {
        throw 'Unexpected unique name ${json.encode(uniqueName)}';
      }
      var classDeclaration = errorDeclarations[className];
      if (classDeclaration == null) {
        throw 'Could not find class declaration for $className';
      }
      var declaration = classDeclaration[uniqueNameSuffix];
      if (declaration == null) {
        throw 'Could not find declaration for $className.$uniqueNameSuffix';
      }
      var variableDeclarationList =
          declaration.parent as VariableDeclarationList;
      var fieldDeclaration = variableDeclarationList.parent as FieldDeclaration;
      var commentInfo = _extractCommentInfo(fieldDeclaration);
      var documentationComment = commentInfo.documentationComment;
      var otherComment = commentInfo.otherComment;
      yamlCodes[uniqueNameSuffix] = AnalyzerErrorCodeInfo(
              sharedName: uniqueNameSuffix == name ? null : name,
              problemMessage: code.problemMessage,
              correctionMessage: code.correctionMessage,
              isUnresolvedIdentifier: code.isUnresolvedIdentifier,
              hasPublishedDocs: code.hasPublishedDocs,
              comment: documentationComment,
              documentation: otherComment)
          .toYaml();
    }
  }
  String encodedYaml = _encodeYaml(yaml);
  print(encodedYaml);
}

class _CommentInfo {
  final String? documentationComment;

  final String? otherComment;

  _CommentInfo({this.documentationComment, this.otherComment});
}
