// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SERVICES_NSNET_URLLOADER_IMPL_H_
#define SKY_SERVICES_NSNET_URLLOADER_IMPL_H_

#include "base/macros.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/services/network/interfaces/url_loader.mojom.h"

#if __OBJC__
@class NSData;
#else   // __OBJC__
class NSData;
#endif  // __OBJC__

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
  void* pending_connection_;
  std::unique_ptr<AsyncNSDataDrainer> request_data_drainer_;

  void StartNow(
             URLRequestPtr request,
             const StartCallback& callback, NSData* body_data);

  DISALLOW_COPY_AND_ASSIGN(URLLoaderImpl);
};

}  // namespace mojo

#endif  // SKY_SERVICES_NSNET_URLLOADER_IMPL_H_
