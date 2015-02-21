// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/dom/custom2/new_custom_element_registry.h"

#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/html/HTMLElement.h"

namespace blink {

NewCustomElementRegistry::NewCustomElementRegistry() {
}

NewCustomElementRegistry::~NewCustomElementRegistry() {
}

void NewCustomElementRegistry::RegisterElement(const AtomicString& name,
                                               PassRefPtr<DartValue> type) {
  if (!dart_state_)
    dart_state_ = type->dart_state();
  DCHECK(dart_state_.get() == type->dart_state().get());

  auto result = registrations_.add(name, type);
  if (!result.isNewEntry) {
    // TODO(abarth): Handle the case of multiple registrations.
  }
}

PassRefPtr<Element> NewCustomElementRegistry::CreateElement(
    Document& document, const AtomicString& name) {
  const auto& it = registrations_.find(name);
  if (it != registrations_.end()) {
    DartState::Scope scope(dart_state_.get());
    Dart_Handle type = it->value->dart_value();
    Dart_Handle wrapper = Dart_New(type, Dart_EmptyString(), 0, nullptr);
    if (!LogIfError(wrapper)) {
      RefPtr<Element> element = DartConverter<Element*>::FromDart(wrapper);
      DCHECK(element);
      DCHECK(element->isUpgradedCustomElement());
      return element.release();
    }
  }
  return HTMLElement::create(QualifiedName(name), document);
}

} // namespace blink
