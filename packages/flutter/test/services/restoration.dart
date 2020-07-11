// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class MockRestorationManager extends TestRestorationManager {
  final Set<VoidCallback> _finalizers = <VoidCallback>{};
  bool get updateScheduled => _updateScheduled;
  bool _updateScheduled = false;

  @override
  void scheduleSerialization({VoidCallback finalizer}) {
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

  @override
  Future<RestorationBucket> get rootBucket {
    rootBucketAccessed++;
    return _rootBucket;
  }
  Future<RestorationBucket> _rootBucket;
  set rootBucket(Future<RestorationBucket> value) {
    _rootBucket = value;
    notifyListeners();
  }


  @override
  Future<void> sendToEngine(Uint8List encodedData) {
    throw UnimplementedError('unimplemented in mock');
  }

  @override
  String toString() => 'MockManager';
}

const String childrenMapKey = 'c';
const String valuesMapKey = 'v';
