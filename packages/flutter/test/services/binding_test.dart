// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';

const String license1 = '''
L1Package1
L1Package2
L1Package3

L1Paragraph1

L1Paragraph2

L1Paragraph3''';

const String license2 = '''
L2Package1
L2Package2
L2Package3

L2Paragraph1

L2Paragraph2

L2Paragraph3''';

const String combinedLicenses = '''
$license1
--------------------------------------------------------------------------------
$license2
''';

class TestBinding extends BindingBase with SchedulerBinding, ServicesBinding {
  @override
  TestDefaultBinaryMessenger get defaultBinaryMessenger => super.defaultBinaryMessenger as TestDefaultBinaryMessenger;

  @override
  TestDefaultBinaryMessenger createBinaryMessenger() {
    return TestDefaultBinaryMessenger(super.createBinaryMessenger());
  }
}

void main() {
  final TestBinding binding = TestBinding();

  test('Adds rootBundle LICENSES to LicenseRegistry', () async {
    binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (ByteData? message) async {
      if (const StringCodec().decodeMessage(message) == 'NOTICES.Z' && !kIsWeb) {
        return Uint8List.fromList(gzip.encode(utf8.encode(combinedLicenses))).buffer.asByteData();
      }
      if (const StringCodec().decodeMessage(message) == 'NOTICES' && kIsWeb) {
        return const StringCodec().encodeMessage(combinedLicenses);
      }
      return null;
    });

    final List<LicenseEntry> licenses = await LicenseRegistry.licenses.toList();

    expect(licenses[0].packages, equals(<String>['L1Package1', 'L1Package2', 'L1Package3']));
    expect(
      licenses[0].paragraphs.map((LicenseParagraph p) => p.text),
      equals(<String>['L1Paragraph1', 'L1Paragraph2', 'L1Paragraph3']),
    );

    expect(licenses[1].packages, equals(<String>['L2Package1', 'L2Package2', 'L2Package3']));
    expect(
      licenses[1].paragraphs.map((LicenseParagraph p) => p.text),
      equals(<String>['L2Paragraph1', 'L2Paragraph2', 'L2Paragraph3']),
    );
  });

  test('didHaveMemoryPressure clears asset caches', () async {
    int flutterAssetsCallCount = 0;
    binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (ByteData? message) async {
      flutterAssetsCallCount += 1;
      return Uint8List.fromList('test_asset_data'.codeUnits).buffer.asByteData();
    });

    await rootBundle.loadString('test_asset');
    expect(flutterAssetsCallCount, 1);
    await rootBundle.loadString('test_asset2');
    expect(flutterAssetsCallCount, 2);
    await rootBundle.loadString('test_asset');
    expect(flutterAssetsCallCount, 2);
    await rootBundle.loadString('test_asset2');
    expect(flutterAssetsCallCount, 2);

    final ByteData message = const JSONMessageCodec().encodeMessage(<String, dynamic>{'type': 'memoryPressure'})!;
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage('flutter/system', message, (_) { });

    await rootBundle.loadString('test_asset');
    expect(flutterAssetsCallCount, 3);
    await rootBundle.loadString('test_asset2');
    expect(flutterAssetsCallCount, 4);
    await rootBundle.loadString('test_asset');
    expect(flutterAssetsCallCount, 4);
    await rootBundle.loadString('test_asset2');
    expect(flutterAssetsCallCount, 4);
  });
}
