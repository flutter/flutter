// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <optional>
#include <ostream>

#include "flutter/impeller/typographer/text_frame.h"

#include "flutter/testing/testing.h"
#include "gtest/gtest.h"

namespace std {

std::ostream& operator<<(std::ostream& out,
                         const impeller::StrokeParameters& params);
std::ostream& operator<<(std::ostream& out,
                         const impeller::GlyphProperties& properties);

template <typename T>
inline std::ostream& operator<<(std::ostream& out,
                                const std::optional<T>& opt) {
  if (opt.has_value()) {
    out << "std::optional(" << *opt << ")";
  } else {
    out << "std::nullopt";
  }
  return out;
}

inline std::ostream& operator<<(std::ostream& out,
                                const impeller::StrokeParameters& params) {
  out << "StrokeParameters {"
      << "width: " << params.width << ", "
      << "cap: " << static_cast<int>(params.cap) << ", "
      << "join: " << static_cast<int>(params.join) << ", "
      << "miter limit: " << params.miter_limit << "}";
  return out;
}

inline std::ostream& operator<<(std::ostream& out,
                                const impeller::GlyphProperties& properties) {
  out << "GlyphProperties {"       //
      << properties.color << ", "  //
      << properties.stroke << "}";
  return out;
}

inline std::ostream& operator<<(std::ostream& out,
                                const impeller::RenderTextFrame& frame) {
  out << "RenderTextFrame {" << std::boolalpha << std::endl
      << "  frame ptr: " << frame.GetFrame().get() << std::endl
      << "  scale: " << frame.GetScale() << std::endl
      << "  offset: " << frame.GetOffset() << std::endl
      << "  transform: " << frame.GetOffsetTransform() << std::endl
      << "  render_as_path: " << frame.ShouldRenderAsPath() << std::endl
      << "  properties index: " << frame.GetProperties() << std::endl
      << "}";
  return out;
}

template <typename T>
std::ostream& operator<<(std::ostream& out, const std::shared_ptr<T>& ptr) {
  out << "std::shared_ptr(" << (ptr ? *ptr : "nullptr") << ")";
  return out;
}

}  // namespace std

namespace impeller {
namespace testing {

TEST(TextFrameTest, RenderTextFrameMinimalConstructor) {
  std::shared_ptr<TextFrame> frame;
  RenderTextFrame render_frame(frame, Rational(100, 50), Point(10, 10));
  EXPECT_EQ(render_frame.GetFrame(), frame);
  EXPECT_EQ(render_frame.GetOffset(), Point(10, 10));
  EXPECT_EQ(render_frame.GetScale(), Rational(200, 100));
  EXPECT_EQ(render_frame.GetOffsetTransform(), Matrix());
  EXPECT_EQ(render_frame.ShouldRenderAsPath(), false);
  EXPECT_EQ(render_frame.GetProperties(), std::nullopt);
}

TEST(TextFrameTest, RenderTextFrameFullConstructor) {
  std::shared_ptr<TextFrame> frame;
  RenderTextFrame render_frame(
      frame, Rational(100, 50), Point(10, 10),
      Matrix::MakeScale({2.0f, 2.0f, 1.0f}),
      /*render_as_path=*/true,
      GlyphProperties{.color = Color::Beige(),
                      .stroke = StrokeParameters{.cap = Cap::kRound,    //
                                                 .join = Join::kBevel,  //
                                                 .miter_limit = 1.5f}});
  EXPECT_EQ(render_frame.GetFrame(), frame);
  EXPECT_EQ(render_frame.GetOffset(), Point(10, 10));
  EXPECT_EQ(render_frame.GetScale(), Rational(200, 100));
  EXPECT_EQ(render_frame.GetOffsetTransform(),
            Matrix::MakeScale({2.0f, 2.0f, 1.0f}));
  EXPECT_EQ(render_frame.ShouldRenderAsPath(), true);
  GlyphProperties expected_properties =
      GlyphProperties{.color = Color::Beige(),
                      .stroke = StrokeParameters{.cap = Cap::kRound,    //
                                                 .join = Join::kBevel,  //
                                                 .miter_limit = 1.5f}};
  EXPECT_EQ(render_frame.GetProperties(), expected_properties);
}

TEST(TextFrameTest, RenderTextFrameEqualsOperator) {
  std::vector<std::shared_ptr<TextFrame>> frames = {
      std::shared_ptr<TextFrame>(new TextFrame()),
      std::shared_ptr<TextFrame>(new TextFrame()),
  };
  std::vector<Rational> scales = {
      Rational(100, 50),
      Rational(150, 50),
  };
  std::vector<Point> offsets = {
      Point(10, 10),
      Point(20, 20),
  };
  std::vector<Matrix> offset_transforms = {
      Matrix::MakeScale({2.0f, 2.0f, 1.0f}),
      Matrix::MakeScale({3.0f, 3.0f, 1.0f}),
  };
  std::vector<bool> render_as_paths = {false, true};
  std::vector<std::optional<GlyphProperties>> properties = {
      GlyphProperties{.color = Color::Beige(),
                      .stroke = StrokeParameters{.cap = Cap::kRound,    //
                                                 .join = Join::kBevel,  //
                                                 .miter_limit = 1.5f}},
      GlyphProperties{.color = Color::Azure(),
                      .stroke = StrokeParameters{.cap = Cap::kSquare,   //
                                                 .join = Join::kMiter,  //
                                                 .miter_limit = 1.6f}},
      std::nullopt,
  };

  RenderTextFrame base_render_frame(frames[0], scales[0], offsets[0],
                                    offset_transforms[0], render_as_paths[0],
                                    properties[0]);
  EXPECT_EQ(base_render_frame, base_render_frame) << base_render_frame;

  bool first = true;
  for (size_t i_frame = 0; i_frame < frames.size(); i_frame++) {
    for (size_t i_scale = 0; i_scale < scales.size(); i_scale++) {
      for (size_t i_offset = 0; i_offset < offsets.size(); i_offset++) {
        for (size_t i_transform = 0; i_transform < offset_transforms.size();
             i_transform++) {
          for (size_t i_render = 0; i_render < render_as_paths.size();
               i_render++) {
            for (size_t i_properties = 0; i_properties < properties.size();
                 i_properties++) {
              RenderTextFrame test_frame(
                  frames[i_frame], scales[i_scale], offsets[i_offset],
                  offset_transforms[i_transform], render_as_paths[i_render],
                  properties[i_properties]);
              EXPECT_EQ(test_frame, test_frame) << test_frame;

              if (first) {
                EXPECT_EQ(test_frame, base_render_frame)
                    << "test frame: " << test_frame << std::endl
                    << "base frame: " << base_render_frame;
                // No other constructed test_frame after this one will have
                // all of the default values.
                first = false;
              } else {
                EXPECT_NE(test_frame, base_render_frame)
                    << "test frame: " << test_frame << std::endl
                    << "base frame: " << base_render_frame;
              }
            }
          }
        }
      }
    }
  }
}

}  // namespace testing
}  // namespace impeller
