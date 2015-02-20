// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_APP_ABSTRACTMODULE_H_
#define SKY_ENGINE_CORE_APP_ABSTRACTMODULE_H_

#include "sky/engine/core/dom/ContextLifecycleObserver.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/events/EventTarget.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {
class Application;

class LibraryEntry {
 public:
  LibraryEntry(PassRefPtr<DartValue> library, TextPosition position)
      : dart_library_(library), text_position_(position) {}

  DartValue* library() const { return dart_library_.get(); }
  const TextPosition& position() const { return text_position_; }

 private:
  RefPtr<DartValue> dart_library_;
  TextPosition text_position_;
};

class AbstractModule : public RefCounted<AbstractModule>,
                       public EventTargetWithInlineData,
                       public ContextLifecycleObserver {
  REFCOUNTED_EVENT_TARGET(AbstractModule);
 public:
  virtual ~AbstractModule();

  Document* document() const { return document_.get(); }
  const String& url() const { return url_; }

  virtual bool isApplication() const { return false; }

  String UrlForLibraryAt(TextPosition);

  void AddLibrary(RefPtr<DartValue> library, TextPosition position);
  const Vector<LibraryEntry>& libraries() const { return libraries_; }

 protected:
  AbstractModule(ExecutionContext*, PassRefPtr<Document>, const String& url);

  virtual Application* GetApplication() = 0;

 private:
  ExecutionContext* executionContext() const override;

  RefPtr<Document> document_;
  String url_;
  Vector<LibraryEntry> libraries_;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_APP_ABSTRACTMODULE_H_
