// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/app/AbstractModule.h"

#include "sky/engine/core/app/Module.h"

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

void AbstractModule::AddLibrary(RefPtr<DartValue> library,
                                TextPosition position) {
  libraries_.append(LibraryEntry(library, position));
}

String AbstractModule::UrlForLibraryAt(TextPosition position) {
  // TODO(eseidel): This could produce invalid urls?
  // TODO(abarth): Mangle these library names to they're not predictable.
  // Otherwise you could 'import url.sky' in dart and it could magically work!
  int line = position.m_line.zeroBasedInt();
  int column = position.m_column.zeroBasedInt();
  return url() + String::format("#l%d,c%d", line, column);
}

ExecutionContext* AbstractModule::executionContext() const {
  return ContextLifecycleObserver::executionContext();
}

} // namespace blink
