// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_MOJO_PLATFORM_VIEW_MOJO_H_
#define SKY_SHELL_PLATFORM_MOJO_PLATFORM_VIEW_MOJO_H_

#include "mojo/public/interfaces/application/application_connector.mojom.h"
#include "mojo/services/gfx/composition/interfaces/scenes.mojom.h"
#include "sky/shell/platform_view.h"

namespace sky {
namespace shell {

class PlatformViewMojo : public PlatformView {
 public:
  explicit PlatformViewMojo(const Config& config);
  ~PlatformViewMojo() override;

  void InitRasterizer(mojo::ApplicationConnectorPtr connector,
                      mojo::gfx::composition::ScenePtr scene);

 private:
  DISALLOW_COPY_AND_ASSIGN(PlatformViewMojo);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_MOJO_PLATFORM_VIEW_MOJO_H_
