// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/stroke_path_geometry.h"

#include "flutter/display_list/geometry/dl_path.h"
#include "impeller/core/buffer_view.h"
#include "impeller/core/formats.h"
#include "impeller/core/host_buffer.h"
#include "impeller/entity/contents/pipelines.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/geometry/constants.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/geometry/path_component.h"
#include "impeller/geometry/separated_vector.h"
#include "impeller/geometry/wangs_formula.h"
#include "impeller/tessellator/path_tessellator.h"

namespace impeller {

namespace {

class PositionWriter {
 public:
  explicit PositionWriter(std::vector<Point>& points)
      : points_(points), oversized_() {
    FML_DCHECK(points_.size() == kPointArenaSize);
  }

  void AppendVertex(const Point& point) {
    if (offset_ >= kPointArenaSize) {
      oversized_.push_back(point);
    } else {
      points_[offset_++] = point;
    }
  }

  /// @brief Return the number of points used in the arena, followed by
  ///        the number of points allocated in the overized buffer.
  std::pair<size_t, size_t> GetUsedSize() const {
    return std::make_pair(offset_, oversized_.size());
  }

  bool HasOversizedBuffer() const { return !oversized_.empty(); }

  const std::vector<Point>& GetOversizedBuffer() const { return oversized_; }

 private:
  std::vector<Point>& points_;
  std::vector<Point> oversized_;
  size_t offset_ = 0u;
};

using CapProc = std::function<void(PositionWriter& vtx_builder,
                                   const Point& position,
                                   const Point& offset,
                                   Scalar scale,
                                   bool reverse)>;

using JoinProc = std::function<void(PositionWriter& vtx_builder,
                                    const Point& position,
                                    const Point& start_offset,
                                    const Point& end_offset,
                                    Scalar miter_limit,
                                    Scalar scale)>;

class StrokeGenerator {
 public:
  StrokeGenerator(const Path::Polyline& p_polyline,
                  const Scalar p_stroke_width,
                  const Scalar p_scaled_miter_limit,
                  const JoinProc& p_join_proc,
                  const CapProc& p_cap_proc,
                  const Scalar p_scale)
      : polyline(p_polyline),
        stroke_width(p_stroke_width),
        scaled_miter_limit(p_scaled_miter_limit),
        join_proc(p_join_proc),
        cap_proc(p_cap_proc),
        scale(p_scale) {}

  void Generate(PositionWriter& vtx_builder) {
    for (size_t contour_i = 0; contour_i < polyline.contours.size();
         contour_i++) {
      const Path::PolylineContour& contour = polyline.contours[contour_i];
      size_t contour_start_point_i, contour_end_point_i;
      std::tie(contour_start_point_i, contour_end_point_i) =
          polyline.GetContourPointBounds(contour_i);

      size_t contour_delta = contour_end_point_i - contour_start_point_i;
      if (contour_delta == 0) {
        continue;  // This contour has no renderable content.
      }

      if (contour_i > 0) {
        // This branch only executes when we've just finished drawing a contour
        // and are switching to a new one.
        // We're drawing a triangle strip, so we need to "pick up the pen" by
        // appending two vertices at the end of the previous contour and two
        // vertices at the start of the new contour (thus connecting the two
        // contours with two zero volume triangles, which will be discarded by
        // the rasterizer).
        vtx.position = polyline.GetPoint(contour_start_point_i - 1);
        // Append two vertices when "picking up" the pen so that the triangle
        // drawn when moving to the beginning of the new contour will have zero
        // volume.
        vtx_builder.AppendVertex(vtx.position);
        vtx_builder.AppendVertex(vtx.position);

        vtx.position = polyline.GetPoint(contour_start_point_i);
        // Append two vertices at the beginning of the new contour, which
        // appends  two triangles of zero area.
        vtx_builder.AppendVertex(vtx.position);
        vtx_builder.AppendVertex(vtx.position);
      }

      if (contour_delta == 1) {
        Point p = polyline.GetPoint(contour_start_point_i);
        cap_proc(vtx_builder, p, {-stroke_width * 0.5f, 0}, scale,
                 /*reverse=*/false);
        cap_proc(vtx_builder, p, {stroke_width * 0.5f, 0}, scale,
                 /*reverse=*/false);
        continue;
      }

      previous_offset = offset;
      offset = ComputeOffset(contour_start_point_i, contour_start_point_i,
                             contour_end_point_i, contour);
      const Point contour_first_offset = offset.GetVector();

      // Generate start cap.
      if (!polyline.contours[contour_i].is_closed) {
        Point cap_offset =
            Vector2(-contour.start_direction.y, contour.start_direction.x) *
            stroke_width * 0.5f;  // Counterclockwise normal
        cap_proc(vtx_builder, polyline.GetPoint(contour_start_point_i),
                 cap_offset, scale, /*reverse=*/true);
      }

      for (size_t contour_component_i = 0;
           contour_component_i < contour.components.size();
           contour_component_i++) {
        const Path::PolylineContour::Component& component =
            contour.components[contour_component_i];
        bool is_last_component =
            contour_component_i == contour.components.size() - 1;

        size_t component_start_index = component.component_start_index;
        size_t component_end_index =
            is_last_component ? contour_end_point_i - 1
                              : contour.components[contour_component_i + 1]
                                    .component_start_index;
        if (component.is_curve) {
          AddVerticesForCurveComponent(
              vtx_builder, component_start_index, component_end_index,
              contour_start_point_i, contour_end_point_i, contour);
        } else {
          AddVerticesForLinearComponent(
              vtx_builder, component_start_index, component_end_index,
              contour_start_point_i, contour_end_point_i, contour);
        }
      }

      // Generate end cap or join.
      if (!contour.is_closed) {
        auto cap_offset =
            Vector2(-contour.end_direction.y, contour.end_direction.x) *
            stroke_width * 0.5f;  // Clockwise normal
        cap_proc(vtx_builder, polyline.GetPoint(contour_end_point_i - 1),
                 cap_offset, scale, /*reverse=*/false);
      } else {
        join_proc(vtx_builder, polyline.GetPoint(contour_start_point_i),
                  offset.GetVector(), contour_first_offset, scaled_miter_limit,
                  scale);
      }
    }
  }

