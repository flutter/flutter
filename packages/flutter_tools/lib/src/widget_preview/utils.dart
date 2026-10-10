// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

/// Convenience getters for examining [String] paths.
extension StringExtension on String {
  static final RegExp _pathSeparator = RegExp(r'[/\\]');

  bool get isDartFile => endsWith('.dart');
  bool get isPubspec => endsWith('pubspec.yaml');
  bool get doesContainDartTool => contains('.dart_tool');
  bool get doesContainWidgetPreview => split(_pathSeparator).contains('.widget_preview');
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
