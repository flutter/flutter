// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_DOM_CUSTOM_NEW_CUSTOM_ELEMENT_CALLBACK_SCOPE_H_
#define SKY_ENGINE_CORE_DOM_CUSTOM_NEW_CUSTOM_ELEMENT_CALLBACK_SCOPE_H_

#include "base/callback_forward.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

class CustomElementCallbackScope {
 public:
  CustomElementCallbackScope();
  ~CustomElementCallbackScope();

  void Enqueue(const base::Closure&);

  static CustomElementCallbackScope* Current();

 private:
  CustomElementCallbackScope* previous_scope_;
  Vector<base::Closure> callbacks_;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_DOM_CUSTOM_NEW_CUSTOM_ELEMENT_CALLBACK_SCOPE_H_
