// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_jni;

/// A group of methods which invoke Java Native Interface APIs from Dart.
class JniApi {
  /// Return the field ID matching a `java.lang.reflect.Field` object.
  static int fromReflectedField(JniObject field)
      native 'JniApi_FromReflectedField';

  /// Return the method ID matching a `java.lang.reflect.Method` object.
  static int fromReflectedMethod(JniObject method)
      native 'JniApi_FromReflectedMethod';

  /// The `ApplicationContext` of this Android application.
  static JniObject getApplicationContext()
      native 'JniApi_GetApplicationContext';

  /// The application's class loader.
  static JniObject getClassLoader()
      native 'JniApi_GetClassLoader';
}

/// Low-level wrapper for a Java object accessed via JNI.
/// These methods map directly to the corresponding JNI functions.  See the JNI
/// documentation for more information.
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

/// Low-level wrapper for a Java class accessed via JNI.
/// These methods map directly to the corresponding JNI functions.  See the JNI
/// documentation for more information.
class JniClass extends JniObject {
  /// Loads the Java class with the given fully qualified name.
  static JniClass fromName(String name)
      native 'JniClass_FromName';

  /// Returns a wrapper for a `java.lang.Class` object.
  static JniClass fromClassObject(JniObject classObject)
      native 'JniClass_FromClassObject';

  /// Returns a field ID for the instance field matching this name and type signature.
  /// See the JNI reference for explanation of type signatures.
  int getFieldId(String name, String sig)
      native 'JniClass_GetFieldId';

  /// Returns a field ID for a static field.
  int getStaticFieldId(String name, String sig)
      native 'JniClass_GetStaticFieldId';

  /// Returns a method ID for an instance method.
  int getMethodId(String name, String sig)
      native 'JniClass_GetMethodId';

  /// Returns a method ID for a static method.
  int getStaticMethodId(String name, String sig)
      native 'JniClass_GetStaticMethodId';

  /// Constructs an instance of the wrapped Java class..
  /// @param methodId The method ID of the constructor, obtained via getMethodId.
  /// @param args A list of argument values passed to the constructor.  Each value should
  ///             be a Dart number, bool, string, or [JniObject] instance.
  JniObject newObject(int methodId, List args)
      native 'JniClass_NewObject';

  /// Returns true if objects of the wrapped Java class can be cast to the
  /// class described by the argument.
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
  /// Construct a Java string from a Dart string.
  static JniString create(String value)
      native 'JniString_Create';

  /// Retrieve the value of the Java string represented by this object as a Dart string.
  String get text native 'JniString_GetText';

  /// Convert a JniObject representing a Java string to a Dart string.
  static String unwrap(JniObject object) => (object as JniString).text;
}

/// Wrapper for a Java array.
class JniArray extends JniObject {
  int get length native 'JniArray_GetLength';

  void set length(int value) { throw new UnsupportedError("Not supported."); }
}

/// Wrapper for a Java `Object` array.
class JniObjectArray extends JniArray with ListMixin<JniObject> {
  static JniObjectArray create(JniClass clazz, int length)
      native 'JniObjectArray_Create';

  JniObject operator [](int index)
      native 'JniObjectArray_GetArrayElement';

  void operator []=(int index, JniObject value)
      native 'JniObjectArray_SetArrayElement';
}

/// Wrapper for a Java `boolean` array.
class JniBooleanArray extends JniArray with ListMixin<bool> {
  static JniBooleanArray create(int length)
      native 'JniBooleanArray_Create';

  bool operator [](int index)
      native 'JniBooleanArray_GetArrayElement';

  void operator []=(int index, bool value)
      native 'JniBooleanArray_SetArrayElement';
}

/// Wrapper for a Java `byte` array.
class JniByteArray extends JniArray with ListMixin<int> {
  static JniByteArray create(int length)
      native 'JniByteArray_Create';

  int operator [](int index)
      native 'JniByteArray_GetArrayElement';

  void operator []=(int index, int value)
      native 'JniByteArray_SetArrayElement';
}

/// Wrapper for a Java `char` array.
class JniCharArray extends JniArray with ListMixin<int> {
  static JniCharArray create(int length)
      native 'JniCharArray_Create';

  int operator [](int index)
      native 'JniCharArray_GetArrayElement';

  void operator []=(int index, int value)
      native 'JniCharArray_SetArrayElement';
}

/// Wrapper for a Java `short` array.
class JniShortArray extends JniArray with ListMixin<int> {
  static JniShortArray create(int length)
      native 'JniShortArray_Create';

  int operator [](int index)
      native 'JniShortArray_GetArrayElement';

  void operator []=(int index, int value)
      native 'JniShortArray_SetArrayElement';
}

/// Wrapper for a Java `int` array.
class JniIntArray extends JniArray with ListMixin<int> {
  static JniIntArray create(int length)
      native 'JniIntArray_Create';

  int operator [](int index)
      native 'JniIntArray_GetArrayElement';

  void operator []=(int index, int value)
      native 'JniIntArray_SetArrayElement';
}

/// Wrapper for a Java `long` array.
class JniLongArray extends JniArray with ListMixin<int> {
  static JniLongArray create(int length)
      native 'JniLongArray_Create';

  int operator [](int index)
      native 'JniLongArray_GetArrayElement';

  void operator []=(int index, int value)
      native 'JniLongArray_SetArrayElement';
}

/// Wrapper for a Java `float` array.
class JniFloatArray extends JniArray with ListMixin<double> {
  static JniFloatArray create(int length)
      native 'JniFloatArray_Create';

  double operator [](int index)
      native 'JniFloatArray_GetArrayElement';

  void operator []=(int index, double value)
      native 'JniFloatArray_SetArrayElement';
}

/// Wrapper for a Java `double` array.
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
