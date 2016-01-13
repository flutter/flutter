// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library dart_jni;

import 'dart:collection';
import 'dart:nativewrappers';

/// Wrapper for a Java class accessed via JNI.
class JniClass extends NativeFieldWrapperClass2 {
  static JniClass fromName(String name) native 'JniClass_FromName';

  int getFieldId(String name, String sig) native 'JniClass_GetFieldId';
  int getStaticFieldId(String name, String sig) native 'JniClass_GetStaticFieldId';
  int getMethodId(String name, String sig) native 'JniClass_GetMethodId';
  int getStaticMethodId(String name, String sig) native 'JniClass_GetStaticMethodId';

  int getStaticIntField(int fieldId) native 'JniClass_GetStaticIntField';
  JniObject getStaticObjectField(int fieldId) native 'JniClass_GetStaticObjectField';

  JniObject newObject(int methodId, List args) native 'JniClass_NewObject';

  int callStaticLongMethod(int methodId, List args) native 'JniClass_CallStaticLongMethod';
}

/// Wrapper for a Java object accessed via JNI.
class JniObject extends NativeFieldWrapperClass2 {
  int getIntField(String name, String sig) native 'JniObject_getIntField';

  JniObject callObjectMethod(int methodId, List args) native 'JniObject_CallObjectMethod';
  bool callBooleanMethod(int methodId, List args) native 'JniObject_CallBooleanMethod';
  int callIntMethod(int methodId, List args) native 'JniObject_CallIntMethod';
}

/// Wrapper for a Java string.
class JniString extends JniObject {
  // Retrieve the value as a Dart string.
  String get text native 'JniString_GetText';
}

/// Wrapper for a Java array.
class JniArray extends JniObject {
  int get length native 'JniArray_GetLength';
}

class JniObjectArray extends JniArray {
  JniObject operator [](int index) native 'JniObjectArray_GetArrayElement';

  void operator []=(int index, JniObject value) native 'JniObjectArray_SetArrayElement';
}
