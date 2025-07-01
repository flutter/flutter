// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/entity/geometry/shadow_path_geometry.h"

#include "flutter/impeller/entity/contents/pipelines.h"
#include "flutter/impeller/geometry/path_source.h"
#include "flutter/impeller/tessellator/path_tessellator.h"

#if EXPORT_SKIA_SHADOW
#include "flutter/third_party/skia/src/core/SkVerticesPriv.h"  // nogncheck
#include "flutter/third_party/skia/src/utils/SkShadowTessellator.h"  // nogncheck
#endif

namespace {

using impeller::kEhCloseEnough;
using impeller::Matrix;
using impeller::PathTessellator;
using impeller::Point;
using impeller::Scalar;
using impeller::ScalarNearlyZero;
using impeller::ShadowVertices;
using impeller::Tessellator;
using impeller::Trig;
using impeller::Vector2;

class PolygonInfo : impeller::PathTessellator::VertexWriter {
 public:
  static constexpr Scalar GetTrigRadiusForHeight(Scalar occluder_height) {
    return GetPenumbraSizeForHeight(occluder_height);
  }

  PolygonInfo(const impeller::PathSource& path,
              const impeller::Matrix& matrix,
              Scalar occluder_height,
              const Tessellator::Trigs& trigs);

  bool IsValid() const { return is_valid_; }
  bool IsEmpty() const { return is_empty_; }

  std::shared_ptr<ShadowVertices> TakeVertices() {
    if (!is_valid_) {
      return nullptr;
    }

    return ShadowVertices::Make(std::move(vertices_),  //
                                std::move(indices_),   //
                                std::move(gaussians_));
  }

 private:
  static constexpr Scalar GetPenumbraSizeForHeight(Scalar occluder_height) {
    return occluder_height;
  }

  static constexpr Scalar GetUmbraSizeForHeight(Scalar occluder_height) {
    return occluder_height;
  }

  enum class PointClass {
    kNonConvex,
    kCollinear,
    kConvex,
  };

  const Scalar occluder_height_;

  // The maximum gaussian of the umbra part of the shadow, usually 1.0f
  // but can be reduced if the umbra size was clipped.
  Scalar umbra_gaussian_ = 1.0f;

  // Each point in the polygon form of the path is turned into a structure
  // that tracks the gradient of the shadow at that point in the path. The
  // shape is turned into a sort of pin cushion where each struct acts
  // like a pin pushed into that cushion in the direction of the shadow
  // gradient at that location.
  //
  // Each entry contains the direction of the pin at that location and the
  // depth to which the pin is inserted, expressed as a fraction of the full
  // umbra size specified by the shadow parameters. A depth of 1.0 means
  // the pin was inserted all the way to the depth of the shadow gradient
  // and didn't collide with any other pins. A fraction less than 1.0 can
  // occur if either the shape was too small and the pins intersected with
  // other pins across the shape from them, or if the curvature in a given
  // area was so tight that adjacent pins started bumping into their neighbors
  // even if the overall size of the shape was larger than the shadow.
  //
  // Different pins will be shortened by different amounts in the same shape
  // depending on the local geometry (tight curves or narrow cross section).
  struct UmbraPin {
    static constexpr Scalar kFractionUninitialized = -1.0f;

    // The point on the original path that generated this entry into the
    // umbra geometry.
    //
    // AKA the point on the path at which this pin was stabbed.
    Point path_vertex;

    // The vector from this path segment to the next.
    Vector2 path_delta;

    // The vector from the path_vertex to the head of the pin (the part
    // outside the shape).
    Vector2 penumbra_delta;

    // The location of the end of this pin, taking into account the reduction
    // of the umbra_size due to minimum distance to centroid, but ignoring
    // clipping against other pins.
    Point pin_tip;

    // The location that this pin confers to the umbra polygon. Initially,
    // this is the same as the pin_tip, but can be reduced by intersecting
    // and clipping against other pins and even eliminated if the other
    // nearby pins make it redundant for defining the umbra polygon.
    // Eventually, if this pin's umbra_vertex was eliminated, this location
    // will be overwritten by the surviving umbra vertex that best servies
    // this pin's path_vertex.
    Point umbra_vertex;
    uint16_t umbra_index = 0u;

    // The interior penetration of the umbra starts out at the full blur
    // radius as modified by the global distance of the path segments to
    // the centroid, but can be shortened when pins are too crowded and start
    // intersecting each other due to tight curvature.
    Scalar umbra_fraction = kFractionUninitialized;

    // Used to create a circular linked list while pruning the umbra polygon.
    // The final vertices that are in the umbra polygon are the vertices that
    // remain on this linked list from a "head" pin.
    UmbraPin* pNext = nullptr;
    UmbraPin* pPrev = nullptr;

    bool IsFractionInitialized() const {
      return umbra_fraction > kFractionUninitialized;
    }
  };

  std::vector<UmbraPin> pins_;
  UmbraPin* umbra_vertices_head_ = nullptr;
  size_t umbra_polygon_count_ = 0u;

  bool is_valid_ = true;   // aka single convex contour
  bool is_empty_ = false;  // is there anything to cast a shadow?

  Point centroid_;
  Scalar shape_area_ = 0.0f;
  Scalar direction_ = 0.0f;
  bool path_ended_ = false;

  // Simple cross products of nearby vertices don't catch all cases of
  // non-convexity so we count the number of times that the sign of the
  // dx/dy of the edges change. It must be <= 3 times for the path to
  // be convex. Think of drawing a circle from the top. First you head
  // to the right, then reverse to the left as you round the bottom of
  // the circle, then back near the top you head to the right again,
  // totalling 3 changes in direction.
  struct DirectionDetector {
    Scalar last_direction_ = 0.0f;
    size_t change_count = 0u;

    void AccumulateDirection(Scalar new_direction) {
      if (last_direction_ == 0.0f || last_direction_ * new_direction < 0.0f) {
        last_direction_ = std::copysign(1.0f, new_direction);
        change_count++;
      }
    }
  } x_direction_detector_, y_direction_detector_;

