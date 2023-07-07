// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:_flutterfire_internals/_flutterfire_internals.dart';
import 'package:flutter/services.dart';

/// Catches a [PlatformException] and returns an [Exception].
///
/// If the [Exception] is a [PlatformException], a [FirebaseException] is returned.
Never convertPlatformException(Object exception, StackTrace stackTrace) {
  convertPlatformExceptionToFirebaseException(
    exception,
    stackTrace,
    plugin: 'cloud_firestore',
  );
}
