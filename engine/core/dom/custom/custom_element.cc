// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/dom/custom/custom_element.h"

#include "base/bind.h"
#include "dart/runtime/include/dart_api.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/Microtask.h"
#include "sky/engine/core/dom/custom/custom_element_callback_scope.h"
#include "sky/engine/core/dom/custom/custom_element_registry.h"
#include "sky/engine/tonic/dart_converter.h"
#include "sky/engine/tonic/dart_state.h"
#include "sky/engine/wtf/text/AtomicString.h"

namespace blink {
namespace {

void ScheduleCallback(const base::Closure& callback) {
  if (auto* scope = CustomElementCallbackScope::Current()) {
    scope->Enqueue(callback);
  } else {
    Microtask::enqueueMicrotask(callback);
  }
}

void CallAttributeDidChangedCallback(RefPtr<Element> element,
                                     AtomicString name,
                                     AtomicString oldValue,
                                     AtomicString newValue) {
  auto* dart_state = element->document().elementRegistry().dart_state().get();
  if (!dart_state)
    return;
  DartState::Scope scope(dart_state);
  Dart_Handle wrapper = ToDart(element);
  Dart_Handle callback = Dart_NewStringFromCString("attributeChangedCallback");
  Dart_Handle args[] = {
    StringToDart(dart_state, name),
    StringToDart(dart_state, oldValue),
    StringToDart(dart_state, newValue),
  };
  LogIfError(Dart_Invoke(wrapper, callback, arraysize(args), args));
}

void CallDidAttachedCallback(RefPtr<Element> element, RefPtr<Document> document) {
  auto* dart_state = document->elementRegistry().dart_state().get();
  if (!dart_state)
    return;
  DartState::Scope scope(dart_state);
  Dart_Handle wrapper = ToDart(element);
  Dart_Handle callback = Dart_NewStringFromCString("attachedCallback");
  LogIfError(Dart_Invoke(wrapper, callback, 0, nullptr));
}

void CallDidDetachedCallback(RefPtr<Element> element, RefPtr<Document> document) {
  auto* dart_state = document->elementRegistry().dart_state().get();
  if (!dart_state)
    return;
  DartState::Scope scope(dart_state);
  Dart_Handle wrapper = ToDart(element);
  Dart_Handle callback = Dart_NewStringFromCString("detachedCallback");
  LogIfError(Dart_Invoke(wrapper, callback, 0, nullptr));
}

}  // namespace

void CustomElement::AttributeDidChange(Element* element,
                                          const AtomicString& name,
                                          const AtomicString& oldValue,
                                          const AtomicString& newValue) {
  ScheduleCallback(base::Bind(CallAttributeDidChangedCallback,
      element, name, oldValue, newValue));
}

void CustomElement::DidAttach(Element* element, Document& document) {
  ScheduleCallback(base::Bind(CallDidAttachedCallback, element, &document));
}

void CustomElement::DidDetach(Element* element, Document& document) {
  ScheduleCallback(base::Bind(CallDidDetachedCallback, element, &document));
}

}  // namespace blink