  // The vertex mesh result that represents the shadow, to be rendered
  // using a modified indexed variant of DrawVertices that also adjusts
  // the alpha of the colors on a per-pixel basis by mapping their linear
  // alphas into the associated gaussian value.
  const impeller::Tessellator::Trigs& trigs_;
  std::vector<Point> vertices_;
  std::vector<uint16_t> indices_;
  std::vector<Scalar> gaussians_;

  bool Invalidate() {
    // This method provides a stop point for debugging shadow conversion
    // failures.
    return is_valid_ = false;
  }

  // |VertexWriter|
  void Write(Point point);

  // |VertexWriter|
  void EndContour();

  // Parameters that determine the sub-pixel grid we will use to simplify
  // the contours to avoid degenerate differences in the vertices.
  static constexpr Scalar kSubPixelCount = 16.0f;
  static constexpr Scalar kSubPixelScale = (1.0f / kSubPixelCount);

  // Rounds the device coordinate to the sub-pixel grid.
  Point ToDeviceGrid(Point point);

  // Check the direction that the edge is heading and count the number of
  // times that the sign of the dx and dy values change. If either of those
  // separated coordinate directions change more than 2 times, return false
  // to indicate that the path is not simple and convex.
  bool CheckEdgeDirection(const Vector2 edge_vector);

  // Validates that the given point continues the path on a single contour,
  // non-self-intersecting, convex path and updates the area and centroid
  // point based on the partial areas of the new point, the previous point
  // and the first point.
  //
  // The method tests for multiple conditions of convexity. If the last 3
  // points are not turning the same direction as previous points, then the
  // path is locally not convex and therefore "invalid". If the quad area of
  // the last 2 points wrt the first point (computed for area and centroid)
  // is not the same sign as the contour's direction then the path is now
  // progressing the "wrong way" around the initial point which indicates
  // multiple turns and self-intersection and is thus "invalid".
  //
  // Note that the area is only computed in order to finalize the centroid
  // point at the end.
  PointClass ValidatePointAndUpdateCentroid(const Point& new_point);

  // Finalize the weighted centroid using the area calculated while the
  // path was being delivered.
  void FinalizeCentroid();

  // Run through the pins and determine the closest pin to the centroid
  // and, in particular, if it is less than the required umbra distance.
  void ComputePinDirectionsAndMinDistanceToCentroid();

  // Run through the pins and determine if they intersect each other
  // internally, whether they are completely obscured by other pins,
  // their new relative lengths if they defer to another pin at some
  // depth, and which remaining pins are part of the umbra polygon and
  // return the pointer to the first pin in the "umbra polygon".
  UmbraPin* ResolveUmbraIntersections();

  // Structure to store the result of computing the intersection between
  // 2 pins, containing the point of intersection and the relative fractions
  // at which the pins intersected (expressed as a ratio of 0 to 1 where
  // 0 represents intersecting at the path outline and 1 represents
  // intersecting at the tip of the pin where the umbra is darkest.
  struct PinIntersection {
    Point intersection;
    Scalar fraction0;
    Scalar fraction1;
  };

  static constexpr Scalar kCrossTolerance = 1.0f / 2048.0f;
  static constexpr Scalar kIntersectionTolerance = 1.0e-6f;

  static constexpr Scalar FiniteVectorLengthSquared(Vector2 v) {
    return !v.IsFinite() ? -1.0f : v.Dot(v);
  }

  static constexpr inline bool OutsideInterval(Scalar numer,
                                               Scalar denom,
                                               bool denomPositive) {
    return (denomPositive && (numer < 0 || numer > denom)) ||
           (!denomPositive && (numer > 0 || numer < denom));
  }

  // Return the intersection between the 2 pins pPin0 and pPin1 if there
  // is an intersection.
  static std::optional<PinIntersection> ComputeIntersection(UmbraPin* pPin0,
                                                            UmbraPin* pPin1);

  static void RemovePin(UmbraPin* pPin, UmbraPin** pHead);

  static int ComputeSide(const Point& p0, const Vector2& v, const Point& p);

  // Run through the path calculating the outset vertices for the penumbra
  // and connecting them to the inset vertices of the umbra and then to
  // the centroid in a system of triangles with the appropriate alpha values
  // representing the intensity of the (non-gamma-adjusted) shadow at those
  // points.
  void ComputeMesh();

  // After the umbra_vertices of the pins are accumulated and linked into
  // a ring using their pPrev/pNext pointers, compute the best surviving
  // umbra vertex for each pin and set its location and index into the pin.
  void PopulateUmbraVertices();

  uint16_t AppendFan(const UmbraPin* p_curr_pin,
                     const Point& fan_start,
                     const Point& fan_end,
                     uint16_t start_index);

  uint16_t AppendVertex(const Point& vertex, Scalar opacity);

