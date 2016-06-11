// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_jni;

/// Invoke Java Native Interface APIs from Dart.
class JniApi {
  static int fromReflectedField(JniObject field)
      native 'JniApi_FromReflectedField';
  static int fromReflectedMethod(JniObject method)
      native 'JniApi_FromReflectedMethod';

  static JniObject getApplicationContext()
      native 'JniApi_GetApplicationContext';
  static JniObject getClassLoader()
      native 'JniApi_GetClassLoader';
}

/// Wrapper for a Java object accessed via JNI.
class JniObject extends NativeFieldWrapperClass2 {
  JniClass getObjectClass()
      native 'JniObject_GetObjectClass';

  JniObject getObjectField(int fieldId)
      native 'JniObject_GetObjectField';
  bool getBooleanField(int fieldId)
      native 'JniObject_GetBooleanField';
  int getByteField(int fieldId)
      native 'JniObject_GetByteField';
  int getCharField(int fieldId)
      native 'JniObject_GetCharField';
  int getShortField(int fieldId)
      native 'JniObject_GetShortField';
  int getIntField(int fieldId)
      native 'JniObject_GetIntField';
  int getLongField(int fieldId)
      native 'JniObject_GetLongField';
  double getFloatField(int fieldId)
      native 'JniObject_GetFloatField';
  double getDoubleField(int fieldId)
      native 'JniObject_GetDoubleField';

  void setObjectField(int fieldId, JniObject value)
      native 'JniObject_SetObjectField';
  void setBooleanField(int fieldId, bool value)
      native 'JniObject_SetBooleanField';
  void setByteField(int fieldId, int value)
      native 'JniObject_SetByteField';
  void setCharField(int fieldId, int value)
      native 'JniObject_SetCharField';
  void setShortField(int fieldId, int value)
      native 'JniObject_SetShortField';
  void setIntField(int fieldId, int value)
      native 'JniObject_SetIntField';
  void setLongField(int fieldId, int value)
      native 'JniObject_SetLongField';
  void setFloatField(int fieldId, double value)
      native 'JniObject_SetFloatField';
  void setDoubleField(int fieldId, double value)
      native 'JniObject_SetDoubleField';

  JniObject callObjectMethod(int methodId, List args)
      native 'JniObject_CallObjectMethod';
  bool callBooleanMethod(int methodId, List args)
      native 'JniObject_CallBooleanMethod';
  int callByteMethod(int methodId, List args)
      native 'JniObject_CallByteMethod';
  int callCharMethod(int methodId, List args)
      native 'JniObject_CallCharMethod';
  int callShortMethod(int methodId, List args)
      native 'JniObject_CallShortMethod';
  int callIntMethod(int methodId, List args)
      native 'JniObject_CallIntMethod';
  int callLongMethod(int methodId, List args)
      native 'JniObject_CallLongMethod';
  double callFloatMethod(int methodId, List args)
      native 'JniObject_CallFloatMethod';
  double callDoubleMethod(int methodId, List args)
      native 'JniObject_CallDoubleMethod';
  void callVoidMethod(int methodId, List args)
      native 'JniObject_CallVoidMethod';
}

/// Wrapper for a Java class accessed via JNI.
class JniClass extends JniObject {
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

  bool isAssignable(JniClass clazz)
      native 'JniClass_IsAssignable';

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

/// Wrapper for a Java string.
class JniString extends JniObject {
  static JniString create(String value)
      native 'JniString_Create';

  // Retrieve the value as a Dart string.
  String get text native 'JniString_GetText';

  static String unwrap(JniObject object) => (object as JniString).text;
}

/// Wrapper for a Java array.
class JniArray extends JniObject {
  int get length native 'JniArray_GetLength';

  void set length(int value) { throw new UnsupportedError("Not supported."); }
}

class JniObjectArray extends JniArray with ListMixin<JniObject> {
  static JniObjectArray create(JniClass clazz, int length)
      native 'JniObjectArray_Create';

  JniObject operator [](int index)
      native 'JniObjectArray_GetArrayElement';

  void operator []=(int index, JniObject value)
      native 'JniObjectArray_SetArrayElement';
}

class JniBooleanArray extends JniArray with ListMixin<bool> {
  static JniBooleanArray create(int length)
      native 'JniBooleanArray_Create';

  bool operator [](int index)
      native 'JniBooleanArray_GetArrayElement';

  void operator []=(int index, bool value)
      native 'JniBooleanArray_SetArrayElement';
}

class JniByteArray extends JniArray with ListMixin<int> {
  static JniByteArray create(int length)
      native 'JniByteArray_Create';

  int operator [](int index)
      native 'JniByteArray_GetArrayElement';

  void operator []=(int index, int value)
      native 'JniByteArray_SetArrayElement';
}

class JniCharArray extends JniArray with ListMixin<int> {
  static JniCharArray create(int length)
      native 'JniCharArray_Create';

  int operator [](int index)
      native 'JniCharArray_GetArrayElement';

  void operator []=(int index, int value)
      native 'JniCharArray_SetArrayElement';
}

class JniShortArray extends JniArray with ListMixin<int> {
  static JniShortArray create(int length)
      native 'JniShortArray_Create';

  int operator [](int index)
      native 'JniShortArray_GetArrayElement';

  void operator []=(int index, int value)
      native 'JniShortArray_SetArrayElement';
}

class JniIntArray extends JniArray with ListMixin<int> {
  static JniIntArray create(int length)
      native 'JniIntArray_Create';

  int operator [](int index)
      native 'JniIntArray_GetArrayElement';

  void operator []=(int index, int value)
      native 'JniIntArray_SetArrayElement';
}

class JniLongArray extends JniArray with ListMixin<int> {
  static JniLongArray create(int length)
      native 'JniLongArray_Create';

  int operator [](int index)
      native 'JniLongArray_GetArrayElement';

  void operator []=(int index, int value)
      native 'JniLongArray_SetArrayElement';
}

class JniFloatArray extends JniArray with ListMixin<double> {
  static JniFloatArray create(int length)
      native 'JniFloatArray_Create';

  double operator [](int index)
      native 'JniFloatArray_GetArrayElement';

  void operator []=(int index, double value)
      native 'JniFloatArray_SetArrayElement';
}

class JniDoubleArray extends JniArray with ListMixin<double> {
  static JniDoubleArray create(int length)
      native 'JniDoubleArray_Create';

  double operator [](int index)
      native 'JniDoubleArray_GetArrayElement';

  void operator []=(int index, double value)
      native 'JniDoubleArray_SetArrayElement';
}

/// Used to pass arguments of type "float" to Java methods.
class JniFloat {
  final double value;
  JniFloat(this.value);
}
