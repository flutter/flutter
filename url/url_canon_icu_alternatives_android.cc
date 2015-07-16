// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string.h>

#include "base/android/jni_android.h"
#include "base/android/jni_string.h"
#include "base/strings/string16.h"
#include "base/strings/string_piece.h"
#include "jni/IDNStringUtil_jni.h"
#include "url/url_canon_internal.h"

namespace url {

// This uses the JDK's conversion function, which uses IDNA 2003, unlike the
// ICU implementation.
bool IDNToASCII(const base::char16* src, int src_len, CanonOutputW* output) {
  DCHECK_EQ(0, output->length());  // Output buffer is assumed empty.

  JNIEnv* env = base::android::AttachCurrentThread();
  base::android::ScopedJavaLocalRef<jstring> java_src =
      base::android::ConvertUTF16ToJavaString(
          env, base::StringPiece16(src, src_len));
  ScopedJavaLocalRef<jstring> java_result =
      android::Java_IDNStringUtil_idnToASCII(env, java_src.obj());
  // NULL indicates failure.
  if (java_result.is_null())
    return false;

  base::string16 utf16_result =
      base::android::ConvertJavaStringToUTF16(java_result);
  output->Append(utf16_result.data(), static_cast<int>(utf16_result.size()));
  return true;
}

bool RegisterIcuAlternativesJni(JNIEnv* env) {
  return android::RegisterNativesImpl(env);
}

}  // namespace url
