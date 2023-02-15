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
  struct AttachmentConfig {
    StorageMode storage_mode;
    LoadAction load_action;
    StoreAction store_action;
  };

  struct AttachmentConfigMSAA {
    StorageMode storage_mode;
    StorageMode resolve_storage_mode;
    LoadAction load_action;
    StoreAction store_action;
  };

  static constexpr AttachmentConfig kDefaultColorAttachmentConfig = {
      .storage_mode = StorageMode::kDevicePrivate,
      .load_action = LoadAction::kClear,
      .store_action = StoreAction::kStore};

  static constexpr AttachmentConfigMSAA kDefaultColorAttachmentConfigMSAA = {
      .storage_mode = StorageMode::kDeviceTransient,
      .resolve_storage_mode = StorageMode::kDevicePrivate,
      .load_action = LoadAction::kClear,
      .store_action = StoreAction::kMultisampleResolve};

  static constexpr AttachmentConfig kDefaultStencilAttachmentConfig = {
      .storage_mode = StorageMode::kDeviceTransient,
      .load_action = LoadAction::kClear,
      .store_action = StoreAction::kDontCare};

  static RenderTarget CreateOffscreen(
      const Context& context,
      ISize size,
      const std::string& label = "Offscreen",
      AttachmentConfig color_attachment_config = kDefaultColorAttachmentConfig,
      std::optional<AttachmentConfig> stencil_attachment_config =
          kDefaultStencilAttachmentConfig);

  static RenderTarget CreateOffscreenMSAA(
      const Context& context,
      ISize size,
      const std::string& label = "Offscreen MSAA",
      AttachmentConfigMSAA color_attachment_config =
          kDefaultColorAttachmentConfigMSAA,
      std::optional<AttachmentConfig> stencil_attachment_config =
          kDefaultStencilAttachmentConfig);

  RenderTarget();

  ~RenderTarget();

  bool IsValid() const;

  SampleCount GetSampleCount() const;

  bool HasColorAttachment(size_t index) const;

  ISize GetRenderTargetSize() const;

  std::shared_ptr<Texture> GetRenderTargetTexture() const;

  PixelFormat GetRenderTargetPixelFormat() const;

  std::optional<ISize> GetColorAttachmentSize(size_t index) const;

  RenderTarget& SetColorAttachment(const ColorAttachment& attachment,
                                   size_t index);

  RenderTarget& SetDepthAttachment(std::optional<DepthAttachment> attachment);

  RenderTarget& SetStencilAttachment(
      std::optional<StencilAttachment> attachment);

  const std::map<size_t, ColorAttachment>& GetColorAttachments() const;

  const std::optional<DepthAttachment>& GetDepthAttachment() const;

  const std::optional<StencilAttachment>& GetStencilAttachment() const;

 private:
  std::map<size_t, ColorAttachment> colors_;
  std::optional<DepthAttachment> depth_;
  std::optional<StencilAttachment> stencil_;

  void IterateAllAttachments(
      const std::function<bool(const Attachment& attachment)>& iterator) const;
};

}  // namespace impeller
