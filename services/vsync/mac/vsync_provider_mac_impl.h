// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SERVICES_VSYNC_MAC_VSYNCPROVIDERMACIMPL_H_
#define FLUTTER_SERVICES_VSYNC_MAC_VSYNCPROVIDERMACIMPL_H_

#include <vector>

#include "base/macros.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/services/vsync/interfaces/vsync.mojom.h"

namespace sky {
namespace services {
namespace vsync {

class VsyncProviderMacImpl : public ::vsync::VSyncProvider {
 public:
  explicit VsyncProviderMacImpl(
      mojo::InterfaceRequest<::vsync::VSyncProvider> request);

  ~VsyncProviderMacImpl() override;

  void AwaitVSync(const AwaitVSyncCallback& callback) override;

 private:
  mojo::StrongBinding<::vsync::VSyncProvider> binding_;
  void* opaque_;
  std::vector<::vsync::VSyncProvider::AwaitVSyncCallback> pending_callbacks_;

  static void OnDisplayLink(void* thiz);
  void OnDisplayLink();

  DISALLOW_COPY_AND_ASSIGN(VsyncProviderMacImpl);
};

}  // namespace vsync
}  // namespace services
}  // namespace sky

#endif  // FLUTTER_SERVICES_VSYNC_MAC_VSYNCPROVIDERMACIMPL_H_
