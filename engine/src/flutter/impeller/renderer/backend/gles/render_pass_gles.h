// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/impeller/renderer/backend/gles/reactor_gles.h"
#include "flutter/impeller/renderer/render_pass.h"

namespace impeller {

class RenderPassGLES final
    : public RenderPass,
      public std::enable_shared_from_this<RenderPassGLES> {
 public:
  // |RenderPass|
  ~RenderPassGLES() override;

 private:
  friend class CommandBufferGLES;

  ReactorGLES::Ref reactor_;
  std::string label_;
  bool is_valid_ = false;

  RenderPassGLES(std::weak_ptr<const Context> context,
                 const RenderTarget& target,
                 ReactorGLES::Ref reactor);

  // |RenderPass|
  bool IsValid() const override;

  // |RenderPass|
  void OnSetLabel(std::string label) override;

  // |RenderPass|
  bool OnEncodeCommands(const Context& context) const override;

  RenderPassGLES(const RenderPassGLES&) = delete;

  RenderPassGLES& operator=(const RenderPassGLES&) = delete;
};

}  // namespace impeller
