// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_APP_APPLICATION_H_
#define SKY_ENGINE_CORE_APP_APPLICATION_H_

#include "sky/engine/core/app/AbstractModule.h"

namespace blink {

class Application : public AbstractModule {
  DEFINE_WRAPPERTYPEINFO();
public:
  static PassRefPtr<Application> create(ExecutionContext* context,
                                        PassRefPtr<Document> document,
                                        const String& url) {
    return adoptRef(new Application(context, document, url));
  }

  virtual ~Application();

  void setTitle(const String& title) { title_ = title; }
  const String& title() { return title_; }

private:
  Application(ExecutionContext* context,
              PassRefPtr<Document> document,
              const String& url);
  const AtomicString& interfaceName() const override;

  Application* GetApplication() override;

  String title_;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_APP_APPLICATION_H_
