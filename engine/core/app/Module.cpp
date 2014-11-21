// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/app/Module.h"

#include "gen/sky/core/EventTargetNames.h"
#include "sky/engine/core/app/Application.h"

namespace blink {

Module::Module(ExecutionContext* context,
               Application* application,
               PassRefPtr<Document> document,
               const String& url)
  : AbstractModule(context, document, url),
    application_(application) {
}

Module::~Module() {
}

const AtomicString& Module::interfaceName() const {
  return EventTargetNames::Module;
}

Application* Module::GetApplication() {
  return application();
}

} // namespace blink
