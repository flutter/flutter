// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A library that mimicks package:firebase_core_web/firebase_core_web_interop.dart
// for platforms that do not target dart2js

abstract class FirebaseError {
  String get code;
  String get message;
  String get name;
  String get stack;
  Object get serverResponse;
}
