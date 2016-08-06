// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_JNI_DART_JNI_H_
#define FLUTTER_LIB_JNI_DART_JNI_H_

#include <vector>

#include "base/android/jni_android.h"
#include "base/android/jni_utils.h"
#include "lib/tonic/dart_library_natives.h"
#include "lib/tonic/dart_wrappable.h"

#define ENTER_JNI()                                   \
  JNIEnv* env = base::android::AttachCurrentThread(); \
  base::android::ScopedJavaLocalFrame java_frame(env);

namespace blink {

bool CheckJniException(JNIEnv* env, Dart_Handle* exception);
bool CheckDartException(Dart_Handle result, Dart_Handle* exception);

// Data cached for each Dart isolate.
struct DartJniIsolateData {
  Dart_PersistentHandle jni_object_type;
  Dart_PersistentHandle jni_float_type;
};

typedef DartJniIsolateData* (*DartJniIsolateDataProvider)();

class DartJni {
 public:
  static void InitForGlobal(DartJniIsolateDataProvider provider);
  static void InitForIsolate();
  static bool InitJni();
  static void OnThreadExit();

  static base::android::ScopedJavaLocalRef<jclass> GetClass(JNIEnv* env,
                                                            const char* name);

  static std::string GetObjectClassName(JNIEnv* env, jobject obj);

  static jstring DartToJavaString(JNIEnv* env,
                                  Dart_Handle dart_string,
                                  Dart_Handle* exception);

  static jobject class_loader();
  static jclass class_clazz();
  static Dart_Handle jni_object_type();
  static Dart_Handle jni_float_type();
};

class JniMethodArgs {
 public:
  void Convert(JNIEnv* env,
               const std::vector<Dart_Handle>& dart_args,
               Dart_Handle* exception);
  jvalue* jvalues() { return jvalues_.data(); }

 private:
  jvalue DartToJavaValue(JNIEnv* env,
                         Dart_Handle handle,
                         Dart_Handle* exception);

  std::vector<jvalue> jvalues_;
};

}  // namespace blink

namespace tonic {

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

}  // namespace tonic

#endif  // FLUTTER_LIB_JNI_DART_JNI_H_
