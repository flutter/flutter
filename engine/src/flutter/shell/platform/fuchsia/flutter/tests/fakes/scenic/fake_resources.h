// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_TESTS_FAKES_SCENIC_FAKE_RESOURCES_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_TESTS_FAKES_SCENIC_FAKE_RESOURCES_H_

#include <fuchsia/images/cpp/fidl.h>
#include <fuchsia/sysmem/cpp/fidl.h>
#include <fuchsia/ui/composition/cpp/fidl.h>
#include <fuchsia/ui/gfx/cpp/fidl.h>
#include <fuchsia/ui/views/cpp/fidl.h>
#include <lib/fidl/cpp/interface_handle.h>
#include <lib/fidl/cpp/interface_request.h>
#include <lib/zx/vmo.h>
#include <zircon/types.h>

#include <array>
#include <memory>
#include <string>
#include <unordered_map>
#include <variant>
#include <vector>

inline bool operator==(const fuchsia::images::ImageInfo& a,
                       const fuchsia::images::ImageInfo& b) {
  return a.height == b.height && a.width == b.width && a.stride == b.stride &&
         a.tiling == b.tiling && a.transform == b.transform &&
         a.alpha_format == b.alpha_format && a.pixel_format == b.pixel_format &&
         a.color_space == b.color_space;
}

inline bool operator==(const fuchsia::ui::gfx::vec3& a,
                       const fuchsia::ui::gfx::vec3& b) {
  return a.x == b.x && a.y == b.y && a.z == b.z;
}

inline bool operator==(const fuchsia::ui::gfx::BoundingBox& a,
                       const fuchsia::ui::gfx::BoundingBox& b) {
  return a.min == b.min && a.max == b.max;
}

inline bool operator==(const fuchsia::ui::gfx::ViewProperties& a,
                       const fuchsia::ui::gfx::ViewProperties& b) {
  return a.downward_input == b.downward_input &&
         a.focus_change == b.focus_change && a.bounding_box == b.bounding_box &&
         a.inset_from_min == b.inset_from_min &&
         a.inset_from_max == b.inset_from_max;
}

namespace flutter_runner::testing {

// Forward declarations
template <typename S>
struct FakeResourceT;

// Unique (within a Session) identifier for a Resource.
using FakeResourceId = decltype(fuchsia::ui::gfx::CreateResourceCmd::id);
constexpr FakeResourceId kInvalidFakeResourceId = 0u;

// Tag type for a Resource "state".  The Resource state keeps alive any handles
// associated with a resource e.g. view token or sysmem token.
//
// "snapshot" Resources are generated from "state" Resources during
// `SceneGraphFromState()` calls.
//
// The `FakeSession` stores `FakeResourceT<StateT>` internally.
struct StateT {
  using ResourceT = FakeResourceT<StateT>;

  template <typename T>
  struct HandleT {
    T value{};
    zx_koid_t koid{ZX_KOID_INVALID};
  };

  template <typename T>
  static bool HandlesAreEqual(const HandleT<T>& token,
                              const HandleT<T>& other_token) {
    return token.koid == other_token.koid;
  }
};

// Tag type for a Resource "snapshot".  The Resource snapshot only stores koids
// for any handles associated with the resource; in this way it doesn't have any
// control over the underlying handle lifetime.
//
// "snapshot" Resources are generated from "state" Resources during
// `SceneGraphFromState()` calls.
//
// The `FakeSession` returns `FakeResourceT<SnapshotT>` from its `SceneGraph()`
// accessor.
struct SnapshotT {
  using ResourceT = FakeResourceT<SnapshotT>;

  template <typename T>
  using HandleT = zx_koid_t;

  template <typename T>
  static bool HandlesAreEqual(const HandleT<T>& token,
                              const HandleT<T>& other_token) {
    return token == other_token;
  }
};

// Common state for Node-typed Resources:  EntityNode, OpacityNode, ShapeNode,
// ViewHolder.
//
// FakeNodeT's are never used directly, only as an embedded field of a
// Node-typed resource.
template <typename S>
struct FakeNodeT {
  bool operator==(const FakeNodeT& other) const;

