// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_APP_ABSTRACT_MODULE_H_
#define SKY_ENGINE_CORE_APP_ABSTRACT_MODULE_H_

#include "core/dom/ContextLifecycleObserver.h"
#include "core/dom/Document.h"
#include "core/events/EventTarget.h"
#include "wtf/RefCounted.h"

namespace blink {

class AbstractModule : public RefCounted<AbstractModule>,
                       public EventTargetWithInlineData,
                       public ContextLifecycleObserver {
  DEFINE_WRAPPERTYPEINFO();
  REFCOUNTED_EVENT_TARGET(AbstractModule);
 public:
  virtual ~AbstractModule();

  Document* document() const { return document_.get(); }
  const String& url() const { return url_; }

 protected:
  AbstractModule(ExecutionContext*, Document*, const String& url);

 private:
  ExecutionContext* executionContext() const override;

  RefPtr<Document> document_;
  String url_;
};

} // namespace blink

#endif // SKY_ENGINE_CORE_APP_ABSTRACT_MODULE_H_
