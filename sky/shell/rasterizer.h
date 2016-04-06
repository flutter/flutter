// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_RASTERIZER_H_
#define SKY_SHELL_RASTERIZER_H_

#include <memory>

#include "base/callback.h"
#include "base/memory/weak_ptr.h"
#include "flow/layers/layer_tree.h"
#include "mojo/public/cpp/bindings/binding.h"
#include "sky/services/rasterizer/rasterizer.mojom.h"

namespace sky {
namespace shell {

class Rasterizer : public rasterizer::Rasterizer {
 public:
  ~Rasterizer() override;
  virtual void ConnectToRasterizer(
      mojo::InterfaceRequest<rasterizer::Rasterizer> request) = 0;
  virtual base::WeakPtr<::sky::shell::Rasterizer> GetWeakRasterizerPtr() = 0;

  virtual flow::LayerTree* GetLastLayerTree() = 0;

  // Implemented by each GPU backend.
  static std::unique_ptr<Rasterizer> Create();
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_RASTERIZER_H_
