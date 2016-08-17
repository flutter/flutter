// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SERVICES_VSYNC_FALLBACK_VSYNCPROVIDERFALLBACKIMPL_H_
#define FLUTTER_SERVICES_VSYNC_FALLBACK_VSYNCPROVIDERFALLBACKIMPL_H_

#include "base/macros.h"
#include "base/time/time.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/services/vsync/interfaces/vsync.mojom.h"
#include "base/memory/weak_ptr.h"

#include <vector>

namespace sky {
namespace services {
namespace vsync {

class VsyncProviderFallbackImpl : public ::vsync::VSyncProvider {
 public:
  explicit VsyncProviderFallbackImpl(
      mojo::InterfaceRequest<::vsync::VSyncProvider> request);

  ~VsyncProviderFallbackImpl() override;

  void AwaitVSync(const AwaitVSyncCallback& callback) override;

 private:
  mojo::StrongBinding<::vsync::VSyncProvider> binding_;
  std::vector<AwaitVSyncCallback> pending_;
  base::TimeTicks phase_;
  bool armed_;
  base::WeakPtrFactory<VsyncProviderFallbackImpl> weak_factory_;

  void ArmIfNecessary();
  void OnFakeVSync();

  DISALLOW_COPY_AND_ASSIGN(VsyncProviderFallbackImpl);
};

}  // namespace vsync
}  // namespace services
}  // namespace sky

#endif  // FLUTTER_SERVICES_VSYNC_FALLBACK_VSYNCPROVIDERFALLBACKIMPL_H_
