// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_RASTERIZER_H_
#define SKY_SHELL_RASTERIZER_H_

#include <memory>

#include "base/callback.h"
#include "base/memory/scoped_ptr.h"
#include "sky/compositor/layer_tree.h"

namespace sky {
namespace shell {

typedef base::Callback<void(scoped_ptr<compositor::LayerTree>)> RasterCallback;

class Rasterizer {
 public:
  virtual ~Rasterizer();
  virtual RasterCallback GetRasterCallback() = 0;

  // Implemented by each GPU backend.
  static scoped_ptr<Rasterizer> Create();
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_RASTERIZER_H_
