// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_APP_MODULE_H_
#define SKY_ENGINE_CORE_APP_MODULE_H_

#include "sky/engine/core/app/AbstractModule.h"

namespace blink {
class Application;

class Module : public AbstractModule {
  DEFINE_WRAPPERTYPEINFO();
public:
  static PassRefPtr<Module> create(ExecutionContext* context,
                                   Application* application,
                                   PassRefPtr<Document> document,
                                   const String& url) {
    return adoptRef(new Module(context, application, document, url));
  }

  virtual ~Module();

  Application* application() const { return application_.get(); }

  void setExports(ScriptState*, const ScriptValue& exports);
  const ScriptValue& exports(ScriptState*) const;

private:
  Module(ExecutionContext* context,
         Application* application,
         PassRefPtr<Document> document,
         const String& url);
  const AtomicString& interfaceName() const override;

  Application* GetApplication() override;

  RefPtr<Application> application_;
  mutable ScriptValue exports_;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_APP_MODULE_H_
