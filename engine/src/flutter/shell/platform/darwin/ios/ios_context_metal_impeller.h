// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_CONTEXT_METAL_IMPELER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_CONTEXT_METAL_IMPELER_H_

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/darwin/graphics/FlutterDarwinContextMetalImpeller.h"
#include "flutter/shell/platform/darwin/graphics/FlutterDarwinContextMetalSkia.h"
#include "flutter/shell/platform/darwin/ios/ios_context.h"

namespace impeller {

class Context;

}  // namespace impeller

namespace flutter {

class IOSContextMetalImpeller final : public IOSContext {
 public:
  IOSContextMetalImpeller(std::shared_ptr<const fml::SyncSwitch> is_gpu_disabled_sync_switch);

  ~IOSContextMetalImpeller();

  fml::scoped_nsobject<FlutterDarwinContextMetalSkia> GetDarwinContext() const;

  IOSRenderingBackend GetBackend() const override;

  // |IOSContext|
  sk_sp<GrDirectContext> GetMainContext() const override;

  sk_sp<GrDirectContext> GetResourceContext() const;

 private:
  fml::scoped_nsobject<FlutterDarwinContextMetalImpeller> darwin_context_metal_impeller_;

  // |IOSContext|
  sk_sp<GrDirectContext> CreateResourceContext() override;

  // |IOSContext|
  std::unique_ptr<GLContextResult> MakeCurrent() override;

  // |IOSContext|
  std::unique_ptr<Texture> CreateExternalTexture(
      int64_t texture_id,
      fml::scoped_nsobject<NSObject<FlutterTexture>> texture) override;

  // |IOSContext|
  std::shared_ptr<impeller::Context> GetImpellerContext() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSContextMetalImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_CONTEXT_METAL_IMPELER_H_
