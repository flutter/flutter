// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/dom/Element.h"

#include "dart/runtime/include/dart_api.h"
#include "sky/engine/core/script/dom_dart_state.h"
#include "sky/engine/tonic/dart_converter.h"

namespace blink {
namespace DartElementInternal {

void constructorCallback(Dart_NativeArguments args) {
  Dart_Handle receiver = Dart_GetNativeArgument(args, 0);
  DCHECK(!LogIfError(receiver));

  Dart_Handle tag_name = Dart_GetField(receiver,
                                       Dart_NewStringFromCString("tagName"));
  if (!Dart_IsString(tag_name)) {
    Dart_ThrowException(Dart_NewStringFromCString("tagName is not a string"));
    return;
  }

  RefPtr<Element> element = Element::create(
      QualifiedName(StringFromDart(tag_name)), DOMDartState::CurrentDocument());

  // TODO(abarth): We should remove these states because elements are never
  // waiting for upgrades.
  element->setCustomElementState(Element::WaitingForUpgrade);
  element->setCustomElementState(Element::Upgraded);
  element->AssociateWithDartWrapper(args);
}

}  // namespace DartElementInternal
}  // namespace blink
