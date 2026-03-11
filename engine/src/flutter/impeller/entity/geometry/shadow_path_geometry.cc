// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/entity/geometry/shadow_path_geometry.h"

#include "flutter/impeller/entity/contents/pipelines.h"
#include "flutter/impeller/geometry/path_source.h"
#include "flutter/impeller/tessellator/path_tessellator.h"

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

/// Each point in the polygon form of the path is turned into a structure
/// that tracks the gradient of the shadow at that point in the path. The
/// shape is turned into a sort of pin cushion where each struct acts
/// like a pin pushed into that cushion in the direction of the shadow
/// gradient at that location.
///
/// Each entry contains the direction of the pin at that location and the
/// depth to which the pin is inserted, expressed as a fraction of the full
/// umbra size indicated by the shadow parameters. A depth of 1.0 means
/// the pin was inserted all the way to the depth of the shadow gradient
/// and didn't collide with any other pins. A fraction less than 1.0 can
/// occur if either the shape was too small and the pins intersected with
/// other pins across the shape from them, or if the curvature in a given
/// area was so tight that adjacent pins started bumping into their neighbors
/// even if the overall size of the shape was larger than the shadow.
///
/// Different pins will be shortened by different amounts in the same shape
/// depending on their local geometry (tight curves or narrow cross section).
struct UmbraPin {
  /// An initial value for the pin fraction that indicates that we have
  /// not yet visited this pin during the clipping process.
  static constexpr Scalar kFractionUninitialized = -1.0f;

  /// The point on the original path that generated this entry into the
  /// umbra geometry.
  ///
  /// AKA the point on the path at which this pin was stabbed.
  Point path_vertex;

  /// The relative vector from this path segment to the next.
  Vector2 path_delta;

  /// The vector from the path_vertex to the head of the pin (the part
  /// outside the shape).
  Vector2 penumbra_delta;

  /// The location of the end of this pin, taking into account the reduction
  /// of the umbra_size due to minimum distance to centroid, but ignoring
  /// clipping against other pins.
  Point pin_tip;

  /// The location that this pin confers to the umbra polygon. Initially,
  /// this is the same as the pin_tip, but can be reduced by intersecting
  /// and clipping against other pins and even eliminated if the other
  /// nearby pins make it redundant for defining the umbra polygon.
  ///
  /// Redundant or "removed" pins are indicated by no longer being a part
  /// of the linked list formed by the |p_next| and |p_prev| pointers.
  ///
  /// Eventually, if this pin's umbra_vertex was eliminated, this location
  /// will be overwritten by the surviving umbra vertex that best servies
  /// this pin's path_vertex in a follow-on step.
  Point umbra_vertex;

  /// The index in the vertices vector where the umbra_vertex is eventually
  /// inserted. Used to enter triangles into the indices vector.
  uint16_t umbra_index = 0u;

  /// The interior penetration of the umbra starts out at the full blur
  /// radius as modified by the global distance of the path segments to
  /// the centroid, but can be shortened when pins are too crowded and start
  /// intersecting each other due to tight curvature.
  ///
  /// It's initial value is actually the uninitialized constant so that the
  /// algorithm can treat it specially the first time it is encountered.
  Scalar umbra_fraction = kFractionUninitialized;

  /// Pointers used to create a circular linked list while pruning the umbra
  /// polygon. The final list of vertices that remain in the umbra polygon
  /// are the vertices that remain on this linked list from a "head" pin.
  UmbraPin* p_next = nullptr;
  UmbraPin* p_prev = nullptr;

  /// Returns true after the umbra_fraction is first initialized to a real
  /// value representing its potential intersections with other pins. At
  /// that point it will be a number from 0 to 1.
  bool IsFractionInitialized() const {
    return umbra_fraction > kFractionUninitialized;
  }
};

/// Simple cross products of nearby vertices don't catch all cases of
/// non-convexity so we count the number of times that the sign of the
/// dx/dy of the edges change. It must be <= 3 times for the path to
/// be convex. Think of drawing a circle from the top. First you head
/// to the right, then reverse to the left as you round the bottom of
/// the circle, then back near the top you head to the right again,
/// totalling 3 changes in direction.
struct DirectionDetector {
  Scalar last_direction_ = 0.0f;
  size_t change_count = 0u;

  /// Check the coordinate delta for a new polygon edge to see if it
  /// represents another change in direction for the path on this axis.
  void AccumulateDirection(Scalar new_direction) {
    if (last_direction_ == 0.0f || last_direction_ * new_direction < 0.0f) {
      last_direction_ = std::copysign(1.0f, new_direction);
      change_count++;
    }
  }

  /// Returns true if the path must be concave.
  bool IsConcave() const {
    // See comment above on the struct for why 3 changes is the most you
    // should see in a convex path.
    return change_count > 3u;
  }
};

/// Utility class to receive the vertices of a path and turn them into
/// a vector of UmbraPins along with a centroid Point.
///
/// The class will immediately flag and stop processing any path that
/// has more than one contour since algorithms of the nature implemented
/// here won't be able to process such paths.
///
/// The class will also flag and stop processing any path that has a
/// non-convex section because the current algorithm only works for convex
/// paths. Though it is possible to improve the algorithm to handle
/// concave single-contour paths in the future as the Skia utilities
/// provide a solution for those paths.
class UmbraPinAccumulator : public PathTessellator::VertexWriter {
 public:
  /// Parameters that determine the sub-pixel grid we will use to simplify
  /// the contours to avoid degenerate differences in the vertices.
  /// These 2 constants are a pair used in the implementation of the
  /// ToDeviceGrid method and must be reciprocals of each other.
  ///
  /// @see ToPixelGrid
  static constexpr Scalar kSubPixelCount = 16.0f;
  static constexpr Scalar kSubPixelScale = (1.0f / kSubPixelCount);

