// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_gallery/gallery/demos.dart';
import 'package:flutter_gallery/gallery/app.dart' show GalleryApp;

// Reports success or failure to the native code.
const MethodChannel _kTestChannel = const MethodChannel('io.flutter.demo.gallery/TestLifecycleListener');

// We don't want to wait for animations to complete before tapping the
// back button in the demos with these titles.
const List<String> _kUnsynchronizedDemoTitles = const <String>[
  'Progress indicators',
  'Activity Indicator',
  'Video',
];

// These demos can't be backed out of by tapping a button whose
// tooltip is 'Back'.
const List<String> _kSkippedDemoTitles = const <String>[
  'Pull to refresh',
  'Progress indicators',
  'Activity Indicator',
  'Video',
];

Future<Null> main() async {
  try {
    // Verify that _kUnsynchronizedDemos and _kSkippedDemos identify
    // demos that actually exist.
    final List<String> allDemoTitles = kAllGalleryDemos.map((GalleryDemo demo) => demo.title).toList();
    if (!new Set<String>.from(allDemoTitles).containsAll(_kUnsynchronizedDemoTitles))
      fail('Unrecognized demo titles in _kUnsynchronizedDemosTitles: $_kUnsynchronizedDemoTitles');
    if (!new Set<String>.from(allDemoTitles).containsAll(_kSkippedDemoTitles))
      fail('Unrecognized demo names in _kSkippedDemoTitles: $_kSkippedDemoTitles');

    runApp(const GalleryApp());
    final _LiveWidgetController controller = new _LiveWidgetController();
    for (GalleryDemoCategory category in kAllGalleryDemoCategories) {
      await controller.tap(find.text(category.name));
      for (GalleryDemo demo in kGalleryCategoryToDemos[category]) {
        final Finder demoItem = find.text(demo.title);
        await controller.scrollIntoView(demoItem, alignment: 0.5);

        if (_kSkippedDemoTitles.contains(demo.title)) {
          print('> skipped $demo');
          continue;
        }

        for (int i = 0; i < 2; i += 1) {
          await controller.tap(demoItem); // Launch the demo
          controller.frameSync = !_kUnsynchronizedDemoTitles.contains(demo.title);
          await controller.tap(find.byTooltip('Back'));
          controller.frameSync = true;
        }
        print('Success');
      }
      await controller.tap(find.byTooltip('Back'));
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
