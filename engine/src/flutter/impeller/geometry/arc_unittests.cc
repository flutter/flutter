// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/geometry/geometry_asserts.h"
#include "gtest/gtest.h"

#include "flutter/impeller/geometry/arc.h"
#include "flutter/impeller/tessellator/tessellator.h"

namespace impeller {
namespace testing {

namespace {

// Tests the basic relationships of the angles iterated according to the
// rules of the ArcIteration struct. Each step iterated should be just
// about the same angular distance from the previous step, computed using
// the Cross product of the adjacent vectors, which should be the same as
// the sine of the angle between them when using unit vectors.
//
// Special support for shorter starting and ending steps to bridge the gap
// from the true arc start and the true arc end and the first and last
// angles iterated from the trigs.
void TestArcIterator(const impeller::Arc::Iteration arc_iteration,
                     const impeller::Tessellator::Trigs& trigs,
                     Degrees start,
                     Degrees sweep,
                     const std::string& label) {
  EXPECT_POINT_NEAR(arc_iteration.start, impeller::Matrix::CosSin(start))
      << label;
  EXPECT_POINT_NEAR(arc_iteration.end, impeller::Matrix::CosSin(start + sweep))
      << label;
  if (arc_iteration.quadrant_count == 0u) {
    // There is just the begin and end angle and there are no constraints
    // on how far apart they should be, but the end vector should be
    // non-counterclockwise from the start vector.
    EXPECT_GE(arc_iteration.start.Cross(arc_iteration.end), 0.0f);
    return;
  }

  const size_t steps = trigs.size() - 1;
  const Scalar step_angle = kPiOver2 / steps;

  // The first and last steps are allowed to be from 0.1 to 1.1 in size
  // as we don't want to iterate an extra step that is less than 0.1 steps
  // from the begin/end angles. We use min/max values that are ever so
  // slightly larger than that to avoid round-off errors.
  const Scalar edge_min_cross = std::sin(step_angle * 0.099f);
  const Scalar edge_max_cross = std::sin(step_angle * 1.101f);
  const Scalar typical_min_cross = std::sin(step_angle * 0.999f);
  const Scalar typical_max_cross = std::sin(step_angle * 1.001f);

  Vector2 cur_vector;
  auto trace = [&cur_vector](Vector2 vector, Scalar min_cross, Scalar max_cross,
                             const std::string& label) -> void {
    EXPECT_GT(cur_vector.Cross(vector), min_cross) << label;
    EXPECT_LT(cur_vector.Cross(vector), max_cross) << label;
    cur_vector = vector;
  };

  // The first edge encountered in the loop should be judged by the edge
  // conditions. After that the steps derived from the Trigs should be
  // judged by the typical min/max values.
  Scalar min_cross = edge_min_cross;
  Scalar max_cross = edge_max_cross;

  cur_vector = arc_iteration.start;
  for (size_t i = 0; i < arc_iteration.quadrant_count; i++) {
    auto& quadrant = arc_iteration.quadrants[i];
    EXPECT_LT(quadrant.start_index, quadrant.end_index)
        << label << ", quadrant: " << i;
    for (size_t j = quadrant.start_index; j < quadrant.end_index; j++) {
      trace(trigs[j] * quadrant.axis, min_cross, max_cross,
            label + ", quadrant: " + std::to_string(i) +
                ", step: " + std::to_string(j));
      // At this point we can guarantee that we've already used the initial
      // min/max values, now replace them with the typical values.
      min_cross = typical_min_cross;
      max_cross = typical_max_cross;
    }
  }

  // The jump to the end angle should be judged by the edge conditions.
  trace(arc_iteration.end, edge_min_cross, edge_max_cross,
        label + " step to end");
}

void TestFullCircleArc(Degrees start, Degrees sweep) {
  auto label =
      std::to_string(start.degrees) + " += " + std::to_string(sweep.degrees);

  Arc arc(Rect::MakeLTRB(10, 10, 20, 20), Degrees(start), Degrees(sweep),
          false);

  Tessellator tessellator;
  const auto trigs = tessellator.GetTrigsForDeviceRadius(100);
  size_t steps = trigs.GetSteps();
  const auto& arc_iteration = arc.ComputeIterations(steps);

  EXPECT_EQ(arc_iteration.start, Vector2(1.0f, 0.0f)) << label;
  EXPECT_EQ(arc_iteration.quadrant_count, 4u) << label;
  EXPECT_EQ(arc_iteration.quadrants[0].axis, Vector2(1.0f, 0.0f)) << label;
  EXPECT_EQ(arc_iteration.quadrants[0].start_index, 1u) << label;
  EXPECT_EQ(arc_iteration.quadrants[0].end_index, steps) << label;
  EXPECT_EQ(arc_iteration.quadrants[1].axis, Vector2(0.0f, 1.0f)) << label;
  EXPECT_EQ(arc_iteration.quadrants[1].start_index, 0u) << label;
  EXPECT_EQ(arc_iteration.quadrants[1].end_index, steps) << label;
  EXPECT_EQ(arc_iteration.quadrants[2].axis, Vector2(-1.0f, 0.0f)) << label;
  EXPECT_EQ(arc_iteration.quadrants[2].start_index, 0u) << label;
  EXPECT_EQ(arc_iteration.quadrants[2].end_index, steps) << label;
  EXPECT_EQ(arc_iteration.quadrants[3].axis, Vector2(0.0f, -1.0f)) << label;
  EXPECT_EQ(arc_iteration.quadrants[3].start_index, 0u) << label;
  EXPECT_EQ(arc_iteration.quadrants[3].end_index, steps) << label;
  EXPECT_EQ(arc_iteration.end, Vector2(1.0f, 0.0f)) << label;

  // For full circle arcs the original start and sweep are ignored and it
  // returns an iterator that always goes from 0->360.
  TestArcIterator(arc_iteration, trigs, Degrees(0), Degrees(360),
                  "Full Circle(" + label + ")");
}

}  // namespace

TEST(ArcTest, ArcIterationsFullCircle) {
  // Anything with a sweep <=-360 or >=360 is a full circle regardless of
  // starting angle
  for (int start = -720; start < 720; start += 30) {
    for (int sweep = 360; sweep < 1080; sweep += 45) {
      TestFullCircleArc(Degrees(start), Degrees(sweep));
      TestFullCircleArc(Degrees(start), Degrees(-sweep));
    }
  }
}

namespace {
static void CheckOneQuadrant(Degrees start, Degrees sweep) {
  Arc arc(Rect::MakeLTRB(10, 10, 20, 20), start, sweep, false);
  Tessellator tessellator;
  const auto trigs = tessellator.GetTrigsForDeviceRadius(100);
  const auto& arc_iteration = arc.ComputeIterations(trigs.GetSteps());

  EXPECT_POINT_NEAR(arc_iteration.start, Matrix::CosSin(start));
  EXPECT_EQ(arc_iteration.quadrant_count, 1u);
  EXPECT_POINT_NEAR(arc_iteration.end, Matrix::CosSin(start + sweep));

  std::string label = "Quadrant(" + std::to_string(start.degrees) +
                      " += " + std::to_string(sweep.degrees) + ")";
  TestArcIterator(arc_iteration, trigs, start, sweep, label);
}
}  // namespace

TEST(ArcTest, ArcIterationsVariousStartAnglesNearQuadrantAxis) {
  Tessellator tessellator;
  const auto trigs = tessellator.GetTrigsForDeviceRadius(100);
  const Degrees sweep(45);

  for (int start_i = -1000; start_i < 1000; start_i += 5) {
    Scalar start_degrees = start_i * 0.01f;
    for (int quadrant = -360; quadrant <= 360; quadrant += 90) {
      const Degrees start(quadrant + start_degrees);
      Arc arc(Rect::MakeLTRB(10, 10, 20, 20), start, sweep, false);
      const auto& arc_iteration = arc.ComputeIterations(trigs.GetSteps());

      TestArcIterator(arc_iteration, trigs, start, sweep,
                      "Various angles(" + std::to_string(start.degrees) +
                          " += " + std::to_string(sweep.degrees));
    }
  }
}

TEST(ArcTest, ArcIterationsVariousEndAnglesNearQuadrantAxis) {
  Tessellator tessellator;
  const auto trigs = tessellator.GetTrigsForDeviceRadius(100);

  for (int sweep_i = 5; sweep_i < 20000; sweep_i += 5) {
    const Degrees sweep(sweep_i * 0.01f);
    for (int quadrant = -360; quadrant <= 360; quadrant += 90) {
      const Degrees start(quadrant + 80);
      Arc arc(Rect::MakeLTRB(10, 10, 20, 20), start, sweep, false);
      const auto& arc_iteration = arc.ComputeIterations(trigs.GetSteps());

      TestArcIterator(arc_iteration, trigs, start, sweep,
                      "Various angles(" + std::to_string(start.degrees) +
                          " += " + std::to_string(sweep.degrees));
    }
  }
}

TEST(ArcTest, ArcIterationsVariousTinyArcsNearQuadrantAxis) {
  Tessellator tessellator;
  const auto trigs = tessellator.GetTrigsForDeviceRadius(100);
  const Degrees sweep(0.1f);

  for (int start_i = -1000; start_i < 1000; start_i += 5) {
    Scalar start_degrees = start_i * 0.01f;
    for (int quadrant = -360; quadrant <= 360; quadrant += 90) {
      const Degrees start(quadrant + start_degrees);
      Arc arc(Rect::MakeLTRB(10, 10, 20, 20), start, sweep, false);
      const auto& arc_iteration = arc.ComputeIterations(trigs.GetSteps());
      ASSERT_EQ(arc_iteration.quadrant_count, 0u);

      TestArcIterator(arc_iteration, trigs, start, sweep,
                      "Various angles(" + std::to_string(start.degrees) +
                          " += " + std::to_string(sweep.degrees));
    }
  }
}

TEST(ArcTest, ArcIterationsOnlyFirstQuadrant) {
  CheckOneQuadrant(Degrees(90 * 0 + 30), Degrees(30));
}

TEST(ArcTest, ArcIterationsOnlySecondQuadrant) {
  CheckOneQuadrant(Degrees(90 * 1 + 30), Degrees(30));
}

TEST(ArcTest, ArcIterationsOnlyThirdQuadrant) {
  CheckOneQuadrant(Degrees(90 * 2 + 30), Degrees(30));
}

TEST(ArcTest, ArcIterationsOnlyFourthQuadrant) {
  CheckOneQuadrant(Degrees(90 * 3 + 30), Degrees(30));
}

namespace {
static void CheckFiveQuadrants(Degrees start, Degrees sweep) {
  std::string label =
      std::to_string(start.degrees) + " += " + std::to_string(sweep.degrees);

  Tessellator tessellator;
  const auto trigs = tessellator.GetTrigsForDeviceRadius(100);
  Arc arc(Rect::MakeLTRB(10, 10, 20, 20), start, sweep, false);
  const auto& arc_iteration = arc.ComputeIterations(trigs.GetSteps());
  size_t steps = trigs.size() - 1;

  EXPECT_POINT_NEAR(arc_iteration.start, Matrix::CosSin(start)) << label;
  EXPECT_EQ(arc_iteration.quadrant_count, 5u) << label;

  // quadrant 0 start index depends on angle
  EXPECT_EQ(arc_iteration.quadrants[0].end_index, steps) << label;

  EXPECT_EQ(arc_iteration.quadrants[1].start_index, 0u) << label;
  EXPECT_EQ(arc_iteration.quadrants[1].end_index, steps) << label;

  EXPECT_EQ(arc_iteration.quadrants[2].start_index, 0u) << label;
  EXPECT_EQ(arc_iteration.quadrants[2].end_index, steps) << label;

  EXPECT_EQ(arc_iteration.quadrants[3].start_index, 0u) << label;
  EXPECT_EQ(arc_iteration.quadrants[3].end_index, steps) << label;

  EXPECT_EQ(arc_iteration.quadrants[4].start_index, 0u) << label;
  // quadrant 4 end index depends on angle

  EXPECT_POINT_NEAR(arc_iteration.end, Matrix::CosSin(start + sweep)) << label;

  TestArcIterator(arc_iteration, trigs, start, sweep,
                  "Five quadrants(" + label + ")");
}
}  // namespace

TEST(ArcTest, ArcIterationsAllQuadrantsFromFirst) {
  CheckFiveQuadrants(Degrees(90 * 0 + 60), Degrees(330));
}

TEST(ArcTest, ArcIterationsAllQuadrantsFromSecond) {
  CheckFiveQuadrants(Degrees(90 * 1 + 60), Degrees(330));
}

TEST(ArcTest, ArcIterationsAllQuadrantsFromThird) {
  CheckFiveQuadrants(Degrees(90 * 2 + 60), Degrees(330));
}

TEST(ArcTest, ArcIterationsAllQuadrantsFromFourth) {
  CheckFiveQuadrants(Degrees(90 * 3 + 60), Degrees(330));
}

}  // namespace testing
}  // namespace impeller
