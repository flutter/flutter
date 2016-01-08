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

  static PassRefPtr<JniClass> fromName(const char* className);

  intptr_t getFieldId(const char* name, const char* sig);
  intptr_t getStaticFieldId(const char* name, const char* sig);

  jint getStaticIntField(jfieldID fieldId);
  PassRefPtr<JniObject> getStaticObjectField(jfieldID fieldId);

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

  jint getIntField(jfieldID fieldId);

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
    Dart_GetNativeIntegerArgument(args, index, &result);
    return reinterpret_cast<jfieldID>(result);
  }
};

} // namespace blink

#endif  // SKY_ENGINE_BINDINGS_OBJC_DART_JNI_H_
