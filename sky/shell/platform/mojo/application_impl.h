// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_MOJO_APPLICATION_IMPL_H_
#define SKY_SHELL_PLATFORM_MOJO_APPLICATION_IMPL_H_

#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/interfaces/application/application.mojom.h"
#include "mojo/public/interfaces/application/shell.mojom.h"
#include "mojo/services/asset_bundle/interfaces/asset_bundle.mojom.h"
#include "mojo/services/content_handler/interfaces/content_handler.mojom.h"
#include "sky/shell/platform/mojo/platform_view_mojo.h"
#include "sky/shell/shell_view.h"

#include "mojo/services/ui/views/interfaces/view_provider.mojom.h"
#include "mojo/common/binding_set.h"

namespace sky {
namespace shell {

class ApplicationImpl : public mojo::Application,
                        public mojo::ServiceProvider,
                        public mojo::ui::ViewProvider {
 public:
  ApplicationImpl(mojo::InterfaceRequest<mojo::Application> application,
                  mojo::URLResponsePtr response);
  ~ApplicationImpl() override;

 private:
  // mojo::Application
  void Initialize(mojo::ShellPtr shell,
                  mojo::Array<mojo::String> args,
                  const mojo::String& url) override;
  void AcceptConnection(
      const mojo::String& requestor_url,
      mojo::InterfaceRequest<mojo::ServiceProvider> outgoing_services,
      mojo::ServiceProviderPtr incoming_services,
      const mojo::String& resolved_url) override;
  void RequestQuit() override;

  // mojo::ServiceProvider
  void ConnectToService(const mojo::String& service_name,
                        mojo::ScopedMessagePipeHandle client_handle) override;

  // mojo::ui::ViewProvider
  void CreateView(
      mojo::InterfaceRequest<mojo::ServiceProvider> services,
      mojo::ServiceProviderPtr exposed_services,
      const mojo::ui::ViewProvider::CreateViewCallback& callback) override;

  void UnpackInitialResponse(mojo::Shell* shell);

  mojo::StrongBinding<mojo::Application> binding_;
  mojo::URLResponsePtr initial_response_;
  mojo::ServiceRegistryPtr initial_service_registry_;
  mojo::BindingSet<mojo::ServiceProvider> service_provider_bindings_;
  mojo::BindingSet<mojo::ui::ViewProvider> view_provider_bindings_;
  std::string url_;
  mojo::ShellPtr shell_;
  mojo::asset_bundle::AssetBundlePtr bundle_;
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_MOJO_APPLICATION_IMPL_H_
