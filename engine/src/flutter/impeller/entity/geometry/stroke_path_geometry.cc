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

}  // namespace

/// StrokePathSegmentReceiver converts path segments (fed by PathTessellator)
/// into a vertex strip that covers the outline of the stroked version of the
/// path and feeds those vertices, expressed in the form of a vertex strip
/// into the supplied PositionWriter.
///
/// The general procedure follows the following basic methodology:
///
/// Every path segment is represented by a box with two starting vertices
/// perpendicular to its start point and two vertices perpendicular to its
/// end point, all perpendiculars of length (stroke_width * 0.5).
///
/// Joins will connect the ending "box" perpendiculars of the previous segment
/// to the starting "box" perpendiculars of the following segment. If the two
/// boxes are so aligned that their adjacent perpendiculars are less than a
/// threshold distance apart (kJoinPixelThreshold), the join will just be
/// elided so that the end of one box becomes the start of the next box.
/// If the join process does add decorations, it assumes that the ending
/// perpendicular vertices from the prior segment are the last vertices
/// added and ensures that it appends the two vertices for the starting
/// perpendiculars of the new segment's "box". Thus every join either
/// adds nothing and the end perpendiculars of the previous segment become
/// the start perpendiculars of the next segment, or it makes sure its
/// geometry fills in the gap and ends with the start perpendiculars for the
/// new segment.
///
/// Prior to the start of an unclosed contour we insert a cap and also the
/// starting perpendicular segments for the first segment. Prior to the
/// start of a closed contour, we just insert the starting perpendiculars
/// for the first segment. Either way, we've initialized the path with the
/// starting perpendiculars of the first segment.
///
/// After the last segment in an unclosed contour we insert a cap which
/// can assume that the last segment has already inserted its closing
/// perpendicular segments. After the last segment in a closed contour, we
/// insert a join back to the very first segment in that contour.
///
/// Connecting any two contours we insert an infinitely thin connecting
/// thread by inserting the last point of the previous contour twice and
/// then inserting the first point of the next contour twice. This ensures
/// that there are no non-empty triangles between the two contours.
///
/// Finally, inserting a line segment can assume that the starting
/// perpendiculars have already been inserted by the preceding cap, join,
/// or prior segment, so all it needs to do is to insert the ending
/// perpendiculars which set the process up for the subsequent cap, join,
/// or future segment.
///
/// Inserting curve segments acts like a series of line segments except
/// that the opening perpendicular is taken from the curve rather than the
/// direction between the starting point and the first sample point. This
/// ensures that any cap or join will be aligned with the curve and not
/// tilted by the first approximating segment. The same is true of the
/// ending perpendicular which is taken from the curve and not the last
/// approximated segment. Between each approximated segment of the curve,
/// we insert only Cap::kRound joins so as not to polygonize a curve when
/// it turns very sharply. We also skip these joins for any change of
/// direction which is smaller than the first sample point of a round join
/// for performance reasons.
///
/// To facilitate all of that work we maintain variables containing
/// SeparatedVector2 values that, by convention, point 90 degrees to the
/// right of the given path direction. This facilitates a quick add/subtract
/// from the point on the path to insert the necessary perpendicular
/// points of a segment's box. These values contain both a unit vector for
/// direction and a magnitude for length.
///
/// SeparatedVector2 values also allow us to quickly test limits on when to
/// include joins by using a simple dot product on the previous and next
/// perpendiculars at a given path point which should match the dot product
/// of the path's direction itself at the same point since both perpendiculars
/// have been rotated identically to the same side of the path.
/// The SeparatedVector2 will perform the dot product on the unit-length
/// vectors so that the result is exactly the cosine of the angle between the
/// segments - also the angle by which the path turned at a given path point.
///
/// @see PathTessellator::PathToStrokedSegments
class StrokePathSegmentReceiver : public PathAndArcSegmentReceiver {
 public:
  StrokePathSegmentReceiver(Tessellator& tessellator,
                            PositionWriter& vtx_builder,
                            const StrokeParameters& stroke,
                            const Scalar scale)
      : tessellator_(tessellator),
        vtx_builder_(vtx_builder),
        half_stroke_width_(stroke.width * 0.5f),
        maximum_join_cosine_(
            ComputeMaximumJoinCosine(scale, half_stroke_width_)),
        minimum_miter_cosine_(ComputeMinimumMiterCosine(stroke.miter_limit)),
        join_(stroke.join),
        cap_(stroke.cap),
        scale_(scale),
        trigs_(MakeTrigs(tessellator, scale, half_stroke_width_)) {
    // Trigs ensures that it always contains at least 2 entries.
    FML_DCHECK(trigs_.size() >= 2);
    FML_DCHECK(trigs_[0].cos == 1.0f);  // Angle == 0 degrees
    FML_DCHECK(trigs_[0].sin == 0.0f);
    FML_DCHECK(trigs_.end()[-1].cos == 0.0f);  // Angle == 90 degrees
    FML_DCHECK(trigs_.end()[-1].sin == 1.0f);
  }

