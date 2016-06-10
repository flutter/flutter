// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/bindings/jni/jni_string.h"

namespace blink {

IMPLEMENT_WRAPPERTYPEINFO(jni, JniString);

JniString::JniString(JNIEnv* env, jstring object)
    : JniObject(env, object) {}

JniString::~JniString() {
}

jstring JniString::java_string() {
  return static_cast<jstring>(java_object());
}

scoped_refptr<JniString> JniString::Create(Dart_Handle dart_string) {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jstring java_string = DartJni::DartToJavaString(env, dart_string,
                                                    &exception);
    if (exception) goto fail;

    return new JniString(env, java_string);
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return nullptr;
}

Dart_Handle JniString::GetText() {
  Dart_Handle exception = nullptr;
  {
    ENTER_JNI();

    jsize length = env->GetStringLength(java_string());
    if (CheckJniException(env, &exception)) goto fail;

    const jchar* chars = env->GetStringChars(java_string(), NULL);
    if (CheckJniException(env, &exception)) goto fail;

    Dart_Handle result = Dart_NewStringFromUTF16(chars, length);
    env->ReleaseStringChars(java_string(), chars);

    return result;
  }
fail:
  Dart_ThrowException(exception);
  NOTREACHED();
  return Dart_Null();
}

} // namespace blink
