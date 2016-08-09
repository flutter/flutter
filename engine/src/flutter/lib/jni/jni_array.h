// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_JNI_JNI_ARRAY_H_
#define FLUTTER_LIB_JNI_JNI_ARRAY_H_

#include <jni.h>

#include "flutter/lib/jni/jni_class.h"
#include "flutter/lib/jni/jni_object.h"

namespace blink {

// Wrapper for a JNI array
class JniArray : public JniObject {
  DEFINE_WRAPPERTYPEINFO();

 public:
  ~JniArray() override;

  jsize GetLength();

 protected:
  JniArray(JNIEnv* env, jarray array);
  template <typename JArrayType>
  JArrayType java_array() const;
};

class JniObjectArray : public JniArray {
  DEFINE_WRAPPERTYPEINFO();
  friend class JniObject;
  FRIEND_MAKE_REF_COUNTED(JniObjectArray);

 public:
  ~JniObjectArray() override;

  static ftl::RefPtr<JniObjectArray> Create(const JniClass* clazz,
                                            jsize length);
  ftl::RefPtr<JniObject> GetArrayElement(jsize index);
  void SetArrayElement(jsize index, const JniObject* value);

 private:
  JniObjectArray(JNIEnv* env, jobjectArray array);
};

class JniBooleanArray : public JniArray {
  DEFINE_WRAPPERTYPEINFO();
  friend class JniObject;
  FRIEND_MAKE_REF_COUNTED(JniBooleanArray);

 public:
  ~JniBooleanArray() override;

  static ftl::RefPtr<JniBooleanArray> Create(jsize length);
  bool GetArrayElement(jsize index);
  void SetArrayElement(jsize index, bool value);

 private:
  JniBooleanArray(JNIEnv* env, jbooleanArray array);
};

class JniByteArray : public JniArray {
  DEFINE_WRAPPERTYPEINFO();
  friend class JniObject;
  FRIEND_MAKE_REF_COUNTED(JniByteArray);

 public:
  ~JniByteArray() override;

  static ftl::RefPtr<JniByteArray> Create(jsize length);
  int64_t GetArrayElement(jsize index);
  void SetArrayElement(jsize index, int64_t value);

 private:
  JniByteArray(JNIEnv* env, jbyteArray array);
};

class JniCharArray : public JniArray {
  DEFINE_WRAPPERTYPEINFO();
  friend class JniObject;
  FRIEND_MAKE_REF_COUNTED(JniCharArray);

 public:
  ~JniCharArray() override;

  static ftl::RefPtr<JniCharArray> Create(jsize length);
  int64_t GetArrayElement(jsize index);
  void SetArrayElement(jsize index, int64_t value);

 private:
  JniCharArray(JNIEnv* env, jcharArray array);
};

class JniShortArray : public JniArray {
  DEFINE_WRAPPERTYPEINFO();
  friend class JniObject;
  FRIEND_MAKE_REF_COUNTED(JniShortArray);

 public:
  ~JniShortArray() override;

  static ftl::RefPtr<JniShortArray> Create(jsize length);
  int64_t GetArrayElement(jsize index);
  void SetArrayElement(jsize index, int64_t value);

 private:
  JniShortArray(JNIEnv* env, jshortArray array);
};

class JniIntArray : public JniArray {
  DEFINE_WRAPPERTYPEINFO();
  friend class JniObject;
  FRIEND_MAKE_REF_COUNTED(JniIntArray);

 public:
  ~JniIntArray() override;

  static ftl::RefPtr<JniIntArray> Create(jsize length);
  int64_t GetArrayElement(jsize index);
  void SetArrayElement(jsize index, int64_t value);

 private:
  JniIntArray(JNIEnv* env, jintArray array);
};

class JniLongArray : public JniArray {
  DEFINE_WRAPPERTYPEINFO();
  friend class JniObject;
  FRIEND_MAKE_REF_COUNTED(JniLongArray);

 public:
  ~JniLongArray() override;

  static ftl::RefPtr<JniLongArray> Create(jsize length);
  int64_t GetArrayElement(jsize index);
  void SetArrayElement(jsize index, int64_t value);

 private:
  JniLongArray(JNIEnv* env, jlongArray array);
};

class JniFloatArray : public JniArray {
  DEFINE_WRAPPERTYPEINFO();
  friend class JniObject;
  FRIEND_MAKE_REF_COUNTED(JniFloatArray);

 public:
  ~JniFloatArray() override;

  static ftl::RefPtr<JniFloatArray> Create(jsize length);
  double GetArrayElement(jsize index);
  void SetArrayElement(jsize index, double value);

 private:
  JniFloatArray(JNIEnv* env, jfloatArray array);
};

class JniDoubleArray : public JniArray {
  DEFINE_WRAPPERTYPEINFO();
  friend class JniObject;
  FRIEND_MAKE_REF_COUNTED(JniDoubleArray);

 public:
  ~JniDoubleArray() override;

  static ftl::RefPtr<JniDoubleArray> Create(jsize length);
  double GetArrayElement(jsize index);
  void SetArrayElement(jsize index, double value);

 private:
  JniDoubleArray(JNIEnv* env, jdoubleArray array);
};

}  // namespace blink

#endif  // FLUTTER_LIB_JNI_JNI_ARRAY_H_