  /// Computes offset by calculating the direction from point_i - 1 to point_i
  /// if point_i is within `contour_start_point_i` and `contour_end_point_i`;
  /// Otherwise, it uses direction from contour.
  SeparatedVector2 ComputeOffset(const size_t point_i,
                                 const size_t contour_start_point_i,
                                 const size_t contour_end_point_i,
                                 const Path::PolylineContour& contour) const {
    Point direction;
    if (point_i >= contour_end_point_i) {
      direction = contour.end_direction;
    } else if (point_i <= contour_start_point_i) {
      direction = -contour.start_direction;
    } else {
      direction = (polyline.GetPoint(point_i) - polyline.GetPoint(point_i - 1))
                      .Normalize();
    }
    return SeparatedVector2(Vector2{-direction.y, direction.x},
                            stroke_width * 0.5f);
  }

  void AddVerticesForLinearComponent(PositionWriter& vtx_builder,
                                     const size_t component_start_index,
                                     const size_t component_end_index,
                                     const size_t contour_start_point_i,
                                     const size_t contour_end_point_i,
                                     const Path::PolylineContour& contour) {
    bool is_last_component = component_start_index ==
                             contour.components.back().component_start_index;

    for (size_t point_i = component_start_index; point_i < component_end_index;
         point_i++) {
      bool is_end_of_component = point_i == component_end_index - 1;

      Point offset_vector = offset.GetVector();

      vtx.position = polyline.GetPoint(point_i) + offset_vector;
      vtx_builder.AppendVertex(vtx.position);
      vtx.position = polyline.GetPoint(point_i) - offset_vector;
      vtx_builder.AppendVertex(vtx.position);

      // For line components, two additional points need to be appended
      // prior to appending a join connecting the next component.
      vtx.position = polyline.GetPoint(point_i + 1) + offset_vector;
      vtx_builder.AppendVertex(vtx.position);
      vtx.position = polyline.GetPoint(point_i + 1) - offset_vector;
      vtx_builder.AppendVertex(vtx.position);

      previous_offset = offset;
      offset = ComputeOffset(point_i + 2, contour_start_point_i,
                             contour_end_point_i, contour);
      if (!is_last_component && is_end_of_component) {
        // Generate join from the current line to the next line.
        join_proc(vtx_builder, polyline.GetPoint(point_i + 1),
                  previous_offset.GetVector(), offset.GetVector(),
                  scaled_miter_limit, scale);
      }
    }
  }

  void AddVerticesForCurveComponent(PositionWriter& vtx_builder,
                                    const size_t component_start_index,
                                    const size_t component_end_index,
                                    const size_t contour_start_point_i,
                                    const size_t contour_end_point_i,
                                    const Path::PolylineContour& contour) {
    bool is_last_component = component_start_index ==
                             contour.components.back().component_start_index;

    for (size_t point_i = component_start_index; point_i < component_end_index;
         point_i++) {
      bool is_end_of_component = point_i == component_end_index - 1;

      vtx.position = polyline.GetPoint(point_i) + offset.GetVector();
      vtx_builder.AppendVertex(vtx.position);
      vtx.position = polyline.GetPoint(point_i) - offset.GetVector();
      vtx_builder.AppendVertex(vtx.position);

      previous_offset = offset;
      offset = ComputeOffset(point_i + 2, contour_start_point_i,
                             contour_end_point_i, contour);

      // If the angle to the next segment is too sharp, round out the join.
      if (!is_end_of_component) {
        constexpr Scalar kAngleThreshold = 10 * kPi / 180;
        // `std::cosf` is not constexpr-able, unfortunately, so we have to bake
        // the alignment constant.
        constexpr Scalar kAlignmentThreshold =
            0.984807753012208;  // std::cosf(kThresholdAngle) -- 10 degrees

        // Use a cheap dot product to determine whether the angle is too sharp.
        if (previous_offset.GetAlignment(offset) < kAlignmentThreshold) {
          Scalar angle_total = previous_offset.AngleTo(offset).radians;
          Scalar angle = kAngleThreshold;

          // Bridge the large angle with additional geometry at
          // `kAngleThreshold` interval.
          while (angle < std::abs(angle_total)) {
            Scalar signed_angle = angle_total < 0 ? -angle : angle;
            Point offset =
                previous_offset.GetVector().Rotate(Radians(signed_angle));
            vtx.position = polyline.GetPoint(point_i) + offset;
            vtx_builder.AppendVertex(vtx.position);
            vtx.position = polyline.GetPoint(point_i) - offset;
            vtx_builder.AppendVertex(vtx.position);

            angle += kAngleThreshold;
          }
        }
      }

      // For curve components, the polyline is detailed enough such that
      // it can avoid worrying about joins altogether.
      if (is_end_of_component) {
        // Append two additional vertices to close off the component. If we're
        // on the _last_ component of the contour then we need to use the
        // contour's end direction.
        // `ComputeOffset` returns the contour's end direction when attempting
        // to grab offsets past `contour_end_point_i`, so just use `offset` when
        // we're on the last component.
        Point last_component_offset = is_last_component
                                          ? offset.GetVector()
                                          : previous_offset.GetVector();
        vtx.position = polyline.GetPoint(point_i + 1) + last_component_offset;
        vtx_builder.AppendVertex(vtx.position);
        vtx.position = polyline.GetPoint(point_i + 1) - last_component_offset;
        vtx_builder.AppendVertex(vtx.position);
        // Generate join from the current line to the next line.
        if (!is_last_component) {
          join_proc(vtx_builder, polyline.GetPoint(point_i + 1),
                    previous_offset.GetVector(), offset.GetVector(),
                    scaled_miter_limit, scale);
        }
      }
    }
  }

