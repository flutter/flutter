// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  test('Turning global semantics on/off sends semantics event', () {
    TestRenderingFlutterBinding.ensureInitialized();
    final List<dynamic> messages = <dynamic>[];
    TestRenderingFlutterBinding.instance.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
      SystemChannels.accessibility,
      (dynamic message) async {
        messages.add(message);
      }
    );
    final SemanticsHandle handle = TestRenderingFlutterBinding.instance.ensureSemantics();
    expect(messages.length, 1);
    expect(messages[0], <String, dynamic>{
      'type': 'generatingSemanticsTree',
      'data': <String, dynamic>{
        'generating': true,
      },
    });

    handle.dispose();
    expect(messages.length, 2);
    expect(messages[1], <String, dynamic>{
      'type': 'generatingSemanticsTree',
      'data': <String, dynamic>{
        'generating': false,
      },
    });
    TestRenderingFlutterBinding.instance.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, null);
  });
}
