// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source.dart';
import 'package:collection/collection.dart';

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
  bool get isDartFile => endsWith('.dart');
  bool get isPubspec => endsWith('pubspec.yaml');
  bool get doesContainDartTool => contains('.dart_tool');
}

extension LibraryElementExtension on LibraryElement {
  /// Convenience method to package path and [uri] into a [PreviewPath]
  PreviewPath toPreviewPath() => (path: firstFragment.source.fullName, uri: uri);
}

extension ParsedUnitResultExtension on ParsedUnitResult {
  /// Convenience method to package [path] and [uri] into a [PreviewPath]
  PreviewPath toPreviewPath() => (path: path, uri: uri);
}

extension SourceExtension on Source {
  /// Convenience method to package [fullName] and [uri] into a [PreviewPath]
  PreviewPath toPreviewPath() => (path: fullName, uri: uri);
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
