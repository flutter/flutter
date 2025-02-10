
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/common/windowing.h"

#include <array>

#include "flutter/fml/logging.h"
#include "gtest/gtest.h"

namespace flutter {

namespace {

using Positioner = WindowPositioner;
using Anchor = Positioner::Anchor;
using Constraint = Positioner::ConstraintAdjustment;

struct WindowPlacementTest
    : ::testing::TestWithParam<std::tuple<Anchor, Anchor>> {
  struct ClientAnchorsToParentConfig {
    Rect const display_area = {{0.0, 0.0}, {800.0, 600.0}};
    Size const parent_size = {400.0, 300.0};
    Size const child_size = {100.0, 50.0};
    Point const parent_position = {
        (display_area.width() - parent_size.width()) / 2.0,
        (display_area.height() - parent_size.height()) / 2.0};
  } client_anchors_to_parent_config;

  Rect const display_area = {{0.0, 0.0}, {640.0, 480.0}};
  Size const parent_size = {600.0, 400.0};
  Size const child_size = {300.0, 300.0};
  Rect const rectangle_away_from_rhs = {{20.0, 20.0}, {20.0, 20.0}};
  Rect const rectangle_near_rhs = {{590.0, 20.0}, {10.0, 20.0}};
  Rect const rectangle_away_from_bottom = {{20.0, 20.0}, {20.0, 20.0}};
  Rect const rectangle_near_bottom = {{20.0, 380.0}, {20.0, 20.0}};
  Rect const rectangle_near_both_sides = {{0.0, 20.0}, {600.0, 20.0}};
  Rect const rectangle_near_both_sides_and_bottom = {{0.0, 380.0},
                                                     {600.0, 20.0}};
  Rect const rectangle_near_all_sides = {{0.0, 20.0}, {600.0, 380.0}};
  Rect const rectangle_near_both_bottom_right = {{400.0, 380.0}, {200.0, 20.0}};
  Point const parent_position = {
      (display_area.width() - parent_size.width()) / 2.0,
      (display_area.height() - parent_size.height()) / 2.0};

  Positioner positioner;

  Rect anchor_rect() {
    Rect rectangle{positioner.anchor_rect.value()};
    return {rectangle.origin() + parent_position, rectangle.size()};
  }

  Rect parent_rect() { return {parent_position, parent_size}; }

  Point on_top_edge() {
    return anchor_rect().origin() - Point{0.0, child_size.height()};
  }

  Point on_left_edge() {
    return anchor_rect().origin() - Point{child_size.width(), 0.0};
  }
};

std::vector<std::tuple<Anchor, Anchor>> all_anchor_combinations() {
  std::array const all_anchors = {
      Anchor::kTopLeft,    Anchor::kTop,    Anchor::kTopRight,
      Anchor::kLeft,       Anchor::kCenter, Anchor::kRight,
      Anchor::kBottomLeft, Anchor::kBottom, Anchor::kBottomRight,
  };
  std::vector<std::tuple<Anchor, Anchor>> combinations;
  combinations.reserve(all_anchors.size() * all_anchors.size());

  for (Anchor const parent_anchor : all_anchors) {
    for (Anchor const child_anchor : all_anchors) {
      combinations.push_back(std::make_tuple(parent_anchor, child_anchor));
    }
  }
  return combinations;
}

}  // namespace

TEST_F(WindowPlacementTest, ClientAnchorsToParentGivenRectAnchorRightOfParent) {
  Rect const& display_area = client_anchors_to_parent_config.display_area;
  Size const& parent_size = client_anchors_to_parent_config.parent_size;
  Size const& child_size = client_anchors_to_parent_config.child_size;
  Point const& parent_position =
      client_anchors_to_parent_config.parent_position;

  double const rect_size = 10.0;
  Rect const overlapping_right = {
      parent_position + Point{parent_size.width() - rect_size / 2.0,
                              parent_size.height() / 2.0},
      {rect_size, rect_size}};

  Positioner const positioner = {
      .anchor_rect = overlapping_right,
      .parent_anchor = Anchor::kTopRight,
      .child_anchor = Anchor::kTopLeft,
      .constraint_adjustment =
          static_cast<Constraint>(static_cast<int>(Constraint::kSlideY) |
                                  static_cast<int>(Constraint::kResizeX))};

  Rect const child_rect =
      PlaceWindow(positioner, child_size, positioner.anchor_rect.value(),
                  {parent_position, parent_size}, display_area);

  Point const expected_position =
      parent_position + Point{parent_size.width(), parent_size.height() / 2.0};

  EXPECT_EQ(child_rect.origin(), expected_position);
  EXPECT_EQ(child_rect.size(), child_size);
}

TEST_F(WindowPlacementTest, ClientAnchorsToParentGivenRectAnchorAboveParent) {
  Rect const& display_area = client_anchors_to_parent_config.display_area;
  Size const& parent_size = client_anchors_to_parent_config.parent_size;
  Size const& child_size = client_anchors_to_parent_config.child_size;
  Point const& parent_position =
      client_anchors_to_parent_config.parent_position;

  double const rect_size = 10.0;
  Rect const overlapping_above = {
      parent_position + Point{parent_size.width() / 2.0, -rect_size / 2.0},
      {rect_size, rect_size}};

  Positioner const positioner = {.anchor_rect = overlapping_above,
                                 .parent_anchor = Anchor::kTopRight,
                                 .child_anchor = Anchor::kBottomRight,
                                 .constraint_adjustment = Constraint::kSlideX};

  Rect const child_rect =
      PlaceWindow(positioner, child_size, positioner.anchor_rect.value(),
                  {parent_position, parent_size}, display_area);

  Point const expected_position =
      parent_position + Point{parent_size.width() / 2.0 + rect_size, 0.0} -
      Point{child_size.width(), child_size.height()};

  EXPECT_EQ(child_rect.origin(), expected_position);
  EXPECT_EQ(child_rect.size(), child_size);
}

TEST_F(WindowPlacementTest, ClientAnchorsToParentGivenOffsetRightOfParent) {
  Rect const& display_area = client_anchors_to_parent_config.display_area;
  Size const& parent_size = client_anchors_to_parent_config.parent_size;
  Size const& child_size = client_anchors_to_parent_config.child_size;
  Point const& parent_position =
      client_anchors_to_parent_config.parent_position;

  double const rect_size = 10.0;
  Rect const mid_right = {
      parent_position +
          Point{parent_size.width() - rect_size, parent_size.height() / 2.0},
      {rect_size, rect_size}};

  Positioner const positioner = {
      .anchor_rect = mid_right,
      .parent_anchor = Anchor::kTopRight,
      .child_anchor = Anchor::kTopLeft,
      .offset = Point{rect_size, 0.0},
      .constraint_adjustment =
          static_cast<Constraint>(static_cast<int>(Constraint::kSlideY) |
                                  static_cast<int>(Constraint::kResizeX))};

  Rect const child_rect =
      PlaceWindow(positioner, child_size, positioner.anchor_rect.value(),
                  {parent_position, parent_size}, display_area);

  Point const expected_position =
      parent_position + Point{parent_size.width(), parent_size.height() / 2};

  EXPECT_EQ(child_rect.origin(), expected_position);
  EXPECT_EQ(child_rect.size(), child_size);
}

TEST_F(WindowPlacementTest, ClientAnchorsToParentGivenOffsetAboveParent) {
  Rect const& display_area = client_anchors_to_parent_config.display_area;
  Size const& parent_size = client_anchors_to_parent_config.parent_size;
  Size const& child_size = client_anchors_to_parent_config.child_size;
  Point const& parent_position =
      client_anchors_to_parent_config.parent_position;

  double const rect_size = 10.0;
  Rect const mid_top = {parent_position + Point{parent_size.width() / 2.0, 0.0},
                        {rect_size, rect_size}};

  Positioner const positioner = {.anchor_rect = mid_top,
                                 .parent_anchor = Anchor::kTopRight,
                                 .child_anchor = Anchor::kBottomRight,
                                 .offset = Point{0.0, -rect_size},
                                 .constraint_adjustment = Constraint::kSlideX};

  Rect const child_rect =
      PlaceWindow(positioner, child_size, positioner.anchor_rect.value(),
                  {parent_position, parent_size}, display_area);

  Point const expected_position =
      parent_position + Point{parent_size.width() / 2.0 + rect_size, 0.0} -
      Point{child_size.width(), child_size.height()};

  EXPECT_EQ(child_rect.origin(), expected_position);
  EXPECT_EQ(child_rect.size(), child_size);
}

TEST_F(WindowPlacementTest,
       ClientAnchorsToParentGivenRectAndOffsetBelowLeftParent) {
  Rect const& display_area = client_anchors_to_parent_config.display_area;
  Size const& parent_size = client_anchors_to_parent_config.parent_size;
  Size const& child_size = client_anchors_to_parent_config.child_size;
  Point const& parent_position =
      client_anchors_to_parent_config.parent_position;

  double const rect_size = 10.0;
  Rect const below_left = {
      parent_position + Point{-rect_size, parent_size.height()},
      {rect_size, rect_size}};

  Positioner const positioner = {
      .anchor_rect = below_left,
      .parent_anchor = Anchor::kBottomLeft,
      .child_anchor = Anchor::kTopRight,
      .offset = Point{-rect_size, rect_size},
      .constraint_adjustment = Constraint::kResizeAny};

  Rect const child_rect =
      PlaceWindow(positioner, child_size, positioner.anchor_rect.value(),
                  {parent_position, parent_size}, display_area);

  Point const expected_position = parent_position +
                                  Point{0.0, parent_size.height()} -
                                  Point{child_size.width(), 0.0};

  EXPECT_EQ(child_rect.origin(), expected_position);
  EXPECT_EQ(child_rect.size(), child_size);
}

TEST_P(WindowPlacementTest, CanAttachByEveryAnchorGivenNoConstraintAdjustment) {
  positioner.anchor_rect = Rect{{100.0, 50.0}, {20.0, 20.0}};
  positioner.constraint_adjustment = Constraint{};
  std::tie(positioner.parent_anchor, positioner.child_anchor) = GetParam();

  auto const position_of = [](Anchor anchor, Rect rectangle) -> Point {
    switch (anchor) {
      case Anchor::kTopLeft:
        return rectangle.origin();
      case Anchor::kTop:
        return rectangle.origin() + Point{rectangle.width() / 2.0, 0.0};
      case Anchor::kTopRight:
        return rectangle.origin() + Point{rectangle.width(), 0.0};
      case Anchor::kLeft:
        return rectangle.origin() + Point{0.0, rectangle.height() / 2.0};
      case Anchor::kCenter:
        return rectangle.origin() +
               Point{rectangle.width() / 2.0, rectangle.height() / 2.0};
      case Anchor::kRight:
        return rectangle.origin() +
               Point{rectangle.width(), rectangle.height() / 2.0};
      case Anchor::kBottomLeft:
        return rectangle.origin() + Point{0.0, rectangle.height()};
      case Anchor::kBottom:
        return rectangle.origin() +
               Point{rectangle.width() / 2.0, rectangle.height()};
      case Anchor::kBottomRight:
        return rectangle.origin() +
               Point{rectangle.width(), rectangle.height()};
      default:
        FML_UNREACHABLE();
    }
  };

  Point const anchor_position =
      position_of(positioner.parent_anchor, anchor_rect());

  Rect const child_rect = PlaceWindow(positioner, child_size, anchor_rect(),
                                      parent_rect(), display_area);

  EXPECT_EQ(position_of(positioner.child_anchor, child_rect), anchor_position);
}

INSTANTIATE_TEST_SUITE_P(AnchorCombinations,
                         WindowPlacementTest,
                         ::testing::ValuesIn(all_anchor_combinations()));

TEST_F(WindowPlacementTest,
       PlacementIsFlippedGivenAnchorRectNearRightSideAndOffset) {
  double const x_offset = 42.0;
  double const y_offset = 13.0;

  positioner.anchor_rect = rectangle_near_rhs;
  positioner.constraint_adjustment = Constraint::kFlipX;
  positioner.offset = Point{x_offset, y_offset};
  positioner.child_anchor = Anchor::kTopLeft;
  positioner.parent_anchor = Anchor::kTopRight;

  Point const expected_position =
      on_left_edge() + Point{-1.0 * x_offset, y_offset};

  Rect const child_rect = PlaceWindow(positioner, child_size, anchor_rect(),
                                      parent_rect(), display_area);

  EXPECT_EQ(child_rect.origin(), expected_position);
}

TEST_F(WindowPlacementTest,
       PlacementIsFlippedGivenAnchorRectNearBottomAndOffset) {
  double const x_offset = 42.0;
  double const y_offset = 13.0;

  positioner.anchor_rect = rectangle_near_bottom;
  positioner.constraint_adjustment = Constraint::kFlipY;
  positioner.offset = Point{x_offset, y_offset};
  positioner.child_anchor = Anchor::kTopLeft;
  positioner.parent_anchor = Anchor::kBottomLeft;

  Point const expected_position =
      on_top_edge() + Point{x_offset, -1.0 * y_offset};

  Rect const child_rect = PlaceWindow(positioner, child_size, anchor_rect(),
                                      parent_rect(), display_area);

  EXPECT_EQ(child_rect.origin(), expected_position);
}

TEST_F(WindowPlacementTest,
       PlacementIsFlippedBothWaysGivenAnchorRectNearBottomRightAndOffset) {
  double const x_offset = 42.0;
  double const y_offset = 13.0;

  positioner.anchor_rect = rectangle_near_both_bottom_right;
  positioner.constraint_adjustment = Constraint::kFlipAny;
  positioner.offset = Point{x_offset, y_offset};
  positioner.child_anchor = Anchor::kTopLeft;
  positioner.parent_anchor = Anchor::kBottomRight;

  Point const expected_position =
      anchor_rect().origin() - Point{child_size.width(), child_size.height()} -
      Point{x_offset, y_offset};

  Rect const child_rect = PlaceWindow(positioner, child_size, anchor_rect(),
                                      parent_rect(), display_area);

  EXPECT_EQ(child_rect.origin(), expected_position);
}

TEST_F(WindowPlacementTest, PlacementCanSlideInXGivenAnchorRectNearRightSide) {
  positioner.anchor_rect = rectangle_near_rhs;
  positioner.constraint_adjustment = Constraint::kSlideX;
  positioner.child_anchor = Anchor::kTopLeft;
  positioner.parent_anchor = Anchor::kTopRight;

  Point const expected_position = {
      (display_area.left() + display_area.width()) - child_size.width(),
      anchor_rect().top()};

  Rect const child_rect = PlaceWindow(positioner, child_size, anchor_rect(),
                                      parent_rect(), display_area);

  EXPECT_EQ(child_rect.origin(), expected_position);
}

TEST_F(WindowPlacementTest, PlacementCanSlideInXGivenAnchorRectNearLeftSide) {
  Rect const rectangle_near_left_side = {{0.0, 20.0}, {20.0, 20.0}};

  positioner.anchor_rect = rectangle_near_left_side;
  positioner.constraint_adjustment = Constraint::kSlideX;
  positioner.child_anchor = Anchor::kTopRight;
  positioner.parent_anchor = Anchor::kTopLeft;

  Point const expected_position = {display_area.left(), anchor_rect().top()};

  Rect const child_rect = PlaceWindow(positioner, child_size, anchor_rect(),
                                      parent_rect(), display_area);

  EXPECT_EQ(child_rect.origin(), expected_position);
}

TEST_F(WindowPlacementTest, PlacementCanSlideInYGivenAnchorRectNearBottom) {
  positioner.anchor_rect = rectangle_near_bottom;
  positioner.constraint_adjustment = Constraint::kSlideY;
  positioner.child_anchor = Anchor::kTopLeft;
  positioner.parent_anchor = Anchor::kBottomLeft;

  Point const expected_position = {
      anchor_rect().left(),
      (display_area.top() + display_area.height()) - child_size.height()};

  Rect const child_rect = PlaceWindow(positioner, child_size, anchor_rect(),
                                      parent_rect(), display_area);

  EXPECT_EQ(child_rect.origin(), expected_position);
}

TEST_F(WindowPlacementTest, PlacementCanSlideInYGivenAnchorRectNearTop) {
  positioner.anchor_rect = rectangle_near_all_sides;
  positioner.constraint_adjustment = Constraint::kSlideY;
  positioner.child_anchor = Anchor::kBottomLeft;
  positioner.parent_anchor = Anchor::kTopLeft;

  Point const expected_position = {anchor_rect().left(), display_area.top()};

  Rect const child_rect = PlaceWindow(positioner, child_size, anchor_rect(),
                                      parent_rect(), display_area);

  EXPECT_EQ(child_rect.origin(), expected_position);
}

TEST_F(WindowPlacementTest,
       PlacementCanSlideInXAndYGivenAnchorRectNearBottomRightAndOffset) {
  positioner.anchor_rect = rectangle_near_both_bottom_right;
  positioner.constraint_adjustment = Constraint::kSlideAny;
  positioner.child_anchor = Anchor::kTopLeft;
  positioner.parent_anchor = Anchor::kBottomLeft;

  Point const expected_position = {
      (display_area.origin() +
       Point{display_area.width(), display_area.height()}) -
      Point{child_size.width(), child_size.height()}};

  Rect const child_rect = PlaceWindow(positioner, child_size, anchor_rect(),
                                      parent_rect(), display_area);

  EXPECT_EQ(child_rect.origin(), expected_position);
}

TEST_F(WindowPlacementTest, PlacementCanResizeInXGivenAnchorRectNearRightSide) {
  positioner.anchor_rect = rectangle_near_rhs;
  positioner.constraint_adjustment = Constraint::kResizeX;
  positioner.child_anchor = Anchor::kTopLeft;
  positioner.parent_anchor = Anchor::kTopRight;

  Point const expected_position =
      anchor_rect().origin() + Point{anchor_rect().width(), 0.0};
  Size const expected_size = {
      (display_area.left() + display_area.width()) -
          (anchor_rect().left() + anchor_rect().width()),
      child_size.height()};

  Rect const child_rect = PlaceWindow(positioner, child_size, anchor_rect(),
                                      parent_rect(), display_area);

  EXPECT_EQ(child_rect.origin(), expected_position);
  EXPECT_EQ(child_rect.size(), expected_size);
}

TEST_F(WindowPlacementTest, PlacementCanResizeInXGivenAnchorRectNearLeftSide) {
  Rect const rectangle_near_left_side = {{0.0, 20.0}, {20.0, 20.0}};

  positioner.anchor_rect = rectangle_near_left_side;
  positioner.constraint_adjustment = Constraint::kResizeX;
  positioner.child_anchor = Anchor::kTopRight;
  positioner.parent_anchor = Anchor::kTopLeft;

  Point const expected_position = {display_area.left(), anchor_rect().top()};
  Size const expected_size = {anchor_rect().left() - display_area.left(),
                              child_size.height()};

  Rect const child_rect = PlaceWindow(positioner, child_size, anchor_rect(),
                                      parent_rect(), display_area);

  EXPECT_EQ(child_rect.origin(), expected_position);
  EXPECT_EQ(child_rect.size(), expected_size);
}

TEST_F(WindowPlacementTest, PlacementCanResizeInYGivenAnchorRectNearBottom) {
  positioner.anchor_rect = rectangle_near_bottom;
  positioner.constraint_adjustment = Constraint::kResizeY;
  positioner.child_anchor = Anchor::kTopLeft;
  positioner.parent_anchor = Anchor::kBottomLeft;

  Point const expected_position =
      anchor_rect().origin() + Point{0.0, anchor_rect().height()};
  Size const expected_size = {
      child_size.width(), (display_area.top() + display_area.height()) -
                              (anchor_rect().top() + anchor_rect().height())};

  Rect const child_rect = PlaceWindow(positioner, child_size, anchor_rect(),
                                      parent_rect(), display_area);

  EXPECT_EQ(child_rect.origin(), expected_position);
  EXPECT_EQ(child_rect.size(), expected_size);
}

TEST_F(WindowPlacementTest, PlacementCanResizeInYGivenAnchorRectNearTop) {
  positioner.anchor_rect = rectangle_near_all_sides;
  positioner.constraint_adjustment = Constraint::kResizeY;
  positioner.child_anchor = Anchor::kBottomLeft;
  positioner.parent_anchor = Anchor::kTopLeft;

  Point const expected_position = {anchor_rect().left(), display_area.top()};
  Size const expected_size = {child_size.width(),
                              anchor_rect().top() - display_area.top()};

  Rect const child_rect = PlaceWindow(positioner, child_size, anchor_rect(),
                                      parent_rect(), display_area);

  EXPECT_EQ(child_rect.origin(), expected_position);
  EXPECT_EQ(child_rect.size(), expected_size);
}

TEST_F(WindowPlacementTest,
       PlacementCanResizeInXAndYGivenAnchorRectNearBottomRightAndOffset) {
  positioner.anchor_rect = rectangle_near_both_bottom_right;
  positioner.constraint_adjustment = Constraint::kResizeAny;
  positioner.child_anchor = Anchor::kTopLeft;
  positioner.parent_anchor = Anchor::kBottomRight;

  Point const expected_position =
      anchor_rect().origin() +
      Point{anchor_rect().width(), anchor_rect().height()};
  Size const expected_size = {
      (display_area.left() + display_area.width()) - expected_position.x(),
      (display_area.top() + display_area.height()) - expected_position.y()};

  Rect const child_rect = PlaceWindow(positioner, child_size, anchor_rect(),
                                      parent_rect(), display_area);

  EXPECT_EQ(child_rect.origin(), expected_position);
  EXPECT_EQ(child_rect.size(), expected_size);
}

}  // namespace flutter
