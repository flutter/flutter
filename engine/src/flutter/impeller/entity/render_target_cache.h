// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_RENDER_TARGET_CACHE_H_
#define FLUTTER_IMPELLER_ENTITY_RENDER_TARGET_CACHE_H_

#include <string_view>

#include "impeller/renderer/render_target.h"

namespace impeller {

/// @brief An implementation of the [RenderTargetAllocator] that caches
///        allocated render targets so that they can be reused.
///
///        Retention is governed by two independent policies:
///
///        1. [keep_alive_frame_count] bounds how *long* an unused render
///           target is retained. See the caveat about its units below.
///        2. [cache_budget_bytes] bounds how *much* the cache retains in
///           total. When the cached render targets exceed the budget, the
///           least recently used ones are released even if their keep alive
///           count has not elapsed.
///
///        The budget exists because the keep alive count alone is unbounded in
///        space: content that requests a differently configured render target
///        every pass (an animated backdrop blur, for example) never produces a
///        cache hit, so every retained render target is pure overhead and the
///        cache grows without limit. See
///        https://github.com/flutter/flutter/issues/190613.
///
/// @warning Despite its name, [keep_alive_frame_count] does not count frames.
///          It counts calls to [End], which happen once per render pass tree
///          (that is, once per `Canvas`) rather than once per frame. A frame
///          renders one pass tree per view, plus one per overlay layer when
///          platform views are composited, plus one for each offscreen render
///          (`Picture.toImage`, for example). A keep alive count of 4 is
///          therefore only 4 frames in the simplest case: a single view with
///          no platform views and no offscreen rendering.
class RenderTargetCache : public RenderTargetAllocator {
 public:
  /// @brief The cache budget, expressed as a multiple of the largest render
  ///        target the cache has been asked to allocate.
  ///
  ///        Deriving the budget from observed render target sizes lets it
  ///        scale with the display resolution without having to plumb device
  ///        specific configuration into the cache.
  static constexpr size_t kCacheBudgetMultiplier = 4u;

  /// @brief The smallest cache budget that will be derived automatically.
  ///
  ///        Small render targets are cheap enough that bounding them isn't
  ///        worth the reallocation cost.
  static constexpr size_t kMinimumCacheBudgetBytes = 4u * 1024u * 1024u;

  /// @param[in]  cache_budget_bytes  The maximum number of bytes of render
  ///                                 target data to retain. If unset, the
  ///                                 budget is derived from the largest render
  ///                                 target the cache has allocated. This is
  ///                                 not plumbed to any embedder facing API;
  ///                                 it exists so that the policy can be
  ///                                 exercised by tests.
  explicit RenderTargetCache(
      std::shared_ptr<Allocator> allocator,
      uint32_t keep_alive_frame_count = 4,
      std::optional<size_t> cache_budget_bytes = std::nullopt);

  ~RenderTargetCache() = default;

  // |RenderTargetAllocator|
  void Start() override;

  // |RenderTargetAllocator|
  void End() override;

  // |RenderTargetAllocator|
  void DisableCache() override;

  // |RenderTargetAllocator|
  void EnableCache() override;

  RenderTarget CreateOffscreen(
      const Context& context,
      ISize size,
      int mip_count,
      std::string_view label = "Offscreen",
      RenderTarget::AttachmentConfig color_attachment_config =
          RenderTarget::kDefaultColorAttachmentConfig,
      std::optional<RenderTarget::AttachmentConfig> stencil_attachment_config =
          RenderTarget::kDefaultStencilAttachmentConfig,
      const std::shared_ptr<Texture>& existing_color_texture = nullptr,
      const std::shared_ptr<Texture>& existing_depth_stencil_texture = nullptr,
      std::optional<PixelFormat> target_pixel_format = std::nullopt) override;

  RenderTarget CreateOffscreenMSAA(
      const Context& context,
      ISize size,
      int mip_count,
      std::string_view label = "Offscreen MSAA",
      RenderTarget::AttachmentConfigMSAA color_attachment_config =
          RenderTarget::kDefaultColorAttachmentConfigMSAA,
      std::optional<RenderTarget::AttachmentConfig> stencil_attachment_config =
          RenderTarget::kDefaultStencilAttachmentConfig,
      const std::shared_ptr<Texture>& existing_color_msaa_texture = nullptr,
      const std::shared_ptr<Texture>& existing_color_resolve_texture = nullptr,
      const std::shared_ptr<Texture>& existing_depth_stencil_texture = nullptr,
      std::optional<PixelFormat> target_pixel_format = std::nullopt) override;

  // visible for testing.
  size_t CachedTextureCount() const;

  /// @brief The total number of bytes of render target data currently
  ///        retained by the cache.
  ///
  ///        This is an estimate computed from texture descriptors. It does not
  ///        account for backend specific behavior such as memoryless
  ///        attachments on tile based renderers.
  size_t CachedTextureBytes() const;

  /// @brief The maximum number of bytes of render target data the cache will
  ///        retain before releasing the least recently used render targets.
  size_t GetCacheBudgetBytes() const;

 private:
  struct RenderTargetData {
    bool used_this_frame;
    uint32_t keep_alive_frame_count;
    /// Monotonically increasing value recording the last time this render
    /// target was created or reused. Used to order eviction candidates.
    uint64_t last_used_generation;
    /// The estimated size of the render target, cached to avoid recomputing it
    /// from the texture descriptors on every eviction pass.
    size_t byte_size;
    RenderTargetConfig config;
    RenderTarget render_target;
  };

  bool CacheEnabled() const;

  /// @brief Record a newly created render target in the cache.
  void InsertNewRenderTarget(const RenderTargetConfig& config,
                             const RenderTarget& render_target);

  /// @brief Release the least recently used render targets until the cache
  ///        fits within its budget.
  ///
  ///        Render targets used during the current pass are never released,
  ///        so the budget is a soft limit.
  void EvictLeastRecentlyUsedOverBudget();

  std::vector<RenderTargetData> render_target_data_;
  uint32_t keep_alive_frame_count_;
  std::optional<size_t> cache_budget_bytes_;
  /// The size of the largest render target ever allocated by the cache, used
  /// to derive the budget when one has not been specified.
  size_t largest_render_target_bytes_ = 0;
  uint64_t generation_ = 0;
  uint32_t cache_disabled_count_ = 0;

  RenderTargetCache(const RenderTargetCache&) = delete;

  RenderTargetCache& operator=(const RenderTargetCache&) = delete;

 public:
  /// Visible for testing.
  std::vector<RenderTargetData>::const_iterator GetRenderTargetDataBegin()
      const {
    return render_target_data_.begin();
  }

  /// Visible for testing.
  std::vector<RenderTargetData>::const_iterator GetRenderTargetDataEnd() const {
    return render_target_data_.end();
  }
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_RENDER_TARGET_CACHE_H_
