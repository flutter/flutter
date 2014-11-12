// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_APP_MODULE_H_
#define SKY_ENGINE_CORE_APP_MODULE_H_

#include "core/app/AbstractModule.h"

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

  void setExports(const ScriptValue& exports) { exports_ = exports; }
  const ScriptValue& exports() const { return exports_; }

private:
  Module(ExecutionContext* context,
         Application* application,
         PassRefPtr<Document> document,
         const String& url);
  const AtomicString& interfaceName() const override;

  RefPtr<Application> application_;
  ScriptValue exports_;
};

} // namespace blink

#endif // SKY_ENGINE_CORE_APP_MODULE_H_
