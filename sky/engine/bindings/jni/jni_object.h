// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS_JNI_JNI_OBJECT_H_
#define SKY_ENGINE_BINDINGS_JNI_JNI_OBJECT_H_

#include <jni.h>

#include "base/android/jni_android.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"

namespace blink {

// Wrapper that exposes a JNI jobject to Dart
class JniObject : public RefCounted<JniObject>, public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();

 public:
  ~JniObject() override;

  static PassRefPtr<JniObject> Create(JNIEnv* env, jobject object);

  jobject java_object() const { return object_.obj(); }

  int64_t GetIntField(jfieldID fieldId);

  PassRefPtr<JniObject> CallObjectMethod(jmethodID methodId,
                                         const Vector<Dart_Handle>& args);
  bool CallBooleanMethod(jmethodID methodId,
                         const Vector<Dart_Handle>& args);
  int64_t CallIntMethod(jmethodID methodId,
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

} // namespace blink

#endif  // SKY_ENGINE_BINDINGS_JNI_JNI_OBJECT_H_
