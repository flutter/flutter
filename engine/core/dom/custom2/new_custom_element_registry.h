// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_DOM_CUSTOM2_NEW_CUSTOM_ELEMENT_REGISTRY_H_
#define SKY_ENGINE_CORE_DOM_CUSTOM2_NEW_CUSTOM_ELEMENT_REGISTRY_H_

#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/tonic/dart_state.h"
#include "sky/engine/tonic/dart_value.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/text/AtomicString.h"

namespace blink {
class Document;

class NewCustomElementRegistry : public RefCounted<NewCustomElementRegistry> {
 public:
  static PassRefPtr<NewCustomElementRegistry> Create() {
    return adoptRef(new NewCustomElementRegistry());
  }

  ~NewCustomElementRegistry();

  void RegisterElement(const AtomicString& name, PassRefPtr<DartValue> type);
  PassRefPtr<Element> CreateElement(Document& document, const AtomicString& name);

  const base::WeakPtr<DartState>& dart_state() const { return dart_state_; }

 private:
  NewCustomElementRegistry();

  base::WeakPtr<DartState> dart_state_;
  HashMap<AtomicString, RefPtr<DartValue>> registrations_;

  DISALLOW_COPY_AND_ASSIGN(NewCustomElementRegistry);
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_DOM_CUSTOM2_NEW_CUSTOM_ELEMENT_REGISTRY_H_
