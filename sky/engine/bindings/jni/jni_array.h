// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS_JNI_JNI_ARRAY_H_
#define SKY_ENGINE_BINDINGS_JNI_JNI_ARRAY_H_

#include <jni.h>

#include "sky/engine/bindings/jni/jni_class.h"
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

  static scoped_refptr<JniObjectArray> Create(const JniClass* clazz, jsize length);
  scoped_refptr<JniObject> GetArrayElement(jsize index);
  void SetArrayElement(jsize index, const JniObject* value);

 private:
  JniObjectArray(JNIEnv* env, jobjectArray array);
};

class JniBooleanArray : public JniArray {
  DEFINE_WRAPPERTYPEINFO();
  friend class JniObject;

 public:
  ~JniBooleanArray() override;

  static scoped_refptr<JniBooleanArray> Create(jsize length);
  bool GetArrayElement(jsize index);
  void SetArrayElement(jsize index, bool value);

 private:
  JniBooleanArray(JNIEnv* env, jbooleanArray array);
};

class JniByteArray : public JniArray {
  DEFINE_WRAPPERTYPEINFO();
  friend class JniObject;

 public:
  ~JniByteArray() override;

  static scoped_refptr<JniByteArray> Create(jsize length);
  int64_t GetArrayElement(jsize index);
  void SetArrayElement(jsize index, int64_t value);

 private:
  JniByteArray(JNIEnv* env, jbyteArray array);
};

class JniCharArray : public JniArray {
  DEFINE_WRAPPERTYPEINFO();
  friend class JniObject;

 public:
  ~JniCharArray() override;

  static scoped_refptr<JniCharArray> Create(jsize length);
  int64_t GetArrayElement(jsize index);
  void SetArrayElement(jsize index, int64_t value);

 private:
  JniCharArray(JNIEnv* env, jcharArray array);
};

class JniShortArray : public JniArray {
  DEFINE_WRAPPERTYPEINFO();
  friend class JniObject;

 public:
  ~JniShortArray() override;

  static scoped_refptr<JniShortArray> Create(jsize length);
  int64_t GetArrayElement(jsize index);
  void SetArrayElement(jsize index, int64_t value);

 private:
  JniShortArray(JNIEnv* env, jshortArray array);
};

class JniIntArray : public JniArray {
  DEFINE_WRAPPERTYPEINFO();
  friend class JniObject;

 public:
  ~JniIntArray() override;

  static scoped_refptr<JniIntArray> Create(jsize length);
  int64_t GetArrayElement(jsize index);
  void SetArrayElement(jsize index, int64_t value);

 private:
  JniIntArray(JNIEnv* env, jintArray array);
};

class JniLongArray : public JniArray {
  DEFINE_WRAPPERTYPEINFO();
  friend class JniObject;

 public:
  ~JniLongArray() override;

  static scoped_refptr<JniLongArray> Create(jsize length);
  int64_t GetArrayElement(jsize index);
  void SetArrayElement(jsize index, int64_t value);

 private:
  JniLongArray(JNIEnv* env, jlongArray array);
};

class JniFloatArray : public JniArray {
  DEFINE_WRAPPERTYPEINFO();
  friend class JniObject;

 public:
  ~JniFloatArray() override;

  static scoped_refptr<JniFloatArray> Create(jsize length);
  double GetArrayElement(jsize index);
  void SetArrayElement(jsize index, double value);

 private:
  JniFloatArray(JNIEnv* env, jfloatArray array);
};

class JniDoubleArray : public JniArray {
  DEFINE_WRAPPERTYPEINFO();
  friend class JniObject;

 public:
  ~JniDoubleArray() override;

  static scoped_refptr<JniDoubleArray> Create(jsize length);
  double GetArrayElement(jsize index);
  void SetArrayElement(jsize index, double value);

 private:
  JniDoubleArray(JNIEnv* env, jdoubleArray array);
};

} // namespace blink

#endif  // SKY_ENGINE_BINDINGS_JNI_JNI_ARRAY_H_
