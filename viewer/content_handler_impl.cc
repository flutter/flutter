// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/content_handler_impl.h"

#include "base/bind.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/cpp/utility/run_loop.h"
#include "mojo/services/network/public/interfaces/network_service.mojom.h"
#include "sky/viewer/document_view.h"

namespace sky {

class SkyApplication : public mojo::Application {
 public:
  SkyApplication(mojo::InterfaceRequest<mojo::Application> application,
                 mojo::URLResponsePtr response)
      : url_(response->url),
        binding_(this, application.Pass()),
        initial_response_(response.Pass()) {}

  void Initialize(mojo::ShellPtr shell,
                  mojo::Array<mojo::String> args) override {
    shell_ = shell.Pass();
    mojo::ServiceProviderPtr service_provider;
    shell_->ConnectToApplication("mojo:network_service",
                                 mojo::GetProxy(&service_provider), nullptr);
    mojo::ConnectToService(service_provider.get(), &network_service_);
  }

  void AcceptConnection(const mojo::String& requestor_url,
                        mojo::InterfaceRequest<mojo::ServiceProvider> services,
                        mojo::ServiceProviderPtr exposed_services) override {
    if (initial_response_) {
      OnResponseReceived(mojo::URLLoaderPtr(), services.Pass(),
                         exposed_services.Pass(), initial_response_.Pass());
    } else {
      mojo::URLLoaderPtr loader;
      network_service_->CreateURLLoader(mojo::GetProxy(&loader));
      mojo::URLRequestPtr request(mojo::URLRequest::New());
      request->url = url_;
      request->auto_follow_redirects = true;

      // |loader| will be pass to the OnResponseReceived method through a
      // callback. Because order of evaluation is undefined, a reference to the
      // raw pointer is needed.
      mojo::URLLoader* raw_loader = loader.get();
      raw_loader->Start(
          request.Pass(),
          base::Bind(&SkyApplication::OnResponseReceived,
                     base::Unretained(this), base::Passed(&loader),
                     base::Passed(&services), base::Passed(&exposed_services)));
    }
  }

  void RequestQuit() override {
    mojo::RunLoop::current()->Quit();
  }

 private:
  void OnResponseReceived(
      mojo::URLLoaderPtr loader,
      mojo::InterfaceRequest<mojo::ServiceProvider> services,
      mojo::ServiceProviderPtr exposed_services,
      mojo::URLResponsePtr response) {
    new DocumentView(services.Pass(), exposed_services.Pass(), response.Pass(),
                     shell_.get());
  }

  mojo::String url_;
  mojo::StrongBinding<mojo::Application> binding_;
  mojo::ShellPtr shell_;
  mojo::NetworkServicePtr network_service_;
  mojo::URLResponsePtr initial_response_;
};

ContentHandlerImpl::ContentHandlerImpl() {
}

ContentHandlerImpl::~ContentHandlerImpl() {
}

void ContentHandlerImpl::StartApplication(
    mojo::InterfaceRequest<mojo::Application> application,
    mojo::URLResponsePtr response) {
  new SkyApplication(application.Pass(), response.Pass());
}

}  // namespace sky
