// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/common/windowing.h"

#include <algorithm>

namespace flutter {

namespace {

Point offset_for(Size const& size, WindowPositioner::Anchor anchor) {
  switch (anchor) {
    case WindowPositioner::Anchor::kTopLeft:
      return {0.0, 0.0};
    case WindowPositioner::Anchor::kTop:
      return {-size.width() / 2.0, 0.0};
    case WindowPositioner::Anchor::kTopRight:
      return {-1.0 * size.width(), 0.0};
    case WindowPositioner::Anchor::kLeft:
      return {0.0, -size.height() / 2.0};
    case WindowPositioner::Anchor::kCenter:
      return {-size.width() / 2.0, -size.height() / 2.0};
    case WindowPositioner::Anchor::kRight:
      return {-1.0 * size.width(), -size.height() / 2.0};
    case WindowPositioner::Anchor::kBottomLeft:
      return {0.0, -1.0 * size.height()};
    case WindowPositioner::Anchor::kBottom:
      return {-size.width() / 2.0, -1.0 * size.height()};
    case WindowPositioner::Anchor::kBottomRight:
      return {-1.0 * size.width(), -1.0 * size.height()};
    default:
      FML_UNREACHABLE();
  }
}

Point anchor_position_for(Rect const& rect, WindowPositioner::Anchor anchor) {
  switch (anchor) {
    case WindowPositioner::Anchor::kTopLeft:
      return rect.origin();
    case WindowPositioner::Anchor::kTop:
      return rect.origin() + Point{rect.width() / 2.0, 0.0};
    case WindowPositioner::Anchor::kTopRight:
      return rect.origin() + Point{rect.width(), 0.0};
    case WindowPositioner::Anchor::kLeft:
      return rect.origin() + Point{0.0, rect.height() / 2.0};
    case WindowPositioner::Anchor::kCenter:
      return rect.origin() + Point{rect.width() / 2.0, rect.height() / 2.0};
    case WindowPositioner::Anchor::kRight:
      return rect.origin() + Point{rect.width(), rect.height() / 2.0};
    case WindowPositioner::Anchor::kBottomLeft:
      return rect.origin() + Point{0.0, rect.height()};
    case WindowPositioner::Anchor::kBottom:
      return rect.origin() + Point{rect.width() / 2.0, rect.height()};
    case WindowPositioner::Anchor::kBottomRight:
      return rect.origin() + Point{rect.width(), rect.height()};
    default:
      FML_UNREACHABLE();
  }
}

Point constrain_to(Rect const& r, Point const& p) {
  return {std::clamp(p.x(), r.left(), r.left() + r.width()),
          std::clamp(p.y(), r.top(), r.top() + r.height())};
}

WindowPositioner::Anchor flip_anchor_x(WindowPositioner::Anchor anchor) {
  switch (anchor) {
    case WindowPositioner::Anchor::kTopLeft:
      return WindowPositioner::Anchor::kTopRight;
    case WindowPositioner::Anchor::kTopRight:
      return WindowPositioner::Anchor::kTopLeft;
    case WindowPositioner::Anchor::kLeft:
      return WindowPositioner::Anchor::kRight;
    case WindowPositioner::Anchor::kRight:
      return WindowPositioner::Anchor::kLeft;
    case WindowPositioner::Anchor::kBottomLeft:
      return WindowPositioner::Anchor::kBottomRight;
    case WindowPositioner::Anchor::kBottomRight:
      return WindowPositioner::Anchor::kBottomLeft;
    default:
      return anchor;
  }
}

WindowPositioner::Anchor flip_anchor_y(WindowPositioner::Anchor anchor) {
  switch (anchor) {
    case WindowPositioner::Anchor::kTopLeft:
      return WindowPositioner::Anchor::kBottomLeft;
    case WindowPositioner::Anchor::kTop:
      return WindowPositioner::Anchor::kBottom;
    case WindowPositioner::Anchor::kTopRight:
      return WindowPositioner::Anchor::kBottomRight;
    case WindowPositioner::Anchor::kBottomLeft:
      return WindowPositioner::Anchor::kTopLeft;
    case WindowPositioner::Anchor::kBottom:
      return WindowPositioner::Anchor::kTop;
    case WindowPositioner::Anchor::kBottomRight:
      return WindowPositioner::Anchor::kTopRight;
    default:
      return anchor;
  }
}

Point flip_offset_x(Point const& p) {
  return {-1.0 * p.x(), p.y()};
}

Point flip_offset_y(Point const& p) {
  return {p.x(), -1.0 * p.y()};
}

}  // namespace

Rect PlaceWindow(WindowPositioner const& positioner,
                 Size child_size,
                 Rect const& anchor_rect,
                 Rect const& parent_rect,
                 Rect const& output_rect) {
  Rect default_result;

  {
    Point const result =
        constrain_to(parent_rect, anchor_position_for(
                                      anchor_rect, positioner.parent_anchor) +
                                      positioner.offset) +
        offset_for(child_size, positioner.child_anchor);

    if (output_rect.contains({result, child_size})) {
      return Rect{result, child_size};
    }

    default_result = Rect{result, child_size};
  }

  if (static_cast<int>(positioner.constraint_adjustment) &
      static_cast<int>(WindowPositioner::ConstraintAdjustment::kFlipX)) {
    Point const result =
        constrain_to(parent_rect,
                     anchor_position_for(
                         anchor_rect, flip_anchor_x(positioner.parent_anchor)) +
                         flip_offset_x(positioner.offset)) +
        offset_for(child_size, flip_anchor_x(positioner.child_anchor));

    if (output_rect.contains({result, child_size})) {
      return Rect{result, child_size};
    }
  }

  if (static_cast<int>(positioner.constraint_adjustment) &
      static_cast<int>(WindowPositioner::ConstraintAdjustment::kFlipY)) {
    Point const result =
        constrain_to(parent_rect,
                     anchor_position_for(
                         anchor_rect, flip_anchor_y(positioner.parent_anchor)) +
                         flip_offset_y(positioner.offset)) +
        offset_for(child_size, flip_anchor_y(positioner.child_anchor));

    if (output_rect.contains({result, child_size})) {
      return Rect{result, child_size};
    }
  }

  if (static_cast<int>(positioner.constraint_adjustment) &
          static_cast<int>(WindowPositioner::ConstraintAdjustment::kFlipX) &&
      static_cast<int>(positioner.constraint_adjustment) &
          static_cast<int>(WindowPositioner::ConstraintAdjustment::kFlipY)) {
    Point const result =
        constrain_to(
            parent_rect,
            anchor_position_for(anchor_rect, flip_anchor_x(flip_anchor_y(
                                                 positioner.parent_anchor))) +
                flip_offset_x(flip_offset_y(positioner.offset))) +
        offset_for(child_size,
                   flip_anchor_x(flip_anchor_y(positioner.child_anchor)));

    if (output_rect.contains({result, child_size})) {
      return Rect{result, child_size};
    }
  }

  {
    Point result =
        constrain_to(parent_rect, anchor_position_for(
                                      anchor_rect, positioner.parent_anchor) +
                                      positioner.offset) +
        offset_for(child_size, positioner.child_anchor);

    if (static_cast<int>(positioner.constraint_adjustment) &
        static_cast<int>(WindowPositioner::ConstraintAdjustment::kSlideX)) {
      double const left_overhang = result.x() - output_rect.left();
      double const right_overhang = (result.x() + child_size.width()) -
                                    (output_rect.left() + output_rect.width());

      if (left_overhang < 0.0) {
        result = {result.x() - left_overhang, result.y()};
      } else if (right_overhang > 0.0) {
        result = {result.x() - right_overhang, result.y()};
      }
    }

    if (static_cast<int>(positioner.constraint_adjustment) &
        static_cast<int>(WindowPositioner::ConstraintAdjustment::kSlideY)) {
      double const top_overhang = result.y() - output_rect.top();
      double const bot_overhang = (result.y() + child_size.height()) -
                                  (output_rect.top() + output_rect.height());

      if (top_overhang < 0.0) {
        result = {result.x(), result.y() - top_overhang};
      } else if (bot_overhang > 0.0) {
        result = {result.x(), result.y() - bot_overhang};
      }
    }

    if (output_rect.contains({result, child_size})) {
      return Rect{result, child_size};
    }
  }

  {
    Point result =
        constrain_to(parent_rect, anchor_position_for(
                                      anchor_rect, positioner.parent_anchor) +
                                      positioner.offset) +
        offset_for(child_size, positioner.child_anchor);

    if (static_cast<int>(positioner.constraint_adjustment) &
        static_cast<int>(WindowPositioner::ConstraintAdjustment::kResizeX)) {
      double const left_overhang = result.x() - output_rect.left();
      double const right_overhang = (result.x() + child_size.width()) -
                                    (output_rect.left() + output_rect.width());

      if (left_overhang < 0.0) {
        result = {result.x() - left_overhang, result.y()};
        child_size = {child_size.width() + left_overhang, child_size.height()};
      }

      if (right_overhang > 0.0) {
        child_size = {child_size.width() - right_overhang, child_size.height()};
      }
    }

    if (static_cast<int>(positioner.constraint_adjustment) &
        static_cast<int>(WindowPositioner::ConstraintAdjustment::kResizeY)) {
      double const top_overhang = result.y() - output_rect.top();
      double const bot_overhang = (result.y() + child_size.height()) -
                                  (output_rect.top() + output_rect.height());

      if (top_overhang < 0.0) {
        result = {result.x(), result.y() - top_overhang};
        child_size = {child_size.width(), child_size.height() + top_overhang};
      }

      if (bot_overhang > 0.0) {
        child_size = {child_size.width(), child_size.height() - bot_overhang};
      }
    }

    if (output_rect.contains({result, child_size})) {
      return Rect{result, child_size};
    }
  }

  return default_result;
}

}  // namespace flutter
