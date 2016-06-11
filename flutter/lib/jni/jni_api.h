// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_JNI_JNI_API_H_
#define FLUTTER_LIB_JNI_JNI_API_H_

#include "flutter/lib/jni/jni_class.h"
#include "flutter/lib/jni/jni_object.h"

namespace blink {

// Dart wrappers for basic JNI APIs.
class JniApi {
 public:
  static int64_t FromReflectedField(const JniObject* field);
  static int64_t FromReflectedMethod(const JniObject* method);
  static scoped_refptr<JniObject> GetApplicationContext();
  static scoped_refptr<JniObject> GetClassLoader();
};

} // namespace blink

#endif  // FLUTTER_LIB_JNI_JNI_API_H_
