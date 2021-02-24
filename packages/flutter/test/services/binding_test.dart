// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

const String licenses = '''
$license1
--------------------------------------------------------------------------------
$license2
''';

class TestBinding extends BindingBase with SchedulerBinding, ServicesBinding {
  @override
  BinaryMessenger createBinaryMessenger() {
    return super.createBinaryMessenger()
      ..setMockMessageHandler('flutter/assets', (ByteData? message) async {
        if (const StringCodec().decodeMessage(message) == 'NOTICES') {
          return const StringCodec().encodeMessage(licenses);
        }
        return null;
      });
  }
}

void main() {
  test('Adds rootBundle LICENSES to LicenseRegistry', () async {
    TestBinding(); // The test binding registers a mock handler that returns licenses for the LICENSE key

    final List<LicenseEntry> licenses = await LicenseRegistry.licenses.toList();

    expect(licenses[0].packages, equals(<String>['L1Package1', 'L1Package2', 'L1Package3']));
    expect(licenses[0].paragraphs.map((LicenseParagraph p) => p.text),
        equals(<String>['L1Paragraph1', 'L1Paragraph2', 'L1Paragraph3']));

    expect(licenses[1].packages, equals(<String>['L2Package1', 'L2Package2', 'L2Package3']));
    expect(licenses[1].paragraphs.map((LicenseParagraph p) => p.text),
        equals(<String>['L2Paragraph1', 'L2Paragraph2', 'L2Paragraph3']));
  });
}