  const Path::Polyline& polyline;
  const Scalar stroke_width;
  const Scalar scaled_miter_limit;
  const JoinProc& join_proc;
  const CapProc& cap_proc;
  const Scalar scale;

  SeparatedVector2 previous_offset;
  SeparatedVector2 offset;
  SolidFillVertexShader::PerVertexData vtx;
};

class StrokePathSegmentReceiver : public PathTessellator::SegmentReceiver {
 public:
  StrokePathSegmentReceiver(PositionWriter& vtx_builder,
                            const Scalar stroke_width,
                            const Scalar miter_limit,
                            const Join join,
                            const Cap cap,
                            const Scalar scale,
                            const Tessellator::Trigs& trigs)
      : vtx_builder_(vtx_builder),
        half_stroke_width_(stroke_width * 0.5f),
        maximum_join_cosine_(
            ComputeMaximumJoinCosine(scale, stroke_width * 0.5f)),
        minimum_miter_cosine_(ComputeMinimumMiterCosine(miter_limit)),
        join_(join),
        cap_(cap),
        scale_(scale),
        trigs_(trigs) {}

  inline SeparatedVector2 ComputePerpendicular(const Point from,
                                               const Point to) const {
    return ComputePerpendicular((to - from).Normalize());
  }

  inline SeparatedVector2 ComputePerpendicular(const Vector2 direction) const {
    return SeparatedVector2(Vector2{-direction.y, direction.x},
                            half_stroke_width_);
  }

  inline void AppendVertices(const Point curve_point, Vector2 offset) {
    vtx_builder_.AppendVertex(curve_point + offset);
    vtx_builder_.AppendVertex(curve_point - offset);
  }

  inline void AppendVertices(const Point curve_point,
                             SeparatedVector2 perpendicular) {
    return AppendVertices(curve_point, perpendicular.GetVector());
  }

  void BeginContour(Point origin, bool will_be_closed) override {
    if (has_prior_contour_ && origin != last_point_) {
      // We only append these extra points if we have had a prior contour.
      vtx_builder_.AppendVertex(last_point_);
      vtx_builder_.AppendVertex(last_point_);
      vtx_builder_.AppendVertex(origin);
      vtx_builder_.AppendVertex(origin);
    }
    has_prior_contour_ = true;
    has_prior_segment_ = false;
    contour_needs_cap_ = !will_be_closed;
    last_point_ = origin;
    origin_point_ = origin;
  }

  void RecordLine(Point p1, Point p2) override {
    if (p2 != p1) {
      auto current_perpendicular = ComputePerpendicular(p1, p2);

      HandlePreviousJoin(current_perpendicular);
      AppendVertices(p2, current_perpendicular);

      last_perpendicular_ = current_perpendicular;
      last_point_ = p2;
    }
  }

  void RecordQuad(Point p1, Point cp, Point p2) override {
    RecordCurve<PathTessellator::Quad>({p1, cp, p2});
  }

  void RecordConic(Point p1, Point cp, Point p2, Scalar weight) override {
    RecordCurve<PathTessellator::Conic>({p1, cp, p2, weight});
  }

  void RecordCubic(Point p1, Point cp1, Point cp2, Point p2) override {
    RecordCurve<PathTessellator::Cubic>({p1, cp1, cp2, p2});
  }

  template <typename Curve>
  inline void RecordCurve(const Curve& curve) {
    auto start_direction = curve.GetStartDirection();
    auto end_direction = curve.GetEndDirection();

    // The Prune receiver should have eliminated any empty curves, so any
    // curve we see should have both start and end direction.
    FML_DCHECK(start_direction.has_value() && end_direction.has_value());

    // In order to keep the compiler/lint happy we check for values anyway.
    if (start_direction.has_value() && end_direction.has_value()) {
      // We now know the curve cannot be degenerate
      auto start_perpendicular = ComputePerpendicular(-start_direction.value());
      auto end_perpendicular = ComputePerpendicular(end_direction.value());

      // We join the previous segment to this one with a normal join
      HandlePreviousJoin(start_perpendicular);
      AppendVertices(curve.p1, start_perpendicular);

      Scalar count = std::ceilf(curve.SubdivisionCount(scale_));
      if (count > 1) {
        Point prev = curve.p1;
        auto prev_perpendicular = start_perpendicular;

        // Handle all intermediate curve points up to but not including the end
        for (int i = 1; i < count; i++) {
          Point cur = curve.Solve(i / count);
          auto cur_perpendicular = ComputePerpendicular(prev, cur);
          AppendVertices(cur, cur_perpendicular);
          prev = cur;
          prev_perpendicular = cur_perpendicular;
        }

        AppendVertices(curve.p2, end_perpendicular);

        last_perpendicular_ = end_perpendicular;
        last_point_ = curve.p2;
      }
    }
  }

