// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/pub.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;

Pubspec? _findAndParsePubspec(Directory root) {
  if (root.existsSync()) {
    var pubspec = root
        .listSync(followLinks: false)
        .whereType<File>()
        .firstWhereOrNull((f) => isPubspecFile(f));
    if (pubspec != null) {
      return Pubspec.parse(pubspec.readAsStringSync(),
          sourceUrl: p.toUri(pubspec.path));
    }
  }
  return null;
}

/// A semantic representation of a Dart project.
///
/// Projects provide a semantic model of a Dart project based on the
/// [pub package layout conventions](https://dart.dev/tools/pub/package-layout).
/// This model allows clients to traverse project contents in a convenient and
/// standardized way, access global information (such as whether elements are
/// in the "public API") and resources that have special meanings in the
/// context of pub package layout conventions.
class DartProject {
  late final _ApiModel _apiModel;
  String? _name;
  Pubspec? _pubspec;

  /// Project root.
  final Directory root;

  /// Create a Dart project for the corresponding [analysisSession] and [files].
  /// If a [dir] is unspecified the current working directory will be
  /// used.
  ///
  /// Note: clients should call [create] which performs API model initialization.
  DartProject._(AnalysisSession analysisSession, List<String> files,
      {Directory? dir})
      : root = dir ?? Directory.current {
    _pubspec = _findAndParsePubspec(root);
    _apiModel = _ApiModel(analysisSession, files, root);
  }

  /// The project's name.
  ///
  /// Project names correspond to the package name as specified in the project's
  /// [pubspec]. The pubspec is found relative to the project [root].  If no
  /// pubspec can be found, the name defaults to the project root basename.
  String get name => _name ??= _calculateName();

  /// The project's pubspec.
  Pubspec? get pubspec => _pubspec;

  /// Returns `true` if the given element is part of this project's public API.
  ///
  /// Public API elements are defined as all elements that are in the packages's
  /// `lib` directory, *less* those in `lib/src` (which are treated as private
  /// *implementation files*), plus elements having been explicitly exported
  /// via an `export` directive.
  bool isApi(Element element) => _apiModel.contains(element);

  String _calculateName() {
    final pubspec = this.pubspec;
    if (pubspec != null) {
      var nameEntry = pubspec.name;
      if (nameEntry != null) {
        return nameEntry.value.text!;
      }
    }
    return p.basename(root.path);
  }

  /// Create an initialized Dart project for the corresponding [analysisSession]
  /// and [files].
  /// If a [dir] is unspecified the current working directory will be
  /// used.
  static Future<DartProject> create(
      AnalysisSession analysisSession, List<String> files,
      {Directory? dir}) async {
    DartProject project = DartProject._(analysisSession, files, dir: dir);
    await project._apiModel._calculate();
    return project;
  }
}

/// An object that can be used to visit Dart project structure.
abstract class ProjectVisitor<T> {
  T? visit(DartProject project) => null;
}

/// Captures the project's API as defined by pub package layout standards.
class _ApiModel {
  final AnalysisSession analysisSession;
  final List<String> files;
  final Directory root;
  final Set<Element> elements = {};

  _ApiModel(this.analysisSession, this.files, this.root) {
    _calculate();
  }

  /// Return `true` if this element is part of the public API for this package.
  bool contains(Element? element) {
    while (element != null) {
      if (!element.isPrivate && elements.contains(element)) {
        return true;
      }
      element = element.enclosingElement;
    }
    return false;
  }

  Future<void> _calculate() async {
    if (files.isEmpty) {
      return;
    }

    String libDir = root.path + '/lib';
    String libSrcDir = libDir + '/src';

    for (var file in files) {
      if (file.startsWith(libDir) && !file.startsWith(libSrcDir)) {
        var result = await analysisSession.getResolvedUnit(file);
        if (result is ResolvedUnitResult) {
          LibraryElement library = result.libraryElement;

          NamespaceBuilder namespaceBuilder = NamespaceBuilder();
          Namespace exports =
              namespaceBuilder.createExportNamespaceForLibrary(library);
          Namespace public =
              namespaceBuilder.createPublicNamespaceForLibrary(library);
          elements.addAll(exports.definedNames.values);
          elements.addAll(public.definedNames.values);
        }
      }
    }
  }
}