  /// The classification status of the path after all of the points are
  /// accumulated.
  enum class PathStatus {
    /// The path was empty either because it contained no points or
    /// because they enclosed no area.
    kEmpty,

    /// The path was complete, a single contour, and convex all around.
    kConvex,

    /// The path violated one of the conditions of convexity. Either it
    /// had points that turned different ways along its perimeter, or it
    /// turned more than 360 degrees, or it self-intersected.
    kNonConvex,

    /// The path had multiple contours.
    kMultipleContours,
  };

  UmbraPinAccumulator() = default;
  ~UmbraPinAccumulator() = default;

  /// Reserve enough pins for the indicated number of path vertices to
  /// avoid having to grow the vector during processing.
  void Reserve(size_t vertex_count) { pins_.reserve(vertex_count); }

  /// Return the status properties of the path.
  /// see |PathStatus|
  PathStatus GetStatus() { return GetResults().status; }

  /// Returns a reference to the accumulated vector of UmbraPin structs.
  /// Only valid if the status is kConvex.
  std::vector<UmbraPin>& GetPins() { return pins_; }

  /// Returns the centroid of the path.
  /// Only valid if the status is kConvex.
  Point GetCentroid() { return GetResults().centroid; }

  /// Returns the turning direction of the path.
  /// Only valid if the status is kConvex.
  Scalar GetDirection() { return GetResults().path_direction; }

 private:
  /// The data computed when completing (finalizing) the analysis of the
  /// path.
  struct PathResults {
    /// The type of path determined during the final analysis.
    PathStatus status;

    /// The centroid ("center of mass") of the path around which we will
    /// build the shadow mesh.
    Point centroid;

    /// The direction of the path as determined by cross products. This
    /// value is important to further processing to know when pins are
    /// intersecting each other as the calculations for that condition
    /// depend on the direction of the path.
    Scalar path_direction = 0.0f;
  };

  // |VertexWriter|
  void Write(Point point) override;

  // |VertexWriter|
  void EndContour() override;

  /// Rounds the device coordinate to the sub-pixel grid.
  static Point ToDeviceGrid(Point point);

  /// The list of pins being accumulated for further processing by the
  /// mesh generation code.
  std::vector<UmbraPin> pins_;

  /// Internal state variable used by the VertexWriter callbacks to know
  /// if the path contained multiple contours. It is set to true when the
  /// first contour is ended by a call to EndContour().
  bool first_contour_ended_ = false;

  /// Internal state variable used by the VertexWriter callbacks to know
  /// if the path contained multiple contours. It is set to true if additional
  /// path points are delivered after the first contour is ended.
  bool has_multiple_contours_ = false;

  /// The results of finalizing the analysis of the path, set only after
  /// the final analysis method is run.
  std::optional<PathResults> results_;

  /// Finalize the path analysis if necessary and return the structure with
  /// the results of the analysis.
  PathResults& GetResults() {
    if (results_.has_value()) {
      return results_.value();
    }
    return (results_ = FinalizePath()).value();
  }

  /// Run through the accumulated, de-duplicated, de-collinearized points
  /// and check for a convex, non-self-intersecting path.
  PathResults FinalizePath();
};

/// The |PolygonInfo| class does most of the work of generating a mesh from
/// a path, including transforming it into device space, computing new vertices
/// by applying the inset and outset for the indicated occluder_height, and
/// then stitching all of those vertices together into a mesh that can be
/// used to render the shadow complete with gaussian coefficients for the
/// location of the mesh points within the shadow.
class PolygonInfo {
 public:
  /// Return the radius of the rounded corners of the shadow for the
  /// indicated occluder_height.
  static constexpr Scalar GetTrigRadiusForHeight(Scalar occluder_height) {
    return GetPenumbraSizeForHeight(occluder_height);
  }

  /// Construct a PolygonInfo that will accept a path and compute a shadow
  /// mesh at the indicated occluder_height.
  explicit PolygonInfo(Scalar occluder_height);

  /// Computes a shadow mesh for the indicated path (source) under the
  /// given matrix with the associated trigs. If the algorithm is successful,
  /// it will return the resulting mesh (which may be empty if the path
  /// contained no area) or nullptr if it was unable to process the path.
  ///
  /// @param source   The PathSource object that delivers the path segments
  ///                 that define the path being shadowed.
  /// @param matrix   The transform matrix under which the shadow is being
  ///                 viewed.
  /// @param trigs    The Trigs array that contains precomputed sin and cos
  ///                 values for a flattened arc at the required radius for
  ///                 rounding out the edges of the shadow as we turn corners
  ///                 in the path.
  ///
  /// @see GetTrigRadiusForHeight
  const std::shared_ptr<ShadowVertices> CalculateConvexShadowMesh(
      const impeller::PathSource& source,
      const impeller::Matrix& matrix,
      const Tessellator::Trigs& trigs);

 private:
  /// Compute the size of the penumbra for a given occluder_height which
  /// can vary depending on the type of shadow. Here we are only processing
  /// ambient shadows.
  static constexpr Scalar GetPenumbraSizeForHeight(Scalar occluder_height) {
    return occluder_height;
  }

  /// Compute the size of the umbra for a given occluder_height which
  /// can vary depending on the type of shadow. Here we are only processing
  /// ambient shadows.
  static constexpr Scalar GetUmbraSizeForHeight(Scalar occluder_height) {
    return occluder_height;
  }

  /// The minimum distance (squared) between points on the mesh before we
  /// eliminate them as redundant.
  static constexpr Scalar kMinSubPixelDistanceSquared =
      UmbraPinAccumulator::kSubPixelScale * UmbraPinAccumulator::kSubPixelScale;

  /// The occluder_height for which we are processing this shadow.
  const Scalar occluder_height_;

  /// The maximum gaussian of the umbra part of the shadow, usually 1.0f
  /// but can be reduced if the umbra size was clipped.
  Scalar umbra_gaussian_ = 1.0f;

