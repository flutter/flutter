// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <map>
#include <optional>

#include "flutter/fml/macros.h"
#include "impeller/geometry/size.h"
#include "impeller/renderer/allocator.h"
#include "impeller/renderer/formats.h"

namespace impeller {

class Context;

class RenderTarget {
 public:
  static RenderTarget CreateOffscreen(
      const Context& context,
      ISize size,
      std::string label = "Offscreen",
      StorageMode color_storage_mode = StorageMode::kDevicePrivate,
      LoadAction color_load_action = LoadAction::kClear,
      StoreAction color_store_action = StoreAction::kStore,
      StorageMode stencil_storage_mode = StorageMode::kDeviceTransient,
      LoadAction stencil_load_action = LoadAction::kClear,
      StoreAction stencil_store_action = StoreAction::kDontCare);

  RenderTarget();

  ~RenderTarget();

  bool IsValid() const;

  SampleCount GetSampleCount() const;

  bool HasColorAttachment(size_t index) const;

  ISize GetRenderTargetSize() const;

  std::shared_ptr<Texture> GetRenderTargetTexture() const;

  std::optional<ISize> GetColorAttachmentSize(size_t index) const;

  RenderTarget& SetColorAttachment(ColorAttachment attachment, size_t index);

  RenderTarget& SetDepthAttachment(DepthAttachment attachment);

  RenderTarget& SetStencilAttachment(StencilAttachment attachment);

  const std::map<size_t, ColorAttachment>& GetColorAttachments() const;

  const std::optional<DepthAttachment>& GetDepthAttachment() const;

  const std::optional<StencilAttachment>& GetStencilAttachment() const;

 private:
  std::map<size_t, ColorAttachment> colors_;
  std::optional<DepthAttachment> depth_;
  std::optional<StencilAttachment> stencil_;

  void IterateAllAttachments(
      std::function<bool(const Attachment& attachment)> iterator) const;
};

}  // namespace impeller
