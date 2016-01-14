// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library dart_jni;

import 'dart:collection';
import 'dart:nativewrappers';

/// Wrapper for a Java class accessed via JNI.
class JniClass extends NativeFieldWrapperClass2 {
  static JniClass fromName(String name)
      native 'JniClass_FromName';
  static JniClass fromClassObject(JniObject classObject)
      native 'JniClass_FromClassObject';

  int getFieldId(String name, String sig)
      native 'JniClass_GetFieldId';
  int getStaticFieldId(String name, String sig)
      native 'JniClass_GetStaticFieldId';
  int getMethodId(String name, String sig)
      native 'JniClass_GetMethodId';
  int getStaticMethodId(String name, String sig)
      native 'JniClass_GetStaticMethodId';

  JniObject newObject(int methodId, List args)
      native 'JniClass_NewObject';

  JniObject getStaticObjectField(int fieldId)
      native 'JniClass_GetStaticObjectField';
  bool getStaticBooleanField(int fieldId)
      native 'JniClass_GetStaticBooleanField';
  int getStaticByteField(int fieldId)
      native 'JniClass_GetStaticByteField';
  int getStaticCharField(int fieldId)
      native 'JniClass_GetStaticCharField';
  int getStaticShortField(int fieldId)
      native 'JniClass_GetStaticShortField';
  int getStaticIntField(int fieldId)
      native 'JniClass_GetStaticIntField';
  int getStaticLongField(int fieldId)
      native 'JniClass_GetStaticLongField';
  double getStaticFloatField(int fieldId)
      native 'JniClass_GetStaticFloatField';
  double getStaticDoubleField(int fieldId)
      native 'JniClass_GetStaticDoubleField';

  void setStaticObjectField(int fieldId, JniObject value)
      native 'JniClass_SetStaticObjectField';
  void setStaticBooleanField(int fieldId, bool value)
      native 'JniClass_SetStaticBooleanField';
  void setStaticByteField(int fieldId, int value)
      native 'JniClass_SetStaticByteField';
  void setStaticCharField(int fieldId, int value)
      native 'JniClass_SetStaticCharField';
  void setStaticShortField(int fieldId, int value)
      native 'JniClass_SetStaticShortField';
  void setStaticIntField(int fieldId, int value)
      native 'JniClass_SetStaticIntField';
  void setStaticLongField(int fieldId, int value)
      native 'JniClass_SetStaticLongField';
  void setStaticFloatField(int fieldId, double value)
      native 'JniClass_SetStaticFloatField';
  void setStaticDoubleField(int fieldId, double value)
      native 'JniClass_SetStaticDoubleField';

  JniObject callStaticObjectMethod(int methodId, List args)
      native 'JniClass_CallStaticObjectMethod';
  bool callStaticBooleanMethod(int methodId, List args)
      native 'JniClass_CallStaticBooleanMethod';
  int callStaticByteMethod(int methodId, List args)
      native 'JniClass_CallStaticByteMethod';
  int callStaticCharMethod(int methodId, List args)
      native 'JniClass_CallStaticCharMethod';
  int callStaticShortMethod(int methodId, List args)
      native 'JniClass_CallStaticShortMethod';
  int callStaticIntMethod(int methodId, List args)
      native 'JniClass_CallStaticIntMethod';
  int callStaticLongMethod(int methodId, List args)
      native 'JniClass_CallStaticLongMethod';
  double callStaticFloatMethod(int methodId, List args)
      native 'JniClass_CallStaticFloatMethod';
  double callStaticDoubleMethod(int methodId, List args)
      native 'JniClass_CallStaticDoubleMethod';
  void callStaticVoidMethod(int methodId, List args)
      native 'JniClass_CallStaticVoidMethod';
}

/// Wrapper for a Java object accessed via JNI.
class JniObject extends NativeFieldWrapperClass2 {
  int getIntField(int fieldId)
      native 'JniObject_GetIntField';

  JniObject callObjectMethod(int methodId, List args)
      native 'JniObject_CallObjectMethod';
  bool callBooleanMethod(int methodId, List args)
      native 'JniObject_CallBooleanMethod';
  int callIntMethod(int methodId, List args)
      native 'JniObject_CallIntMethod';
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

/// Used to pass arguments of type "float" to Java methods.
class JniFloat {
  final double value;
  JniFloat(this.value);
}