 protected:
  // |SegmentReceiver|
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

  // |SegmentReceiver|
  void RecordLine(Point p1, Point p2) override {
    if (p2 != p1) {
      SeparatedVector2 current_perpendicular = PerpendicularFromPoints(p1, p2);

      HandlePreviousJoin(current_perpendicular);
      AppendVertices(p2, current_perpendicular);

      last_perpendicular_ = current_perpendicular;
      last_point_ = p2;
    }
  }

  // |SegmentReceiver|
  void RecordQuad(Point p1, Point cp, Point p2) override {
    RecordCurve<PathTessellator::Quad>({p1, cp, p2});
  }

  // |SegmentReceiver|
  void RecordConic(Point p1, Point cp, Point p2, Scalar weight) override {
    RecordCurve<PathTessellator::Conic>({p1, cp, p2, weight});
  }

  // |SegmentReceiver|
  void RecordCubic(Point p1, Point cp1, Point cp2, Point p2) override {
    RecordCurve<PathTessellator::Cubic>({p1, cp1, cp2, p2});
  }

  // Utility implementation of |SegmentReceiver| Record<Curve> methods
  template <typename Curve>
  inline void RecordCurve(const Curve& curve) {
    std::optional<Point> start_direction = curve.GetStartDirection();
    std::optional<Point> end_direction = curve.GetEndDirection();

    // The Prune receiver should have eliminated any empty curves, so any
    // curve we see should have both start and end direction.
    FML_DCHECK(start_direction.has_value() && end_direction.has_value());

    // In order to keep the compiler/lint happy we check for values anyway.
    if (start_direction.has_value() && end_direction.has_value()) {
      // We now know the curve cannot be degenerate.
      SeparatedVector2 start_perpendicular =
          PerpendicularFromUnitDirection(-start_direction.value());
      SeparatedVector2 end_perpendicular =
          PerpendicularFromUnitDirection(end_direction.value());

      // We join the previous segment to this one with a normal join
      // The join will append the perpendicular at the start of this
      // curve as well.
      HandlePreviousJoin(start_perpendicular);

      Scalar count =
          std::ceilf(curve.SubdivisionCount(scale_ * half_stroke_width_));

      Point prev = curve.p1;
      SeparatedVector2 prev_perpendicular = start_perpendicular;

      // Handle all intermediate curve points up to but not including the end.
      for (int i = 1; i < count; i++) {
        Point cur = curve.Solve(i / count);
        SeparatedVector2 cur_perpendicular = PerpendicularFromPoints(prev, cur);
        RecordCurveSegment(prev_perpendicular, cur, cur_perpendicular);
        prev = cur;
        prev_perpendicular = cur_perpendicular;
      }

      RecordCurveSegment(prev_perpendicular, curve.p2, end_perpendicular);

      last_perpendicular_ = end_perpendicular;
      last_point_ = curve.p2;
    }
  }

