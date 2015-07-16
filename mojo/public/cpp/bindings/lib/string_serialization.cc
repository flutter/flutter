// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/bindings/lib/string_serialization.h"

#include <string.h>

namespace mojo {

size_t GetSerializedSize_(const String& input) {
  if (!input)
    return 0;
  return internal::Align(sizeof(internal::String_Data) + input.size());
}

void Serialize_(const String& input,
                internal::Buffer* buf,
                internal::String_Data** output) {
  if (input) {
    internal::String_Data* result =
        internal::String_Data::New(input.size(), buf);
    if (result)
      memcpy(result->storage(), input.data(), input.size());
    *output = result;
  } else {
    *output = nullptr;
  }
}

void Deserialize_(internal::String_Data* input, String* output) {
  if (input) {
    String result(input->storage(), input->size());
    result.Swap(output);
  } else {
    output->reset();
  }
}

}  // namespace mojo
