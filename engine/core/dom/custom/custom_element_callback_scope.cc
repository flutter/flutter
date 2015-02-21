// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/dom/custom/custom_element_callback_scope.h"

#include "base/callback.h"

namespace blink {
namespace {
static CustomElementCallbackScope* g_current = nullptr;
}

CustomElementCallbackScope::CustomElementCallbackScope()
    : previous_scope_(g_current) {
  g_current = this;
}

CustomElementCallbackScope::~CustomElementCallbackScope() {
  while(!callbacks_.isEmpty()) {
    Vector<base::Closure> local;
    callbacks_.swap(local);
    for (const auto& callback : local)
      callback.Run();
  }

  g_current = previous_scope_;
}

CustomElementCallbackScope* CustomElementCallbackScope::Current() {
  return g_current;
}

void CustomElementCallbackScope::Enqueue(const base::Closure& callback) {
  callbacks_.append(callback);
}

}  // namespace blink
