// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_CLIP_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_CLIP_CONTENTS_H_

#include "impeller/entity/contents/contents.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/geometry/geometry.h"

namespace impeller {

class ClipContents final : public Contents {
 public:
  ClipContents();

  ~ClipContents();

  void SetGeometry(const Geometry* geometry);

  void SetClipOperation(Entity::ClipOperation clip_op);

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  ClipCoverage GetClipCoverage(
      const Entity& entity,
      const std::optional<Rect>& current_clip_coverage) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  // |Contents|
  void SetInheritedOpacity(Scalar opacity) override;

 private:
  const Geometry* geometry_ = nullptr;
  Entity::ClipOperation clip_op_ = Entity::ClipOperation::kIntersect;

  ClipContents(const ClipContents&) = delete;

  ClipContents& operator=(const ClipContents&) = delete;
};

class ClipRestoreContents final : public Contents {
 public:
  ClipRestoreContents();

  ~ClipRestoreContents();

  void SetRestoreHeight(size_t clip_height);

  size_t GetRestoreHeight() const;

  /// @brief  The area on the pass texture where this clip restore will be
  ///         applied. If unset, the entire pass texture will be restored.
  ///
  /// @note   This rectangle is not transformed by the entity's transform.
  void SetRestoreCoverage(std::optional<Rect> coverage);

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  ClipCoverage GetClipCoverage(
      const Entity& entity,
      const std::optional<Rect>& current_clip_coverage) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  // |Contents|
  void SetInheritedOpacity(Scalar opacity) override;

 private:
  std::optional<Rect> restore_coverage_;
  size_t restore_height_ = 0;

  ClipRestoreContents(const ClipRestoreContents&) = delete;

  ClipRestoreContents& operator=(const ClipRestoreContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_CLIP_CONTENTS_H_
