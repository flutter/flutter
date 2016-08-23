// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SERVICES_NSNET_URLLOADER_IMPL_H_
#define FLUTTER_SERVICES_NSNET_URLLOADER_IMPL_H_

#include <memory>

#include "base/mac/scoped_nsobject.h"
#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/services/network/interfaces/url_loader.mojom.h"

@class NSData, NSURLConnection, URLLoaderConnectionDelegate;

namespace mojo {

class AsyncNSDataDrainer;

class URLLoaderImpl : public URLLoader {
 public:
  explicit URLLoaderImpl(InterfaceRequest<URLLoader> request);

  ~URLLoaderImpl() override;

  void Start(URLRequestPtr request, const StartCallback& callback) override;

  void FollowRedirect(const FollowRedirectCallback& callback) override;

  void QueryStatus(const QueryStatusCallback& callback) override;

 private:
  StrongBinding<URLLoader> binding_;
  base::scoped_nsobject<URLLoaderConnectionDelegate> connection_delegate_;
  base::scoped_nsobject<NSURLConnection> pending_connection_;
  std::unique_ptr<AsyncNSDataDrainer> request_data_drainer_;
  base::WeakPtrFactory<URLLoaderImpl> weak_factory_;

  void StartNow(URLRequestPtr request,
                const StartCallback& callback,
                NSData* body_data);

  DISALLOW_COPY_AND_ASSIGN(URLLoaderImpl);
};

}  // namespace mojo

#endif  // FLUTTER_SERVICES_NSNET_URLLOADER_IMPL_H_
