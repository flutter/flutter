// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/tonic/dart_string.h"

#include "base/logging.h"

namespace blink {
namespace {

void FinalizeString(void* string_impl) {
  DCHECK(string_impl);
  reinterpret_cast<StringImpl*>(string_impl)->deref();
}

template <typename CharType>
String Externalize(Dart_Handle handle, intptr_t length) {
  if (!length)
    return StringImpl::empty();
  CharType* buffer = nullptr;
  RefPtr<StringImpl> string_impl =
      StringImpl::createUninitialized(length, buffer);

  string_impl->ref();  // Balanced in FinalizeString.

  Dart_Handle result =
      Dart_MakeExternalString(handle, buffer, length * sizeof(CharType),
                              string_impl.get(), FinalizeString);
  DCHECK(!Dart_IsError(result));
  return String(string_impl.release());
}

}  // namespace

Dart_Handle CreateDartString(StringImpl* string_impl) {
  if (!string_impl)
    return Dart_EmptyString();

  string_impl->ref();  // Balanced in FinalizeString.

  if (string_impl->is8Bit()) {
    return Dart_NewExternalLatin1String(string_impl->characters8(),
                                        string_impl->length(), string_impl,
                                        FinalizeString);
  } else {
    return Dart_NewExternalUTF16String(string_impl->characters16(),
                                       string_impl->length(), string_impl,
                                       FinalizeString);
  }
}

String ExternalizeDartString(Dart_Handle handle) {
  DCHECK(Dart_IsString(handle));
  DCHECK(!Dart_IsExternalString(handle));
  bool is_latin1 = Dart_IsStringLatin1(handle);
  intptr_t length;
  Dart_StringLength(handle, &length);
  if (is_latin1)
    return Externalize<LChar>(handle, length);
  return Externalize<UChar>(handle, length);
}

}  // namespace blink
