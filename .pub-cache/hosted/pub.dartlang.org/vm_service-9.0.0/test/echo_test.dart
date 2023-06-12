// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:test/test.dart';
import 'package:vm_service/src/vm_service.dart';
import 'common/test_helper.dart';

class EchoResponse extends Response {
  static EchoResponse? parse(Map<String, dynamic>? json) =>
      json == null ? null : EchoResponse._fromJson(json);

  EchoResponse._fromJson(Map<String, dynamic> json) : text = json['text'];

  @override
  String get type => '_EchoResponse';
  final String text;
}

var tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    addTypeFactory('_EchoResponse', EchoResponse.parse);
  },
  (VmService service, IsolateRef isolateRef) async {
    // Echo from VM target.
    final result = await service.callMethod('_echo', args: {
      'text': 'hello',
    });
    expect(result, isA<EchoResponse>());
    expect((result as EchoResponse).text, 'hello');
  },
  (VmService service, IsolateRef isolateRef) async {
    // Echo from Isolate target.
    final result =
        await service.callMethod('_echo', isolateId: isolateRef.id!, args: {
      'text': 'hello',
    });
    expect(result, isA<EchoResponse>());
    expect((result as EchoResponse).text, 'hello');
  },
  (VmService service, IsolateRef isolateRef) async {
    final completer = Completer<void>();
    late final StreamSubscription sub;
    sub = service.onEvent('_Echo').listen((event) async {
      expect(event.kind, '_Echo');
      expect(event.data!.lengthInBytes, 3);
      expect(event.data!.getUint8(0), 0);
      expect(event.data!.getUint8(1), 128);
      expect(event.data!.getUint8(2), 255);
      await sub.cancel();
      await service.streamCancel('_Echo');
      completer.complete();
    });

    await service.streamListen('_Echo');
    await service.callMethod(
      '_triggerEchoEvent',
      isolateId: isolateRef.id!,
      args: {
        'text': 'hello',
      },
    );
    await completer.future;
  },
];

main(args) => runIsolateTests(
      args,
      tests,
      'echo_test.dart',
    );
