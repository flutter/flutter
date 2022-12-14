// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final MemoryAllocations ma = MemoryAllocations.instance;

  setUp(() {
    assert(!ma.hasListeners);
    _checkSdkHandlersNotSet();
  });

  test('kFlutterMemoryAllocationsEnabled is false in release mode.', () {
    expect(kFlutterMemoryAllocationsEnabled, isFalse);
  });

  testWidgets(
    '$MemoryAllocations is noop when kFlutterMemoryAllocationsEnabled is false.',
    (WidgetTester tester) async {
      ObjectEvent? recievedEvent;
      ObjectEvent listener(ObjectEvent event) => recievedEvent = event;

      ma.addListener(listener);
      _checkSdkHandlersNotSet();
      expect(ma.hasListeners, isFalse);

      await _activateFlutterObjects(tester);
      _checkSdkHandlersNotSet();
      expect(recievedEvent, isNull);
      expect(ma.hasListeners, isFalse);

      ma.removeListener(listener);
      _checkSdkHandlersNotSet();
    },
  );
}

void _checkSdkHandlersNotSet() {
  expect(Image.onCreate, isNull);
  expect(Picture.onCreate, isNull);
  expect(Image.onDispose, isNull);
  expect(Picture.onDispose, isNull);
}

/// Create and dispose Flutter objects to fire memory allocation events.
Future<void> _activateFlutterObjects(WidgetTester tester) async {
  final ValueNotifier<bool> valueNotifier = ValueNotifier<bool>(true);
  final ChangeNotifier changeNotifier = ChangeNotifier()..addListener(() {});
  final Picture picture = _createPicture();

  valueNotifier.dispose();
  changeNotifier.dispose();
  picture.dispose();

  // TODO(polina-c): Remove the condition after
  // https://github.com/flutter/flutter/issues/110599 is fixed.
  if (!kIsWeb) {
    final Image image = await _createImage();
    image.dispose();
  }
}

Future<Image> _createImage() async {
  final Picture picture = _createPicture();
  final Image result = await picture.toImage(10, 10);
  picture.dispose();
  return result;
}

Picture _createPicture() {
  final PictureRecorder recorder = PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  const Rect rect = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
  canvas.clipRect(rect);
  return recorder.endRecording();
}
