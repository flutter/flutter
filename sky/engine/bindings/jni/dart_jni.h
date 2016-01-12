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

 private:
  static base::android::ScopedJavaGlobalRef<jobject> class_loader_;
  static jmethodID load_class_method_id_;
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

  static PassRefPtr<JniObject> create(JNIEnv* env, jobject object);

  jint GetIntField(jfieldID fieldId);

 private:
  JniObject(JNIEnv* env, jobject object);

  base::android::ScopedJavaGlobalRef<jobject> object_;
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