  void EndContour(Point origin, bool with_close) override {
    FML_DCHECK(origin == origin_point_);
    if (!has_prior_segment_) {
      // Empty contour, fill in an axis aligned "cap box" at the origin
      FML_DCHECK(last_point_ == origin);
      // kButt wouldn't fill anything so it defers to kSquare by convention
      Cap cap = (cap_ == Cap::kButt) ? Cap::kSquare : cap_;
      Vector2 perpendicular = {-half_stroke_width_, 0};
      AddCap(cap, origin, perpendicular, true);
      if (cap == Cap::kRound) {
        // Only round caps need the perpendicular between them to connect.
        AppendVertices(origin, perpendicular);
      }
      AddCap(cap, origin, perpendicular, false);
    } else if (with_close) {
      // Closed contour, join back to origin
      FML_DCHECK(origin == origin_point_);
      FML_DCHECK(last_point_ == origin);
      AddJoin(join_, origin, last_perpendicular_, origin_perpendicular_);

      last_perpendicular_ = origin_perpendicular_;
      last_point_ = origin;
    } else {
      AddCap(cap_, last_point_, last_perpendicular_.GetVector(), false);
    }
    has_prior_segment_ = false;
  }

 private:
  PositionWriter& vtx_builder_;
  const Scalar half_stroke_width_;
  const Scalar maximum_join_cosine_;
  const Scalar minimum_miter_cosine_;
  const Join join_;
  const Cap cap_;
  const Scalar scale_;
  const Tessellator::Trigs& trigs_;

  SeparatedVector2 origin_perpendicular_;
  Point origin_point_;
  SeparatedVector2 last_perpendicular_;
  Point last_point_;
  bool has_prior_contour_ = false;
  bool has_prior_segment_ = false;
  bool contour_needs_cap_ = false;

  // Half of the allowed distance between the ends of the perpendiculars.
  static constexpr Scalar kJoinPixelThreshold = 0.25f;

  static Scalar ComputeMaximumJoinCosine(Scalar scale,
                                         Scalar half_stroke_width) {
    // Consider 2 perpendicular vectors, each pointing to the same side of
    // two adjacent path segment "boxes". If they are identical, then there
    // is no turn at that point on the path and we do not need to decorate
    // that gap with any join geometry. If they differ, there will be a gap
    // between them that must be decorated and the cosine of the angle of
    // that gap will be their Dot product (with +1 meaning that there is
    // no turn and therefore no decoration needed). We need to find the
    // cosine of the angle between them where we start to care about adding
    // the join geometry.
    //
    // Consider the right triangle where one side is the line bisecting the
    // two perpendiculars, starting from the common point on the path and
    // ending at the line that joins them. The hypotenuse of that triangle
    // is one of the perpendiculars, whose length is (scale * half_width).
    // The other non-hypotenuse side is kJoinPixelThreshold. This
    // triangle establishes the equation:
    //   ||bisector|| ^ 2 + kJoinThreshold ^ 2 == ||hypotenuse|| ^ 2
    // and the cosine of the angle between the perpendicular and the bisector
    // will be (||bisector|| / ||hypotenuse||).
    // The cosine between the perpendiculars which can be compared to the
    // will be the cosine of double that angle.
    Scalar hypotenuse = scale * half_stroke_width;
    if (hypotenuse <= kJoinPixelThreshold) {
      // The line geometry is too small to register the docorations. Return
      // a cosine value small enough to never qualify to add join decorations.
      return -1.1f;
    }
    Scalar bisector = std::sqrt(hypotenuse * hypotenuse -
                                kJoinPixelThreshold * kJoinPixelThreshold);
    Scalar half_cosine = bisector / hypotenuse;
    Scalar cosine = 2.0f * half_cosine * half_cosine - 1;
    return cosine;
  }

  static Scalar ComputeMinimumMiterCosine(Scalar miter_limit) {
    if (miter_limit <= 1.0f) {
      // Miter limits less than 1.0 are impossible to meet since the miter
      // join will always be at least as long as half the line width, so they
      // essentially eliminate all miters. We return a degenerate cosine
      // value so that the join routine never adds a miter.
      return 1.1f;
    }
    // We enter the join routine with a point on the path shared between
    // two segments that must be joined and 2 perpendicular values that
    // locate the sides of the old and new segment "boxes" relative to
    // that point. We can think of the miter as a diamond starting at the
    // point on the path, extending outwards by those 2 perpendicular
    // lines, and then continuing perpendicular to those perpendiculars
    // to a common intersection point out in the distance. If you then
    // consider the line that extends from the path point to the far
    // intersection point, that divides the diamond into 2 right triangles
    // (they are right triangles due to the right angle turn we take at
    // the ends of the path perpendiculars). If we want to know the angle
    // at which we reach the miter limit we can assume maximum extension
    // which places the dividing line (the hypotenuse) at a multiple of the
    // line width which is the length of one of those segment perpendiculars.
    // This means that the near bisected angle has a cosine of the ratio
    // of one of the near edges (length of half the line width) with the
    // miter length (miter_limit times half the line width). The ratio of
    // those is (1 / miter_limit).
    Scalar half_cosine = 1 / miter_limit;
    Scalar cosine = 2.0f * half_cosine * half_cosine - 1;
    return cosine;
  }

  inline void HandlePreviousJoin(SeparatedVector2 new_perpendicular) {
    FML_DCHECK(has_prior_contour_);
    if (has_prior_segment_) {
      AddJoin(join_, last_point_, last_perpendicular_, new_perpendicular);
    } else {
      has_prior_segment_ = true;
      auto perpendicular_vector = new_perpendicular.GetVector();
      if (contour_needs_cap_) {
        AddCap(cap_, last_point_, perpendicular_vector, true);
      }
      // Start the new segment's "box" at the shared "last_point_" with
      // the new perpendicular vector.
      AppendVertices(last_point_, perpendicular_vector);
      origin_perpendicular_ = new_perpendicular;
    }
  }