  void AddTriangle(uint16_t v0, uint16_t v1, uint16_t v2);
};

PolygonInfo::PolygonInfo(const impeller::PathSource& source,
                         const Matrix& matrix,
                         Scalar occluder_height,
                         const Tessellator::Trigs& trigs)
    : occluder_height_(occluder_height), trigs_(trigs) {
  Scalar scale = matrix.GetMaxBasisLengthXY();

  auto [point_count, contour_count] =
      impeller::PathTessellator::CountFillStorage(source, scale);
  pins_.reserve(point_count);

  PathTessellator::PathToTransformedFilledVertices(source, *this, matrix);
  if (!is_valid_ || pins_.size() < 3 || direction_ == 0.0f ||
      shape_area_ == 0.0f) {
    // The shape was either invalid or empty.
    return;
  }

  FinalizeCentroid();

  ComputePinDirectionsAndMinDistanceToCentroid();

  umbra_vertices_head_ = ResolveUmbraIntersections();
  if (umbra_vertices_head_ == nullptr) {
    // The Skia algorithm from which this was taken tries to fake an
    // umbra polygon that is 95% from the path polygon to the centroid,
    // but that result does not look great. If we run into this case
    // a lot we should either beef up the ResolveIntersections algorithm
    // or find a better approximation.
    Invalidate();
    return;
  }

  ComputeMesh();
}

// Enter a new point for the polygon approximation of the shape. Points are
// normalized to a device subpixel grid based on |kSubPixelCount|, duplicates
// at that sub-pixel grid are ignored, collinear points are reduced to just
// the endpoints, and the centroid is updated from the remaining non-duplicate
// grid points.
void PolygonInfo::Write(Point point) {
  if (!is_valid_) {
    return;
  }

  if (path_ended_) {
    Invalidate();
    return;
  }

  point = ToDeviceGrid(point);

  if (!pins_.empty()) {
    // If this isn't the first point then we need to perform de-duplication
    // and possibly convexity checking and centroid updates.

    if (point == pins_.back().path_vertex) {
      // Avoid duplicate points, adjusted points are rounded so == is OK
      // for floating point comparison here.
      return;
    }

    switch (ValidatePointAndUpdateCentroid(point)) {
      case PointClass::kConvex:
        break;
      case PointClass::kCollinear:
        pins_.pop_back();
        break;
      case PointClass::kNonConvex:
        Invalidate();
        return;
    }
  }

  pins_.emplace_back(point);
}

// Called at the end of every contour of which we hope there is only one.
// If we detect more than one contour then the shadow tessellation becomes
// invalid.
//
// Each contour will have exactly one point at the beginning and end which
// are duplicates. The extra repeat of the first point actually helped the
// centroid accumulation do its math for ever segment in the path, but
// going forward we don't need the extra pin in the shape so we verify that
// it is a duplicate and then we delete it.
void PolygonInfo::EndContour() {
  if (!is_valid_) {
    return;
  }

  if (path_ended_) {
    Invalidate();
    return;
  }

  // PathTessellator always ensures the path is closed back to the origin
  // by an extra call to Write(Point).
  FML_DCHECK(pins_.front().path_vertex == pins_.back().path_vertex);
  pins_.pop_back();
  path_ended_ = true;
}

// Adjust the device point to its nearest sub-pixel grid location.
Point PolygonInfo::ToDeviceGrid(Point point) {
  // Transform to device space and round to nearest sub-pixel.
  return (point * kSubPixelCount).Round() * kSubPixelScale;
}

// Use the direction change accumulators to count the number of times
// that edges change direction in X and Y and return whether the path
// can still be classified as simple and convex.
bool PolygonInfo::CheckEdgeDirection(const Vector2 edge_vector) {
  x_direction_detector_.AccumulateDirection(edge_vector.x);
  y_direction_detector_.AccumulateDirection(edge_vector.y);
  return x_direction_detector_.change_count <= 3u &&
         y_direction_detector_.change_count <= 3u;
}

// This method performs 3 functions.
// - Ensure that the 3 most recent vertices are turning in a consistent
//   direction. (No concave sections.)
// - Ensure that all vertices turn the same direction from the perspective
//   of the first point. (No "going around twice".)
// - Accumulate data to compute the centroid
PolygonInfo::PointClass PolygonInfo::ValidatePointAndUpdateCentroid(
    const Point& new_point) {
  if (!is_valid_) {
    return PointClass::kNonConvex;
  }

  if (pins_.size() < 2u) {
    return PointClass::kConvex;
  }

  const Point& prev = pins_.back().path_vertex;
  if (!CheckEdgeDirection(new_point - prev)) {
    return PointClass::kNonConvex;
  }

  // direction_ is always normalized to one of these values.
  FML_DCHECK(direction_ == 0.0f ||  //
             direction_ == 1.0f ||  //
             direction_ == -1.0f);

  PointClass result = PointClass::kConvex;

  // We can only perform concavity detection once we have a direction.
  if (pins_.size() >= 2u) {
    // Note that if there are only 2 points in the path, the direction_
    // will not yet have been determined and this check computes the same
    // values as the global check below anyway.
    // FML_DCHECK(pins_.size() > 2u);

    // Check that each triplet of points (this, prev, prev_prev) turn the
    // same direction.
    const Point& prev_prev = pins_.end()[-2].path_vertex;
    Vector2 v0 = prev - prev_prev;
    Vector2 v1 = new_point - prev_prev;
    Scalar cross = v0.Cross(v1);
    if (cross == 0) {
      result = PointClass::kCollinear;
    } else if (cross * direction_ < 0) {
      return PointClass::kNonConvex;
    }
  }

  const Point& first = pins_.front().path_vertex;
  Vector2 v0 = prev - first;
  Vector2 v1 = new_point - first;
  Scalar quad_area = v0.Cross(v1);
  if (quad_area == 0) {
    return result;
  }

  // convexity check for whole path which can detect if we turn more than
  // 360 degrees and start going the other way wrt the start point, but
  // does not detect if any pair of points are concave (checked above).
  if (direction_ == 0) {
    direction_ = std::copysign(1.0f, quad_area);
  } else if (quad_area * direction_ < 0) {
    return PointClass::kNonConvex;
  }

  // We are computing the centroid using a weighted average of all of the
  // centroids of the triangles in a tessellation of the polygon, in this
  // case a triangle fan tessellation relative to the first point in the
  // polygon.  We could use any point, but since we had to compute the
  // cross product above relative to the initial point in order to detect
  // if the path turned more than once, we already have values available
  // relative to that first point here.
  //
  // The centroid of each triangle is the 3-way average of the corners of
  // that triangle. Since the triangles are all relative to the first point,
  // one of those corners is (0, 0) in this relative triangle and so we
  // can simply add up the x,y of the two relative points and divide by
  // 3.0. Since all values in the sum are divided by 3.0, we can save that
  // constant division until the end when we finalize the average computation.
  //
  // We also weight these centroids by the area of the triangle so that we
  // adjust for the parts of the polygon that are represented more densely
  // and the parts that span a larger part of its circumference. A simple
  // average would bias the centroid towards parts of the polygon where the
  // points are denser. If we are rendering a polygonal representation of a
  // round rect with only one round corner, all of the many approximating
  // segments of the flattened round corner would overwhelm the handful of
  // other simple segments for the flat sides. A weighted average places the
  // centroid back at the "center of mass" of the polygon.
  //
  // Luckily, the same cross product used above that helps us determine the
  // turning and convexity of the polygon also provides us with the area of
  // the parallelogram projected from the 3 points in the triangle. That
  // area is exactly double the area of the triangle itself. We could divide
  // by 2 here, but since we are also accumulating these cross product values
  // for the final weighted division, the factors of 2 all cancel out.
  //
  // quad_area is (2 * triangle area).
  // centroid_ is accumulating sum(3 * triangle centroid * quad area).
  // shape_area_ is accumulating sum(quad area).
  //
  // The final combined average weight factor will be (3 * sum(quad area)).
  centroid_ += (v0 + v1) * quad_area;
  shape_area_ += quad_area;

  return result;
}

void PolygonInfo::FinalizeCentroid() {
  // To finalize the centroid value we need to divide by both the constant
  // factor of 3.0 that was ignored when we computed the triangle centroids
  // (average of the 3 triangle vertices) and also the accumulation of all
  // of the individual triangle areas used as the averaging weights.
  centroid_ /= 3.0f * shape_area_;

  // The centroid accumulation was relative to the first point in the
  // polygon so we make it absolute here.
  centroid_ += pins_[0].path_vertex;
}

void PolygonInfo::ComputePinDirectionsAndMinDistanceToCentroid() {
  Scalar desired_umbra_size = GetUmbraSizeForHeight(occluder_height_);
  Scalar min_umbra_squared = desired_umbra_size * desired_umbra_size;
  FML_DCHECK(direction_ == 1.0f || direction_ == -1.0f);

  // For simplicity of iteration, we start with the last vertex as the
  // "previous" pin and then iterate once over the vector of pins,
  // performing these calculations on the path segment from the previous
  // pin to the current pin. In the end, all pins and therefore all path
  // segments are processed once even if we start with the last pin.

  // First pass, compute the smallest distance to the centroid.
  UmbraPin* p_prev_pin = &pins_.back();
  for (UmbraPin& pin : pins_) {
    UmbraPin* p_curr_pin = &pin;

    // Accumulate (min) the distance from the centroid to "this" segment.
    Scalar distance_squared = centroid_.GetDistanceToSegmentSquared(
        p_prev_pin->path_vertex, p_curr_pin->path_vertex);
    min_umbra_squared = std::min(min_umbra_squared, distance_squared);

    p_prev_pin = p_curr_pin;
  }

  static constexpr auto kTolerance = 1.0e-2f;
  Scalar umbra_size = std::sqrt(min_umbra_squared);
  if (umbra_size < desired_umbra_size + kTolerance) {
    // if the umbra would collapse, we back off a bit on the inner blur and
    // adjust the alpha
    auto newInset = umbra_size - kTolerance;
    auto ratio = 0.5f * (newInset / desired_umbra_size + 1);
    FML_DCHECK(std::isfinite(ratio));
    // they aren't PMColors, but the interpolation algorithm is the same
    umbra_gaussian_ = ratio;
    umbra_size = newInset;
  } else {
    FML_DCHECK(umbra_gaussian_ == 1.0f);
  }

  // Second pass, fill out the pin data with the final umbra size.
  //
  // We also link all of the pins into a circular linked list so they can be
  // quickly eliminated in the method that resolves intersections of the pins.
  Scalar penumbra_scale = -GetPenumbraSizeForHeight(occluder_height_);
  p_prev_pin = &pins_.back();
  for (UmbraPin& pin : pins_) {
    UmbraPin* p_curr_pin = &pin;
    p_curr_pin->pPrev = p_prev_pin;
    p_prev_pin->pNext = p_curr_pin;

    // We compute the vector along the path segment from the previous
    // path vertex to this one as well as the unit direction vector
    // that points from that pin towards the center of the shape,
    // perpendicular to that segment.
    p_prev_pin->path_delta = p_curr_pin->path_vertex - p_prev_pin->path_vertex;
    Vector2 pin_direction = p_prev_pin
                                ->path_delta  //
                                .Normalize()
                                .PerpendicularRight() *
                            direction_;

    p_prev_pin->penumbra_delta = pin_direction * penumbra_scale;
    p_prev_pin->umbra_vertex =  //
        p_prev_pin->pin_tip =
            p_prev_pin->path_vertex + pin_direction * umbra_size;

    p_prev_pin = p_curr_pin;
  }
}

// Compute the intersection 'p' between the two pins pin 0 and pin 1, if any.
// The intersection structure will contain the fractional distances along the
// pins of the intersection and the intersection point itself if there is an
// intersection.
//
// The intersection structure will be reset to empty otherwise.
//
// This method was converted nearly verbatim from the Skia source files
// SkShadowTessellator.cpp and SkPolyUtils.cpp, except for variable
// naming and differences in the methods on Point and Vertex2.
std::optional<PolygonInfo::PinIntersection> PolygonInfo::ComputeIntersection(
    UmbraPin* pPin0,
    UmbraPin* pPin1) {
  Vector2 v0 = pPin0->path_delta;
  Vector2 v1 = pPin1->path_delta;
  Vector2 tip_delta = pPin1->pin_tip - pPin0->pin_tip;
  Vector2 w = tip_delta;
  Scalar denom = pPin0->path_delta.Cross(pPin1->path_delta);
  bool denomPositive = (denom > 0);
  Scalar sNumer, tNumer;
  if (ScalarNearlyZero(denom, kCrossTolerance)) {
    // segments are parallel, but not collinear
    if (!ScalarNearlyZero(tip_delta.Cross(pPin0->path_delta),
                          kCrossTolerance) ||
        !ScalarNearlyZero(tip_delta.Cross(pPin1->path_delta),
                          kCrossTolerance)) {
      return std::nullopt;
    }

    // Check for zero-length segments
    Scalar v0dotv0 = FiniteVectorLengthSquared(v0);
    if (v0dotv0 <= 0.0f) {
      // Both are zero-length
      Scalar v1dotv1 = FiniteVectorLengthSquared(v1);
      if (v1dotv1 <= 0.0f) {
        // Check if they're the same point
        if (w.IsFinite() && !w.IsZero()) {
          // *p = s0.fP0;
          // *s = 0;
          // *t = 0;
          return {{
              .intersection = pPin0->pin_tip,
              .fraction0 = 0.0f,
              .fraction1 = 0.0f,
          }};
        } else {
          // Intersection is indeterminate
          return std::nullopt;
        }
      }
      // Otherwise project segment0's origin onto segment1
      tNumer = v1.Dot(-w);
      denom = v1dotv1;
      if (OutsideInterval(tNumer, denom, true)) {
        return std::nullopt;
      }
      sNumer = 0;
    } else {
      // Project segment1's endpoints onto segment0
      sNumer = v0.Dot(w);
      denom = v0dotv0;
      tNumer = 0;
      if (OutsideInterval(sNumer, denom, true)) {
        // The first endpoint doesn't lie on segment0
        // If segment1 is degenerate, then there's no collision
        Scalar v1dotv1 = FiniteVectorLengthSquared(v1);
        if (v1dotv1 <= 0.0f) {
          return std::nullopt;
        }

        // Otherwise try the other one
        Scalar oldSNumer = sNumer;
        sNumer = v0.Dot(w + v1);
        tNumer = denom;
        if (OutsideInterval(sNumer, denom, true)) {
          // it's possible that segment1's interval surrounds segment0
          // this is false if params have the same signs, and in that case
          // no collision
          if (sNumer * oldSNumer > 0) {
            return std::nullopt;
          }
          // otherwise project segment0's endpoint onto segment1 instead
          sNumer = 0;
          tNumer = v1.Dot(-w);
          denom = v1dotv1;
        }
      }
    }
  } else {
    sNumer = w.Cross(v1);
    if (OutsideInterval(sNumer, denom, denomPositive)) {
      return std::nullopt;
    }
    tNumer = w.Cross(v0);
    if (OutsideInterval(tNumer, denom, denomPositive)) {
      return std::nullopt;
    }
  }

  Scalar localS = sNumer / denom;
  Scalar localT = tNumer / denom;

  return {{
      .intersection = pPin0->pin_tip + v0 * localS,
      .fraction0 = localS,
      .fraction1 = localT,
  }};
}

void PolygonInfo::RemovePin(UmbraPin* pPin, UmbraPin** pHead) {
  UmbraPin* pNext = pPin->pNext;
  UmbraPin* pPrev = pPin->pPrev;
  pPrev->pNext = pNext;
  pNext->pPrev = pPrev;
  if (*pHead == pPin) {
    *pHead = (pNext == pPin) ? nullptr : pNext;
  }
}

// Computes the relative direction for point p compared to segment defined
// by origin p0 and vector v. A positive value means the point is to the
// left of the segment, negative is to the right, 0 is collinear.
int PolygonInfo::ComputeSide(const Point& p0,
                             const Vector2& v,
                             const Point& p) {
  Vector2 w = p - p0;
  Scalar cross = v.Cross(w);
  if (!impeller::ScalarNearlyZero(cross, kCrossTolerance)) {
    return ((cross > 0) ? 1 : -1);
  }

  return 0;
}

// This method was converted nearly verbatim from the Skia source files
// SkShadowTessellator.cpp and SkPolyUtils.cpp, except for variable
// naming and differences in the methods on Point and Vertex2.
PolygonInfo::UmbraPin* PolygonInfo::ResolveUmbraIntersections() {
  UmbraPin* p_head_pin = &pins_.front();
  UmbraPin* p_curr_pin = p_head_pin;
  UmbraPin* p_prev_pin = p_curr_pin->pPrev;
  size_t umbra_vertex_count = pins_.size();

  // we should check each edge against each other edge at most once
  size_t allowed_iterations = pins_.size() * pins_.size() + 1u;

  while (p_head_pin && p_prev_pin != p_curr_pin) {
    if (--allowed_iterations == 0) {
      return nullptr;
    }

    std::optional<PinIntersection> intersection =
        ComputeIntersection(p_prev_pin, p_curr_pin);
    if (intersection.has_value()) {
      // If the new intersection is further back on previous inset from the
      // prior intersection...
      if (intersection->fraction0 < p_prev_pin->umbra_fraction) {
        // no point in considering this one again
        RemovePin(p_prev_pin, &p_head_pin);
        --umbra_vertex_count;
        // go back one segment
        p_prev_pin = p_prev_pin->pPrev;
      } else if (p_curr_pin->IsFractionInitialized() &&
                 p_curr_pin->umbra_vertex.GetDistanceSquared(
                     intersection->intersection) < kIntersectionTolerance) {
        // We've already considered this intersection and come to the same
        // result, we're done.
        break;
      } else {
        // Add intersection.
        p_curr_pin->umbra_vertex = intersection->intersection;
        p_curr_pin->umbra_fraction = intersection->fraction1;

        // go to next segment
        p_prev_pin = p_curr_pin;
        p_curr_pin = p_curr_pin->pNext;
      }
    } else {
      // if previous pin is to right side of the current pin...
      int side = direction_ * ComputeSide(p_curr_pin->pin_tip,     //
                                          p_curr_pin->path_delta,  //
                                          p_prev_pin->pin_tip);
      if (side < 0 &&
          side == direction_ * ComputeSide(p_curr_pin->pin_tip,     //
                                           p_curr_pin->path_delta,  //
                                           p_prev_pin->pin_tip +
                                               p_prev_pin->path_delta)) {
        // no point in considering this one again
        RemovePin(p_prev_pin, &p_head_pin);
        --umbra_vertex_count;
        // go back one segment
        p_prev_pin = p_prev_pin->pPrev;
      } else {
        // move to next segment
        RemovePin(p_curr_pin, &p_head_pin);
        --umbra_vertex_count;
        p_curr_pin = p_curr_pin->pNext;
      }
    }
  }

  if (!p_head_pin) {
    return nullptr;
  }

  // Now remove any duplicates from the umbra polygon. The head pin is
  // automatically included as the first point of the umbra polygon.
  p_prev_pin = p_head_pin;
  p_curr_pin = p_head_pin->pNext;
  size_t umbra_vertices = 1u;
  while (p_curr_pin != p_head_pin) {
    if (p_prev_pin->umbra_vertex.GetDistanceSquared(p_curr_pin->umbra_vertex) <
        kSubPixelScale * kSubPixelScale) {
      RemovePin(p_curr_pin, &p_head_pin);
      p_curr_pin = p_curr_pin->pNext;
    } else {
      umbra_vertices++;
      p_prev_pin = p_curr_pin;
      p_curr_pin = p_curr_pin->pNext;
    }
    FML_DCHECK(p_curr_pin == p_prev_pin->pNext);
    FML_DCHECK(p_prev_pin == p_curr_pin->pPrev);
  }

  if (umbra_vertices < 3u) {
    return nullptr;
  }

  umbra_polygon_count_ = umbra_vertices;
  return p_head_pin;
}

// The mesh computed connects all of the points in two rings. The outermost
// ring represents the point where the shadow disappears and those points
// are associated with an alpha of 0. The umbra polygon represents the ring
// where the shadow is its darkest, usually fully "opaque" (potentially
// modulated by a non-opaque shadow color, but opaque with respect to the
// shadow's varying intensity). The umbra polygon may not be fully "opaque"
// with respect to the shadow cast by the shape if the shadows radius is
// larger than the cross-section of the shape. If the umbra polygon is pulled
// back from extending the shadow distance inward due to this phenomenon,
// then the umbra_gaussian will be computed to be less than fully opaque.
//
// The mesh will connect the centroid to the umbra (inner) polygon at a
// constant level as computed in umbra_gaussian, and then the umbra polygon
// is connected to the nearest points on the penumbra (outer) polygon which
// is seeded with points that are fully transparent (umbra level 0).
//
// This creates 2 rings of triangles that are interspersed in the vertices_
// and connected into triangles using indices_ both to reuse the vertices
// as best we can and also because we don't generate the vertices in any
// kind of useful fan or strip format. The points are reused as such:
//
// - The centroid vertex will be used once for each pair of umbra vertices
//   to make triangles for the inner ring.
// - Each umbra vertex will be used in both the inner and the outer rings.
//   In particular, in 2 of the inner ring triangles and in an arbitrary
//   number of the outer ring vertices (each outer ring vertex is connected
//   to the neariest inner ring vertex so the mapping is not predictable).
// - Each outer ring vertex is used in at least 2 outer ring triangles, the
//   one that links to the vertex before it and the one that links to the
//   vertex following it, plus we insert extra vertices on the outer ring
//   to turn the corners beteween the projected segments.
void PolygonInfo::ComputeMesh() {
  if (!is_valid_) {
    return;
  }

  // Centroid and umbra polygon...
  size_t vertex_count = umbra_polygon_count_ + 1u;
  size_t triangle_count = umbra_polygon_count_;

  // Penumbra corners - likely many more fan vertices than estimated...
  size_t penumbra_count = pins_.size() * 2;  // 2 perp at each vertex.
  penumbra_count += trigs_.size() * 4;       // total 360 degrees of fans.
  vertex_count += penumbra_count;
  triangle_count += penumbra_count;

  vertices_.reserve(vertex_count);
  gaussians_.reserve(vertex_count);
  indices_.reserve(triangle_count * 3);

  // First we populate the umbra_vertex and umbra_index of each pin with its
  // nearest point on the umbra polygon (the linked list computed earlier).
  //
  // This step simplifies the following operations because we will always
  // know which umbra vertex each pin object is associated with and whether
  // we need to bridge between them as we progress through the pins, without
  // having to search through the linked list every time.
  //
  // This method will also fill in the inner part of the mesh that connects
  // the centroid to every vertex in the umbra polygon with triangles that
  // are all at the maximum umbra gaussian coefficient.
  PopulateUmbraVertices();

  // We now run through the list of all pins and append points and triangles
  // to our internal vectors to cover the part of the mesh that extends
  // out from the umbra polygon to the outer penumbra points.
  //
  // Each pin assumes that the previous pin contributed some points to the
  // penumbra polygon that ended with the point that is perpendicular to
  // the side between that previous path vertex and its own path vertex.
  // This pin will then contribute any number of the following points to
  // the penumbra polygon:
  //
  // - If this pin uses a different umbra vertex than the previous pin
  //   (common for simple large polygons that have no clipping of their
  //   inner umbra points) then it inserts a bridging quad that connects
  //   from the ending segment of the previous pin to the starting segment
  //   of this pin. If both are based on the same umbra vertex then the
  //   end of the previous pin is identical to the start of this one.
  // - Possibly a fan of extra vertices to round the corner from the
  //   last segment added, which is perpendicular to the previous path
  //   segment, to the final segmet of this pin, which will be perpendicular
  //   to the following path segment.
  // - The last penumbra point added will be the penumbra point that is
  //   perpendicular to the following segment, which prepares for the
  //   initial conditions that the next pin will expect.
  UmbraPin* p_prev_pin = &pins_.back();

  // This point may be duplicated at the end of the path. We can try to
  // avoid adding it twice with some bookkeeping, but it is simpler to
  // just add it here for the pre-conditions of the start of the first
  // pin and allow the duplication to happen naturally as we process the
  // final pin later. One extra point should not be very noticeable in
  // the long list of mesh vertices.
  Point last_penumbra_point =
      p_prev_pin->path_vertex + p_prev_pin->penumbra_delta;
  uint16_t last_penumbra_index = AppendVertex(last_penumbra_point, 0.0f);

  for (UmbraPin& pin : pins_) {
    UmbraPin* p_curr_pin = &pin;

    // Preconditions:
    // - last_penumbra_point was the last outer vertex added by the
    //   previous pin
    // - last_penumbra_index is its index in the vertices to be used
    //   for creating indexed triangles.

    if (p_prev_pin->umbra_index != p_curr_pin->umbra_index) {
      // We've moved on to a new umbra index to anchor our penumbra triangles.
      // We need to bridge the gap so that we are now building a new fan from
      // a point that has the same relative angle from the current pin's
      // path vertex as the previous penumbra point had from the previous
      // pin's path vertex.
      //
      // Our previous penumbra fan vector would have gone from the previous
      // pin's umbra point to the previous pen's final penumbra point:
      // - prev->umbra_vertex
      // => prev->path_vertex + prev->penumbra_delta
      // We will connect to a parallel vector that extends from the new
      // (current pin's) umbra index in the same direction:
      // - curr->umbra_vertex
      // => curr->path_vertex + prev->penumbra_delta

      // First we pivot about the old penumbra point to bridge from the old
      // umbra vertex to our new umbra point.
      AddTriangle(last_penumbra_index,  //
                  p_prev_pin->umbra_index, p_curr_pin->umbra_index);

      // Then we bridge from the old penumbra point to the new parallel
      // penumbra point, pivoting around the new umbra index.
      Point new_penumbra_point =
          p_curr_pin->path_vertex + p_prev_pin->penumbra_delta;
      uint16_t new_penumbra_index = AppendVertex(new_penumbra_point, 0.0f);

      AddTriangle(p_curr_pin->umbra_index, last_penumbra_index,
                  new_penumbra_index);

      last_penumbra_point = new_penumbra_point;
      last_penumbra_index = new_penumbra_index;
    }

    // Now draw a fan from the current pin's umbra vertex to all of the
    // penumbra points associated with this pin's path vertex, ending at
    // our new final penumbra point associated with this pin.
    Point new_penumbra_point =
        p_curr_pin->path_vertex + p_curr_pin->penumbra_delta;
    uint16_t new_penumbra_index =
        AppendFan(p_curr_pin, last_penumbra_point, new_penumbra_point,
                  last_penumbra_index);

    last_penumbra_point = new_penumbra_point;
    last_penumbra_index = new_penumbra_index;
    p_prev_pin = p_curr_pin;
  }
}

// Visit each pin and find the nearest umbra_vertex from the linked list of
// surviving umbra pins so we don't have to constantly find this as we stitch
// together the mesh.
void PolygonInfo::PopulateUmbraVertices() {
  // We should be having the first crack at the vertex list, filling it with
  // the centroid, the umbra vertices, and the mesh connecting those into the
  // central core of the shadow.
  FML_DCHECK(umbra_vertices_head_ != nullptr);
  FML_DCHECK(vertices_.empty());
  FML_DCHECK(gaussians_.empty());
  FML_DCHECK(indices_.empty());

  // Always start with the centroid.
  uint16_t last_umbra_index = AppendVertex(centroid_, umbra_gaussian_);
  FML_DCHECK(last_umbra_index == 0u);

  // curr_umbra_pin is the most recently matched umbra vertex pin.
  // next_umbra_pin is the next umbra vertex pin to consider.
  // These pointers will always point to one of the pins that is on the
  // linked list of surviving umbra pins, possibly jumping over many
  // other umbra pins that were eliminated when we inset the polygon.
  UmbraPin* p_next_umbra_pin = umbra_vertices_head_;
  UmbraPin* p_curr_umbra_pin = p_next_umbra_pin->pPrev;
  for (UmbraPin& pin : pins_) {
    if (p_next_umbra_pin == &pin ||
        (pin.path_vertex.GetDistanceSquared(p_curr_umbra_pin->umbra_vertex) >
         pin.path_vertex.GetDistanceSquared(p_next_umbra_pin->umbra_vertex))) {
      // We always bump to the next vertex when it was generated from this
      // pin, and also when it is closer to this path_vertex than the last
      // matched pin (curr).
      p_curr_umbra_pin = p_next_umbra_pin;
      p_next_umbra_pin = p_next_umbra_pin->pNext;

      // New umbra vertex - append it and remember its index.
      uint16_t new_umbra_index =
          AppendVertex(p_curr_umbra_pin->umbra_vertex, umbra_gaussian_);
      p_curr_umbra_pin->umbra_index = new_umbra_index;
      if (last_umbra_index != 0u) {
        AddTriangle(0u, last_umbra_index, new_umbra_index);
      }
      last_umbra_index = new_umbra_index;
    }
    if (p_curr_umbra_pin != &pin) {
      pin.umbra_vertex = p_curr_umbra_pin->umbra_vertex;
      pin.umbra_index = last_umbra_index;
    }
    FML_DCHECK(pin.umbra_index != 0u);
  }
  if (last_umbra_index != pins_.front().umbra_index) {
    AddTriangle(0u, last_umbra_index, pins_.front().umbra_index);
  }
}

// Appends a fan based on center from the relative point in start_delta to
// the relative point in end_delta, potentially adding additional relative
// vectors if the turning rate is faster than the trig values in trigs_.
uint16_t PolygonInfo::AppendFan(const UmbraPin* p_curr_pin,
                                const Vector2& start,
                                const Vector2& end,
                                uint16_t start_index) {
  Point center = p_curr_pin->path_vertex;
  uint16_t center_index = p_curr_pin->umbra_index;
  uint16_t prev_index = start_index;

  Vector2 start_delta = start - center;
  Vector2 end_delta = end - center;
  size_t trig_count = trigs_.size();
  for (size_t i = 1u; i < trig_count; i++) {
    Trig trig = trigs_[i];
    Point fan_delta = (direction_ >= 0 ? trig : -trig) * start_delta;
    if (fan_delta.Cross(end_delta) * direction_ <= 0) {
      break;
    }
    uint16_t cur_index = AppendVertex(center + fan_delta, 0.0f);
    AddTriangle(center_index, prev_index, cur_index);
    prev_index = cur_index;
    if (i == trig_count - 1) {
      // This corner was >90 degrees so we start the loop over in case there
      // are more intermediate angles to emit.
      //
      // We set the loop variable to 0u which looks like it might apply a
      // 0 rotation to the new start_delta, but the for loop is about to
      // auto-incrment the variable to 1u, which will start at the next
      // non-0 rotation angle.
      i = 0u;
      start_delta = fan_delta;
    }
  }
  uint16_t cur_index = AppendVertex(center + end_delta, 0.0f);
  AddTriangle(center_index, prev_index, cur_index);
  return cur_index;
}

// Appends a vertex and gaussian value into the associated std::vectors
// and returns the index at which the point was inserted.
uint16_t PolygonInfo::AppendVertex(const Point& vertex, Scalar gaussian) {
  FML_DCHECK(gaussian >= 0.0f && gaussian <= 1.0f);
  uint16_t index = vertices_.size();
  FML_DCHECK(index == gaussians_.size());
  // TODO(jimgraham): Turn this condition into a failure of the tessellation
  FML_DCHECK(index <= std::numeric_limits<uint16_t>::max());
  vertices_.push_back(vertex);
  gaussians_.push_back(gaussian);
  return index;
}

// Appends a triangle of the 3 indices into the indices_ vector.
void PolygonInfo::AddTriangle(uint16_t v0, uint16_t v1, uint16_t v2) {
  FML_DCHECK(std::max(std::max(v0, v1), v2) < vertices_.size());
  indices_.push_back(v0);
  indices_.push_back(v1);
  indices_.push_back(v2);
}

}  // namespace

