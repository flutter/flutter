// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_TESTS_FAKES_SCENIC_FAKE_FLATLAND_GRAPH_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_TESTS_FAKES_SCENIC_FAKE_FLATLAND_GRAPH_H_

#include <fuchsia/math/cpp/fidl.h>
#include <fuchsia/ui/composition/cpp/fidl.h>
#include <fuchsia/ui/composition/cpp/fidl_test_base.h>
#include <fuchsia/ui/views/cpp/fidl.h>
#include <lib/fidl/cpp/binding.h>
#include <lib/fidl/cpp/interface_handle.h>
#include <lib/fidl/cpp/interface_ptr.h>
#include <lib/fidl/cpp/interface_request.h>
#include <zircon/types.h>

#include <cstdint>
#include <optional>
#include <unordered_map>
#include <variant>
#include <vector>

#include "flutter/fml/macros.h"

inline bool operator==(const fuchsia::math::SizeU& a,
                       const fuchsia::math::SizeU& b) {
  return a.width == b.width && a.height == b.height;
}

inline bool operator==(const fuchsia::math::Vec& a,
                       const fuchsia::math::Vec& b) {
  return a.x == b.x && a.y == b.y;
}

inline bool operator==(const fuchsia::math::Rect& a,
                       const fuchsia::math::Rect& b) {
  return a.x == b.x && a.y == b.y && a.width == b.width && a.height == b.height;
}

inline bool operator==(const fuchsia::math::RectF& a,
                       const fuchsia::math::RectF& b) {
  return a.x == b.x && a.y == b.y && a.width == b.width && a.height == b.height;
}

inline bool operator==(const fuchsia::ui::composition::ContentId& a,
                       const fuchsia::ui::composition::ContentId& b) {
  return a.value == b.value;
}

inline bool operator==(const fuchsia::ui::composition::TransformId& a,
                       const fuchsia::ui::composition::TransformId& b) {
  return a.value == b.value;
}

inline bool operator==(const fuchsia::ui::composition::ViewportProperties& a,
                       const fuchsia::ui::composition::ViewportProperties& b) {
  if (a.has_logical_size() != b.has_logical_size()) {
    return false;
  }

  bool logical_size_equal = true;
  if (a.has_logical_size()) {
    const fuchsia::math::SizeU& a_logical_size = a.logical_size();
    const fuchsia::math::SizeU& b_logical_size = b.logical_size();
    logical_size_equal = (a_logical_size.width == b_logical_size.width &&
                          a_logical_size.height == b_logical_size.height);
  }

  return logical_size_equal;
}

inline bool operator==(const fuchsia::ui::composition::ImageProperties& a,
                       const fuchsia::ui::composition::ImageProperties& b) {
  if (a.has_size() != b.has_size()) {
    return false;
  }

  bool size_equal = true;
  if (a.has_size()) {
    const fuchsia::math::SizeU& a_size = a.size();
    const fuchsia::math::SizeU& b_size = b.size();
    size_equal =
        (a_size.width == b_size.width && a_size.height == b_size.height);
  }

  return size_equal;
}

namespace flutter_runner::testing {

constexpr static fuchsia::ui::composition::TransformId kInvalidTransformId{0};
constexpr static fuchsia::ui::composition::ContentId kInvalidContentId{0};

// Convenience structure which allows clients to easily create a valid
// `ViewCreationToken` / `ViewportCreationToken` pair for use with Flatland
// `CreateView` and `CreateViewport`.
struct ViewTokenPair {
  static ViewTokenPair New();

  fuchsia::ui::views::ViewCreationToken view_token;
  fuchsia::ui::views::ViewportCreationToken viewport_token;
};

// Convenience structure which allows clients to easily create a valid
// `BufferCollectionExportToken` / `BufferCollectionImportToken` pair for use
// with Flatland `RegisterBufferCollection` and `CreateImage`.
struct BufferCollectionTokenPair {
  static BufferCollectionTokenPair New();

  fuchsia::ui::composition::BufferCollectionExportToken export_token;
  fuchsia::ui::composition::BufferCollectionImportToken import_token;
};

struct FakeView {
  bool operator==(const FakeView& other) const;

  zx_koid_t view_token{};
  zx_koid_t view_ref{};
  zx_koid_t view_ref_control{};
  zx_koid_t view_ref_focused{};
  zx_koid_t focuser{};
  zx_koid_t touch_source{};
  zx_koid_t mouse_source{};
  zx_koid_t parent_viewport_watcher{};
};

struct FakeViewport {
  bool operator==(const FakeViewport& other) const;

  constexpr static fuchsia::math::SizeU kDefaultViewportLogicalSize{};

  fuchsia::ui::composition::ContentId id{kInvalidContentId};

  fuchsia::ui::composition::ViewportProperties viewport_properties{};
  zx_koid_t viewport_token{};
  zx_koid_t child_view_watcher{};
};

struct FakeImage {
  bool operator==(const FakeImage& other) const;