  // Adds a cap to an endpoint of a contour. The location points to the
  // centerline of the stroke. The perpendicular points clockwise to the
  // direction the path is traveling and is the length of half of the
  // stroke width.
  //
  // If contour_start is true, then the cap is being added prior to the first
  // segment at the beginning of a contour and assumes that no points have
  // been added for this contour yet and also that the caller will add the
  // two points that start the segment's "box" when this method returns.
  //
  // If contour_start is false, then the cap is being added after the last
  // segment at the end of a contour and assumes that the caller has already
  // added the two segments that define the end of the "box" for the last
  // path segment.
  void AddCap(Cap cap,
              Point path_point,
              Vector2 perpendicular,
              bool contour_start) {
    switch (cap) {
      case Cap::kButt:
        break;
      case Cap::kRound: {
        Point along(perpendicular.y, -perpendicular.x);
        if (contour_start) {
          // Add a single point at the far end of the round cap
          vtx_builder_.AppendVertex(path_point - along);

          // Iterate down to, but not including, the first entry (1, 0)
          for (size_t i = trigs_.size() - 2u; i > 0u; --i) {
            Point center = path_point - along * trigs_[i].sin;
            Vector2 offset = perpendicular * trigs_[i].cos;

            AppendVertices(center, offset);
          }
        } else {
          // Iterate up to, but not including, the last entry (0, 1)
          size_t end = trigs_.size() - 1u;
          for (size_t i = 1u; i < end; ++i) {
            Point center = path_point + along * trigs_[i].sin;
            Vector2 offset = perpendicular * trigs_[i].cos;

            AppendVertices(center, offset);
          }

          vtx_builder_.AppendVertex(path_point + along);
        }
        break;
      }
      case Cap::kSquare: {
        Point along(perpendicular.y, -perpendicular.x);
        Point square_center = contour_start             //
                                  ? path_point - along  //
                                  : path_point + along;
        AppendVertices(square_center, perpendicular);
        break;
      }
    }
  }

