// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SERVICES_VSYNC_IOS_VSYNCPROVIDERIOSIMPL_H_
#define SKY_SERVICES_VSYNC_IOS_VSYNCPROVIDERIOSIMPL_H_

#include "base/macros.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/services/vsync/interfaces/vsync.mojom.h"

#if __OBJC__
@class VSyncClient;
#else   // __OBJC__
class VSyncClient;
#endif  // __OBJC__

namespace sky {
namespace services {
namespace vsync {

class VsyncProviderIOSImpl : public ::vsync::VSyncProvider {
 public:
  explicit VsyncProviderIOSImpl(
      mojo::InterfaceRequest<::vsync::VSyncProvider> request);
  ~VsyncProviderIOSImpl() override;
  void AwaitVSync(const AwaitVSyncCallback& callback) override;

 private:
  mojo::StrongBinding<::vsync::VSyncProvider> binding_;
  VSyncClient* client_;

  DISALLOW_COPY_AND_ASSIGN(VsyncProviderIOSImpl);
};

}  // namespace vsync
}  // namespace services
}  // namespace sky

#endif  // SKY_SERVICES_VSYNC_IOS_VSYNCPROVIDERIOSIMPL_H_
