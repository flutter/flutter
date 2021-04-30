// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_VIEW_HOLDER_H_
#define FLUTTER_FLOW_VIEW_HOLDER_H_

#include <fuchsia/ui/gfx/cpp/fidl.h>
#include <fuchsia/ui/views/cpp/fidl.h>
#include <lib/ui/scenic/cpp/id.h>
#include <lib/ui/scenic/cpp/resources.h>
#include <lib/ui/scenic/cpp/session.h>
#include <zircon/types.h>

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_counted.h"
#include "flutter/fml/task_runner.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkPoint.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkSize.h"

namespace flutter {

// Represents a Scenic |ViewHolder| resource that imports a |View| from another
// session.
//
// This object is created and destroyed on the |Rasterizer|'s thread.
class ViewHolder {
 public:
  using ViewIdCallback = std::function<void(scenic::ResourceId)>;

  // `Create`, `Destroy`, and `FromId` must be executed on the raster thread or
  // errors will occur.
  //
  // `on_bind_callback` and `on_unbind_callback` will likewise execute on the
  // raster thread; clients are responsible for re-threading the callback if
  // needed.
  static void Create(zx_koid_t id,
                     ViewIdCallback on_view_created,
                     fuchsia::ui::views::ViewHolderToken view_holder_token);
  static void Destroy(zx_koid_t id, ViewIdCallback on_view_destroyed);
  static ViewHolder* FromId(zx_koid_t id);

  ~ViewHolder() = default;

  // Sets the properties of the child view by issuing a Scenic command.
  void SetProperties(double width,
                     double height,
                     double insetTop,
                     double insetRight,
                     double insetBottom,
                     double insetLeft,
                     bool focusable);

  // Creates or updates the contained ViewHolder resource using the specified
  // |SceneUpdateContext|.
  void UpdateScene(scenic::Session* session,
                   scenic::ContainerNode& container_node,
                   const SkPoint& offset,
                   SkAlpha opacity);

  // Alters various apsects of the ViewHolder's ViewProperties.  The updates
  // are applied to Scenic on the new |UpdateScene| call.
  void set_hit_testable(bool value);
  void set_focusable(bool value);
  void set_size(const SkSize& size);
  void set_occlusion_hint(const SkRect& occlusion_hint);

 private:
  ViewHolder(fuchsia::ui::views::ViewHolderToken view_holder_token,
             ViewIdCallback on_view_created);

  std::unique_ptr<scenic::EntityNode> entity_node_;
  std::unique_ptr<scenic::OpacityNodeHACK> opacity_node_;
  std::unique_ptr<scenic::ViewHolder> view_holder_;

  fuchsia::ui::views::ViewHolderToken pending_view_holder_token_;
  ViewIdCallback on_view_created_;

  fuchsia::ui::gfx::HitTestBehavior hit_test_behavior_ =
      fuchsia::ui::gfx::HitTestBehavior::kDefault;
  fuchsia::ui::gfx::ViewProperties view_properties_;

  FML_DISALLOW_COPY_AND_ASSIGN(ViewHolder);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_VIEW_HOLDER_H_