  void AddJoin(Join join,
               Point path_point,
               SeparatedVector2 old_perpendicular,
               SeparatedVector2 new_perpendicular) {
    Scalar cosine = old_perpendicular.GetAlignment(new_perpendicular);
    if (cosine >= maximum_join_cosine_) {
      // If the perpendiculars are closer than a pixel to each other, then
      // no need to add any further points, we don't even need to start
      // the new segment's "box", we can just let it connect back to the
      // prior segment's "box end" directly.
      return;
    }
    // All cases of this switch will fall through into the code that starts
    // the new segment's "box" down below which is good enough to bevel join
    // the segments should they individually decide that they don't need any
    // other decorations to bridge the gap.
    switch (join) {
      case Join::kBevel:
        // Just fall through to the bevel operation after the switch
        break;

      case Join::kMiter: {
        if (cosine >= minimum_miter_cosine_) {
          Point miter_vector =
              (old_perpendicular.GetVector() + new_perpendicular.GetVector()) /
              (cosine + 1);
          if (old_perpendicular.Cross(new_perpendicular) < 0) {
            vtx_builder_.AppendVertex(path_point + miter_vector);
          } else {
            vtx_builder_.AppendVertex(path_point - miter_vector);
          }
          // else default (fall through) to bevel operation after the switch
        }
        break;
      }  // end of kMiter join case

      case Join::kRound: {
        if (cosine >= trigs_[1].cos) {
          // If rotating by the first (non-quadrant) entry in trigs takes
          // us too far then we don't need to fill in anything. Just fall
          // through to the bevel operation after the switch.
          break;
        }
        // We want to set up the from and to vectors to facilitate a
        // clockwise angular fill from one to the other. We might generate
        // a couple fewer points by iterating counter-clockwise in some
        // cases so that we always go from the old to new perpendiculars,
        // but there is a lot of code to duplicate below for just a small
        // change in whether we negate the trigs and expect the a.Cross(b)
        // values to be > or < 0.
        Vector2 from_vector, to_vector;
        bool begin_end_crossed;
        Scalar turning = old_perpendicular.Cross(new_perpendicular);
        if (turning == 0) {
          // Uh oh, this is a 180 degree turn, but there is no clean way to
          // adjust the code below to make a semi-circle when the cross
          // product of the vectors is not signed. We resolve this by simply
          // adding a cap here based on the previous segment and then let
          // the bevel operation below position us for the next segment.
          AddCap(Cap::kRound, path_point, old_perpendicular.GetVector(), false);
          break;
        }
        if (turning > 0) {
          // Clockwise path turn, since our prependicular vectors point to
          // the right of the path we need to fill in the "back side" of the
          // turn, so we fill from -old to -new perpendicular which also
          // has a clockwise turn.
          from_vector = -old_perpendicular.GetVector();
          to_vector = -new_perpendicular.GetVector();
          // Despite the fact that we are using the negative vectors, they
          // are in the right "order" so we can connect directly from the
          // prior segment's "box" and directly to the following segment's.
          begin_end_crossed = false;
        } else {
          // Countercockwise path turn, we need to reverse the order of the
          // perpendiculars to achieve a clockwise angular fill, and since
          // both vectors are pointing to the right, the vectors themselves
          // are "turning outside" the widened path.
          from_vector = new_perpendicular.GetVector();
          to_vector = old_perpendicular.GetVector();
          // We are reversing the direction of traversal with respect to
          // the old segment's and new segment's boxes so we should append
          // extra segments to cross back and forth.
          begin_end_crossed = true;
        }
        FML_DCHECK(from_vector.Cross(to_vector) > 0);

        if (begin_end_crossed) {
          vtx_builder_.AppendVertex(path_point + from_vector);
        }

        // We only need to trace back to the common center point on every
        // other circular vertex we add. This generates a "corrugated"
        // path that visits the center once for every pair of edge vertices.
        bool visit_center = false;

        // The sum of the vectors points in the direction halfway between
        // them.  Since we only need its direction, this is enough without
        // having to adjust for the length to get the exact midpoint of
        // the curve we have to draw.
        Point middle_vector = (from_vector + to_vector);

        // Iterate through trigs until we reach a full quadrant's rotation
        // or until we pass the halfway point (middle_vector)
        size_t end = trigs_.size() - 1u;
        for (size_t i = 1u; i < end; ++i) {
          Point p = trigs_[i] * from_vector;
          if (p.Cross(middle_vector) <= 0) {
            // We've traversed far enough to pass the halfway vector,
            // stop and traverse backwards from the new_perpendicular.
            // Record the stopping point in end as we will use it to
            // backtrack in the next loop.
            end = i;
            break;
          }
          if (visit_center) {
            vtx_builder_.AppendVertex(path_point);
            visit_center = false;
          } else {
            visit_center = true;
          }
          vtx_builder_.AppendVertex(path_point + p);
        }

        // end points to the last trigs entry we decided not to use, so
        // a pre-decrement here moves us onto the trigs we do want to use
        // (stopping before we use 0 which is the 0 rotation vector)
        while (--end > 0u) {
          Point p = -trigs_[end] * to_vector;
          if (visit_center) {
            vtx_builder_.AppendVertex(path_point);
            visit_center = false;
          } else {
            visit_center = true;
          }
          vtx_builder_.AppendVertex(path_point + p);
        }

        if (begin_end_crossed) {
          vtx_builder_.AppendVertex(path_point + to_vector);
        }
        break;
      }  // end of kRound join case
    }  // end of switch
    // All joins need a final segment that is perpendicular to the shared
    // path point along the new perpendicular direction, and this also
    // provides a bevel join for all cases that decided no further
    // decoration was warranted.
    AppendVertices(path_point, new_perpendicular);
  }
};

void CreateButtCap(PositionWriter& vtx_builder,
                   const Point& position,
                   const Point& offset,
                   Scalar scale,
                   bool reverse) {
  Point orientation = offset * (reverse ? -1 : 1);
  vtx_builder.AppendVertex(position + orientation);
  vtx_builder.AppendVertex(position - orientation);
}

void CreateRoundCap(PositionWriter& vtx_builder,
                    const Point& position,
                    const Point& offset,
                    Scalar scale,
                    bool reverse) {
  Point orientation = offset * (reverse ? -1 : 1);
  Point forward(offset.y, -offset.x);
  Point forward_normal = forward.Normalize();

  CubicPathComponent arc;
  if (reverse) {
    arc = CubicPathComponent(
        forward, forward + orientation * PathBuilder::kArcApproximationMagic,
        orientation + forward * PathBuilder::kArcApproximationMagic,
        orientation);
  } else {
    arc = CubicPathComponent(
        orientation,
        orientation + forward * PathBuilder::kArcApproximationMagic,
        forward + orientation * PathBuilder::kArcApproximationMagic, forward);
  }

  Point vtx = position + orientation;
  vtx_builder.AppendVertex(vtx);
  vtx = position - orientation;
  vtx_builder.AppendVertex(vtx);

  Scalar line_count = std::ceilf(ComputeCubicSubdivisions(scale, arc));
  for (size_t i = 1; i < line_count; i++) {
    Point point = arc.Solve(i / line_count);
    vtx = position + point;
    vtx_builder.AppendVertex(vtx);
    vtx = position + (-point).Reflect(forward_normal);
    vtx_builder.AppendVertex(vtx);
  }

  Point point = arc.p2;
  vtx = position + point;
  vtx_builder.AppendVertex(position + point);
  vtx = position + (-point).Reflect(forward_normal);
  vtx_builder.AppendVertex(vtx);
}

void CreateSquareCap(PositionWriter& vtx_builder,
                     const Point& position,
                     const Point& offset,
                     Scalar scale,
                     bool reverse) {
  Point orientation = offset * (reverse ? -1 : 1);
  Point forward(offset.y, -offset.x);

  Point vtx = position + orientation;
  vtx_builder.AppendVertex(vtx);
  vtx = position - orientation;
  vtx_builder.AppendVertex(vtx);
  vtx = position + orientation + forward;
  vtx_builder.AppendVertex(vtx);
  vtx = position - orientation + forward;
  vtx_builder.AppendVertex(vtx);
}

Scalar CreateBevelAndGetDirection(PositionWriter& vtx_builder,
                                  const Point& position,
                                  const Point& start_offset,
                                  const Point& end_offset) {
  Point vtx = position;
  vtx_builder.AppendVertex(vtx);

  Scalar dir = start_offset.Cross(end_offset) > 0 ? -1 : 1;
  vtx = position + start_offset * dir;
  vtx_builder.AppendVertex(vtx);
  vtx = position + end_offset * dir;
  vtx_builder.AppendVertex(vtx);

  return dir;
}

void CreateMiterJoin(PositionWriter& vtx_builder,
                     const Point& position,
                     const Point& start_offset,
                     const Point& end_offset,
                     Scalar miter_limit,
                     Scalar scale) {
  Point start_normal = start_offset.Normalize();
  Point end_normal = end_offset.Normalize();

  // 1 for no joint (straight line), 0 for max joint (180 degrees).
  Scalar alignment = (start_normal.Dot(end_normal) + 1) / 2;
  if (ScalarNearlyEqual(alignment, 1)) {
    return;
  }

  Scalar direction = CreateBevelAndGetDirection(vtx_builder, position,
                                                start_offset, end_offset);

  Point miter_point = (((start_offset + end_offset) / 2) / alignment);
  if (miter_point.GetDistanceSquared({0, 0}) > miter_limit * miter_limit) {
    return;  // Convert to bevel when we exceed the miter limit.
  }

  // Outer miter point.
  vtx_builder.AppendVertex(position + miter_point * direction);
}

void CreateRoundJoin(PositionWriter& vtx_builder,
                     const Point& position,
                     const Point& start_offset,
                     const Point& end_offset,
                     Scalar miter_limit,
                     Scalar scale) {
  Point start_normal = start_offset.Normalize();
  Point end_normal = end_offset.Normalize();

  // 0 for no joint (straight line), 1 for max joint (180 degrees).
  Scalar alignment = 1 - (start_normal.Dot(end_normal) + 1) / 2;
  if (ScalarNearlyEqual(alignment, 0)) {
    return;
  }

  Scalar direction = CreateBevelAndGetDirection(vtx_builder, position,
                                                start_offset, end_offset);

  Point middle =
      (start_offset + end_offset).Normalize() * start_offset.GetLength();
  Point middle_normal = middle.Normalize();

  Point middle_handle = middle + Point(-middle.y, middle.x) *
                                     PathBuilder::kArcApproximationMagic *
                                     alignment * direction;
  Point start_handle = start_offset + Point(start_offset.y, -start_offset.x) *
                                          PathBuilder::kArcApproximationMagic *
                                          alignment * direction;

  CubicPathComponent arc(start_offset, start_handle, middle_handle, middle);
  Scalar line_count = std::ceilf(ComputeCubicSubdivisions(scale, arc));
  for (size_t i = 1; i < line_count; i++) {
    Point point = arc.Solve(i / line_count);
    vtx_builder.AppendVertex(position + point * direction);
    vtx_builder.AppendVertex(position +
                             (-point * direction).Reflect(middle_normal));
  }
  vtx_builder.AppendVertex(position + arc.p2 * direction);
  vtx_builder.AppendVertex(position +
                           (-arc.p2 * direction).Reflect(middle_normal));
}

void CreateBevelJoin(PositionWriter& vtx_builder,
                     const Point& position,
                     const Point& start_offset,
                     const Point& end_offset,
                     Scalar miter_limit,
                     Scalar scale) {
  CreateBevelAndGetDirection(vtx_builder, position, start_offset, end_offset);
}

// static

JoinProc GetJoinProc(Join stroke_join) {
  switch (stroke_join) {
    case Join::kBevel:
      return &CreateBevelJoin;
    case Join::kMiter:
      return &CreateMiterJoin;
    case Join::kRound:
      return &CreateRoundJoin;
  }
}

CapProc GetCapProc(Cap stroke_cap) {
  switch (stroke_cap) {
    case Cap::kButt:
      return &CreateButtCap;
    case Cap::kRound:
      return &CreateRoundCap;
    case Cap::kSquare:
      return &CreateSquareCap;
  }
}
}  // namespace

std::vector<Point> StrokePathGeometry::GenerateSolidStrokeVertices(
    const Path::Polyline& polyline,
    Scalar stroke_width,
    Scalar miter_limit,
    Join stroke_join,
    Cap stroke_cap,
    Scalar scale) {
  auto scaled_miter_limit = stroke_width * miter_limit * 0.5f;
  JoinProc join_proc = GetJoinProc(stroke_join);
  CapProc cap_proc = GetCapProc(stroke_cap);
  StrokeGenerator stroke_generator(polyline, stroke_width, scaled_miter_limit,
                                   join_proc, cap_proc, scale);
  std::vector<Point> points(4096);
  PositionWriter vtx_builder(points);
  stroke_generator.Generate(vtx_builder);
  auto [arena, extra] = vtx_builder.GetUsedSize();
  FML_DCHECK(extra == 0u);
  points.resize(arena);
  return points;
}

std::vector<Point> StrokePathGeometry::GenerateSolidStrokeVertices(
    const Path& path,
    Scalar stroke_width,
    Scalar miter_limit,
    Join stroke_join,
    Cap stroke_cap,
    Scalar scale) {
  auto scaled_miter_limit = stroke_width * miter_limit * 0.5f;
  JoinProc join_proc = GetJoinProc(stroke_join);
  CapProc cap_proc = GetCapProc(stroke_cap);

  auto poly_points = std::make_unique<std::vector<Point>>();
  poly_points->reserve(2048);
  auto polyline = path.CreatePolyline(
      scale, std::move(poly_points),
      [&poly_points](Path::Polyline::PointBufferPtr reclaimed) {
        poly_points = std::move(reclaimed);
      });
  StrokeGenerator stroke_generator(polyline, stroke_width, scaled_miter_limit,
                                   join_proc, cap_proc, scale);
  std::vector<Point> points(4096);
  PositionWriter vtx_builder(points);
  stroke_generator.Generate(vtx_builder);
  auto [arena, extra] = vtx_builder.GetUsedSize();
  FML_DCHECK(extra == 0u);
  points.resize(arena);
  return points;
}

std::vector<Point> StrokePathGeometry::GenerateSolidStrokeVerticesDirect(
    const PathSource& source,
    Scalar stroke_width,
    Scalar miter_limit,
    Join stroke_join,
    Cap stroke_cap,
    Scalar scale) {
  std::vector<Point> points(4096);
  PositionWriter vtx_builder(points);
  Tessellator::Trigs trigs(scale * stroke_width * 0.5f);
  StrokePathSegmentReceiver receiver(vtx_builder, stroke_width, miter_limit,
                                     stroke_join, stroke_cap, scale, trigs);
  PathTessellator::PathToStrokedSegments(source, receiver);
  auto [arena, extra] = vtx_builder.GetUsedSize();
  FML_DCHECK(extra == 0u);
  points.resize(arena);
  return points;
}

StrokePathGeometry::StrokePathGeometry(const Path& path,
                                       Scalar stroke_width,
                                       Scalar miter_limit,
                                       Cap stroke_cap,
                                       Join stroke_join)
    : path_(path),
      stroke_width_(stroke_width),
      miter_limit_(miter_limit),
      stroke_cap_(stroke_cap),
      stroke_join_(stroke_join) {}

StrokePathGeometry::~StrokePathGeometry() = default;

Scalar StrokePathGeometry::GetStrokeWidth() const {
  return stroke_width_;
}

Scalar StrokePathGeometry::GetMiterLimit() const {
  return miter_limit_;
}

Cap StrokePathGeometry::GetStrokeCap() const {
  return stroke_cap_;
}

Join StrokePathGeometry::GetStrokeJoin() const {
  return stroke_join_;
}

Scalar StrokePathGeometry::ComputeAlphaCoverage(const Matrix& transform) const {
  return Geometry::ComputeStrokeAlphaCoverage(transform, stroke_width_);
}

GeometryResult StrokePathGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  if (stroke_width_ < 0.0) {
    return {};
  }
  Scalar max_basis = entity.GetTransform().GetMaxBasisLengthXY();
  if (max_basis == 0) {
    return {};
  }