  constexpr static std::array<float, 4> kDefaultZeroRotation{0.f, 0.f, 0.f,
                                                             1.f};
  constexpr static std::array<float, 3> kDefaultOneScale{1.f, 1.f, 1.f};
  constexpr static std::array<float, 3> kDefaultZeroTranslation{0.f, 0.f, 0.f};
  constexpr static std::array<float, 3> kDefaultZeroAnchor{0.f, 0.f, 0.f};
  constexpr static bool kIsHitTestable{true};
  constexpr static bool kIsNotHitTestable{false};
  constexpr static bool kIsSemanticallyVisible{true};
  constexpr static bool kIsNotSemanticallyVisible{false};

  std::vector<std::shared_ptr<typename S::ResourceT>> children;
  std::array<float, 4> rotation_quaternion{kDefaultZeroRotation};
  std::array<float, 3> scale_vector{kDefaultOneScale};
  std::array<float, 3> translation_vector{kDefaultZeroTranslation};
  std::array<float, 3> anchor_vector{kDefaultZeroAnchor};
  bool hit_testable{kIsHitTestable};
  bool semantically_visible{kIsSemanticallyVisible};
};

using FakeNodeState = FakeNodeT<StateT>;
using FakeNode = FakeNodeT<SnapshotT>;

// EntityNode Resource state.
template <typename S>
struct FakeEntityNodeT {
  struct ClipPlane {
    bool operator==(const ClipPlane& other) const;

    constexpr static std::array<float, 3> kDefaultZeroDir{0.f, 0.f, 0.f};
    constexpr static float kDefaultZeroDist{0.f};

    std::array<float, 3> dir{kDefaultZeroDir};
    float dist{kDefaultZeroDist};
  };

  bool operator==(const FakeEntityNodeT& other) const;

  FakeNodeT<S> node_state;

  std::vector<ClipPlane> clip_planes;
};
using FakeEntityNodeState = FakeEntityNodeT<StateT>;
using FakeEntityNode = FakeEntityNodeT<SnapshotT>;

// OpacityNode Resource state.
template <typename S>
struct FakeOpacityNodeT {
  bool operator==(const FakeOpacityNodeT& other) const;

  FakeNodeT<S> node_state;

  constexpr static float kDefaultOneOpacity{1.f};

  float opacity{kDefaultOneOpacity};
};
using FakeOpacityNodeState = FakeOpacityNodeT<StateT>;
using FakeOpacityNode = FakeOpacityNodeT<SnapshotT>;

// ShapeNode Resource state.
template <typename S>
struct FakeShapeNodeT {
  bool operator==(const FakeShapeNodeT& other) const;

  FakeNodeT<S> node_state;

  std::shared_ptr<typename S::ResourceT> shape;
  std::shared_ptr<typename S::ResourceT> material;
};
using FakeShapeNodeState = FakeShapeNodeT<StateT>;
using FakeShapeNode = FakeShapeNodeT<SnapshotT>;

// View Resource state.
template <typename S>
struct FakeViewT {
  bool operator==(const FakeViewT& other) const;

  constexpr static bool kDebugBoundsEnabled{true};
  constexpr static bool kDebugBoundsDisbaled{false};

  typename S::template HandleT<fuchsia::ui::views::ViewToken> token{};
  typename S::template HandleT<fuchsia::ui::views::ViewRefControl>
      control_ref{};
  typename S::template HandleT<fuchsia::ui::views::ViewRef> view_ref{};
  std::string debug_name{};

  std::vector<std::shared_ptr<typename S::ResourceT>> children;
  bool enable_debug_bounds{kDebugBoundsDisbaled};
};
using FakeViewState = FakeViewT<StateT>;
using FakeView = FakeViewT<SnapshotT>;

// ViewHolder Resource state.
template <typename S>
struct FakeViewHolderT {
  bool operator==(const FakeViewHolderT& other) const;

