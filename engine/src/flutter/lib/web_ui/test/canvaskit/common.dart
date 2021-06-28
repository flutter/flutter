// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// Whether the current browser is Safari.
bool get isSafari => browserEngine == BrowserEngine.webkit;

/// Whether the current browser is Safari on iOS.
// TODO: https://github.com/flutter/flutter/issues/60040
bool get isIosSafari => isSafari && operatingSystem == OperatingSystem.iOs;

/// Whether the current browser is Firefox.
bool get isFirefox => browserEngine == BrowserEngine.firefox;

/// Used in tests instead of [ProductionCollector] to control Skia object
/// collection explicitly, and to prevent leaks across tests.
///
/// See [TestCollector] for usage.
late TestCollector testCollector;

/// Common test setup for all CanvasKit unit-tests.
void setUpCanvasKitTest() {
  setUpAll(() async {
    expect(useCanvasKit, true, reason: 'This test must run in CanvasKit mode.');
    debugResetBrowserSupportsFinalizationRegistry();
    await ui.webOnlyInitializePlatform(assetManager: WebOnlyMockAssetManager());
  });

  setUp(() async {
    testCollector = TestCollector();
    Collector.debugOverrideCollector(testCollector);
  });

  tearDown(() {
    testCollector.cleanUpAfterTest();
    debugResetBrowserSupportsFinalizationRegistry();
    HtmlViewEmbedder.instance.debugClear();
    SurfaceFactory.instance.debugClear();
  });

  tearDownAll(() {
    debugResetBrowserSupportsFinalizationRegistry();
  });
}

/// Utility function for CanvasKit tests to draw pictures without
/// the [CkPictureRecorder] boilerplate.
CkPicture paintPicture(
    ui.Rect cullRect, void Function(CkCanvas canvas) painter) {
  final CkPictureRecorder recorder = CkPictureRecorder();
  final CkCanvas canvas = recorder.beginRecording(cullRect);
  painter(canvas);
  return recorder.endRecording();
}

class _TestFinalizerRegistration {
  _TestFinalizerRegistration(this.wrapper, this.deletable, this.stackTrace);

  final Object wrapper;
  final SkDeletable deletable;
  final StackTrace stackTrace;
}

class _TestCollection {
  _TestCollection(this.deletable, this.stackTrace);

  final SkDeletable deletable;
  final StackTrace stackTrace;
}

/// Provides explicit synchronous API for collecting Skia objects in tests.
///
/// [ProductionCollector] relies on `FinalizationRegistry` and timers to
/// delete Skia objects, which makes it more precise and efficient. However,
/// it also makes it unpredictable. For example, an object created in one
/// test may be collected while running another test because the timing is
/// subject to browser-specific GC scheduling.
///
/// Tests should use [collectNow] and [collectAfterTest] to trigger collections.
class TestCollector implements Collector {
  final List<_TestFinalizerRegistration> _activeRegistrations =
      <_TestFinalizerRegistration>[];
  final List<_TestFinalizerRegistration> _collectedRegistrations =
      <_TestFinalizerRegistration>[];

  final List<_TestCollection> _pendingCollections = <_TestCollection>[];
  final List<_TestCollection> _completedCollections = <_TestCollection>[];

  @override
  void register(Object wrapper, SkDeletable deletable) {
    _activeRegistrations.add(
      _TestFinalizerRegistration(wrapper, deletable, StackTrace.current),
    );
  }

  @override
  void collect(SkDeletable deletable) {
    _pendingCollections.add(
      _TestCollection(deletable, StackTrace.current),
    );
  }

  /// Deletes all Skia objects scheduled for collection.
  void collectNow() {
    for (_TestCollection collection in _pendingCollections) {
      late final _TestFinalizerRegistration? activeRegistration;
      for (_TestFinalizerRegistration registration in _activeRegistrations) {
        if (identical(registration.deletable, collection.deletable)) {
          activeRegistration = registration;
          break;
        }
      }
      if (activeRegistration == null) {
        late final _TestFinalizerRegistration? collectedRegistration;
        for (_TestFinalizerRegistration registration
            in _collectedRegistrations) {
          if (identical(registration.deletable, collection.deletable)) {
            collectedRegistration = registration;
            break;
          }
        }
        if (collectedRegistration == null) {
          fail(
              'Attempted to collect an object that was never registered for finalization.\n'
              'The collection was requested here:\n'
              '${collection.stackTrace}');
        } else {
          final _TestCollection firstCollection = _completedCollections
              .firstWhere((_TestCollection completedCollection) {
            return identical(
                completedCollection.deletable, collection.deletable);
          });
          fail(
            'Attempted to collect an object that was previously collected.\n'
            'The object was registered for finalization here:\n'
            '${collection.stackTrace}\n\n'
            'The first collection was requested here:\n'
            '${firstCollection.stackTrace}\n\n'
            'The second collection was requested here:\n'
            '${collection.stackTrace}',
          );
        }
      } else {
        _collectedRegistrations.add(activeRegistration);
        _activeRegistrations.remove(activeRegistration);
        _completedCollections.add(collection);
        if (!collection.deletable.isDeleted()) {
          collection.deletable.delete();
        }
      }
    }
    _pendingCollections.clear();
  }

  /// Deletes all Skia objects with registered finalizers.
  ///
  /// This also deletes active objects that have not been scheduled for
  /// collection, to prevent objects leaking across tests.
  void cleanUpAfterTest() {
    for (_TestCollection collection in _pendingCollections) {
      if (!collection.deletable.isDeleted()) {
        collection.deletable.delete();
      }
    }
    for (_TestFinalizerRegistration registration in _activeRegistrations) {
      if (!registration.deletable.isDeleted()) {
        registration.deletable.delete();
      }
    }
    _activeRegistrations.clear();
    _collectedRegistrations.clear();
    _pendingCollections.clear();
    _completedCollections.clear();
  }
}
