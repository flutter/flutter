// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('ImageDecodingManager', () {
    late ImageDecodingManager manager;

    setUp(() {
      manager = ImageDecodingManager.instance;
      manager.debugReset();
    });

    test('throttles concurrency', () async {
      final requests = <ImageDecodingRequest>[];
      for (var i = 0; i < 25; i++) {
        requests.add(manager.requestDecodingSlot(100, 100));
      }

      var grantedCount = 0;
      for (var i = 0; i < 25; i++) {
        unawaited(requests[i].future.then((_) => grantedCount++));
      }

      await Future<void>.delayed(Duration.zero);
      expect(grantedCount, 8);

      // Release one slot
      manager.releaseDecodingSlot(requests[0]);
      await Future<void>.delayed(Duration.zero);
      expect(grantedCount, 9);
    });

    test('throttles memory', () async {
      // 128MB limit. 2000x2000x4 = 16MB. 8 such images = 128MB.
      final requests = <ImageDecodingRequest>[];
      for (var i = 0; i < 20; i++) {
        requests.add(manager.requestDecodingSlot(2000, 2000));
      }

      var grantedCount = 0;
      for (var i = 0; i < 20; i++) {
        unawaited(requests[i].future.then((_) => grantedCount++));
      }

      await Future<void>.delayed(Duration.zero);
      expect(grantedCount, 8);

      // Release one slot
      manager.releaseDecodingSlot(requests[0]);
      await Future<void>.delayed(Duration.zero);
      expect(grantedCount, 9);
    });

    test('Greedy First rule', () async {
      // Request a huge image that exceeds the budget
      // 200MB image: 5000x10000x4 = 200MB.
      final ImageDecodingRequest request = manager.requestDecodingSlot(5000, 10000);

      var granted = false;
      unawaited(request.future.then((_) => granted = true));
      await Future<void>.delayed(Duration.zero);
      expect(granted, true); // Should be granted because it's the first and nothing else is active.

      // While huge image is active, another small request should be blocked by memory limit.
      final ImageDecodingRequest request2 = manager.requestDecodingSlot(100, 100);
      var granted2 = false;
      unawaited(request2.future.then((_) => granted2 = true));
      await Future<void>.delayed(Duration.zero);
      expect(granted2, false);

      // Release huge image
      manager.releaseDecodingSlot(request);
      await Future<void>.delayed(Duration.zero);
      expect(granted2, true);
    });

    test('cancel request', () async {
      final activeRequests = <ImageDecodingRequest>[];
      for (var i = 0; i < 8; i++) {
        activeRequests.add(manager.requestDecodingSlot(100, 100));
      }

      final ImageDecodingRequest request = manager.requestDecodingSlot(100, 100);
      var granted = false;
      Object? error;
      unawaited(request.future.then((_) => granted = true, onError: (Object e) => error = e));
      await Future<void>.delayed(Duration.zero);
      expect(granted, false);
      expect(error, isNull);

      manager.cancel(request);
      await Future<void>.delayed(Duration.zero);
      expect(error, isA<ImageDecodingCancelledException>());

      // Release a slot, the cancelled request should not be granted.
      manager.releaseDecodingSlot(activeRequests[0]);
      await Future<void>.delayed(Duration.zero);
      expect(granted, false);

      // A new request should get the slot.
      final ImageDecodingRequest request2 = manager.requestDecodingSlot(100, 100);
      var granted2 = false;
      unawaited(request2.future.then((_) => granted2 = true));
      await Future<void>.delayed(Duration.zero);
      expect(granted2, true);
    });

    test('releasing pending request before grant', () async {
      // Occupy all slots
      final activeRequests = <ImageDecodingRequest>[];
      for (var i = 0; i < 8; i++) {
        activeRequests.add(manager.requestDecodingSlot(100, 100));
      }

      final int initialCount = manager.debugActiveDecodesCount;
      final int initialBytes = manager.debugActiveDecodesBytes;
      expect(initialCount, 8);

      // Request another slot (will be pending)
      final ImageDecodingRequest pendingRequest = manager.requestDecodingSlot(100, 100);
      var granted = false;
      unawaited(pendingRequest.future.then((_) => granted = true));
      await Future<void>.delayed(Duration.zero);
      expect(granted, false);

      // Release the pending request before it's granted
      manager.releaseDecodingSlot(pendingRequest);

      // Verify that accounting hasn't changed
      expect(manager.debugActiveDecodesCount, initialCount);
      expect(manager.debugActiveDecodesBytes, initialBytes);

      // Release an active slot
      manager.releaseDecodingSlot(activeRequests[0]);
      await Future<void>.delayed(Duration.zero);

      // The pending request should never have been granted
      expect(granted, false);
      expect(manager.debugActiveDecodesCount, 7);

      // A new request should still be able to get a slot
      final ImageDecodingRequest newRequest = manager.requestDecodingSlot(100, 100);
      var newGranted = false;
      unawaited(newRequest.future.then((_) => newGranted = true));
      await Future<void>.delayed(Duration.zero);
      expect(newGranted, true);
      expect(manager.debugActiveDecodesCount, 8);
    });
  });
}
