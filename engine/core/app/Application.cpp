// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/app/Application.h"

#include "core/EventTargetNames.h"

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
