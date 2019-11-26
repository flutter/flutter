// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_DART_DART_CONVERTER_H_
#define FLUTTER_FML_DART_DART_CONVERTER_H_

#include <memory>
#include <vector>

#include "flutter/fml/mapping.h"
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/tonic/converter/dart_converter.h"

namespace tonic {

using DartConverterMapping = std::unique_ptr<fml::Mapping>;

template <>
struct DartConverter<DartConverterMapping> {
  static Dart_Handle ToDart(const DartConverterMapping& val) {
    if (!val) {
      return Dart_Null();
    }

    auto dart_list_handle = Dart_NewListOf(Dart_CoreType_Int, val->GetSize());

    if (Dart_IsError(dart_list_handle)) {
      FML_LOG(ERROR) << "Error while attempting to allocate a list: "
                     << Dart_GetError(dart_list_handle);
      return dart_list_handle;
    }

    if (val->GetSize() == 0) {
      // Nothing to copy. Just return the zero sized list.
      return dart_list_handle;
    }

    auto result = Dart_ListSetAsBytes(dart_list_handle,   // list
                                      0,                  // offset
                                      val->GetMapping(),  // native array,
                                      val->GetSize()      // length
    );

    if (Dart_IsError(result)) {
      FML_LOG(ERROR) << "Error while attempting to create a Dart list: "
                     << Dart_GetError(result);
      return result;
    }

    return dart_list_handle;
  }

  static void SetReturnValue(Dart_NativeArguments args,
                             const DartConverterMapping& val) {
    Dart_SetReturnValue(args, ToDart(val));
  }

  static DartConverterMapping FromDart(Dart_Handle dart_list) {
    if (Dart_IsNull(dart_list)) {
      return nullptr;
    }

    if (Dart_IsError(dart_list)) {
      FML_LOG(ERROR) << "Cannot convert an error handle to a list: "
                     << Dart_GetError(dart_list);
      return nullptr;
    }

    if (!Dart_IsList(dart_list)) {
      FML_LOG(ERROR) << "Dart handle was not a list.";
      return nullptr;
    }

    intptr_t length = 0;
    auto handle = Dart_ListLength(dart_list, &length);

    if (Dart_IsError(handle)) {
      FML_LOG(ERROR) << "Could not get the length of the Dart list: "
                     << Dart_GetError(handle);
      return nullptr;
    }

    if (length == 0) {
      // Return a valid zero sized mapping.
      return std::make_unique<fml::NonOwnedMapping>(nullptr, 0);
    }

    auto mapping_buffer = ::malloc(length);

    if (!mapping_buffer) {
      FML_LOG(ERROR)
          << "Out of memory while attempting to allocate a mapping of size: "
          << length;
      return nullptr;
    }

    auto mapping = std::make_unique<fml::NonOwnedMapping>(
        static_cast<const uint8_t*>(mapping_buffer), length,
        [](const uint8_t* data, size_t size) {
          ::free(const_cast<uint8_t*>(data));
        });

    handle = Dart_ListGetAsBytes(
        dart_list,                              // list
        0,                                      // offset
        static_cast<uint8_t*>(mapping_buffer),  // native array
        length                                  // length
    );

    if (Dart_IsError(handle)) {
      FML_LOG(ERROR) << "Could not copy Dart list to native buffer: "
                     << Dart_GetError(handle);
      return nullptr;
    }

    return mapping;
  }
};

}  // namespace tonic

#endif  // FLUTTER_FML_DART_DART_CONVERTER_H_
