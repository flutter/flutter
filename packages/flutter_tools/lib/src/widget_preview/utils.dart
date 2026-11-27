// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;

import '../base/file_system.dart';
import '../project.dart';
import 'dependency_graph.dart';

extension TokenExtension on Token {
  /// Convenience getter to identify tokens for private fields and functions.
  bool get isPrivate => toString().startsWith('_');

  /// Convenience getter to identify WidgetBuilder types.
  bool get isWidgetBuilder => toString() == 'WidgetBuilder';

  /// Convenience getter to identify Widget types.
  bool get isWidget => toString() == 'Widget';
}

extension on InterfaceType {
  bool isType({required String typeName, required Uri uri}) {
    if (getDisplayString() == typeName && element.library.uri == uri) {
      return true;
    }
    return allSupertypes.firstWhereOrNull((e) {
          return e.getDisplayString() == typeName && e.element.library.uri == uri;
        }) !=
        null;
  }
}

extension AnnotationExtension on Annotation {
  static final Uri widgetPreviewsLibraryUri = Uri.parse(
    'package:flutter/src/widget_previews/widget_previews.dart',
  );

  bool _isPreviewType(String typeName) {
    final Element? element = elementAnnotation!.element;
    if (element is ConstructorElement) {
      final InterfaceType type = element.enclosingElement.thisType;
      return type.isType(typeName: typeName, uri: widgetPreviewsLibraryUri);
    }
    return false;
  }

  /// Convenience getter to identify `@Preview` annotations
  bool get isPreview => _isPreviewType('Preview');

  /// Convenience getter to identify `@MultiPreview` annotations
  bool get isMultiPreview => _isPreviewType('MultiPreview');
}

/// Convenience getters for examining [String] paths.
extension StringExtension on String {
  static final RegExp _pathSeparator = RegExp(r'[/\\]');

  bool get isDartFile => endsWith('.dart');
  bool get isPubspec => endsWith('pubspec.yaml');
  bool get doesContainDartTool => contains('.dart_tool');
  bool get doesContainWidgetPreview => split(_pathSeparator).contains('.widget_preview');
}

extension LibraryElementExtension on LibraryElement {
  /// Convenience method to package path and [uri] into a [PreviewPath]
  PreviewPath toPreviewPath() => (path: firstFragment.source.fullName, uri: uri);
}

/// Used to protect global state accessed in blocks containing calls to
/// asynchronous methods.
///
/// Originally from DDS:
/// https://github.com/dart-lang/sdk/blob/3fe58da3cfe2c03fb9ee691a7a4709082fad3e73/pkg/dds/lib/src/utils/mutex.dart
class PreviewDetectorMutex {
  /// Executes a block of code containing asynchronous calls atomically.
  ///
  /// If no other asynchronous context is currently executing within
  /// [criticalSection], it will immediately be called. Otherwise, the
  /// caller will be suspended and entered into a queue to be resumed once the
  /// lock is released.
  Future<T> runGuarded<T>(FutureOr<T> Function() criticalSection) async {
    try {
      await _acquireLock();
      return await criticalSection();
    } finally {
      _releaseLock();
    }
  }

  Future<void> _acquireLock() async {
    if (!_locked) {
      _locked = true;
      return;
    }

    final request = Completer<void>();
    _outstandingRequests.add(request);
    await request.future;
  }

  void _releaseLock() {
    if (_outstandingRequests.isNotEmpty) {
      final Completer<void> request = _outstandingRequests.removeFirst();
      request.complete();
      return;
    }
    // Only release the lock if no other requests are pending to prevent races
    // between the next request from the queue to be handled and incoming
    // requests.
    _locked = false;
  }

  /// Returns true if the lock is currently held.
  ///
  /// WARNING: this should only be used for assertions in functions that expect
  /// the mutex to already be held.
  bool get isLocked => _locked;

  var _locked = false;
  final _outstandingRequests = Queue<Completer<void>>();
}

/// Convenience extensions for examining [FlutterProject] in widget preview context.
extension FlutterProjectPreviewExtension on FlutterProject {
  /// Returns whether [pubspecPath] corresponds to the root `pubspec.yaml` of
  /// this project.
  bool isRootPubspec(String pubspecPath) {
    final FileSystem fs = directory.fileSystem;
    return _resolveSymlinksAndCanonicalize(fs, pubspecPath) ==
        _resolveSymlinksAndCanonicalize(fs, pubspecFile.path);
  }

