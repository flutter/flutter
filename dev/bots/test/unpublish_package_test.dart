// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show ProcessResult;

import '../unpublish_package.dart';
import 'common.dart';

void main() {
  test('UnpublishException string includes class name and stderr', () {
    final exception = UnpublishException(
      'failed to unpublish package',
      ProcessResult(0, 1, '', 'stderr details'),
    );

    expect(
      exception.toString(),
      'UnpublishException: failed to unpublish package:\nstderr details',
    );
  });
}
