// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_CONTENTS_H_

#include <memory>

#include "flutter/impeller/entity/contents/color_source_contents.h"
#include "flutter/impeller/entity/contents/contents.h"
#include "impeller/entity/geometry/circle_geometry.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/entity/geometry/rect_geometry.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/rect.h"

namespace impeller {

class UberSDFContents : public ColorSourceContents {
 public:
  static std::unique_ptr<UberSDFContents> MakeRect(
      Color color,
      Scalar stroke_width,
      Join stroke_join,
      bool stroked,
      const FillRectGeometry* geometry);

  static std::unique_ptr<UberSDFContents>
  MakeCircle(Color color, bool stroked, const CircleGeometry* geometry);

  ~UberSDFContents() override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |ColorSourceContents|
  Color GetColor() const;

  // |ColorSourceContents|
  bool ApplyColorFilter(const ColorFilterProc& color_filter_proc) override;

 protected:
  UberSDFContents(Color color,
                  bool stroked,
                  Scalar stroke_width,
                  Join stroke_join);

  using VS = UberSDFPipeline::VertexShader;
  using FS = UberSDFPipeline::FragmentShader;

  void SetCommonUniforms(FS::FragInfo& frag_info) const;

  virtual bool BindData(const ContentContext& renderer,
                        const Entity& entity,
                        RenderPass& pass,
                        FS::FragInfo& frag_info) const = 0;

 private:
  Color color_;
  bool stroked_;
  Scalar stroke_width_;
  Join stroke_join_;

  UberSDFContents(const UberSDFContents&) = delete;

  UberSDFContents& operator=(const UberSDFContents&) = delete;
};

class CircleSDFContents final : public UberSDFContents {
 public:
  CircleSDFContents(Color color, bool stroked, const CircleGeometry* geometry);

  ~CircleSDFContents() override;

  // |ColorSourceContents|
  const Geometry* GetGeometry() const override;

 protected:
  // |UberSDFContents|
  bool BindData(const ContentContext& renderer,
                const Entity& entity,
                RenderPass& pass,
                FS::FragInfo& frag_info) const override;

 private:
  const CircleGeometry* geometry_;

  CircleSDFContents(const CircleSDFContents&) = delete;

  CircleSDFContents& operator=(const CircleSDFContents&) = delete;
};

class RectSDFContents final : public UberSDFContents {
 public:
  RectSDFContents(Color color,
                  Scalar stroke_width,
                  Join stroke_join,
                  bool stroked,
                  const FillRectGeometry* geometry);

  ~RectSDFContents() override;

  // |ColorSourceContents|
  const Geometry* GetGeometry() const override;

 protected:
  // |UberSDFContents|
  bool BindData(const ContentContext& renderer,
                const Entity& entity,
                RenderPass& pass,
                FS::FragInfo& frag_info) const override;

 private:
  const FillRectGeometry* geometry_;

  RectSDFContents(const RectSDFContents&) = delete;

  RectSDFContents& operator=(const RectSDFContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_CONTENTS_H_