  /// Returns whether [pubspecPath] corresponds to the `pubspec.yaml` of this
  /// project or one of its workspace projects (including glob-matched entries).
  bool isPubspecForProject(String pubspecPath) {
    final FileSystem fs = directory.fileSystem;
    final String resolvedPubspecPath = _resolveSymlinksAndCanonicalize(fs, pubspecPath);
    if (resolvedPubspecPath == _resolveSymlinksAndCanonicalize(fs, pubspecFile.path)) {
      return true;
    }

    if (fs.path.basename(resolvedPubspecPath) == 'pubspec.yaml' &&
        manifest.workspace.isNotEmpty) {
      final String resolvedRootDir = _resolveSymlinksAndCanonicalize(fs, directory.path);
      final String candidateDir = fs.path.dirname(resolvedPubspecPath);
      final String relativeDir = fs.path.relative(candidateDir, from: resolvedRootDir);
      if (relativeDir != '.' &&
          !relativeDir.startsWith('..') &&
          !fs.path.isAbsolute(relativeDir)) {
        final List<String> dirSegments = fs.path
            .split(relativeDir)
            .where((String s) => s.isNotEmpty && s != '.')
            .toList();
        final bool hasIgnoredSegment = dirSegments.any(
          (String segment) => segment.startsWith('.') || segment == 'build',
        );
        if (!hasIgnoredSegment) {
          for (final String pattern in manifest.workspace) {
            final List<String> patternSegments = pattern
                .replaceAll(r'\', '/')
                .split('/')
                .where((String s) => s.isNotEmpty && s != '.')
                .toList();
            if (patternSegments.isNotEmpty &&
                _matchesWorkspacePattern(dirSegments, patternSegments, fs.path)) {
              return true;
            }
          }
        }
      }
    }

    return workspaceProjects.any(
      (FlutterProject workspaceProject) =>
          _resolveSymlinksAndCanonicalize(fs, workspaceProject.pubspecFile.path) ==
          resolvedPubspecPath,
    );
  }
}

/// Resolves symlinks for [rawPath] (walking up to the nearest existing ancestor
/// if [rawPath] does not exist on disk) before canonicalizing.
String _resolveSymlinksAndCanonicalize(FileSystem fs, String rawPath) {
  String current = fs.path.canonicalize(rawPath);
  final trailingSegments = <String>[];
  while (true) {
    if (fs.typeSync(current) != FileSystemEntityType.notFound) {
      try {
        final String resolved = fs.directory(current).resolveSymbolicLinksSync();
        if (trailingSegments.isEmpty) {
          return fs.path.canonicalize(resolved);
        }
        return fs.path.canonicalize(
          fs.path.joinAll(<String>[resolved, ...trailingSegments.reversed]),
        );
      } on FileSystemException {
        break;
      }
    }
    final String parent = fs.path.dirname(current);
    if (parent == current) {
      break;
    }
    trailingSegments.add(fs.path.basename(current));
    current = parent;
  }
  return fs.path.canonicalize(rawPath);
}

bool _matchesWorkspacePattern(
  List<String> dirSegments,
  List<String> patternSegments,
  path.Context pathContext, [
  int dirIndex = 0,
  int patternIndex = 0,
]) {
  while (patternIndex < patternSegments.length) {
    final String patternSegment = patternSegments[patternIndex];
    if (patternSegment == '**') {
      // Collapse consecutive '**' segments.
      while (patternIndex + 1 < patternSegments.length &&
          patternSegments[patternIndex + 1] == '**') {
        patternIndex++;
      }
      if (patternIndex == patternSegments.length - 1) {
        return true;
      }
      for (var nextDir = dirIndex; nextDir <= dirSegments.length; nextDir++) {
        if (_matchesWorkspacePattern(
          dirSegments,
          patternSegments,
          pathContext,
          nextDir,
          patternIndex + 1,
        )) {
          return true;
        }
      }
      return false;
    }
    if (dirIndex >= dirSegments.length) {
      return false;
    }
    final glob = Glob(patternSegment, context: pathContext);
    if (!glob.matches(dirSegments[dirIndex])) {
      return false;
    }
    dirIndex++;
    patternIndex++;
  }
  return dirIndex == dirSegments.length;
}
