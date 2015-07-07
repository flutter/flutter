// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/application/interface_factory.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/services/network/public/interfaces/url_loader.mojom.h"

namespace mojo {

class URLLoaderImpl : public URLLoader {
 public:
  explicit URLLoaderImpl(InterfaceRequest<URLLoader> request);
  ~URLLoaderImpl() override;

  void Start(URLRequestPtr request, const StartCallback& callback) override;
  void FollowRedirect(const FollowRedirectCallback& callback) override;
  void QueryStatus(const QueryStatusCallback& callback) override;

 private:
  StrongBinding<URLLoader> binding_;
  void* connection_delegate_;
  void* pending_connection_;
};

}  // namespace mojo
