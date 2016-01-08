// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library dart_jni;

import 'dart:nativewrappers';

/// Wrapper for a Java class accessed via JNI.
class JniClass extends NativeFieldWrapperClass2 {
  static JniClass fromName(String name) native 'JniClass_fromName';

  int getFieldId(String name, String sig) native 'JniClass_getFieldId';
  int getStaticFieldId(String name, String sig) native 'JniClass_getStaticFieldId';

  int getStaticIntField(int fieldId) native 'JniClass_getStaticIntField';
  JniObject getStaticObjectField(int fieldId) native 'JniClass_getStaticObjectField';
}

/// Wrapper for a Java object accessed via JNI.
class JniObject extends NativeFieldWrapperClass2 {
  int getIntField(String name, String sig) native 'JniObject_getIntField';
}