  /// The vertex mesh result that represents the shadow, to be rendered
  /// using a modified indexed variant of DrawVertices that also adjusts
  /// the alpha of the colors on a per-pixel basis by mapping their linear
  /// gaussian coefficients into the associated gaussian integral values.

  /// vertices_ stores all of the points in the mesh.
  std::vector<Point> vertices_;

  /// indices_ stores the indexes of the triangles in the mesh, in a
  /// raw triangle format (i.e. not a triangle fan or strip).
  std::vector<uint16_t> indices_;

  /// gaussians_ stores the gaussian values associated with each vertex
  /// in the mesh, the values being 1:1 with the equivalent vertex in
  /// the vertices_ vedtor.
  std::vector<Scalar> gaussians_;

  /// Run through the pins and determine the closest pin to the centroid
  /// and, in particular, adjust the umbra_gaussian value if the closest pin
  /// is less than the required umbra distance.
  void ComputePinDirectionsAndMinDistanceToCentroid(std::vector<UmbraPin>& pins,
                                                    const Point& centroid,
                                                    Scalar direction);

  /// The head and count for the list of UmbraPins that contribute to the
  /// umbra vertex ring.
  ///
  /// The forward and backward pointers for the linked list are stored
  /// in the UmbraPin struct as p_next, p_prev.
  struct UmbraPinLinkedList {
    UmbraPin* p_head_pin = nullptr;
    size_t pin_count = 0u;

    bool IsNull() { return p_head_pin == nullptr; }
  };

  /// Run through the pins and determine if they intersect each other
  /// internally, whether they are completely obscured by other pins,
  /// their new relative lengths if they defer to another pin at some
  /// depth, and which remaining pins are part of the umbra polygon,
  /// and then return the pointer to the first pin in the "umbra polygon".
  UmbraPinLinkedList ResolveUmbraIntersections(std::vector<UmbraPin>& pins,
                                               Scalar direction);

  /// Structure to store the result of computing the intersection between
  /// 2 pins, pin0 and pin1, containing the point of intersection and the
  /// relative fractions at which the 2 pins intersected (expressed as a
  /// ratio of 0 to 1 where 0 represents intersecting at the path outline
  /// and 1 represents intersecting at the tip of the pin where the umbra
  /// is darkest.
  struct PinIntersection {
    // The Point of the intersection between the pins.
    Point intersection;
    // The fraction along pin0 of the intersection.
    Scalar fraction0;
    // The fraction along pin1 of the intersection
    Scalar fraction1;
  };

  /// Return the intersection between the 2 pins pin0 and pin1 if there
  /// is an intersection, otherwise a nullopt to indicate that there is
  /// no intersection.
  static std::optional<PinIntersection> ComputeIntersection(UmbraPin& pin0,
                                                            UmbraPin& pin1);

  /// Constants used to resolve pin intersections, adopted from the Skia
  /// version of the algorithm.
  static constexpr Scalar kCrossTolerance = 1.0f / 2048.0f;
  static constexpr Scalar kIntersectionTolerance = 1.0e-6f;

  /// Compute the squared length of a vector or a special out of bounds
  /// value if the vector becomes infinite.
  static constexpr Scalar FiniteVectorLengthSquared(Vector2 v) {
    return !v.IsFinite() ? -1.0f : v.Dot(v);
  }

  /// Determine if the numerator and denominator are outside of the
  /// interval that makes sense for an umbra intersection.
  ///
  /// Note calculation borrowed from Skia's SkPathUtils.
  static constexpr inline bool OutsideInterval(Scalar numer,
                                               Scalar denom,
                                               bool denom_positive) {
    return (denom_positive && (numer < 0 || numer > denom)) ||
           (!denom_positive && (numer > 0 || numer < denom));
  }

  /// Remove the pin at p_pin from the linked list of pins when the caller
  /// determines that it should not contribute to the final umbra polygon.
  /// The pointer to the head pin at *p_head will also be adjusted if we've
  /// eliminated the head pin itself and it will be additionally set to
  /// nullptr if that was the last pin in the list.
  ///
  /// @param p_pin    The pin to be eliminated from the list.
  /// @param p_head   The pointer to the head of the list which might also
  ///                 need adjustment depending on which pin is removed.
  static void RemovePin(UmbraPin* p_pin, UmbraPin** p_head);

  /// A helper method for resolving pin conflicts, adopted directly from the
  /// associated Skia algorithm.
  ///
  /// Note calculation borrowed from Skia's SkPathUtils.
  static int ComputeSide(const Point& p0, const Vector2& v, const Point& p);

  /// Run through the path calculating the outset vertices for the penumbra
  /// and connecting them to the inset vertices of the umbra and then to
  /// the centroid in a system of triangles with the appropriate alpha values
  /// representing the intensity of the (non-gamma-adjusted) shadow at those
  /// points. The resulting mesh should consist of 2 rings of triangles, an
  /// inner ring connecting the centroid to the umbra polygon, and another
  /// outer ring connecting vertices in the umbra polygon to vertices on the
  /// outer edge of the penumbra.
  ///
  /// @param pins       The list of pins, one for each edge of the polygon.
  /// @param centroid   The centroid ("center of mass") of the polygon.
  /// @param list       The linked list of the subset of pins that have
  ///                   umbra vertices which appear in the umbra polygon.
  /// @param trigs      The vector of sin and cos for subdivided arcs that
  ///                   can round the penumbra corner at each polygon corner.
  /// @param direction  The overall direction of the path as determined by
  ///                   the consistent cross products of each edge turn.
  void ComputeMesh(std::vector<UmbraPin>& pins,
                   const Point& centroid,
                   UmbraPinLinkedList& list,
                   const impeller::Tessellator::Trigs& trigs,
                   Scalar direction);

