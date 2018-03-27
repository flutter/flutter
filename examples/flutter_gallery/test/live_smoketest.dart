// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_gallery/gallery/app.dart';
import 'package:flutter_gallery/gallery/item.dart';

// Reports success or failure to the native code.
const MethodChannel _kTestChannel = const MethodChannel('io.flutter.demo.gallery/TestLifecycleListener');

// The titles for all of the Gallery demos.
final List<String> _kAllDemos = kAllGalleryItems.map((GalleryItem item) => item.title).toList();

// We don't want to wait for animations to complete before tapping the
// back button in the demos with these titles.
const List<String> _kUnsynchronizedDemos = const <String>[
  'Progress indicators',
  'Activity Indicator',
  'Video',
];

// These demos can't be backed out of by tapping a button whose
// tooltip is 'Back'.
const List<String> _kSkippedDemos = const <String>[
  'Backdrop',
  'Pull to refresh',
];

Future<Null> main() async {
  try {
    // Verify that _kUnsynchronizedDemos and _kSkippedDemos identify
    // demos that actually exist.
    if (!new Set<String>.from(_kAllDemos).containsAll(_kUnsynchronizedDemos))
      fail('Unrecognized demo names in _kUnsynchronizedDemos: $_kUnsynchronizedDemos');
    if (!new Set<String>.from(_kAllDemos).containsAll(_kSkippedDemos))
      fail('Unrecognized demo names in _kSkippedDemos: $_kSkippedDemos');

    runApp(const GalleryApp());
    final _LiveWidgetController controller = new _LiveWidgetController();
    for (String demo in _kAllDemos) {
      print('Testing "$demo" demo');
      final Finder menuItem = find.text(demo);
      await controller.scrollIntoView(menuItem, alignment: 0.5);

      if (_kSkippedDemos.contains(demo)) {
        print('> skipped $demo');
        continue;
      }

      for (int i = 0; i < 2; i += 1) {
        await controller.tap(menuItem); // Launch the demo
        controller.frameSync = !_kUnsynchronizedDemos.contains(demo);
        await controller.tap(find.byTooltip('Back'));
        controller.frameSync = true;
      }
      print('Success');
    }

    _kTestChannel.invokeMethod('success');
  } catch (error) {
    _kTestChannel.invokeMethod('failure');
  }
}

class _LiveWidgetController {

  final WidgetController _controller = new WidgetController(WidgetsBinding.instance);

  /// With [frameSync] enabled, Flutter Driver will wait to perform an action
  /// until there are no pending frames in the app under test.
  bool frameSync = true;

  /// Waits until at the end of a frame the provided [condition] is [true].
  Future<Null> _waitUntilFrame(bool condition(), [Completer<Null> completer]) {
    completer ??= new Completer<Null>();
    if (!condition()) {
      SchedulerBinding.instance.addPostFrameCallback((Duration timestamp) {
        _waitUntilFrame(condition, completer);
      });
    } else {
      completer.complete();
    }
    return completer.future;
  }

  /// Runs `finder` repeatedly until it finds one or more [Element]s.
  Future<Finder> _waitForElement(Finder finder) async {
    if (frameSync)
      await _waitUntilFrame(() => SchedulerBinding.instance.transientCallbackCount == 0);

    await _waitUntilFrame(() => finder.precache());

    if (frameSync)
      await _waitUntilFrame(() => SchedulerBinding.instance.transientCallbackCount == 0);

    return finder;
  }

  Future<Null> tap(Finder finder) async {
    await _controller.tap(await _waitForElement(finder));
  }

  Future<Null> scrollIntoView(Finder finder, {double alignment}) async {
    final Finder target = await _waitForElement(finder);
    await Scrollable.ensureVisible(target.evaluate().single, duration: const Duration(milliseconds: 100), alignment: alignment);
  }
}
