// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SERVICES_PLATFORM_IOS_PATH_PROVIDER_IMPL_H_
#define FLUTTER_SERVICES_PLATFORM_IOS_PATH_PROVIDER_IMPL_H_

#include "base/macros.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "flutter/services/platform/path_provider.mojom.h"

namespace flutter {
namespace platform {

class PathProviderImpl : public PathProvider {
 public:
  explicit PathProviderImpl(mojo::InterfaceRequest<PathProvider> request);

  ~PathProviderImpl() override;

  void TemporaryDirectory(const TemporaryDirectoryCallback& callback) override;

  void ApplicationDocumentsDirectory(
      const ApplicationDocumentsDirectoryCallback& callback) override;

 private:
  mojo::StrongBinding<PathProvider> binding_;

  DISALLOW_COPY_AND_ASSIGN(PathProviderImpl);
};

}  // namespace platform
}  // namespace flutter

#endif  // FLUTTER_SERVICES_PLATFORM_IOS_PATH_PROVIDER_IMPL_H_
