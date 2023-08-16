// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <map>
#include <optional>

#include "flutter/fml/macros.h"
#include "impeller/core/allocator.h"
#include "impeller/core/formats.h"
#include "impeller/geometry/size.h"

namespace impeller {

class Context;

/// @brief a wrapper around the impeller [Allocator] instance that can be used
///        to provide caching of allocated render target textures.
class RenderTargetAllocator {
 public:
  explicit RenderTargetAllocator(std::shared_ptr<Allocator> allocator);

  virtual ~RenderTargetAllocator() = default;

  /// @brief Create a new render target texture, or recycle a previously
  /// allocated render
  ///        target texture.
  virtual std::shared_ptr<Texture> CreateTexture(const TextureDescriptor& desc);

  /// @brief Mark the beginning of a frame workload.
  ///
  ///       This may be used to reset any tracking state on whether or not a
  ///       particular texture instance is still in use.
  virtual void Start();

  /// @brief Mark the end of a frame workload.
  ///
  ///        This may be used to deallocate any unused textures.
  virtual void End();

 private:
  std::shared_ptr<Allocator> allocator_;
};

class RenderTarget final {
 public:
  struct AttachmentConfig {
    StorageMode storage_mode;
    LoadAction load_action;
    StoreAction store_action;
    Color clear_color;
  };

  struct AttachmentConfigMSAA {
    StorageMode storage_mode;
    StorageMode resolve_storage_mode;
    LoadAction load_action;
    StoreAction store_action;
    Color clear_color;
  };

  static constexpr AttachmentConfig kDefaultColorAttachmentConfig = {
      .storage_mode = StorageMode::kDevicePrivate,
      .load_action = LoadAction::kClear,
      .store_action = StoreAction::kStore,
      .clear_color = Color::BlackTransparent()};

  static constexpr AttachmentConfigMSAA kDefaultColorAttachmentConfigMSAA = {
      .storage_mode = StorageMode::kDeviceTransient,
      .resolve_storage_mode = StorageMode::kDevicePrivate,
      .load_action = LoadAction::kClear,
      .store_action = StoreAction::kMultisampleResolve,
      .clear_color = Color::BlackTransparent()};

  static constexpr AttachmentConfig kDefaultStencilAttachmentConfig = {
      .storage_mode = StorageMode::kDeviceTransient,
      .load_action = LoadAction::kClear,
      .store_action = StoreAction::kDontCare,
      .clear_color = Color::BlackTransparent()};

  static RenderTarget CreateOffscreen(
      const Context& context,
      RenderTargetAllocator& allocator,
      ISize size,
      const std::string& label = "Offscreen",
      AttachmentConfig color_attachment_config = kDefaultColorAttachmentConfig,
      std::optional<AttachmentConfig> stencil_attachment_config =
          kDefaultStencilAttachmentConfig);

  static RenderTarget CreateOffscreenMSAA(
      const Context& context,
      RenderTargetAllocator& allocator,
      ISize size,
      const std::string& label = "Offscreen MSAA",
      AttachmentConfigMSAA color_attachment_config =
          kDefaultColorAttachmentConfigMSAA,
      std::optional<AttachmentConfig> stencil_attachment_config =
          kDefaultStencilAttachmentConfig);

  RenderTarget();

  ~RenderTarget();

  bool IsValid() const;

  void SetupStencilAttachment(const Context& context,
                              RenderTargetAllocator& allocator,
                              ISize size,
                              bool msaa,
                              const std::string& label = "Offscreen",
                              AttachmentConfig stencil_attachment_config =
                                  kDefaultStencilAttachmentConfig);

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

  size_t GetMaxColorAttacmentBindIndex() const;

  const std::map<size_t, ColorAttachment>& GetColorAttachments() const;

  const std::optional<DepthAttachment>& GetDepthAttachment() const;

  const std::optional<StencilAttachment>& GetStencilAttachment() const;

  size_t GetTotalAttachmentCount() const;

  void IterateAllAttachments(
      const std::function<bool(const Attachment& attachment)>& iterator) const;

  std::string ToString() const;

 private:
  std::map<size_t, ColorAttachment> colors_;
  std::optional<DepthAttachment> depth_;
  std::optional<StencilAttachment> stencil_;
};

}  // namespace impeller