  FakeNodeT<S> node_state;

  constexpr static std::array<float, 4> kDefaultBoundsColorWhite{1.f, 1.f, 1.f,
                                                                 1.f};
  typename S::template HandleT<fuchsia::ui::views::ViewHolderToken> token{};
  std::string debug_name{};

  fuchsia::ui::gfx::ViewProperties properties;
  std::array<float, 4> bounds_color{kDefaultBoundsColorWhite};
};
using FakeViewHolderState = FakeViewHolderT<StateT>;
using FakeViewHolder = FakeViewHolderT<SnapshotT>;

// Shape Resource state.
template <typename S>
struct FakeShapeT {
  bool operator==(const FakeShapeT& other) const;

  struct CircleDef {
    bool operator==(const CircleDef& other) const;

    float radius{0.f};
  };

  struct RectangleDef {
    bool operator==(const RectangleDef& other) const;

    float width{0.f};
    float height{0.f};
  };

  struct RoundedRectangleDef {
    bool operator==(const RoundedRectangleDef& other) const;

    float width{0.f};
    float height{0.f};
    float top_left_radius{0.f};
    float top_right_radius{0.f};
    float bottom_right_radius{0.f};
    float bottom_left_radius{0.f};
  };

  std::variant<CircleDef, RectangleDef, RoundedRectangleDef> shape_def;
};
using FakeShapeState = FakeShapeT<StateT>;
using FakeShape = FakeShapeT<SnapshotT>;

// Material Resource state.
template <typename S>
struct FakeMaterialT {
  bool operator==(const FakeMaterialT& other) const;

  constexpr static std::array<float, 4> kDefaultColorWhite{1.f, 1.f, 1.f, 1.f};

  std::shared_ptr<typename S::ResourceT> image;
  std::array<float, 4> color{kDefaultColorWhite};
};
using FakeMaterialState = FakeMaterialT<StateT>;
using FakeMaterial = FakeMaterialT<SnapshotT>;

// Image Resource state.
template <typename S>
struct FakeImageT {
  struct ImageDef {
    bool operator==(const ImageDef& other) const;

    fuchsia::images::ImageInfo info{};
    uint32_t memory_offset{};
  };

  struct Image2Def {
    bool operator==(const Image2Def& other) const;

    uint32_t buffer_collection_id{};
    uint32_t buffer_collection_index{};
    uint32_t width{};
    uint32_t height{};
  };

  struct Image3Def {
    bool operator==(const Image3Def& other) const;

    typename S::template HandleT<
        fuchsia::ui::composition::BufferCollectionImportToken>
        import_token{};
    uint32_t buffer_collection_index{};
    uint32_t width{};
    uint32_t height{};
  };

  struct ImagePipe2Def {
    bool operator==(const ImagePipe2Def& other) const;

    typename S::template HandleT<
        fidl::InterfaceRequest<fuchsia::images::ImagePipe2>>
        image_pipe_request{};
  };

  bool operator==(const FakeImageT& other) const;

  std::variant<ImageDef, Image2Def, Image3Def, ImagePipe2Def> image_def;
  std::shared_ptr<typename S::ResourceT> memory;
};
using FakeImageState = FakeImageT<StateT>;
using FakeImage = FakeImageT<SnapshotT>;

// Memory Resource state.
template <typename S>
struct FakeMemoryT {
  bool operator==(const FakeMemoryT& other) const;

  constexpr static bool kIsDeviceMemory{true};
  constexpr static bool kIsNotDeviceMemory{false};