  /// After the umbra_vertices of the pins are accumulated and linked into a
  /// ring using their p_prev/p_next pointers, compute the best surviving umbra
  /// vertex for each pin and set its location and index into the UmbraPin.
  ///
  /// @param pins       The list of pins, one for each edge of the polygon.
  /// @param list       The linked list of the subset of pins that have
  ///                   umbra vertices which appear in the umbra polygon.
  /// @param centroid   The centroid ("center of mass") of the polygon.
  void PopulateUmbraVertices(std::vector<UmbraPin>& pins,
                             UmbraPinLinkedList& list,
                             const Point centroid);

  /// Appends a fan of penumbra vertices centered on the path vertex of the
  /// |p_curr_pin| starting from the absolute point |fan_start| and ending
  /// at the absolute point |fan_end|, both of which should be equi-distant
  /// from the path vertex. The index of the vertex at |fan_start| should
  /// already be in the vector of vertices at an index given by |start_index|.
  ///
  /// @param p_curr_pin    The pin at the corner around which the penumbra is
  ///                      rotating.
  /// @param fan_start     The point on the penumbra where the fan starts.
  /// @param fan_start     The point on the penumbra where the fan ends.
  /// @param start_index   The index in the vector of vertices where the
  ///                      fan_start vertex has already been inserted.
  /// @param trigs      The vector of sin and cos for subdivided arcs that
  ///                   can round the penumbra corner at each polygon corner.
  /// @param direction  The overall direction of the path as determined by
  ///                   the consistent cross products of each edge turn.
  uint16_t AppendFan(const UmbraPin* p_curr_pin,
                     const Point& fan_start,
                     const Point& fan_end,
                     uint16_t start_index,
                     const impeller::Tessellator::Trigs& trigs,
                     Scalar direction);

  /// Append a vertex and its associated gaussian coefficient to the lists
  /// of vertices and guassians and return their (shared) index.
  uint16_t AppendVertex(const Point& vertex, Scalar gaussian);

  /// Append 3 indices to the indices vector to form a new triangle in the mesh.
  void AddTriangle(uint16_t v0, uint16_t v1, uint16_t v2);
};

PolygonInfo::PolygonInfo(Scalar occluder_height)
    : occluder_height_(occluder_height) {}

const std::shared_ptr<ShadowVertices> PolygonInfo::CalculateConvexShadowMesh(
    const impeller::PathSource& source,
    const Matrix& matrix,
    const Tessellator::Trigs& trigs) {
  if (!matrix.IsInvertible()) {
    return ShadowVertices::kEmpty;
  }

  Scalar scale = matrix.GetMaxBasisLengthXY();

  UmbraPinAccumulator pin_accumulator;

  auto [point_count, contour_count] =
      impeller::PathTessellator::CountFillStorage(source, scale);
  pin_accumulator.Reserve(point_count);

  PathTessellator::PathToTransformedFilledVertices(source, pin_accumulator,
                                                   matrix);

  switch (pin_accumulator.GetStatus()) {
    case UmbraPinAccumulator::PathStatus::kEmpty:
      return ShadowVertices::kEmpty;
    case UmbraPinAccumulator::PathStatus::kNonConvex:
    case UmbraPinAccumulator::PathStatus::kMultipleContours:
      return nullptr;
    case UmbraPinAccumulator::PathStatus::kConvex:
      break;
  }

  std::vector<UmbraPin>& pins = pin_accumulator.GetPins();
  const Point& centroid = pin_accumulator.GetCentroid();
  Scalar direction = pin_accumulator.GetDirection();

  ComputePinDirectionsAndMinDistanceToCentroid(pins, centroid, direction);

  UmbraPinLinkedList list = ResolveUmbraIntersections(pins, direction);
  if (list.IsNull()) {
    // Ideally the Resolve algorithm will always be able to create an
    // inner loop of umbra vertices, but it is not perfect.
    //
    // The Skia algorithm from which this was taken tries to fake an
    // umbra polygon that is 95% from the path polygon to the centroid,
    // but that result does not resemble a proper shadow. If we run into
    // this case a lot we should either beef up the ResolveIntersections
    // algorithm or find a better approximation than "95% to the centroid".
    return nullptr;
  }

  ComputeMesh(pins, centroid, list, trigs, direction);

  Matrix inverted_matrix = matrix.Invert();
  for (Point& vertex : vertices_) {
    vertex = inverted_matrix * vertex;
  }
  return ShadowVertices::Make(std::move(vertices_), std::move(indices_),
                              std::move(gaussians_));
}