  void RecordCurveSegment(const SeparatedVector2& prev_perpendicular,
                          const Point cur,
                          const SeparatedVector2& cur_perpendicular) {
    if (prev_perpendicular.GetAlignment(cur_perpendicular) < trigs_[1].cos) {
      // We only connect 2 curved segments if their change in direction
      // is faster than a single sample of a round join.
      AppendVertices(cur, prev_perpendicular);
      AddJoin(Join::kRound, cur, prev_perpendicular, cur_perpendicular);
    }
    AppendVertices(cur, cur_perpendicular);
  }

  // |SegmentReceiver|
  void EndContour(Point origin, bool with_close) override {
    FML_DCHECK(origin == origin_point_);
    if (!has_prior_segment_) {
      // Empty contour, fill in an axis aligned "cap box" at the origin.
      FML_DCHECK(last_point_ == origin);
      // kButt wouldn't fill anything so it defers to kSquare by convention.
      Cap cap = (cap_ == Cap::kButt) ? Cap::kSquare : cap_;
      Vector2 perpendicular = {-half_stroke_width_, 0};
      AddCap(cap, origin, perpendicular, true);
      if (cap == Cap::kRound) {
        // Only round caps need the perpendicular between them to connect.
        AppendVertices(origin, perpendicular);
      }
      AddCap(cap, origin, perpendicular, false);
    } else if (with_close) {
      // Closed contour, join back to origin.
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

  // |PathAndArcSegmentReceiver|
  void RecordArc(const Arc& arc,
                 const Point center,
                 const Size radii) override {
    Tessellator::Trigs trigs =
        tessellator_.GetTrigsForDeviceRadius(scale_ * radii.MaxDimension());
    Arc::Iteration iterator = arc.ComputeIterations(trigs.GetSteps(), false);

    SeparatedVector2 prev_perpendicular =
        PerpendicularFromUnitDirection({-iterator.start.y, iterator.start.x});
    HandlePreviousJoin(prev_perpendicular);

    for (size_t i = 0u; i < iterator.quadrant_count; i++) {
      Arc::Iteration::Quadrant quadrant = iterator.quadrants[i];
      for (size_t j = quadrant.start_index; j < quadrant.end_index; j++) {
        Vector2 direction = trigs[j] * quadrant.axis;
        Point cur = center + direction * radii;
        SeparatedVector2 cur_perpendicular =
            PerpendicularFromUnitDirection({-direction.y, direction.x});
        RecordCurveSegment(prev_perpendicular, cur, cur_perpendicular);
        prev_perpendicular = cur_perpendicular;
      }
    }

    SeparatedVector2 end_perpendicular =
        PerpendicularFromUnitDirection({-iterator.end.y, iterator.end.x});
    Point end = center + iterator.end * radii;
    RecordCurveSegment(prev_perpendicular, end, end_perpendicular);

    last_perpendicular_ = end_perpendicular;
    last_point_ = end;
  }

 private:
  Tessellator& tessellator_;
  PositionWriter& vtx_builder_;
  const Scalar half_stroke_width_;
  const Scalar maximum_join_cosine_;
  const Scalar minimum_miter_cosine_;
  const Join join_;
  const Cap cap_;
  const Scalar scale_;
  const Tessellator::Trigs trigs_;

  SeparatedVector2 origin_perpendicular_;
  Point origin_point_;
  SeparatedVector2 last_perpendicular_;
  Point last_point_;
  bool has_prior_contour_ = false;
  bool has_prior_segment_ = false;
  bool contour_needs_cap_ = false;

  static Tessellator::Trigs MakeTrigs(Tessellator& tessellator,
                                      Scalar scale,
                                      Scalar half_stroke_width) {
    return tessellator.GetTrigsForDeviceRadius(scale * half_stroke_width);
  }

  // Half of the allowed distance between the ends of the perpendiculars.
  static constexpr Scalar kJoinPixelThreshold = 0.25f;

  /// Determine the cosine of the angle where the ends of 2 vectors that are
  /// each as long as half of the stroke width, differ by less than the
  /// kJoinPixelThreshold.
  ///
  /// Any angle between 2 segments in the path for which the cosine of that
  /// angle is greater than this return value, do not need any kind of join
  /// geometry. The angle between the segments can be quickly computed by
  /// the dot product of their direction vectors.
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

  /// Determine the cosine of the angle between 2 segments on the path where
  /// the miter limit will be exceeded if their outer stroked outlines are
  /// joined at their intersection. The miter limit is expressed as a multiple
  /// of the stroke width and since it is dependent on lines offset from the
  /// path by that same stroke width, the angle is based just on the miter
  /// limit itself.
  ///
  /// Any angle between 2 segments in the path for which the cosine of that
  /// angle is less than this return value would result in an intersection
  /// point that is further than the miter limit would allow. The angle
  /// between the segments can be quickly computed by the dot product of
  /// their direction vectors.
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

  inline SeparatedVector2 PerpendicularFromPoints(const Point from,
                                                  const Point to) const {
    return PerpendicularFromUnitDirection((to - from).Normalize());
  }

  inline SeparatedVector2 PerpendicularFromUnitDirection(
      const Vector2 direction) const {
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

  inline void HandlePreviousJoin(SeparatedVector2 new_perpendicular) {
    FML_DCHECK(has_prior_contour_);
    if (has_prior_segment_) {
      AddJoin(join_, last_point_, last_perpendicular_, new_perpendicular);
    } else {
      has_prior_segment_ = true;
      Vector2 perpendicular_vector = new_perpendicular.GetVector();
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
          // Start with a single point at the far end of the round cap.
          vtx_builder_.AppendVertex(path_point - along);

          // Iterate from the last non-quadrant value in the trigs vector
          // (trigs.back() == (1, 0)) down to, but not including, the first
          // entry (which is (0, 1)).
          for (size_t i = trigs_.size() - 2u; i > 0u; --i) {
            Point center = path_point - along * trigs_[i].sin;
            Vector2 offset = perpendicular * trigs_[i].cos;

            AppendVertices(center, offset);
          }
        } else {
          // Iterate from the first non-quadrant value in the trigs vector
          // (trigs[0] == (0, 1)) up to, but not including, the last entry
          // (which is (0, 1)).
          size_t end = trigs_.size() - 1u;
          for (size_t i = 1u; i < end; ++i) {
            Point center = path_point + along * trigs_[i].sin;
            Vector2 offset = perpendicular * trigs_[i].cos;

            AppendVertices(center, offset);
          }

          // End with a single point at the far end of the round cap.
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
        // Just fall through to the bevel operation after the switch.
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
        }
        // Else just fall through to bevel operation after the switch.
        break;
      }  // end of case Join::kMiter

      case Join::kRound: {
        if (cosine >= trigs_[1].cos) {
          // If rotating by the first (non-quadrant) entry in trigs takes
          // us too far then we don't need to fill in anything. Just fall
          // through to the bevel operation after the switch.
          break;
        }
        if (cosine < -trigs_[1].cos) {
          // This is closer to a 180 degree turn than the last trigs entry
          // can distinguish. Since we are going to generate all of the
          // sample points of the entire round join anyway, it is faster to
          // generate them using a round cap operation. Additionally, it
          // avoids math issues in the code below that stem from the
          // calculations being performed on a pair of vectors that are
          // nearly opposite each other.
          AddCap(Cap::kRound, path_point, old_perpendicular.GetVector(), false);
          // The bevel operation following the switch statement will set
          // us up to start drawing the following segment.
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
        // or until we pass the halfway point (middle_vector). We start at
        // position 1 because the first value is (0, 1) and just repeats
        // the from_vector, and we choose the end here as the last value
        // rather than the end of the vector because it is (1, 0) and that
        // would just repeat the to_vector. The end variable will be updated
        // in the first loop if we stop short of a full quadrant.
        size_t end = trigs_.size() - 1u;
        for (size_t i = 1u; i < end; ++i) {
          Point p = trigs_[i] * from_vector;
          if (p.Cross(middle_vector) <= 0) {
            // We've traversed far enough to pass the halfway vector, stop
            // here and drop out to traverse backwards from the to_vector.
            // Record the stopping point in the end variable as we will use
            // it to backtrack in the next loop.
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

        // The end variable points to the last trigs entry we decided not to
        // use, so a pre-decrement here moves us onto the trigs we actually
        // want to use (stopping before we use 0 which is the no rotation
        // vector).
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
      }  // end of case Join::kRound
    }  // end of switch
    // All joins need a final segment that is perpendicular to the shared
    // path point along the new perpendicular direction, and this also
    // provides a bevel join for all cases that decided no further
    // decoration was warranted.
    AppendVertices(path_point, new_perpendicular);
  }
};

// Private for benchmarking and debugging
std::vector<Point> StrokeSegmentsGeometry::GenerateSolidStrokeVertices(
    Tessellator& tessellator,
    const PathSource& source,
    const StrokeParameters& stroke,
    Scalar scale) {
  std::vector<Point> points(4096);
  PositionWriter vtx_builder(points);
  StrokePathSegmentReceiver receiver(tessellator, vtx_builder, stroke, scale);
  PathTessellator::PathToStrokedSegments(source, receiver);
  auto [arena, extra] = vtx_builder.GetUsedSize();
  FML_DCHECK(extra == 0u);
  points.resize(arena);
  return points;
}

StrokeSegmentsGeometry::StrokeSegmentsGeometry(const StrokeParameters& stroke)
    : stroke_(stroke) {}

StrokeSegmentsGeometry::~StrokeSegmentsGeometry() = default;

Scalar StrokeSegmentsGeometry::GetStrokeWidth() const {
  return stroke_.width;
}

Scalar StrokeSegmentsGeometry::GetMiterLimit() const {
  return stroke_.miter_limit;
}

Cap StrokeSegmentsGeometry::GetStrokeCap() const {
  return stroke_.cap;
}

Join StrokeSegmentsGeometry::GetStrokeJoin() const {
  return stroke_.join;
}

Scalar StrokeSegmentsGeometry::ComputeAlphaCoverage(
    const Matrix& transform) const {
  return Geometry::ComputeStrokeAlphaCoverage(transform, stroke_.width);
}

GeometryResult StrokeSegmentsGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  if (stroke_.width < 0.0) {
    return {};
  }
  Scalar max_basis = entity.GetTransform().GetMaxBasisLengthXY();
  if (max_basis == 0) {
    return {};
  }

  Scalar min_size = kMinStrokeSize / max_basis;
  StrokeParameters adjusted_stroke = stroke_;
  adjusted_stroke.width = std::max(stroke_.width, min_size);

  auto& data_host_buffer = renderer.GetTransientsDataBuffer();
  auto scale = entity.GetTransform().GetMaxBasisLengthXY();
  auto& tessellator = renderer.GetTessellator();

  PositionWriter position_writer(tessellator.GetStrokePointCache());
  StrokePathSegmentReceiver receiver(tessellator, position_writer,
                                     adjusted_stroke, scale);
  Dispatch(receiver, tessellator, scale);

  const auto [arena_length, oversized_length] = position_writer.GetUsedSize();
  if (!position_writer.HasOversizedBuffer()) {
    BufferView buffer_view =
        data_host_buffer.Emplace(tessellator.GetStrokePointCache().data(),
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
  BufferView buffer_view = data_host_buffer.Emplace(
      /*buffer=*/nullptr,                                 //
      (arena_length + oversized_length) * sizeof(Point),  //
      alignof(Point)                                      //
  );
  memcpy(buffer_view.GetBuffer()->OnGetContents() +
             buffer_view.GetRange().offset,         //
         tessellator.GetStrokePointCache().data(),  //
         arena_length * sizeof(Point)               //
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

GeometryResult::Mode StrokeSegmentsGeometry::GetResultMode() const {
  return GeometryResult::Mode::kPreventOverdraw;
}

std::optional<Rect> StrokeSegmentsGeometry::GetStrokeCoverage(
    const Matrix& transform,
    const Rect& path_bounds) const {
  if (path_bounds.IsEmpty()) {
    return std::nullopt;
  }

  Scalar max_radius = 0.5;
  if (stroke_.cap == Cap::kSquare) {
    max_radius = max_radius * kSqrt2;
  }
  if (stroke_.join == Join::kMiter) {
    max_radius = std::max(max_radius, stroke_.miter_limit * 0.5f);
  }
  Scalar max_basis = transform.GetMaxBasisLengthXY();
  if (max_basis == 0) {
    return {};
  }
  // Use the most conervative coverage setting.
  Scalar min_size = kMinStrokeSize / max_basis;
  max_radius *= std::max(stroke_.width, min_size);
  return path_bounds.Expand(max_radius).TransformBounds(transform);
}

StrokePathSourceGeometry::StrokePathSourceGeometry(
    const StrokeParameters& parameters)
    : StrokeSegmentsGeometry(parameters) {}

std::optional<Rect> StrokePathSourceGeometry::GetCoverage(
    const Matrix& transform) const {
  return GetStrokeCoverage(transform, GetSource().GetBounds());
}

void StrokePathSourceGeometry::Dispatch(PathAndArcSegmentReceiver& receiver,
                                        Tessellator& tessellator,
                                        Scalar scale) const {
  PathTessellator::PathToStrokedSegments(GetSource(), receiver);
}

StrokePathGeometry::StrokePathGeometry(const flutter::DlPath& path,
                                       const StrokeParameters& parameters)
    : StrokePathSourceGeometry(parameters), path_(path) {}

const PathSource& StrokePathGeometry::GetSource() const {
  return path_;
}

ArcStrokeGeometry::ArcStrokeGeometry(const Arc& arc,
                                     const StrokeParameters& parameters)
    : StrokeSegmentsGeometry(parameters), arc_(arc) {}

std::optional<Rect> ArcStrokeGeometry::GetCoverage(
    const Matrix& transform) const {
  return GetStrokeCoverage(transform, arc_.GetTightArcBounds());
}

void ArcStrokeGeometry::Dispatch(PathAndArcSegmentReceiver& receiver,
                                 Tessellator& tessellator,
                                 Scalar scale) const {
  Point center = arc_.GetOvalCenter();
  Size radii = arc_.GetOvalSize() * 0.5f;

  auto trigs =
      tessellator.GetTrigsForDeviceRadius(scale * radii.MaxDimension());
  Arc::Iteration iterator =
      arc_.ComputeIterations(trigs.GetSteps(), /*simplify_360=*/false);
  Point start = center + iterator.start * radii;
  bool include_center = arc_.IncludeCenter();

  receiver.BeginContour(start, include_center);
  receiver.RecordArc(arc_, center, radii);
  if (include_center) {
    Point end = center + iterator.end * radii;
    receiver.RecordLine(end, center);
    receiver.RecordLine(center, start);
  }
  receiver.EndContour(start, include_center);
}

StrokeDiffRoundRectGeometry::StrokeDiffRoundRectGeometry(
    const RoundRect& outer,
    const RoundRect& inner,
    const StrokeParameters& parameters)
    : StrokePathSourceGeometry(parameters), source_(outer, inner) {}

const PathSource& StrokeDiffRoundRectGeometry::GetSource() const {
  return source_;
}

StrokeDashedLineGeometry::StrokeDashedLineGeometry(
    Point p0,
    Point p1,
    Scalar on_length,
    Scalar off_length,
    const StrokeParameters& parameters)
    : StrokePathSourceGeometry(parameters),
      source_(p0, p1, on_length, off_length) {}

const PathSource& StrokeDashedLineGeometry::GetSource() const {
  return source_;
}

}  // namespace impeller
