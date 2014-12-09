// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/content_handler_impl.h"

#include "base/bind.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/services/public/interfaces/network/network_service.mojom.h"
#include "sky/viewer/document_view.h"

namespace sky {

class SkyApplication : public mojo::Application {
 public:
  SkyApplication(mojo::ShellPtr shell,
                 mojo::URLResponsePtr response)
      : url_(response->url),
        shell_(shell.Pass()),
        initial_response_(response.Pass()) {
    shell_.set_client(this);
    mojo::ServiceProviderPtr service_provider;
    shell_->ConnectToApplication("mojo:network_service",
                                 mojo::GetProxy(&service_provider));
    mojo::ConnectToService(service_provider.get(), &network_service_);
  }

  void Initialize(mojo::Array<mojo::String> args) override {}

  void AcceptConnection(const mojo::String& requestor_url,
                        mojo::ServiceProviderPtr provider) override {
    if (initial_response_) {
      OnResponseReceived(mojo::URLLoaderPtr(), provider.Pass(),
                         initial_response_.Pass());
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
                     base::Passed(&provider)));
    }
  }

 private:
  void OnResponseReceived(mojo::URLLoaderPtr loader,
                          mojo::ServiceProviderPtr provider,
                          mojo::URLResponsePtr response) {
    new DocumentView(provider.Pass(), response.Pass(), shell_.get());
  }

  mojo::String url_;
  mojo::ShellPtr shell_;
  mojo::NetworkServicePtr network_service_;
  mojo::URLResponsePtr initial_response_;
};

ContentHandlerImpl::ContentHandlerImpl() {
}

ContentHandlerImpl::~ContentHandlerImpl() {
}

void ContentHandlerImpl::StartApplication(mojo::ShellPtr shell,
                                          mojo::URLResponsePtr response) {
  new SkyApplication(shell.Pass(), response.Pass());
}

}  // namespace sky
