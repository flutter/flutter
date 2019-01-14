import 'dart:typed_data' show Uint8List;
import 'dart:ui' as ui show instantiateImageCodec, Codec;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../painting/image_data.dart';

class PaintingBindingSpy extends BindingBase with ServicesBinding, PaintingBinding {
  int counter = 0;
  int get instantiateImageCodecCalledCount => counter;

  @override
  Future<ui.Codec> instantiateImageCodec(Uint8List list) {
    counter++;
    return ui.instantiateImageCodec(list, decodedCacheRatioCap: decodedCacheRatioCap); // ignore: deprecated_member_use
  }

  @override
  void initLicenses() {
    // Do not include any licenses, because we're a test, and the LICENSE file
    // doesn't get generated for tests.
  }
}

void main() {
  final PaintingBindingSpy binding = PaintingBindingSpy();

  test('decodedCacheRatio', () async {
    // final PaintingBinding binding = PaintingBinding.instance;
    // Has default value.
    expect(binding.decodedCacheRatioCap, isNot(null)); // ignore: deprecated_member_use

    // Can be set.
    binding.decodedCacheRatioCap = 1.0; // ignore: deprecated_member_use
    expect(binding.decodedCacheRatioCap, 1.0); // ignore: deprecated_member_use
  });

  test('instantiateImageCodec used for loading images', () async {
    expect(binding.instantiateImageCodecCalledCount, 0);

    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final MemoryImage memoryImage = MemoryImage(bytes);
    memoryImage.load(memoryImage);
    expect(binding.instantiateImageCodecCalledCount, 1);
  });
}