  Scalar min_size = kMinStrokeSize / max_basis;
  Scalar stroke_width = std::max(stroke_width_, min_size);

  auto& host_buffer = renderer.GetTransientsBuffer();
  auto scale = entity.GetTransform().GetMaxBasisLengthXY();

  auto& tessellator = renderer.GetTessellator();
  PositionWriter position_writer(tessellator.GetStrokePointCache());
  Tessellator::Trigs trigs =
      tessellator.GetTrigsForDeviceRadius(scale * stroke_width * 0.5f);
  StrokePathSegmentReceiver receiver(position_writer, stroke_width,
                                     miter_limit_, stroke_join_, stroke_cap_,
                                     scale, trigs);
  PathTessellator::PathToStrokedSegments(flutter::DlPath(path_), receiver);

  const auto [arena_length, oversized_length] = position_writer.GetUsedSize();
  if (!position_writer.HasOversizedBuffer()) {
    BufferView buffer_view = host_buffer.Emplace(
        renderer.GetTessellator().GetStrokePointCache().data(),
        arena_length * sizeof(Point), alignof(Point));

    return GeometryResult{.type = PrimitiveType::kTriangleStrip,
                          .vertex_buffer =
                              {
                                  .vertex_buffer = buffer_view,
                                  .vertex_count = arena_length,
                                  .index_type = IndexType::kNone,
                              },
                          .transform = entity.GetShaderTransform(pass),
                          .mode = GeometryResult::Mode::kPreventOverdraw};
  }
  const std::vector<Point>& oversized_data =
      position_writer.GetOversizedBuffer();
  BufferView buffer_view = host_buffer.Emplace(
      /*buffer=*/nullptr,                                 //
      (arena_length + oversized_length) * sizeof(Point),  //
      alignof(Point)                                      //
  );
  memcpy(buffer_view.GetBuffer()->OnGetContents() +
             buffer_view.GetRange().offset,                       //
         renderer.GetTessellator().GetStrokePointCache().data(),  //
         arena_length * sizeof(Point)                             //
  );
  memcpy(buffer_view.GetBuffer()->OnGetContents() +
             buffer_view.GetRange().offset + arena_length * sizeof(Point),  //
         oversized_data.data(),                                             //
         oversized_data.size() * sizeof(Point)                              //
  );
  buffer_view.GetBuffer()->Flush(buffer_view.GetRange());

