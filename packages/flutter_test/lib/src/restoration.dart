// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The [RestorationManager] used for tests.
///
/// Unlike the real [RestorationManager], this one just keeps the restoration
/// data in memory and does not make it available to the engine.
class TestRestorationManager extends RestorationManager {
  /// Creates a [TestRestorationManager].
  TestRestorationManager() {
    // Ensures that [rootBucket] always returns a synchronous future to avoid
    // extra pumps in tests.
    restoreFrom(TestRestorationData.empty);
  }

  @override
  Future<RestorationBucket?> get rootBucket {
    _debugRootBucketAccessed = true;
    return super.rootBucket;
  }

  /// The current restoration data from which the current state can be restored.
  ///
  /// To restore the state to the one described by this data, pass the
  /// [TestRestorationData] obtained from this getter back to [restoreFrom].
  ///
  /// See also:
  ///
  ///  * [WidgetTester.getRestorationData], which makes this data available
  ///    in a widget test.
  TestRestorationData get restorationData => _restorationData;
  late TestRestorationData _restorationData;

  /// Whether the [rootBucket] has been obtained.
  bool get debugRootBucketAccessed => _debugRootBucketAccessed;
  bool _debugRootBucketAccessed = false;

  /// Restores the state from the provided [TestRestorationData].
  ///
  /// The restoration data obtained form [restorationData] can be passed into
  /// this method to restore the state to what it was when the restoration data
  /// was originally retrieved.
  ///
  /// See also:
  ///
  ///  * [WidgetTester.restoreFrom], which exposes this method to a widget test.
  void restoreFrom(TestRestorationData data) {
    _restorationData = data;
    handleRestorationUpdateFromEngine(enabled: true, data: data.binary);
  }

  /// Disabled state restoration.
  ///
  /// To turn restoration back on call [restoreFrom].
  void disableRestoration() {
    _restorationData = TestRestorationData.empty;
    handleRestorationUpdateFromEngine(enabled: false, data: null);
  }

  @override
  Future<void> sendToEngine(Uint8List encodedData) async {
    _restorationData = TestRestorationData._(encodedData);
  }
}

/// Restoration data that can be used to restore the state to the one described
/// by this data.
///
/// See also:
///
///  * [WidgetTester.getRestorationData], which retrieves the restoration data
///    from the widget under test.
///  * [WidgetTester.restoreFrom], which takes a [TestRestorationData] to
///    restore the state of the widget under test from the provided data.
class TestRestorationData {
  const TestRestorationData._(this.binary);

  /// Empty restoration data indicating that no data is available to restore
  /// state from.
  static const TestRestorationData empty = TestRestorationData._(null);

  /// The serialized representation of the restoration data.
  ///
  /// Should only be accessed by the test framework.
  @protected
  final Uint8List? binary;
}
