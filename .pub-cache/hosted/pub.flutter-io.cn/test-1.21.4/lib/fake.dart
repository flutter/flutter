// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Note: eventually we would like to fold this into test.dart, but we can't do
// so until Mockito stops implementing its own version of `Fake`, because there
// is code in the wild that imports both test_api.dart and Mockito.

// ignore: deprecated_member_use
export 'package:test_api/fake.dart';
