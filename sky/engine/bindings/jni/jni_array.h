// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS_JNI_JNI_ARRAY_H_
#define SKY_ENGINE_BINDINGS_JNI_JNI_ARRAY_H_

#include <jni.h>

#include "sky/engine/bindings/jni/jni_object.h"

namespace blink {

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

} // namespace blink

#endif  // SKY_ENGINE_BINDINGS_JNI_JNI_ARRAY_H_
