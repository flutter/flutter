// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolate) async {
    final isolateId = isolate.id!;
    final unresolvedUris = <String>[
      'dart:io', // dart:io -> org-dartlang-sdk:///sdk/lib/io/io.dart
      Platform.script.toString(), // file:///abc.dart -> file:///abc.dart
      'package:test/test.dart', // package:test/test.dart -> file:///some_dir/test/lib/test.dart
      'package:does_not_exist/does_not_exist.dart', // invalid URI -> null
    ];

    var result = await service.lookupResolvedPackageUris(
      isolateId,
      unresolvedUris,
    );
    expect(result.uris, isNotNull);
    var uris = result.uris!;
    expect(uris.length, 4);
    expect(uris[0], 'org-dartlang-sdk:///sdk/lib/io/io.dart');
    expect(uris[1], Platform.script.toString());
    expect(uris[2], startsWith('file:///'));
    expect(uris[2], endsWith('third_party/pkg/test/pkgs/test/lib/test.dart'));
    expect(uris[3], isNull);

    result = await service.lookupPackageUris(
      isolateId,
      [
        ...uris.sublist(0, 3).cast<String>(),
        'does_not_exist.dart',
      ],
    );
    expect(result.uris, isNotNull);
    uris = result.uris!;
    expect(uris.length, 4);
    expect(uris[0], unresolvedUris[0]);
    expect(uris[1], unresolvedUris[1]);
    expect(uris[2], unresolvedUris[2]);
    expect(uris[3], isNull);
  },
];

void main(args) => runIsolateTests(
      args,
      tests,
      'uri_mappings_lookup_test.dart',
    );
