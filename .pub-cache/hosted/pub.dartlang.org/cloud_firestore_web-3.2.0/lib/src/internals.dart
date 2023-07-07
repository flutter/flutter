// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:_flutterfire_internals/_flutterfire_internals.dart'
    as internals;

/// Will return a [FirebaseException] from a thrown web error.
/// Any other errors will be propagated as normal.
R convertWebExceptions<R>(R Function() cb) {
  return internals.guardWebExceptions(
    cb,
    plugin: 'cloud_firestore',
    codeParser: (code) => code.replaceFirst('firestore/', ''),
  );
}
