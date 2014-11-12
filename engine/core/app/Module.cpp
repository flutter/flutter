// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/app/Module.h"

#include "core/app/Application.h"
#include "core/EventTargetNames.h"

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