  typename S::template HandleT<zx::vmo> vmo{};
  uint64_t allocation_size{};
  bool is_device_memory{kIsNotDeviceMemory};
};
using FakeMemoryState = FakeMemoryT<StateT>;
using FakeMemory = FakeMemoryT<SnapshotT>;

// A complete Resource which records common Resource data and stores it's
// type-specific state inside of a variant.
template <typename S>
struct FakeResourceT {
  bool operator==(const FakeResourceT& other) const;

  constexpr static uint32_t kDefaultEmptyEventMask{0};

  FakeResourceId id{kInvalidFakeResourceId};

  std::string label{};
  uint32_t event_mask{kDefaultEmptyEventMask};

  std::variant<FakeEntityNodeT<S>,
               FakeOpacityNodeT<S>,
               FakeShapeNodeT<S>,
               FakeViewT<S>,
               FakeViewHolderT<S>,
               FakeShapeT<S>,
               FakeMaterialT<S>,
               FakeImageT<S>,
               FakeMemoryT<S>>
      state;
};
using FakeResourceState = FakeResourceT<StateT>;
using FakeResource = FakeResourceT<SnapshotT>;

// A complete scene graph which records a forest of Resource trees.
//
// It also records auxiliary data like buffer collection IDs and resource labels
// for fast lookup.
//
// Each Session / scene graph may only have a single View Resource which is
// treated as the root of that scene.  The root View and all Resources
// descending from it are what the real scenic implementation would submit for
// rendering.
template <typename S>
struct FakeSceneGraphT {
  bool operator==(const FakeSceneGraphT& other) const;

  std::unordered_map<uint32_t,
                     typename S::template HandleT<fidl::InterfaceHandle<
                         fuchsia::sysmem::BufferCollectionToken>>>
      buffer_collection_map;

