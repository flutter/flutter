// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_LAYER_HOST_CLIENT_H_
#define SKY_COMPOSITOR_LAYER_HOST_CLIENT_H_

#include "base/time/time.h"
#include "mojo/services/surfaces/public/interfaces/surface_id.mojom.h"

namespace mojo {
class Shell;
}

namespace sky {

class LayerHostClient {
 public:
  virtual mojo::Shell* GetShell() = 0;
  virtual void BeginFrame(base::TimeTicks frame_time) = 0;
  virtual void OnSurfaceIdAvailable(mojo::SurfaceIdPtr surface_id) = 0;

 protected:
  virtual ~LayerHostClient();
};

}  // namespace sky

#endif  // SKY_COMPOSITOR_LAYER_HOST_CLIENT_H_
