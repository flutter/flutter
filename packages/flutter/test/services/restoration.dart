// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MockRestorationManager implements RestorationManager {
  final Set<VoidCallback> _finalizers = <VoidCallback>{};
  bool get updateScheduled => _updateScheduled;
  bool _updateScheduled = false;

  @override
  void scheduleUpdate({VoidCallback finalizer}) {
    _updateScheduled = true;
    if (finalizer != null) {
      _finalizers.add(finalizer);
    }
  }

  void runFinalizers() {
    _updateScheduled = false;
    for (final VoidCallback finalizer in _finalizers) {
      finalizer();
    }
    _finalizers.clear();
  }

  int rootBucketAccessed = 0;

  Future<RestorationBucket> rootBucketFuture;
  @override
  Future<RestorationBucket> get rootBucket {
    rootBucketAccessed++;
    return rootBucketFuture;
  }

  @override
  Future<void> sendToEngine(Map<String, dynamic> rawData) {
    throw UnimplementedError('unimplemented in mock');
  }

  @override
  Future<Map<String, dynamic>> retrieveFromEngine() {
    throw UnimplementedError('unimplemented in mock');
  }

  @override
  String toString() => 'MockManager';
}

const String childrenMapKey = 'c';
const String valuesMapKey = 'v';
