// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_JS_SUPPORT_H_
#define MOJO_EDK_JS_SUPPORT_H_

#include "v8/include/v8.h"

namespace mojo {
namespace js {

class Support {
 public:
  static const char kModuleName[];
  static v8::Local<v8::Value> GetModule(v8::Isolate* isolate);
};

}  // namespace js
}  // namespace mojo

#endif  // MOJO_EDK_JS_SUPPORT_H_