  return GeometryResult{.type = PrimitiveType::kTriangleStrip,
                        .vertex_buffer =
                            {
                                .vertex_buffer = buffer_view,
                                .vertex_count = arena_length + oversized_length,
                                .index_type = IndexType::kNone,
                            },
                        .transform = entity.GetShaderTransform(pass),
                        .mode = GeometryResult::Mode::kPreventOverdraw};
}

GeometryResult::Mode StrokePathGeometry::GetResultMode() const {
  return GeometryResult::Mode::kPreventOverdraw;
}

std::optional<Rect> StrokePathGeometry::GetCoverage(
    const Matrix& transform) const {
  auto path_bounds = path_.GetBoundingBox();
  if (!path_bounds.has_value()) {
    return std::nullopt;
  }

  Scalar max_radius = 0.5;
  if (stroke_cap_ == Cap::kSquare) {
    max_radius = max_radius * kSqrt2;
  }
  if (stroke_join_ == Join::kMiter) {
    max_radius = std::max(max_radius, miter_limit_ * 0.5f);
  }
  Scalar max_basis = transform.GetMaxBasisLengthXY();
  if (max_basis == 0) {
    return {};
  }
  // Use the most conervative coverage setting.
  Scalar min_size = kMinStrokeSize / max_basis;
  max_radius *= std::max(stroke_width_, min_size);
  return path_bounds->Expand(max_radius).TransformBounds(transform);
}

}  // namespace impeller
