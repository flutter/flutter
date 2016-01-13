// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS_OBJC_DART_JNI_H_
#define SKY_ENGINE_BINDINGS_OBJC_DART_JNI_H_

#include "base/android/jni_android.h"
#include "base/android/jni_utils.h"
#include "sky/engine/tonic/dart_library_natives.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class DartJni {
 public:
  static void InitForGlobal();
  static void InitForIsolate();
  static bool InitJni();

  static base::android::ScopedJavaLocalRef<jclass> GetClass(
      JNIEnv* env, const char* name);

  static std::string GetObjectClassName(JNIEnv* env, jobject obj);

 private:
  static base::android::ScopedJavaGlobalRef<jobject> class_loader_;
  static jmethodID class_loader_load_class_method_id_;
  static jmethodID class_get_name_method_id_;
};

class JniObject;

// Wrapper that exposes a JNI jclass to Dart
class JniClass : public RefCounted<JniClass>, public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();

 public:
  ~JniClass() override;

  static PassRefPtr<JniClass> FromName(const char* className);

  intptr_t GetFieldId(const char* name, const char* sig);
  intptr_t GetStaticFieldId(const char* name, const char* sig);
  intptr_t GetMethodId(const char* name, const char* sig);
  intptr_t GetStaticMethodId(const char* name, const char* sig);

  jint GetStaticIntField(jfieldID fieldId);
  PassRefPtr<JniObject> GetStaticObjectField(jfieldID fieldId);

  PassRefPtr<JniObject> NewObject(jmethodID methodId,
                                  const Vector<Dart_Handle>& args);

  jlong CallStaticLongMethod(jmethodID methodId,
                             const Vector<Dart_Handle>& args);

 private:
  JniClass(JNIEnv* env, jclass clazz);

  base::android::ScopedJavaGlobalRef<jclass> clazz_;
};

// Wrapper that exposes a JNI jobject to Dart
class JniObject : public RefCounted<JniObject>, public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();

 public:
  ~JniObject() override;

  static PassRefPtr<JniObject> Create(JNIEnv* env, jobject object);

  jobject java_object() const { return object_.obj(); }

  jint GetIntField(jfieldID fieldId);

  PassRefPtr<JniObject> CallObjectMethod(jmethodID methodId,
                                         const Vector<Dart_Handle>& args);
  bool CallBooleanMethod(jmethodID methodId,
                         const Vector<Dart_Handle>& args);
  jint CallIntMethod(jmethodID methodId,
                     const Vector<Dart_Handle>& args);

 protected:
  JniObject(JNIEnv* env, jobject object);

  base::android::ScopedJavaGlobalRef<jobject> object_;
};

// Wrapper for a JNI string
class JniString : public JniObject {
  DEFINE_WRAPPERTYPEINFO();
  friend class JniObject;

 public:
  ~JniString() override;

  String GetText();

 private:
  JniString(JNIEnv* env, jstring string);

  jstring java_string();
};

// Wrapper for a JNI array
class JniArray : public JniObject {
  DEFINE_WRAPPERTYPEINFO();

 public:
  ~JniArray() override;

  jsize GetLength();

 protected:
  JniArray(JNIEnv* env, jarray array);
  template <typename JArrayType> JArrayType java_array() const;
};

class JniObjectArray : public JniArray {
  DEFINE_WRAPPERTYPEINFO();
  friend class JniObject;

 public:
  ~JniObjectArray() override;

  PassRefPtr<JniObject> GetArrayElement(jsize index);
  void SetArrayElement(jsize index, const JniObject* value);

 private:
  JniObjectArray(JNIEnv* env, jobjectArray array);
};

template <>
struct DartConverter<jfieldID> {
  static jfieldID FromArguments(Dart_NativeArguments args,
                                int index,
                                Dart_Handle& exception) {
    int64_t result = 0;
    Dart_Handle handle = Dart_GetNativeIntegerArgument(args, index, &result);
    if (Dart_IsError(handle))
      exception = handle;
    return reinterpret_cast<jfieldID>(result);
  }
};

template <>
struct DartConverter<jmethodID> {
  static jmethodID FromArguments(Dart_NativeArguments args,
                                 int index,
                                 Dart_Handle& exception) {
    int64_t result = 0;
    Dart_Handle handle = Dart_GetNativeIntegerArgument(args, index, &result);
    if (Dart_IsError(handle))
      exception = handle;
    return reinterpret_cast<jmethodID>(result);
  }
};

} // namespace blink

#endif  // SKY_ENGINE_BINDINGS_OBJC_DART_JNI_H_