namespace impeller {

std::optional<Rect> ShadowVertices::GetBounds() const {
  return Rect::MakePointBounds(vertices_);
}

ShadowPathGeometry::ShadowPathGeometry(Tessellator& tessellator,
                                       const Matrix& matrix,
                                       const PathSource& source,
                                       Scalar occluder_height)
    : shadow_vertices_(MakeAmbientShadowVertices(tessellator,
                                                 source,
                                                 occluder_height,
                                                 matrix)) {}

bool ShadowPathGeometry::CanRender() const {
  return shadow_vertices_ != nullptr;
}

bool ShadowPathGeometry::IsEmpty() const {
  return shadow_vertices_ != nullptr && shadow_vertices_->IsEmpty();
}

const std::shared_ptr<ShadowVertices>& ShadowPathGeometry::GetShadowVertices()
    const {
  return shadow_vertices_;
}

std::optional<Rect> ShadowPathGeometry::GetCoverage(
    const Matrix& transform) const {
  return shadow_vertices_ ? shadow_vertices_->GetBounds() : std::nullopt;
}

GeometryResult ShadowPathGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  FML_DCHECK(CanRender());

  using VS = ShadowVerticesVertexShader;

  size_t vertex_count = shadow_vertices_->GetVertexCount();

  BufferView vertex_buffer = renderer.GetTransientsDataBuffer().Emplace(
      vertex_count * sizeof(VS::PerVertexData), alignof(VS::PerVertexData),
      [&](uint8_t* data) {
        VS::PerVertexData* vtx_contents =
            reinterpret_cast<VS::PerVertexData*>(data);
        const std::vector<Point>& vertices = shadow_vertices_->GetVertices();
        const std::vector<Scalar>& gaussians = shadow_vertices_->GetGaussians();
        for (size_t i = 0u; i < vertex_count; i++) {
          vtx_contents[i] = {.position = vertices[i], .gaussian = gaussians[i]};
        }
      });

