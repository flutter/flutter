// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/app/Application.h"

#include "gen/sky/core/EventTargetNames.h"

namespace blink {

Application::Application(ExecutionContext* context,
                         PassRefPtr<Document> document,
                         const String& url)
  : AbstractModule(context, document, url) {
}

Application::~Application() {
}

const AtomicString& Application::interfaceName() const {
  return EventTargetNames::Application;
}

Application* Application::GetApplication() {
  return this;
}

} // namespace blink