  constexpr static fuchsia::math::SizeU kDefaultImageSize{};
  constexpr static fuchsia::math::RectF kDefaultSampleRegion{};
  constexpr static fuchsia::math::SizeU kDefaultDestinationSize{};
  constexpr static float kDefaultOpacity{1.f};
  constexpr static fuchsia::ui::composition::BlendMode kDefaultBlendMode{
      fuchsia::ui::composition::BlendMode::SRC_OVER};

  fuchsia::ui::composition::ContentId id{kInvalidContentId};

  fuchsia::ui::composition::ImageProperties image_properties{};
  fuchsia::math::RectF sample_region{kDefaultSampleRegion};
  fuchsia::math::SizeU destination_size{kDefaultDestinationSize};
  float opacity{kDefaultOpacity};
  fuchsia::ui::composition::BlendMode blend_mode{kDefaultBlendMode};

  zx_koid_t import_token{};
  uint32_t vmo_index{0};
};

using FakeContent = std::variant<FakeViewport, FakeImage>;

struct FakeTransform {
  bool operator==(const FakeTransform& other) const;

  constexpr static fuchsia::math::Vec kDefaultTranslation{.x = 0, .y = 0};
  constexpr static fuchsia::ui::composition::Orientation kDefaultOrientation{
      fuchsia::ui::composition::Orientation::CCW_0_DEGREES};

  fuchsia::ui::composition::TransformId id{kInvalidTransformId};

  fuchsia::math::Vec translation{kDefaultTranslation};
  std::optional<fuchsia::math::Rect> clip_bounds;
  fuchsia::ui::composition::Orientation orientation{kDefaultOrientation};

  std::vector<std::shared_ptr<FakeTransform>> children;
  std::shared_ptr<FakeContent> content;
  size_t num_hit_regions;
};

struct FakeGraph {
  using ContentIdKey = decltype(fuchsia::ui::composition::ContentId::value);
  using TransformIdKey = decltype(fuchsia::ui::composition::TransformId::value);

  bool operator==(const FakeGraph& other) const;

  void Clear();
  FakeGraph Clone() const;

  std::unordered_map<ContentIdKey, std::shared_ptr<FakeContent>> content_map;
  std::unordered_map<TransformIdKey, std::shared_ptr<FakeTransform>>
      transform_map;
  std::shared_ptr<FakeTransform> root_transform;
  std::optional<FakeView> view;
};

template <typename ZX>
std::pair<zx_koid_t, zx_koid_t> GetKoids(const ZX& kobj) {
  zx_info_handle_basic_t info;
  zx_status_t status =
      kobj.get_info(ZX_INFO_HANDLE_BASIC, &info, sizeof(info),
                    /*actual_records*/ nullptr, /*avail_records*/ nullptr);
  return status == ZX_OK ? std::make_pair(info.koid, info.related_koid)
                         : std::make_pair(zx_koid_t{}, zx_koid_t{});
}

template <typename F>
std::pair<zx_koid_t, zx_koid_t> GetKoids(
    const fidl::InterfaceHandle<F>& interface_handle) {
  return GetKoids(interface_handle.channel());
}

template <typename F>
std::pair<zx_koid_t, zx_koid_t> GetKoids(
    const fidl::InterfaceRequest<F>& interface_request) {
  return GetKoids(interface_request.channel());
}

template <typename F>
std::pair<zx_koid_t, zx_koid_t> GetKoids(
    const fidl::InterfacePtr<F>& interface_ptr) {
  return GetKoids(interface_ptr.channel());
}

template <typename F>
std::pair<zx_koid_t, zx_koid_t> GetKoids(
    const fidl::Binding<F>& interface_binding) {
  return GetKoids(interface_binding.channel());
}

inline std::pair<zx_koid_t, zx_koid_t> GetKoids(
    const fuchsia::ui::views::ViewCreationToken& view_token) {
  return GetKoids(view_token.value);
}

inline std::pair<zx_koid_t, zx_koid_t> GetKoids(
    const fuchsia::ui::views::ViewportCreationToken& viewport_token) {
  return GetKoids(viewport_token.value);
}

inline std::pair<zx_koid_t, zx_koid_t> GetKoids(
    const fuchsia::ui::views::ViewRef& view_ref) {
  return GetKoids(view_ref.reference);
}

inline std::pair<zx_koid_t, zx_koid_t> GetKoids(
    const fuchsia::ui::views::ViewRefControl& view_ref_control) {
  return GetKoids(view_ref_control.reference);
}

inline std::pair<zx_koid_t, zx_koid_t> GetKoids(
    const fuchsia::ui::composition::BufferCollectionExportToken&
        buffer_collection_token) {
  return GetKoids(buffer_collection_token.value);
}

inline std::pair<zx_koid_t, zx_koid_t> GetKoids(
    const fuchsia::ui::composition::BufferCollectionImportToken&
        buffer_collection_token) {
  return GetKoids(buffer_collection_token.value);
}

};  // namespace flutter_runner::testing

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_TESTS_FAKES_SCENIC_FAKE_FLATLAND_GRAPH_H_