  size_t index_count = shadow_vertices_->GetIndexCount();
  const uint16_t* indices_data = shadow_vertices_->GetIndices().data();
  BufferView index_buffer = {};
  index_buffer = renderer.GetTransientsIndexesBuffer().Emplace(
      indices_data, index_count * sizeof(uint16_t), alignof(uint16_t));

  return GeometryResult{
      .type = PrimitiveType::kTriangle,
      .vertex_buffer =
          {
              .vertex_buffer = vertex_buffer,
              .index_buffer = index_buffer,
              .vertex_count = index_count,
              .index_type = IndexType::k16bit,
          },
      .transform = pass.GetOrthographicTransform(),
  };
}

std::shared_ptr<ShadowVertices> ShadowPathGeometry::MakeAmbientShadowVertices(
    Tessellator& tessellator,
    const PathSource& source,
    Scalar occluder_height,
    const Matrix& matrix) {
  Scalar trig_radius = PolygonInfo::GetTrigRadiusForHeight(occluder_height);
  Tessellator::Trigs trigs = tessellator.GetTrigsForDeviceRadius(trig_radius);
  PolygonInfo polygon(source, matrix, occluder_height, trigs);

  return polygon.TakeVertices();
}

#if EXPORT_SKIA_SHADOW
std::shared_ptr<ShadowVertices>
ShadowPathGeometry::MakeAmbientShadowVerticesSkia(const flutter::DlPath& path,
                                                  Scalar occluder_height,
                                                  const Matrix& matrix) {
  const SkMatrix ctm = SkMatrix::MakeAll(
      // clang-format off
      matrix.m[0], matrix.m[4], matrix.m[12],
      matrix.m[1], matrix.m[5], matrix.m[13],
      matrix.m[3], matrix.m[7], matrix.m[15]
      // clang-format on
  );
  SkPoint3 z_plane = {0, 0, occluder_height};
  SkPoint3 light_pos = {0, -1, 1};
  SkScalar light_radius = 800 / 600;
  bool transparent = true;
  bool directional = true;
  auto sk_vertices =
      SkShadowTessellator::MakeSpot(path.GetSkPath(), ctm, z_plane, light_pos,
                                    light_radius, transparent, directional);
  if (sk_vertices == nullptr) {
    return nullptr;
  }

  auto sk_priv = sk_vertices->priv();

  std::vector<Point> vertices;
  std::vector<uint16_t> indices;
  std::vector<Scalar> gaussians;
  vertices.reserve(sk_priv.vertexCount());
  indices.reserve(sk_priv.indexCount());
  gaussians.reserve(sk_priv.vertexCount());

  for (int i = 0; i < sk_priv.vertexCount(); i++) {
    SkPoint vertex = sk_priv.positions()[i];
    vertices.emplace_back(vertex.fX, vertex.fY);
    gaussians.push_back(SkColorGetA(sk_priv.colors()[i]) / 255.0f);
  }
  for (int i = 0; i < sk_priv.indexCount(); i++) {
    indices.push_back(sk_priv.indices()[i]);
  }

  return ShadowVertices::Make(vertices, indices, gaussians);
}
#endif

}  // namespace impeller
