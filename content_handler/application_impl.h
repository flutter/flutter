// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_APPLICATION_IMPL_H_
#define FLUTTER_CONTENT_HANDLER_APPLICATION_IMPL_H_

#include <memory>

#include "apps/mozart/services/views/interfaces/view_provider.mojom.h"
#include "flutter/glue/drain_data_pipe_job.h"
#include "lib/ftl/macros.h"
#include "mojo/public/cpp/bindings/binding_set.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/interfaces/application/application.mojom.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"
#include "mojo/public/interfaces/application/shell.mojom.h"
#include "mojo/services/content_handler/interfaces/content_handler.mojom.h"

namespace flutter_content_handler {
class RuntimeHolder;

class ApplicationImpl : public mojo::Application,
                        public mojo::ServiceProvider,
                        public mozart::ViewProvider {
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

  // mojo::ServiceProvider
  void ConnectToService(const mojo::String& service_name,
                        mojo::ScopedMessagePipeHandle client_handle) override;

  // mozart::ViewProvider
  void CreateView(
      mojo::InterfaceRequest<mozart::ViewOwner> view_owner_request,
      mojo::InterfaceRequest<mojo::ServiceProvider> services) override;

  void StartRuntimeIfReady();

  mojo::StrongBinding<mojo::Application> binding_;
  std::unique_ptr<glue::DrainDataPipeJob> drainer_;

  mojo::BindingSet<mojo::ServiceProvider> service_provider_bindings_;
  mojo::BindingSet<mozart::ViewProvider> view_provider_bindings_;

  std::vector<char> bundle_;
  mojo::ShellPtr shell_;
  std::string url_;

  std::unique_ptr<RuntimeHolder> runtime_holder_;

  FTL_DISALLOW_COPY_AND_ASSIGN(ApplicationImpl);
};

}  // namespace flutter_content_handler

#endif  // FLUTTER_CONTENT_HANDLER_APPLICATION_IMPL_H_
