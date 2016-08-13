// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_APPLICATION_IMPL_H_
#define FLUTTER_CONTENT_HANDLER_APPLICATION_IMPL_H_

#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/interfaces/application/application.mojom.h"
#include "mojo/public/interfaces/application/shell.mojom.h"
#include "mojo/services/content_handler/interfaces/content_handler.mojom.h"

namespace flutter_content_handler {

class ApplicationImpl : public mojo::Application {
 public:
  ApplicationImpl(mojo::InterfaceRequest<mojo::Application> application,
                  mojo::URLResponsePtr response);
  ~ApplicationImpl() override;

 private:
  // mojo::Application
  void Initialize(mojo::InterfaceHandle<mojo::Shell> shell,
                  mojo::Array<mojo::String> args,
                  const mojo::String& url) override;
  void AcceptConnection(
      const mojo::String& requestor_url,
      const mojo::String& resolved_url,
      mojo::InterfaceRequest<mojo::ServiceProvider> services) override;
  void RequestQuit() override;

  mojo::StrongBinding<mojo::Application> binding_;
  mojo::URLResponsePtr initial_response_;
  std::string url_;
  mojo::ShellPtr shell_;
};

}  // namespace flutter_content_handler

#endif  // FLUTTER_CONTENT_HANDLER_APPLICATION_IMPL_H_
