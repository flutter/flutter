// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <vector>

#include "flutter/impeller/geometry/matrix.h"
#include "flutter/impeller/geometry/point.h"
#include "flutter/impeller/geometry/scalar.h"
#include "flutter/impeller/geometry/trig.h"
#include "flutter/impeller/tessellator/tessellator.h"

namespace impeller {

using TessellatedPointProc = std::function<void(const Point& p)>;

/// @brief  A utility class to compute the number of divisions for a circle
///         given a transform-adjusted pixel radius and methods for generating
///         a tessellated set of triangles for a quarter or full circle.
///
///         The constructor will compute the device pixel radius size for
///         the specified geometry-space |radius| when viewed under
///         a specified geometry-to-device |transform|.
///
///         The object should be constructed with the expected transform and
///         radius of the circle, but can then be used to generate a triangular
///         tessellation with the computed number of divisions for any
///         radius after that. Since the coordinate space in which the
///         circle being tessellated is not necessarily device pixel space,
///         the radius supplied during tessellation might not match the
///         pixel radius computed during construction, but the two values
///         should be related by the transform in place when the tessellated
///         triangles are rendered for maximum tessellation fidelity.
class CircleTessellator {
 public:
  /// @brief   The pixel tolerance used by the algorighm to determine how
  ///          many divisions to create for a circle.
  ///
  ///          No point on the polygon of vertices should deviate from the
  ///          true circle by more than this tolerance.
  static constexpr Scalar kCircleTolerance = 0.1;

  /// @brief   Constructs a CircleTessellator that produces enough segments
  ///          to reasonably approximate a circle with a specified |radius|
  ///          when viewed under the specified |transform|.
  CircleTessellator(std::shared_ptr<Tessellator>& tessellator,
                    const Matrix& transform,
                    Scalar radius)
      : CircleTessellator(tessellator, transform.GetMaxBasisLength() * radius) {
  }

  ~CircleTessellator() = default;

  /// @brief   Return the number of divisions computed by the algorithm for
  ///          a single quarter circle.
  size_t GetQuadrantDivisionCount() const { return trigs_.size() - 1; }

  /// @brief   Return the number of vertices that will be generated to
  ///          tessellate a full circle with a triangle strip.
  ///
  ///          This value can be used to pre-allocate space in a vector
  ///          to hold the vertices that will be produced by the
  ///          |GenerateCircleTriangleStrip| and
  ///          |GenerateRoundCapLineTriangleStrip| methods.
  size_t GetCircleVertexCount() const { return trigs_.size() * 4; }

  /// @brief   Return the number of vertices that will be generated to
  ///          tessellate a full stroked circle with a triangle strip.
  ///
  ///          This value can be used to pre-allocate space in a vector
  ///          to hold the vertices that will be produced by the
  ///          |GenerateCircleTriangleStrip| and
  ///          |GenerateRoundCapLineTriangleStrip| methods.
  size_t GetStrokedCircleVertexCount() const { return trigs_.size() * 8; }

  /// @brief   Generate the vertices for a triangle strip that covers the
  ///          circle at a given |radius| from a given |center|, delivering
  ///          the computed coordinates to the supplied |proc|.
  ///
  ///          This procedure will generate no more than the number of
  ///          vertices returned by |GetCircleVertexCount| in an order
  ///          appropriate for rendering as a triangle strip.
  void GenerateCircleTriangleStrip(const TessellatedPointProc& proc,
                                   const Point& center,
                                   Scalar radius) const;

  /// @brief   Generate the vertices for a triangle strip that draws the gap
  ///          between 2 circles at |outer_radius| and |inner_radius|
  ///          from a given |center|, delivering the computed coordinates to
  ///          the supplied |proc|.
  ///
  ///          This procedure will generate no more than the number of
  ///          vertices returned by |GetStrokedCircleVertexCount| in an order
  ///          appropriate for rendering as a triangle strip.
  void GenerateStrokedCircleTriangleStrip(const TessellatedPointProc& proc,
                                          const Point& center,
                                          Scalar outer_radius,
                                          Scalar inner_radius) const;

  /// @brief   Generate the vertices for a triangle strip that covers the
  ///          line from |p0| to |p1| with round caps of the specified
  ///          |radius|, delivering the computed coordinates to the supplied
  ///          |proc|.
  ///
  ///          This procedure will generate no more than the number of
  ///          vertices returned by |GetCircleVertexCount| in an order
  ///          appropriate for rendering as a triangle strip.
  void GenerateRoundCapLineTriangleStrip(const TessellatedPointProc& proc,
                                         const Point& p0,
                                         const Point& p1,
                                         Scalar radius) const;

 private:
  const std::vector<Trig>& trigs_;
  std::vector<Trig> temp_trigs_;

  /// @brief   Constructs a CircleTessellator that produces enough segments
  ///          to reasonably approximate a circle with a specified radius
  ///          in pixels.
  explicit CircleTessellator(std::shared_ptr<Tessellator>& tessellator,
                             Scalar pixel_radius)
      : trigs_(GetTrigsForDivisions(tessellator,
                                    ComputeQuadrantDivisions(pixel_radius))) {}

  CircleTessellator(const CircleTessellator&) = delete;

  CircleTessellator& operator=(const CircleTessellator&) = delete;

  /// @brief   Compute the number of vertices to divide each quadrant of
  ///          the circle into based on the expected pixel space radius.
  ///
  /// @return  the number of vertices.
  static size_t ComputeQuadrantDivisions(Scalar pixel_radius);

  /// @brief   Compute the sine and cosine for each angle in the number of
  ///          divisions [0, divisions] of a quarter circle and return the
  ///          values in a vector of trig objects.
  ///
  ///          Note that since the 0th division is included, the vector will
  ///          contain (divisions + 1) values.
  ///
  /// @return  The vector of (divisions + 1) trig values.
  const std::vector<Trig>& GetTrigsForDivisions(
      std::shared_ptr<Tessellator>& tessellator,
      size_t divisions);

  static constexpr int kPrecomputedDivisionCount = 1024;
  static int kPrecomputedDivisions[kPrecomputedDivisionCount];
};

}  // namespace impeller
