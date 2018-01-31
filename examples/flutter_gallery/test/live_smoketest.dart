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

/// Reports success or failure to the native code.
const MethodChannel _kTestChannel = const MethodChannel('io.flutter.demo.gallery/TestLifecycleListener');

Future<Null> main() async {
  try {
    runApp(const GalleryApp());

    const Duration kWaitBetweenActions = const Duration(milliseconds: 250);
    final _LiveWidgetController controller = new _LiveWidgetController();

    for (Demo demo in demos) {
      print('Testing "${demo.title}" demo');
      final Finder menuItem = find.text(demo.title);
      await controller.scrollIntoView(menuItem, alignment: 0.5);
      await new Future<Null>.delayed(kWaitBetweenActions);

      for (int i = 0; i < 2; i += 1) {
        await controller.tap(menuItem); // Launch the demo
        await new Future<Null>.delayed(kWaitBetweenActions);
        controller.frameSync = demo.synchronized;
        await controller.tap(find.byTooltip('Back'));
        controller.frameSync = true;
        await new Future<Null>.delayed(kWaitBetweenActions);
      }
      print('Success');
    }

    _kTestChannel.invokeMethod('success');
  } catch (error) {
    _kTestChannel.invokeMethod('failure');
  }
}

class Demo {
  const Demo(this.title, {this.synchronized = true});

  /// The title of the demo.
  final String title;

  /// True if frameSync should be enabled for this test.
  final bool synchronized;
}

// Warning: this list must be kept in sync with the value of
// kAllGalleryItems.map((GalleryItem item) => item.title).toList();
const List<Demo> demos = const <Demo>[
  // Demos
  const Demo('Shrine'),
  const Demo('Contact profile'),
  const Demo('Animation'),

  // Material Components
  const Demo('Bottom navigation'),
  const Demo('Buttons'),
  const Demo('Cards'),
  const Demo('Chips'),
  const Demo('Date and time pickers'),
  const Demo('Dialog'),
  const Demo('Drawer'),
  const Demo('Expand/collapse list control'),
  const Demo('Expansion panels'),
  const Demo('Floating action button'),
  const Demo('Grid'),
  const Demo('Icons'),
  const Demo('Leave-behind list items'),
  const Demo('List'),
  const Demo('Menus'),
  const Demo('Modal bottom sheet'),
  const Demo('Page selector'),
  const Demo('Persistent bottom sheet'),
  const Demo('Progress indicators', synchronized: false),
  const Demo('Pull to refresh'),
  const Demo('Scrollable tabs'),
  const Demo('Selection controls'),
  const Demo('Sliders'),
  const Demo('Snackbar'),
  const Demo('Tabs'),
  const Demo('Text fields'),
  const Demo('Tooltips'),

  // Cupertino Components
  const Demo('Activity Indicator', synchronized: false),
  const Demo('Buttons'),
  const Demo('Dialogs'),
  const Demo('Navigation'),
  const Demo('Sliders'),
  const Demo('Switches'),

  // Media
  const Demo('Animated images'),

  // Style
  const Demo('Colors'),
  const Demo('Typography'),
];


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