  std::unordered_map<FakeResourceId, std::shared_ptr<FakeResourceT<S>>>
      resource_map;
  std::unordered_map<std::string, std::vector<std::weak_ptr<FakeResourceT<S>>>>
      label_map;
  FakeResourceId root_view_id{kInvalidFakeResourceId};
};
using FakeSceneGraphState = FakeSceneGraphT<StateT>;
using FakeSceneGraph = FakeSceneGraphT<SnapshotT>;

// Generate a snapshot of a scene graph from that scene graph's state.
//
// The lifetime of the snapshot and its Resources has no influence on the
// lifetime of the source scene graph or its Resources.
FakeSceneGraph SceneGraphFromState(const FakeSceneGraphState& state);

template <typename S>
bool FakeEntityNodeT<S>::ClipPlane::operator==(
    const FakeEntityNodeT<S>::ClipPlane& other) const {
  return dir == other.dir && dist == other.dist;
}

template <typename S>
bool FakeNodeT<S>::operator==(const FakeNodeT<S>& other) const {
  return children == other.children &&
         rotation_quaternion == other.rotation_quaternion &&
         scale_vector == other.scale_vector &&
         translation_vector == other.translation_vector &&
         anchor_vector == other.anchor_vector &&
         hit_testable == other.hit_testable &&
         semantically_visible == other.semantically_visible;
}

template <typename S>
bool FakeEntityNodeT<S>::operator==(const FakeEntityNodeT<S>& other) const {
  return node_state == other.node_state && clip_planes == other.clip_planes;
}

template <typename S>
bool FakeOpacityNodeT<S>::operator==(const FakeOpacityNodeT<S>& other) const {
  return node_state == other.node_state && opacity == other.opacity;
}

template <typename S>
bool FakeShapeNodeT<S>::operator==(const FakeShapeNodeT<S>& other) const {
  return node_state == other.node_state && shape == other.shape &&
         material == other.material;
}

template <typename S>
bool FakeViewT<S>::operator==(const FakeViewT<S>& other) const {
  return S::template HandlesAreEqual<fuchsia::ui::views::ViewToken>(
             token, other.token) &&
         S::template HandlesAreEqual<fuchsia::ui::views::ViewRefControl>(
             control_ref, other.control_ref) &&
         S::template HandlesAreEqual<fuchsia::ui::views::ViewRef>(
             view_ref, other.view_ref) &&
         children == other.children && debug_name == other.debug_name &&
         enable_debug_bounds == other.enable_debug_bounds;
}

template <typename S>
bool FakeViewHolderT<S>::operator==(const FakeViewHolderT<S>& other) const {
  return FakeNodeT<S>::operator==(other) &&
         S::template HandlesAreEqual<fuchsia::ui::views::ViewHolderToken>(
             token, other.token) &&
         debug_name == other.debug_name && properties == other.properties &&
         bounds_color == other.bounds_color;
}

template <typename S>
bool FakeShapeT<S>::CircleDef::operator==(
    const FakeShapeT<S>::CircleDef& other) const {
  return radius == other.radius;
}

template <typename S>
bool FakeShapeT<S>::RectangleDef::operator==(
    const FakeShapeT<S>::RectangleDef& other) const {
  return width == other.width && height == other.height;
}

template <typename S>
bool FakeShapeT<S>::RoundedRectangleDef::operator==(
    const FakeShapeT<S>::RoundedRectangleDef& other) const {
  return width == other.width && height == other.height &&
         top_left_radius == other.top_left_radius &&
         top_right_radius == other.top_right_radius &&
         bottom_right_radius == other.bottom_right_radius &&
         bottom_left_radius == other.bottom_left_radius;
}

template <typename S>
bool FakeShapeT<S>::operator==(const FakeShapeT<S>& other) const {
  return shape_def == other.shape_def;
}

template <typename S>
bool FakeMaterialT<S>::operator==(const FakeMaterialT<S>& other) const {
  return image == other.image && color == other.color;
}

template <typename S>
bool FakeImageT<S>::ImageDef::operator==(
    const FakeImageT<S>::ImageDef& other) const {
  return info == other.info && memory_offset == other.memory_offset;
}

template <typename S>
bool FakeImageT<S>::Image2Def::operator==(
    const FakeImageT<S>::Image2Def& other) const {
  return buffer_collection_id == other.buffer_collection_id &&
         buffer_collection_index == other.buffer_collection_index &&
         width == other.width && height == other.height;
}

template <typename S>
bool FakeImageT<S>::Image3Def::operator==(
    const FakeImageT<S>::Image3Def& other) const {
  return S::template HandlesAreEqual<
             fuchsia::ui::composition::BufferCollectionImportToken>(
             import_token, other.import_token) &&
         buffer_collection_index == other.buffer_collection_index &&
         width == other.width && height == other.height;
}

template <typename S>
bool FakeImageT<S>::ImagePipe2Def::operator==(
    const FakeImageT<S>::ImagePipe2Def& other) const {
  return S::template HandlesAreEqual<
      fidl::InterfaceRequest<fuchsia::images::ImagePipe2>>(
      image_pipe_request, other.image_pipe_request);
}

template <typename S>
bool FakeImageT<S>::operator==(const FakeImageT<S>& other) const {
  return image_def == other.image_def && memory == other.memory;
}

template <typename S>
bool FakeMemoryT<S>::operator==(const FakeMemoryT<S>& other) const {
  return S::template HandlesAreEqual<zx::vmo>(vmo, other.vmo) &&
         allocation_size == other.allocation_size &&
         is_device_memory == other.is_device_memory;
}

template <typename S>
bool FakeResourceT<S>::operator==(const FakeResourceT<S>& other) const {
  return id == other.id && label == other.label &&
         event_mask == other.event_mask && state == other.state;
}

template <typename S>
bool FakeSceneGraphT<S>::operator==(const FakeSceneGraphT<S>& other) const {
  return buffer_collection_map == other.buffer_collection_map &&
         resource_map ==
             other.resource_map &&  // labels_map == other.labels_map &&
         root_view_id == other.root_view_id;
}

}  // namespace flutter_runner::testing

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_FLUTTER_TESTS_FAKES_SCENIC_FAKE_RESOURCES_H_
