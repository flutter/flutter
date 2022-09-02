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
  });

  test('kFlutterMemoryAllocationsEnabled is false in release mode.', () {
    expect(kFlutterMemoryAllocationsEnabled, isFalse);
  });

  test(
    'Publishers in Flutter respect kFlutterMemoryAllocationsEnabled.',
    () async {
      ObjectEvent? recievedEvent;
      ObjectEvent listener(ObjectEvent event) => recievedEvent = event;
      ma.addListener(listener);

      await _activateFlutterObjects();

      expect(recievedEvent, isNull);
      expect(ma.hasListeners, isTrue);
      ma.removeListener(listener);
    },
  );
}

Future<void> _activateFlutterObjects() async {
  final ValueNotifier<bool> valueNotifier = ValueNotifier<bool>(true);
  final ChangeNotifier changeNotifier = ChangeNotifier()..addListener(() {});
  final Image image = await _createImage();
  final Picture picture = _createPicture();

  valueNotifier.dispose();
  changeNotifier.dispose();
  image.dispose();
  picture.dispose();
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
