// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';

/// Manages the concurrency and memory impact of `HTMLImageElement.decode()`.
///
/// This manager ensures that we don't overwhelm the browser's image subsystem
/// by limiting the number of simultaneous decodes and the cumulative memory
/// footprint of in-flight decodes.
class ImageDecodingManager {
  ImageDecodingManager._();

  /// The shared instance of [ImageDecodingManager].
  static final ImageDecodingManager instance = ImageDecodingManager._();

  static const int _maxConcurrentDecodes = 8;
  static const int _maxConcurrentBytes = 128 * 1024 * 1024; // 128MB

  int _activeDecodesCount = 0;
  int _activeDecodesBytes = 0;

  final ListQueue<ImageDecodingRequest> _pendingRequests = ListQueue<ImageDecodingRequest>();

  /// Requests a slot for decoding an image with the given [width] and [height].
  ///
  /// Returns an [ImageDecodingRequest] that will complete when a slot is
  /// available.
  ImageDecodingRequest requestDecodingSlot(int width, int height) {
    final int estimatedBytes = width * height * 4;
    final completer = Completer<void>();
    final request = ImageDecodingRequest._(estimatedBytes, completer);
    _pendingRequests.add(request);
    _runNext();
    return request;
  }

  /// Releases a decoding slot previously obtained via [requestDecodingSlot].
  void releaseDecodingSlot(ImageDecodingRequest request) {
    if (!request._granted) {
      _pendingRequests.remove(request);
      return;
    }
    request._granted = false;
    _activeDecodesCount--;
    _activeDecodesBytes -= request._estimatedBytes;
    _runNext();
  }

  /// Cancels a pending decoding request.
  void cancel(ImageDecodingRequest request) {
    if (_pendingRequests.remove(request)) {
      request._completer.completeError(const ImageDecodingCancelledException());
    }
  }

  @visibleForTesting
  int get debugActiveDecodesCount => _activeDecodesCount;

  @visibleForTesting
  int get debugActiveDecodesBytes => _activeDecodesBytes;

  @visibleForTesting
  void debugReset() {
    _activeDecodesCount = 0;
    _activeDecodesBytes = 0;
    _pendingRequests.clear();
  }

  void _runNext() {
    // We attempt to process as many pending requests as possible given our
    // current resource availability.
    while (_pendingRequests.isNotEmpty) {
      final ImageDecodingRequest request = _pendingRequests.first;

      // We use a "Greedy First" rule to determine if the next request in the
      // FIFO queue can proceed.
      var canProceed = false;

      // If there are no other decodes currently in flight, we ALWAYS allow the
      // first item in the queue to proceed. This is critical to prevent
      // deadlocks where a single extremely large image (e.g., > 128MB) would
      // otherwise be permanently blocked by the memory limit.
      if (_activeDecodesCount == 0) {
        canProceed = true;
      } else if (_activeDecodesCount < _maxConcurrentDecodes &&
          _activeDecodesBytes + request._estimatedBytes <= _maxConcurrentBytes) {
        // If we have active decodes, we only proceed if we are under BOTH the
        // concurrency limit and the cumulative memory footprint limit.
        canProceed = true;
      }

      if (canProceed) {
        // The request has been granted a slot. We remove it from the queue,
        // update our accounting of active resources, and notify the requester.
        _pendingRequests.removeFirst();
        request._granted = true;
        _activeDecodesCount++;
        _activeDecodesBytes += request._estimatedBytes;
        request._completer.complete();
      } else {
        // Since we are enforcing a strict FIFO order, if the first item in the
        // queue cannot proceed due to resource limits, we must stop and wait
        // for an active decode to complete and release its slot.
        break;
      }
    }
  }
}

/// A request for a decoding slot from [ImageDecodingManager].
class ImageDecodingRequest {
  ImageDecodingRequest._(this._estimatedBytes, this._completer);

  final int _estimatedBytes;
  final Completer<void> _completer;
  bool _granted = false;

  /// A future that completes when the decoding slot has been granted.
  Future<void> get future => _completer.future;
}

/// Exception thrown when an image decoding request is cancelled.
class ImageDecodingCancelledException implements Exception {
  const ImageDecodingCancelledException();

  @override
  String toString() => 'Image decoding request was cancelled.';
}
