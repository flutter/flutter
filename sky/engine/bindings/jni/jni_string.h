// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS_JNI_JNI_STRING_H_
#define SKY_ENGINE_BINDINGS_JNI_JNI_STRING_H_

#include "sky/engine/bindings/jni/dart_jni.h"
#include "sky/engine/bindings/jni/jni_object.h"

namespace blink {

// Wrapper for a JNI string
class JniString : public JniObject {
  DEFINE_WRAPPERTYPEINFO();
  friend class JniObject;

 public:
  ~JniString() override;

  static scoped_refptr<JniString> Create(Dart_Handle dart_string);
  Dart_Handle GetText();

 private:
  JniString(JNIEnv* env, jstring string);

  jstring java_string();
};

} // namespace blink

#endif  // SKY_ENGINE_BINDINGS_JNI_JNI_STRING_H_
