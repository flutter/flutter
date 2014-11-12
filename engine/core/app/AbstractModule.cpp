// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/app/AbstractModule.h"

namespace blink {

AbstractModule::AbstractModule(ExecutionContext* context,
                               PassRefPtr<Document> document,
                               const String& url)
  : ContextLifecycleObserver(context),
    document_(document),
    url_(url) {
  document_->setModule(this);
}

AbstractModule::~AbstractModule() {
  document_->setModule(nullptr);
}

ExecutionContext* AbstractModule::executionContext() const {
  return ContextLifecycleObserver::executionContext();
}

} // namespace blink
