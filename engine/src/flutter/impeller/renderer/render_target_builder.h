// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <map>
#include <optional>
#include "context.h"
#include "flutter/fml/macros.h"
#include "impeller/geometry/size.h"
#include "impeller/renderer/allocator.h"
#include "impeller/renderer/formats.h"
#include "render_target.h"

namespace impeller {

enum class RenderTargetType { kOffscreen, kOffscreenMSAA, kUnknown };

class RenderTargetBuilder {
 public:
  RenderTargetBuilder();

  ~RenderTargetBuilder();

  RenderTargetBuilder& SetSize(ISize size);

  RenderTargetBuilder& SetLabel(std::string label);

  RenderTargetBuilder& SetColorStorageMode(StorageMode mode);

  RenderTargetBuilder& SetColorLoadAction(LoadAction action);

  RenderTargetBuilder& SetColorStoreAction(StoreAction action);

  RenderTargetBuilder& SetStencilStorageMode(StorageMode mode);

  RenderTargetBuilder& SetStencilLoadAction(LoadAction action);

  RenderTargetBuilder& SetStencilStoreAction(StoreAction action);

  RenderTargetBuilder& SetColorResolveStorageMode(StorageMode mode);

  RenderTargetBuilder& SetRenderTargetType(RenderTargetType type);

  RenderTarget Build(const Context& context) const;

 private:
  ISize size_;
  std::string label_;

  StorageMode color_storage_mode_ = StorageMode::kDevicePrivate;
  LoadAction color_load_action_ = LoadAction::kClear;
  StoreAction color_store_action_ = StoreAction::kStore;

  StorageMode stencil_storage_mode_ = StorageMode::kDeviceTransient;
  LoadAction stencil_load_action_ = LoadAction::kClear;
  StoreAction stencil_store_action_ = StoreAction::kDontCare;

  StorageMode color_resolve_storage_mode_ = StorageMode::kDevicePrivate;

  RenderTargetType render_target_type_ = RenderTargetType::kOffscreen;

  RenderTarget CreateOffscreen(const Context& context) const;

  RenderTarget CreateOffscreenMSAA(const Context& context) const;

  FML_DISALLOW_COPY_AND_ASSIGN(RenderTargetBuilder);
};

}  // namespace impeller
