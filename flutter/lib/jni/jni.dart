// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Invoke Java Native Interface APIs from Dart.
///
/// To use, import `dart:jni`.
///
/// Example:
///
///     JavaClass dateFormatClass = Java.getClass('java.text.SimpleDateFormat');
///     JavaObject format = dateFormatClass.newInstance('yyyy.MM.dd');
///     print(format.parse('2016.01.01').getYear());
///
/// This library provides a way to access Java classes that are accessible to
/// the Android runtime hosting Flutter (including Android system APIs).
///
/// The library consists of two parts: a raw module that offers Dart access
/// to low-level JNI functions, and a helper module that uses reflection to
/// build Java object wrappers that act like standard Dart objects.
///
/// # Raw JNI
///
/// Call [JniClass.fromName] to load a JNI class given its fully-qualified name.
/// The resulting [JniClass] object provides methods for constructing instances,
/// looking up field and method IDs, getting and setting static fields, and calling
/// static methods. These methods closely match the JNI functions provided by the VM.
///
/// Getters/setters of object fields and calls to methods that return objects will
/// return instances of [JniObject].  [JniObject] similarly offers wrappers of the
/// JNI functions that get and set object fields and call object methods.
///
/// Array instances are represented by [JniArray] and its subclasses, which provide
/// a Dart [List] interface backed by an underlying Java array.
///
/// # Java Object Wrappers
///
/// Call [Java.getClass] to create a [JavaClass] instance that acts as a higher-level
/// wrapper for a Java class.  Using this wrapper, you can call static methods and read
/// and write static fields using standard Dart field and method syntax.  The wrapper
/// will use reflection to locate the corresponding Java fields and methods and map Dart
/// operations to JNI calls.
///
/// Use the [JavaClass.newInstance] method to construct instances of the class.
/// `newInstance` will pass its arguments to the appropriate constructor.
///
/// Instances of Java objects are represented by [JavaObject], which similarly exposes
/// field and method accessors derived via reflection.
///
/// Dart boolean, number, and string types as well as [JavaObject] instances can be passed
/// as arguments to wrapped Java methods.  The JNI libraries will convert these arguments
/// from Dart types to the matching Java type.
///
/// Dart does not support function overloading, and as a result the Java method
/// wrappers need to locate the method on the underlying Java class that most closely
/// matches the arguments passed to the wrapper.  If there are multiple Java method overloads
/// that could be suitable for a given set of arguments and the wrappers do not choose the
/// desired overload, then you can obtain the [JniObject] wrapped by the [JavaObject] and
/// use the raw JNI library to invoke the method.

library dart_jni;

import 'dart:collection';
import 'dart:nativewrappers';

part 'jni_raw.dart';
part 'jni_helper.dart';
