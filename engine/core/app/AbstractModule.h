// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_APP_ABSTRACTMODULE_H_
#define SKY_ENGINE_CORE_APP_ABSTRACTMODULE_H_

#include "sky/engine/bindings/core/v8/ScriptPromiseResolver.h"
#include "sky/engine/core/app/ModuleLoader.h"
#include "sky/engine/core/dom/ContextLifecycleObserver.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/events/EventTarget.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {
class Application;

class AbstractModule : public RefCounted<AbstractModule>,
                       public EventTargetWithInlineData,
                       public ContextLifecycleObserver,
                       public ModuleLoader::Client {
  DEFINE_WRAPPERTYPEINFO();
  REFCOUNTED_EVENT_TARGET(AbstractModule);
 public:
  virtual ~AbstractModule();

  Document* document() const { return document_.get(); }
  const String& url() const { return url_; }

  ScriptPromise import(ScriptState*, const String& url);

 protected:
  AbstractModule(ExecutionContext*, PassRefPtr<Document>, const String& url);

  virtual Application* GetApplication() = 0;

 private:
  ExecutionContext* executionContext() const override;

  void OnModuleLoadComplete(ModuleLoader*, Module*) override;

  RefPtr<Document> document_;
  String url_;

  HashMap<OwnPtr<ModuleLoader>, RefPtr<ScriptPromiseResolver>> loaders_;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_APP_ABSTRACTMODULE_H_
