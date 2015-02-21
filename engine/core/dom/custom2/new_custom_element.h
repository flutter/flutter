// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_DOM_CUSTOM_NEW_CUSTOM_ELEMENT_H_
#define SKY_ENGINE_CORE_DOM_CUSTOM_NEW_CUSTOM_ELEMENT_H_

#include "sky/engine/wtf/text/AtomicString.h"

namespace blink {
class Document;
class Element;

class NewCustomElement {
 public:
  static void AttributeDidChange(Element*, const AtomicString& name, const AtomicString& oldValue, const AtomicString& newValue);
  static void DidAttach(Element*, Document&);
  static void DidDetach(Element*, Document&);

 private:
  NewCustomElement();
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_DOM_CUSTOM_NEW_CUSTOM_ELEMENT_H_
