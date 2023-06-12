// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

const Map<String, dynamic> kNullInstance = {
  'type': '@Instance',
  'id': 'instance/123',
  'kind': 'Null',
  'class': {
    'type': '@Class',
    'id': 'object/0',
    'name': 'Null',
  }
};

void main() {
  test('Ensure createServiceObject handles Null @Instances properly', () {
    expect(createServiceObject(kNullInstance, ['InstanceRef']), isNotNull);
    expect(createServiceObject(kNullInstance, ['ClassRef']), isNull);
  });
}
