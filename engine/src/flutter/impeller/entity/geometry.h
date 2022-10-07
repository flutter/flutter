// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/geometry/color.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/vertices.h"
#include "impeller/renderer/allocator.h"
#include "impeller/renderer/host_buffer.h"
#include "impeller/renderer/vertex_buffer.h"

namespace impeller {

struct GeometryResult {
  PrimitiveType type;
  VertexBuffer vertex_buffer;
  bool prevent_overdraw;
};

enum GeometryVertexType {
  kPosition,
  kColor,
  kUV,
};

class Geometry {
 public:
  Geometry();

  virtual ~Geometry();

  static std::unique_ptr<Geometry> MakeVertices(Vertices vertices);

  virtual GeometryResult GetPositionBuffer(
      std::shared_ptr<Allocator> device_allocator,
      HostBuffer& host_buffer) = 0;

  virtual GeometryResult GetPositionColorBuffer(
      std::shared_ptr<Allocator> device_allocator,
      HostBuffer& host_buffer,
      Color paint_color,
      BlendMode blend_mode) = 0;

  virtual GeometryResult GetPositionUVBuffer(
      std::shared_ptr<Allocator> device_allocator,
      HostBuffer& host_buffer,
      ISize render_target_size) = 0;

  virtual GeometryVertexType GetVertexType() = 0;

  virtual std::optional<Rect> GetCoverage(Matrix transform) = 0;
};

class VerticesGeometry : public Geometry {
 public:
  VerticesGeometry(Vertices vertices);

  ~VerticesGeometry();

 private:
  // |Geometry|
  GeometryResult GetPositionBuffer(std::shared_ptr<Allocator> device_allocator,
                                   HostBuffer& host_buffer) override;

  // |Geometry|
  GeometryResult GetPositionColorBuffer(
      std::shared_ptr<Allocator> device_allocator,
      HostBuffer& host_buffer,
      Color paint_color,
      BlendMode blend_mode) override;

  // |Geometry|
  GeometryResult GetPositionUVBuffer(
      std::shared_ptr<Allocator> device_allocator,
      HostBuffer& host_buffer,
      ISize render_target_size) override;

  // |Geometry|
  GeometryVertexType GetVertexType() override;

  // |Geometry|
  std::optional<Rect> GetCoverage(Matrix transform) override;

  Vertices vertices_;

  FML_DISALLOW_COPY_AND_ASSIGN(VerticesGeometry);
};

}  // namespace impeller
