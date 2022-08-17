// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/windows_proc_table.h"

namespace flutter {

WindowsProcTable::WindowsProcTable() {
  user32_ = fml::NativeLibrary::Create("user32.dll");
  get_pointer_type_ =
      user32_->ResolveFunction<GetPointerType_*>("GetPointerType");
}

WindowsProcTable::~WindowsProcTable() {
  user32_ = nullptr;
}

BOOL WindowsProcTable::GetPointerType(UINT32 pointer_id,
                                      POINTER_INPUT_TYPE* pointer_type) {
  if (!get_pointer_type_.has_value()) {
    return FALSE;
  }

  return get_pointer_type_.value()(pointer_id, pointer_type);
}

}  // namespace flutter