// Enter a new point for the polygon approximation of the shape. Points are
// normalized to a device subpixel grid based on |kSubPixelCount|, duplicates
// at that sub-pixel grid are ignored, collinear points are reduced to just
// the endpoints, and the centroid is updated from the remaining non-duplicate
// grid points.
void UmbraPinAccumulator::Write(Point point) {
  // This type of algorithm will never be able to handle multiple contours.
  if (first_contour_ended_) {
    has_multiple_contours_ = true;
    return;
  }
  FML_DCHECK(!has_multiple_contours_);

  point = ToDeviceGrid(point);

  if (!pins_.empty()) {
    // If this isn't the first point then we need to perform de-duplication
    // and possibly convexity checking and centroid updates.
    Point prev = pins_.back().path_vertex;

    // Adjusted points are rounded so == testing is OK here even for floating
    // point coordinates.
    if (point == prev) {
      // Ignore this point as a duplicate
      return;
    }

    if (pins_.size() >= 2u) {
      // A quick collinear check to avoid extra processing later.
      Point prev_prev = pins_.end()[-2].path_vertex;
      Vector2 v0 = prev - prev_prev;
      Vector2 v1 = point - prev_prev;
      Scalar cross = v0.Cross(v1);
      if (cross == 0) {
        // This point is on the same line as the line between the last
        // 2 points, so skip the intermediate point. Points that are
        // collinear only contribute to the edge of the shape the vector
        // from the first to the last of them.
        pins_.pop_back();
        if (point == prev_prev) {
          // Not only do we eliminate the previous point as collinear, but
          // we also eliminate this point as a duplicate.
          // This point would tend to be eliminated anyway because it would
          // automatically be collinear with whatever the next point would
          // be, but we just avoid inserting it anyway to reduce processing.
          return;
        }
      }
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
void UmbraPinAccumulator::EndContour() {
  // This type of algorithm will never be able to handle multiple contours.
  if (first_contour_ended_) {
    has_multiple_contours_ = true;
    return;
  }
  FML_DCHECK(!has_multiple_contours_);

  // PathTessellator always ensures the path is closed back to the origin
  // by an extra call to Write(Point).
  FML_DCHECK(pins_.front().path_vertex == pins_.back().path_vertex);
  pins_.pop_back();
  first_contour_ended_ = true;
}

// Adjust the device point to its nearest sub-pixel grid location.
Point UmbraPinAccumulator::ToDeviceGrid(Point point) {
  return (point * kSubPixelCount).Round() * kSubPixelScale;
}

// This method assumes that the pins have been accumulated by the PathVertex
// methods which ensure that no adjacent points are identical or collinear.
// It returns a PathResults that contains all of the relevant information
// depending on the geometric state of the path itself (ignoring whether
// the rest of the shadow processing will succeed).
//
// It performs 4 functions:
// - Normalizes empty paths (either too few vertices, or no turning directin)
//   to an empty pins vector.
// - Accumulates and sets the centroid of the path
// - Accumulates and sets the overall direction of the path as determined by
//   the sign of the cross products which must all agree.
// - Checks for convexity, including:
//   - The direction vector determined above.
//   - The turning direction of every triplet of points.
//   - The signs of the area accumulated using cross products.
//   - The number of times that the path edges change sign in X or Y.
UmbraPinAccumulator::PathResults UmbraPinAccumulator::FinalizePath() {
  FML_DCHECK(!results_.has_value());

  if (has_multiple_contours_) {
    return {.status = PathStatus::kMultipleContours};
  }

  if (pins_.size() < 3u) {
    return {.status = PathStatus::kEmpty};
  }

  DirectionDetector x_direction_detector;
  DirectionDetector y_direction_detector;

  Point relative_centroid;
  Scalar path_direction = 0.0f;
  Scalar path_area = 0.0f;

  Point prev = pins_.back().path_vertex;
  Point prev_prev = pins_.end()[-2].path_vertex;
  Point first = pins_.front().path_vertex;
  for (UmbraPin& pin : pins_) {
    Point new_point = pin.path_vertex;

    // Check for going around more than once in the same direction.
    {
      Vector2 delta = new_point - prev;
      x_direction_detector.AccumulateDirection(delta.x);
      y_direction_detector.AccumulateDirection(delta.y);
      if (x_direction_detector.IsConcave() ||
          y_direction_detector.IsConcave()) {
        return {.status = PathStatus::kNonConvex};
      }
    }

    // Check if the path is locally convex over the most recent 3 vertices.
    if (path_direction != 0.0f) {
      Vector2 v0 = prev - prev_prev;
      Vector2 v1 = new_point - prev_prev;
      Scalar cross = v0.Cross(v1);
      // We should have eliminated adjacent collinear points in the first pass.
      FML_DCHECK(cross != 0.0f);
      if (cross * path_direction < 0.0f) {
        return {.status = PathStatus::kNonConvex};
      }
    }

    // Check if the path is globally convex with respect to the first vertex.
    {
      Vector2 v0 = prev - first;
      Vector2 v1 = new_point - first;
      Scalar quad_area = v0.Cross(v1);
      if (quad_area != 0) {
        // convexity check for whole path which can detect if we turn more than
        // 360 degrees and start going the other way wrt the start point, but
        // does not detect if any pair of points are concave (checked above).
        if (path_direction == 0) {
          path_direction = std::copysign(1.0f, quad_area);
        } else if (quad_area * path_direction < 0) {
          return {.status = PathStatus::kNonConvex};
        }

        relative_centroid += (v0 + v1) * quad_area;
        path_area += quad_area;
      }
    }

    prev_prev = prev;
    prev = new_point;
  }

  if (path_direction == 0.0f) {
    // We never changed direction, indicate emptiness.
    return {.status = PathStatus::kEmpty};
  }

  // We are computing the centroid using a weighted average of all of  the
  // centroids of the triangles in a tessellation of the polygon, in this
  // case a triangle fan tessellation relative to the first point in the
  // polygon.  We could use any point, but since we had to compute the cross
  // product above relative to the initial point in order to detect if the
  // path turned more than once, we already have values available relative
  // to that first point here.
  //
  // The centroid of each triangle is the 3-way average of the corners of
  // that triangle. Since the triangles are all relative to the first point,
  // one of those corners is (0, 0) in this relative triangle and so we can
  // simply add up the x,y of the two relative points and divide by 3.0.
  // Since all values in the sum are divided by 3.0, we can save that
  // constant division until the end when we finalize the average computation.
  //
  // We also weight these centroids by the area of the triangle so that we
  // adjust for the parts of the polygon that are represented more densely
  // and the parts that span a larger part of its circumference. A simple
  // average would bias the centroid towards parts of the polygon where the
  // points are denser. If we are rendering a polygonal representation of
  // a round rect with only one round corner, all of the many approximating
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
  // path_area is (2 * triangle area).
  // relative_centroid is accumulating sum(3 * triangle centroid * quad area).
  // path_area_ is accumulating sum(quad area).
  //
  // The final combined average weight factor will be (3 * sum(quad area)).
  relative_centroid /= 3.0f * path_area;

  // The centroid accumulation was relative to the first point in the
  // polygon so we make it absolute here.
  return {
      .status = PathStatus::kConvex,
      .centroid = pins_[0].path_vertex + relative_centroid,
      .path_direction = path_direction,
  };
}

void PolygonInfo::ComputePinDirectionsAndMinDistanceToCentroid(
    std::vector<UmbraPin>& pins,
    const Point& centroid,
    Scalar direction) {
  Scalar desired_umbra_size = GetUmbraSizeForHeight(occluder_height_);
  Scalar min_umbra_squared = desired_umbra_size * desired_umbra_size;
  FML_DCHECK(direction == 1.0f || direction == -1.0f);

  // For simplicity of iteration, we start with the last vertex as the
  // "previous" pin and then iterate once over the vector of pins,
  // performing these calculations on the path segment from the previous
  // pin to the current pin. In the end, all pins and therefore all path
  // segments are processed once even if we start with the last pin.

  // First pass, compute the smallest distance to the centroid.
  UmbraPin* p_prev_pin = &pins.back();
  for (UmbraPin& pin : pins) {
    UmbraPin* p_curr_pin = &pin;

    // Accumulate (min) the distance from the centroid to "this" segment.
    Scalar distance_squared = centroid.GetDistanceToSegmentSquared(
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
  p_prev_pin = &pins.back();
  for (UmbraPin& pin : pins) {
    UmbraPin* p_curr_pin = &pin;
    p_curr_pin->p_prev = p_prev_pin;
    p_prev_pin->p_next = p_curr_pin;

    // We compute the vector along the path segment from the previous
    // path vertex to this one as well as the unit direction vector
    // that points from that pin towards the center of the shape,
    // perpendicular to that segment.
    p_prev_pin->path_delta = p_curr_pin->path_vertex - p_prev_pin->path_vertex;
    Vector2 pin_direction = p_prev_pin
                                ->path_delta  //
                                .Normalize()
                                .PerpendicularRight() *
                            direction;

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
    UmbraPin& pin0,
    UmbraPin& pin1) {
  Vector2 v0 = pin0.path_delta;
  Vector2 v1 = pin1.path_delta;
  Vector2 tip_delta = pin1.pin_tip - pin0.pin_tip;
  Vector2 w = tip_delta;
  Scalar denom = pin0.path_delta.Cross(pin1.path_delta);
  bool denom_positive = (denom > 0);
  Scalar numerator0, numerator1;

  if (ScalarNearlyZero(denom, kCrossTolerance)) {
    // This code also exists in the Skia version of this method, but it is
    // not clear that we can ever enter here. In particular, since points
    // were normalized to a grid (1/16th of a pixel), de-duplicated, and
    // collinear points eliminated, denom can never be 0. And since the
    // denom value was computed from a cross product of non-normalized
    // delta vectors, its magnitude must exceed 1/256 which is far greater
    // than the tolerance value.
    //
    // Note that in the Skia code, this method lived in a general polygon
    // module that was unaware that it was being fed de-duplicated vertices
    // from the Shadow module, so this code might be possible to trigger
    // for "unfiltered" polygons, but not the normalized polygons that our
    // (and Skia's) shadow code uses.
    //
    // Though entering here seems unlikely, we include the code until we can
    // perform more due diligence in vetting that this is truly dead code.

    // segments are parallel, but not collinear
    if (!ScalarNearlyZero(tip_delta.Cross(pin0.path_delta), kCrossTolerance) ||
        !ScalarNearlyZero(tip_delta.Cross(pin1.path_delta), kCrossTolerance)) {
      return std::nullopt;
    }

    // Check for zero-length segments
    Scalar v0_length_squared = FiniteVectorLengthSquared(v0);
    if (v0_length_squared <= 0.0f) {
      // Both are zero-length
      Scalar v1_length_squared = FiniteVectorLengthSquared(v1);
      if (v1_length_squared <= 0.0f) {
        // Check if they're the same point
        if (w.IsFinite() && !w.IsZero()) {
          return {{
              .intersection = pin0.pin_tip,
              .fraction0 = 0.0f,
              .fraction1 = 0.0f,
          }};
        } else {
          // Intersection is indeterminate
          return std::nullopt;
        }
      }
      // Otherwise project segment0's origin onto segment1
      numerator1 = v1.Dot(-w);
      denom = v1_length_squared;
      if (OutsideInterval(numerator1, denom, true)) {
        return std::nullopt;
      }
      numerator0 = 0;
    } else {
      // Project segment1's endpoints onto segment0
      numerator0 = v0.Dot(w);
      denom = v0_length_squared;
      numerator1 = 0;
      if (OutsideInterval(numerator0, denom, true)) {
        // The first endpoint doesn't lie on segment0
        // If segment1 is degenerate, then there's no collision
        Scalar v1_length_squared = FiniteVectorLengthSquared(v1);
        if (v1_length_squared <= 0.0f) {
          return std::nullopt;
        }

        // Otherwise try the other one
        Scalar old_numerator0 = numerator0;
        numerator0 = v0.Dot(w + v1);
        numerator1 = denom;
        if (OutsideInterval(numerator0, denom, true)) {
          // it's possible that segment1's interval surrounds segment0
          // this is false if params have the same signs, and in that case
          // no collision
          if (numerator0 * old_numerator0 > 0) {
            return std::nullopt;
          }
          // otherwise project segment0's endpoint onto segment1 instead
          numerator0 = 0;
          numerator1 = v1.Dot(-w);
          denom = v1_length_squared;
        }
      }
    }
  } else {
    numerator0 = w.Cross(v1);
    if (OutsideInterval(numerator0, denom, denom_positive)) {
      return std::nullopt;
    }
    numerator1 = w.Cross(v0);
    if (OutsideInterval(numerator1, denom, denom_positive)) {
      return std::nullopt;
    }
  }

  Scalar fraction0 = numerator0 / denom;
  Scalar fraction1 = numerator1 / denom;

  return {{
      .intersection = pin0.pin_tip + v0 * fraction0,
      .fraction0 = fraction0,
      .fraction1 = fraction1,
  }};
}

void PolygonInfo::RemovePin(UmbraPin* p_pin, UmbraPin** p_head) {
  UmbraPin* p_next = p_pin->p_next;
  UmbraPin* p_prev = p_pin->p_prev;
  p_prev->p_next = p_next;
  p_next->p_prev = p_prev;
  if (*p_head == p_pin) {
    *p_head = (p_next == p_pin) ? nullptr : p_next;
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
PolygonInfo::UmbraPinLinkedList PolygonInfo::ResolveUmbraIntersections(
    std::vector<UmbraPin>& pins,
    Scalar direction) {
  UmbraPin* p_head_pin = &pins.front();
  UmbraPin* p_curr_pin = p_head_pin;
  UmbraPin* p_prev_pin = p_curr_pin->p_prev;
  size_t umbra_vertex_count = pins.size();

  // we should check each edge against each other edge at most once
  size_t allowed_iterations = pins.size() * pins.size() + 1u;

  while (p_head_pin && p_prev_pin != p_curr_pin) {
    if (--allowed_iterations == 0) {
      return {};
    }

    std::optional<PinIntersection> intersection =
        ComputeIntersection(*p_prev_pin, *p_curr_pin);
    if (intersection.has_value()) {
      // If the new intersection is further back on previous inset from the
      // prior intersection...
      if (intersection->fraction0 < p_prev_pin->umbra_fraction) {
        // no point in considering this one again
        RemovePin(p_prev_pin, &p_head_pin);
        --umbra_vertex_count;
        // go back one segment
        p_prev_pin = p_prev_pin->p_prev;
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
        p_curr_pin = p_curr_pin->p_next;
      }
    } else {
      // if previous pin is to right side of the current pin...
      int side = direction * ComputeSide(p_curr_pin->pin_tip,     //
                                         p_curr_pin->path_delta,  //
                                         p_prev_pin->pin_tip);
      if (side < 0 &&
          side == direction * ComputeSide(p_curr_pin->pin_tip,     //
                                          p_curr_pin->path_delta,  //
                                          p_prev_pin->pin_tip +
                                              p_prev_pin->path_delta)) {
        // no point in considering this one again
        RemovePin(p_prev_pin, &p_head_pin);
        --umbra_vertex_count;
        // go back one segment
        p_prev_pin = p_prev_pin->p_prev;
      } else {
        // move to next segment
        RemovePin(p_curr_pin, &p_head_pin);
        --umbra_vertex_count;
        p_curr_pin = p_curr_pin->p_next;
      }
    }
  }

  if (!p_head_pin) {
    return {};
  }

  // Now remove any duplicates from the umbra polygon. The head pin is
  // automatically included as the first point of the umbra polygon.
  p_prev_pin = p_head_pin;
  p_curr_pin = p_head_pin->p_next;
  size_t umbra_vertices = 1u;
  while (p_curr_pin != p_head_pin) {
    if (p_prev_pin->umbra_vertex.GetDistanceSquared(p_curr_pin->umbra_vertex) <
        kMinSubPixelDistanceSquared) {
      RemovePin(p_curr_pin, &p_head_pin);
      p_curr_pin = p_curr_pin->p_next;
    } else {
      umbra_vertices++;
      p_prev_pin = p_curr_pin;
      p_curr_pin = p_curr_pin->p_next;
    }
    FML_DCHECK(p_curr_pin == p_prev_pin->p_next);
    FML_DCHECK(p_prev_pin == p_curr_pin->p_prev);
  }

  if (umbra_vertices < 3u) {
    return {};
  }

  return {p_head_pin, umbra_vertices};
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
void PolygonInfo::ComputeMesh(std::vector<UmbraPin>& pins,
                              const Point& centroid,
                              UmbraPinLinkedList& list,
                              const impeller::Tessellator::Trigs& trigs,
                              Scalar direction) {
  // Centroid and umbra polygon...
  size_t vertex_count = list.pin_count + 1u;
  size_t triangle_count = list.pin_count;

  // Penumbra corners - likely many more fan vertices than estimated...
  size_t penumbra_count = pins.size() * 2;  // 2 perp at each vertex.
  penumbra_count += trigs.size() * 4;       // total 360 degrees of fans.
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
  PopulateUmbraVertices(pins, list, centroid);

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
  const UmbraPin* p_prev_pin = &pins.back();

  // This point may be duplicated at the end of the path. We can try to
  // avoid adding it twice with some bookkeeping, but it is simpler to
  // just add it here for the pre-conditions of the start of the first
  // pin and allow the duplication to happen naturally as we process the
  // final pin later. One extra point should not be very noticeable in
  // the long list of mesh vertices.
  Point last_penumbra_point =
      p_prev_pin->path_vertex + p_prev_pin->penumbra_delta;
  uint16_t last_penumbra_index = AppendVertex(last_penumbra_point, 0.0f);

  for (const UmbraPin& pin : pins) {
    const UmbraPin* p_curr_pin = &pin;

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
    }

    // Then we bridge from the old penumbra point to the new parallel
    // penumbra point, pivoting around the new umbra index.
    Point new_penumbra_point =
        p_curr_pin->path_vertex + p_prev_pin->penumbra_delta;
    uint16_t new_penumbra_index = AppendVertex(new_penumbra_point, 0.0f);

    if (last_penumbra_index != new_penumbra_index) {
      AddTriangle(p_curr_pin->umbra_index, last_penumbra_index,
                  new_penumbra_index);
    }

    last_penumbra_point = new_penumbra_point;
    last_penumbra_index = new_penumbra_index;

    // Now draw a fan from the current pin's umbra vertex to all of the
    // penumbra points associated with this pin's path vertex, ending at
    // our new final penumbra point associated with this pin.
    new_penumbra_point = p_curr_pin->path_vertex + p_curr_pin->penumbra_delta;
    new_penumbra_index =
        AppendFan(p_curr_pin, last_penumbra_point, new_penumbra_point,
                  last_penumbra_index, trigs, direction);

    last_penumbra_point = new_penumbra_point;
    last_penumbra_index = new_penumbra_index;
    p_prev_pin = p_curr_pin;
  }
}

// Visit each pin and find the nearest umbra_vertex from the linked list of
// surviving umbra pins so we don't have to constantly find this as we stitch
// together the mesh.
void PolygonInfo::PopulateUmbraVertices(std::vector<UmbraPin>& pins,
                                        UmbraPinLinkedList& list,
                                        const Point centroid) {
  // We should be having the first crack at the vertex list, filling it with
  // the centroid, the umbra vertices, and the mesh connecting those into the
  // central core of the shadow.
  FML_DCHECK(list.p_head_pin != nullptr);
  FML_DCHECK(vertices_.empty());
  FML_DCHECK(gaussians_.empty());
  FML_DCHECK(indices_.empty());

  // Always start with the centroid.
  uint16_t last_umbra_index = AppendVertex(centroid, umbra_gaussian_);
  FML_DCHECK(last_umbra_index == 0u);

  // curr_umbra_pin is the most recently matched umbra vertex pin.
  // next_umbra_pin is the next umbra vertex pin to consider.
  // These pointers will always point to one of the pins that is on the
  // linked list of surviving umbra pins, possibly jumping over many
  // other umbra pins that were eliminated when we inset the polygon.
  UmbraPin* p_next_umbra_pin = list.p_head_pin;
  UmbraPin* p_curr_umbra_pin = p_next_umbra_pin->p_prev;
  for (UmbraPin& pin : pins) {
    if (p_next_umbra_pin == &pin ||
        (pin.path_vertex.GetDistanceSquared(p_curr_umbra_pin->umbra_vertex) >
         pin.path_vertex.GetDistanceSquared(p_next_umbra_pin->umbra_vertex))) {
      // We always bump to the next vertex when it was generated from this
      // pin, and also when it is closer to this path_vertex than the last
      // matched pin (curr).
      p_curr_umbra_pin = p_next_umbra_pin;
      p_next_umbra_pin = p_next_umbra_pin->p_next;

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
  if (last_umbra_index != pins.front().umbra_index) {
    AddTriangle(0u, last_umbra_index, pins.front().umbra_index);
  }
}

// Appends a fan based on center from the relative point in start_delta to
// the relative point in end_delta, potentially adding additional relative
// vectors if the turning rate is faster than the trig values in trigs_.
uint16_t PolygonInfo::AppendFan(const UmbraPin* p_curr_pin,
                                const Vector2& start,
                                const Vector2& end,
                                uint16_t start_index,
                                const impeller::Tessellator::Trigs& trigs,
                                Scalar direction) {
  Point center = p_curr_pin->path_vertex;
  uint16_t center_index = p_curr_pin->umbra_index;
  uint16_t prev_index = start_index;

  Vector2 start_delta = start - center;
  Vector2 end_delta = end - center;
  size_t trig_count = trigs.size();
  for (size_t i = 1u; i < trig_count; i++) {
    Trig trig = trigs[i];
    Point fan_delta = (direction >= 0 ? trig : -trig) * start_delta;
    if (fan_delta.Cross(end_delta) * direction <= 0) {
      break;
    }
    uint16_t cur_index = AppendVertex(center + fan_delta, 0.0f);
    if (prev_index != cur_index) {
      AddTriangle(center_index, prev_index, cur_index);
      prev_index = cur_index;
    }
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
  if (prev_index != cur_index) {
    AddTriangle(center_index, prev_index, cur_index);
  }
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
  if (index > 0u) {
    FML_DCHECK(!gaussians_.empty() && !vertices_.empty());
    if (gaussian == gaussians_.back() && vertex == vertices_.back()) {
      return index - 1;
    }
  }
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

const std::shared_ptr<ShadowVertices> ShadowVertices::kEmpty =
    std::make_shared<ShadowVertices>();

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

const std::shared_ptr<ShadowVertices> ShadowPathGeometry::TakeShadowVertices() {
  return std::move(shadow_vertices_);
}

GeometryResult ShadowVertices::GetPositionBuffer(const ContentContext& renderer,
                                                 const Entity& entity,
                                                 RenderPass& pass) const {
  using VS = ShadowVerticesVertexShader;

  size_t vertex_count = GetVertexCount();

  BufferView vertex_buffer = renderer.GetTransientsDataBuffer().Emplace(
      vertex_count * sizeof(VS::PerVertexData), alignof(VS::PerVertexData),
      [&](uint8_t* data) {
        VS::PerVertexData* vtx_contents =
            reinterpret_cast<VS::PerVertexData*>(data);
        for (size_t i = 0u; i < vertex_count; i++) {
          vtx_contents[i] = {
              .position = vertices_[i],
              .gaussian = gaussians_[i],
          };
        }
      });

  size_t index_count = GetIndexCount();
  const uint16_t* indices_data = GetIndices().data();
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
      .transform = entity.GetShaderTransform(pass),
  };
}

std::shared_ptr<ShadowVertices> ShadowPathGeometry::MakeAmbientShadowVertices(
    Tessellator& tessellator,
    const PathSource& source,
    Scalar occluder_height,
    const Matrix& matrix) {
  Scalar trig_radius = PolygonInfo::GetTrigRadiusForHeight(occluder_height);
  Tessellator::Trigs trigs = tessellator.GetTrigsForDeviceRadius(trig_radius);

  PolygonInfo polygon(occluder_height);

  return polygon.CalculateConvexShadowMesh(source, matrix, trigs);
}

}  // namespace impeller
