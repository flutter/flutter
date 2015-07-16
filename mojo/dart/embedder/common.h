// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_DART_EMBEDDER_COMMON_H_
#define MOJO_DART_EMBEDDER_COMMON_H_

#include "base/logging.h"
#include "base/macros.h"
#include "dart/runtime/include/dart_api.h"

namespace mojo {
namespace dart {

class DartEmbedder {
 public:
  // Returns the integer value of a Dart object. If the object is not
  // an integer value an API error is propagated.
  static int64_t GetIntegerValue(Dart_Handle value_obj);
  // Returns the integer value of a Dart object. If the object is not
  // an integer value or outside the requested range an API error is
  // propagated.
  static int64_t GetInt64ValueCheckRange(
      Dart_Handle value_obj, int64_t lower, int64_t upper);
  // Returns the intptr_t value of a Dart object. If the object is not
  // an integer value or the value is outside the intptr_t range an
  // API error is propagated.
  static intptr_t GetIntptrValue(Dart_Handle value_obj);
  // Returns the string value of a Dart object. If the object is not
  // a string value an API error is propagated.
  static const char* GetStringValue(Dart_Handle str_obj);
  // Returns the boolean value of a Dart object. If the object is not
  // a boolean value an API error is propagated.
  static bool GetBooleanValue(Dart_Handle bool_obj);
  // Sets the field "name" in handle to val. Any error is propagated.
  static void SetIntegerField(Dart_Handle handle,
                              const char* name,
                              int64_t val);
  // Sets the field "name" in handle to val. Any error is propagated.
  static void SetStringField(Dart_Handle handle,
                             const char* name,
                             const char* val);
  // Returns a new Dart string. Any error is propagated.
  static Dart_Handle NewCString(const char* str);

  // Sets the return value in arguments to null.
  static void SetNullReturn(Dart_NativeArguments arguments);

  // Sets the return value in arguments to a string created from |str|.
  static void SetCStringReturn(Dart_NativeArguments arguments, const char* str);

  // Gets the string argument at index and returns a C string.
  // Any error is propagated.
  static const char* GetStringArgument(Dart_NativeArguments arguments,
                                       intptr_t index);

  // Copies the bytes from a TypedDataList argument at |index| into a C array.
  // Any error is propagated. Caller must call free on |out|.
  // NOTE: Only supports Uint8List now.
  static void GetTypedDataListArgument(Dart_NativeArguments arguments,
                                       intptr_t index,
                                       uint8_t** out,
                                       intptr_t* out_len);

  // Creates a Uint8List with a copy of bytes.
  // Any error is propagated.
  static Dart_Handle MakeUint8TypedData(uint8_t* bytes, intptr_t length);
};

}  // namespace dart
}  // namespace mojo


#endif  // MOJO_DART_EMBEDDER_COMMON_H_
