// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/display_list/display_list_dispatcher.h"

#include <optional>
#include <unordered_map>

#include "display_list/display_list_blend_mode.h"
#include "display_list/display_list_color_filter.h"
#include "display_list/display_list_path_effect.h"
#include "display_list/display_list_tile_mode.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "impeller/display_list/display_list_image_impeller.h"
#include "impeller/display_list/nine_patch_converter.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"
#include "impeller/entity/contents/linear_gradient_contents.h"
#include "impeller/entity/contents/radial_gradient_contents.h"
#include "impeller/entity/contents/solid_stroke_contents.h"
#include "impeller/entity/contents/sweep_gradient_contents.h"
#include "impeller/entity/contents/tiled_texture_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/geometry/scalar.h"
#include "impeller/geometry/sigma.h"
#include "impeller/geometry/vertices.h"
#include "impeller/renderer/formats.h"
#include "impeller/typographer/backends/skia/text_frame_skia.h"

#include "third_party/skia/include/core/SkColor.h"

namespace impeller {

#define UNIMPLEMENTED \
  FML_DLOG(ERROR) << "Unimplemented detail in " << __FUNCTION__;

DisplayListDispatcher::DisplayListDispatcher() = default;

DisplayListDispatcher::~DisplayListDispatcher() = default;

static Entity::BlendMode ToBlendMode(flutter::DlBlendMode mode) {
  switch (mode) {
    case flutter::DlBlendMode::kClear:
      return Entity::BlendMode::kClear;
    case flutter::DlBlendMode::kSrc:
      return Entity::BlendMode::kSource;
    case flutter::DlBlendMode::kDst:
      return Entity::BlendMode::kDestination;
    case flutter::DlBlendMode::kSrcOver:
      return Entity::BlendMode::kSourceOver;
    case flutter::DlBlendMode::kDstOver:
      return Entity::BlendMode::kDestinationOver;
    case flutter::DlBlendMode::kSrcIn:
      return Entity::BlendMode::kSourceIn;
    case flutter::DlBlendMode::kDstIn:
      return Entity::BlendMode::kDestinationIn;
    case flutter::DlBlendMode::kSrcOut:
      return Entity::BlendMode::kSourceOut;
    case flutter::DlBlendMode::kDstOut:
      return Entity::BlendMode::kDestinationOut;
    case flutter::DlBlendMode::kSrcATop:
      return Entity::BlendMode::kSourceATop;
    case flutter::DlBlendMode::kDstATop:
      return Entity::BlendMode::kDestinationATop;
    case flutter::DlBlendMode::kXor:
      return Entity::BlendMode::kXor;
    case flutter::DlBlendMode::kPlus:
      return Entity::BlendMode::kPlus;
    case flutter::DlBlendMode::kModulate:
      return Entity::BlendMode::kModulate;
    case flutter::DlBlendMode::kScreen:
      return Entity::BlendMode::kScreen;
    case flutter::DlBlendMode::kOverlay:
      return Entity::BlendMode::kOverlay;
    case flutter::DlBlendMode::kDarken:
      return Entity::BlendMode::kDarken;
    case flutter::DlBlendMode::kLighten:
      return Entity::BlendMode::kLighten;
    case flutter::DlBlendMode::kColorDodge:
      return Entity::BlendMode::kColorDodge;
    case flutter::DlBlendMode::kColorBurn:
      return Entity::BlendMode::kColorBurn;
    case flutter::DlBlendMode::kHardLight:
      return Entity::BlendMode::kHardLight;
    case flutter::DlBlendMode::kSoftLight:
      return Entity::BlendMode::kSoftLight;
    case flutter::DlBlendMode::kDifference:
      return Entity::BlendMode::kDifference;
    case flutter::DlBlendMode::kExclusion:
      return Entity::BlendMode::kExclusion;
    case flutter::DlBlendMode::kMultiply:
      return Entity::BlendMode::kMultiply;
    case flutter::DlBlendMode::kHue:
      return Entity::BlendMode::kHue;
    case flutter::DlBlendMode::kSaturation:
      return Entity::BlendMode::kSaturation;
    case flutter::DlBlendMode::kColor:
      return Entity::BlendMode::kColor;
    case flutter::DlBlendMode::kLuminosity:
      return Entity::BlendMode::kLuminosity;
  }
  FML_UNREACHABLE();
}

static Entity::TileMode ToTileMode(flutter::DlTileMode tile_mode) {
  switch (tile_mode) {
    case flutter::DlTileMode::kClamp:
      return Entity::TileMode::kClamp;
    case flutter::DlTileMode::kRepeat:
      return Entity::TileMode::kRepeat;
    case flutter::DlTileMode::kMirror:
      return Entity::TileMode::kMirror;
    case flutter::DlTileMode::kDecal:
      return Entity::TileMode::kDecal;
  }
}

static impeller::SamplerDescriptor ToSamplerDescriptor(
    const flutter::DlImageSampling options) {
  impeller::SamplerDescriptor desc;
  switch (options) {
    case flutter::DlImageSampling::kNearestNeighbor:
      desc.min_filter = desc.mag_filter = impeller::MinMagFilter::kNearest;
      desc.label = "Nearest Sampler";
      break;
    case flutter::DlImageSampling::kLinear:
      desc.min_filter = desc.mag_filter = impeller::MinMagFilter::kLinear;
      desc.label = "Linear Sampler";
      break;
    case flutter::DlImageSampling::kMipmapLinear:
      desc.min_filter = desc.mag_filter = impeller::MinMagFilter::kLinear;
      desc.mip_filter = impeller::MipFilter::kLinear;
      desc.label = "Mipmap Linear Sampler";
      break;
    default:
      break;
  }
  return desc;
}

static impeller::SamplerDescriptor ToSamplerDescriptor(
    const flutter::DlFilterMode options) {
  impeller::SamplerDescriptor desc;
  switch (options) {
    case flutter::DlFilterMode::kNearest:
      desc.min_filter = desc.mag_filter = impeller::MinMagFilter::kNearest;
      desc.label = "Nearest Sampler";
      break;
    case flutter::DlFilterMode::kLinear:
      desc.min_filter = desc.mag_filter = impeller::MinMagFilter::kLinear;
      desc.label = "Linear Sampler";
      break;
    default:
      break;
  }
  return desc;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setAntiAlias(bool aa) {
  // Nothing to do because AA is implicit.
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setDither(bool dither) {}

static Paint::Style ToStyle(flutter::DlDrawStyle style) {
  switch (style) {
    case flutter::DlDrawStyle::kFill:
      return Paint::Style::kFill;
    case flutter::DlDrawStyle::kStroke:
      return Paint::Style::kStroke;
    case flutter::DlDrawStyle::kStrokeAndFill:
      UNIMPLEMENTED;
      break;
  }
  return Paint::Style::kFill;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setStyle(flutter::DlDrawStyle style) {
  paint_.style = ToStyle(style);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setColor(flutter::DlColor color) {
  paint_.color = {
      color.getRedF(),
      color.getGreenF(),
      color.getBlueF(),
      color.getAlphaF(),
  };
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setStrokeWidth(SkScalar width) {
  paint_.stroke_width = width;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setStrokeMiter(SkScalar limit) {
  paint_.stroke_miter = limit;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setStrokeCap(flutter::DlStrokeCap cap) {
  switch (cap) {
    case flutter::DlStrokeCap::kButt:
      paint_.stroke_cap = SolidStrokeContents::Cap::kButt;
      break;
    case flutter::DlStrokeCap::kRound:
      paint_.stroke_cap = SolidStrokeContents::Cap::kRound;
      break;
    case flutter::DlStrokeCap::kSquare:
      paint_.stroke_cap = SolidStrokeContents::Cap::kSquare;
      break;
  }
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setStrokeJoin(flutter::DlStrokeJoin join) {
  switch (join) {
    case flutter::DlStrokeJoin::kMiter:
      paint_.stroke_join = SolidStrokeContents::Join::kMiter;
      break;
    case flutter::DlStrokeJoin::kRound:
      paint_.stroke_join = SolidStrokeContents::Join::kRound;
      break;
    case flutter::DlStrokeJoin::kBevel:
      paint_.stroke_join = SolidStrokeContents::Join::kBevel;
      break;
  }
}

static Point ToPoint(const SkPoint& point) {
  return Point::MakeXY(point.fX, point.fY);
}

static Color ToColor(const SkColor& color) {
  return {
      static_cast<Scalar>(SkColorGetR(color) / 255.0),  //
      static_cast<Scalar>(SkColorGetG(color) / 255.0),  //
      static_cast<Scalar>(SkColorGetB(color) / 255.0),  //
      static_cast<Scalar>(SkColorGetA(color) / 255.0)   //
  };
}

static std::vector<Color> ToColors(const flutter::DlColor colors[], int count) {
  auto result = std::vector<Color>();
  if (colors == nullptr) {
    return result;
  }
  for (int i = 0; i < count; i++) {
    result.push_back(ToColor(colors[i]));
  }
  return result;
}

static std::vector<Matrix> ToRSXForms(const SkRSXform xform[], int count) {
  auto result = std::vector<Matrix>();
  for (int i = 0; i < count; i++) {
    auto form = xform[i];
    // clang-format off
    auto matrix = Matrix{
      form.fSCos, form.fSSin, 0, 0,
     -form.fSSin, form.fSCos, 0, 0,
      0,          0,          1, 0,
      form.fTx,   form.fTy,   0, 1
    };
    // clang-format on
    result.push_back(matrix);
  }
  return result;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setColorSource(
    const flutter::DlColorSource* source) {
  if (!source) {
    paint_.color_source = std::nullopt;
    return;
  }

  switch (source->type()) {
    case flutter::DlColorSourceType::kColor: {
      const flutter::DlColorColorSource* color = source->asColor();
      paint_.color_source = std::nullopt;
      setColor(color->color());
      FML_DCHECK(color);
      return;
    }
    case flutter::DlColorSourceType::kLinearGradient: {
      const flutter::DlLinearGradientColorSource* linear =
          source->asLinearGradient();
      FML_DCHECK(linear);
      auto start_point = ToPoint(linear->start_point());
      auto end_point = ToPoint(linear->end_point());
      std::vector<Color> colors;
      for (auto i = 0; i < linear->stop_count(); i++) {
        colors.emplace_back(ToColor(linear->colors()[i]));
      }
      auto tile_mode = ToTileMode(linear->tile_mode());
      paint_.color_source = [start_point, end_point, colors = std::move(colors),
                             tile_mode]() {
        auto contents = std::make_shared<LinearGradientContents>();
        contents->SetEndPoints(start_point, end_point);
        contents->SetColors(std::move(colors));
        contents->SetTileMode(tile_mode);
        return contents;
      };
      return;
    }
    case flutter::DlColorSourceType::kRadialGradient: {
      const flutter::DlRadialGradientColorSource* radialGradient =
          source->asRadialGradient();
      FML_DCHECK(radialGradient);
      auto center = ToPoint(radialGradient->center());
      auto radius = radialGradient->radius();
      std::vector<Color> colors;
      for (auto i = 0; i < radialGradient->stop_count(); i++) {
        colors.emplace_back(ToColor(radialGradient->colors()[i]));
      }
      auto tile_mode = ToTileMode(radialGradient->tile_mode());
      paint_.color_source = [center, radius, colors = std::move(colors),
                             tile_mode]() {
        auto contents = std::make_shared<RadialGradientContents>();
        contents->SetCenterAndRadius(center, radius),
            contents->SetColors(std::move(colors));
        contents->SetTileMode(tile_mode);
        return contents;
      };
      return;
    }
    case flutter::DlColorSourceType::kSweepGradient: {
      const flutter::DlSweepGradientColorSource* sweepGradient =
          source->asSweepGradient();
      FML_DCHECK(sweepGradient);

      auto center = ToPoint(sweepGradient->center());
      auto start_angle = Degrees(sweepGradient->start());
      auto end_angle = Degrees(sweepGradient->end());
      std::vector<Color> colors;
      for (auto i = 0; i < sweepGradient->stop_count(); i++) {
        colors.emplace_back(ToColor(sweepGradient->colors()[i]));
      }
      auto tile_mode = ToTileMode(sweepGradient->tile_mode());
      paint_.color_source = [center, start_angle, end_angle,
                             colors = std::move(colors), tile_mode]() {
        auto contents = std::make_shared<SweepGradientContents>();
        contents->SetCenterAndAngles(center, start_angle, end_angle);
        contents->SetColors(std::move(colors));
        contents->SetTileMode(tile_mode);
        return contents;
      };
      return;
    }
    case flutter::DlColorSourceType::kImage: {
      const flutter::DlImageColorSource* image_color_source = source->asImage();
      FML_DCHECK(image_color_source &&
                 image_color_source->image()->impeller_texture());
      auto texture = image_color_source->image()->impeller_texture();
      auto x_tile_mode = ToTileMode(image_color_source->horizontal_tile_mode());
      auto y_tile_mode = ToTileMode(image_color_source->vertical_tile_mode());
      auto desc = ToSamplerDescriptor(image_color_source->sampling());
      paint_.color_source = [texture, x_tile_mode, y_tile_mode, desc]() {
        auto contents = std::make_shared<TiledTextureContents>();
        contents->SetTexture(texture);
        contents->SetTileModes(x_tile_mode, y_tile_mode);
        contents->SetSamplerDescriptor(desc);
        // TODO(109384) Support 'matrix' parameter for all color sources.
        return contents;
      };
      return;
    }
    case flutter::DlColorSourceType::kConicalGradient:
    case flutter::DlColorSourceType::kUnknown:
      UNIMPLEMENTED;
      break;
  }

  // Needs https://github.com/flutter/flutter/issues/95434
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setColorFilter(
    const flutter::DlColorFilter* filter) {
  // Needs https://github.com/flutter/flutter/issues/95434
  if (filter == nullptr) {
    // Reset everything
    paint_.color_filter = std::nullopt;
    return;
  }
  switch (filter->type()) {
    case flutter::DlColorFilterType::kBlend: {
      auto dl_blend = filter->asBlend();

      auto blend_mode = ToBlendMode(dl_blend->mode());
      auto color = ToColor(dl_blend->color());

      paint_.color_filter = [blend_mode, color](FilterInput::Ref input) {
        return FilterContents::MakeBlend(blend_mode, {input}, color);
      };
      return;
    }
    case flutter::DlColorFilterType::kMatrix: {
      const flutter::DlMatrixColorFilter* dl_matrix = filter->asMatrix();
      impeller::FilterContents::ColorMatrix color_matrix;
      dl_matrix->get_matrix(color_matrix.array);
      paint_.color_filter = [color_matrix](FilterInput::Ref input) {
        return FilterContents::MakeColorMatrix({input}, color_matrix);
      };
      return;
    }
    case flutter::DlColorFilterType::kSrgbToLinearGamma:
      FML_LOG(ERROR) << "requested DlColorFilterType::kSrgbToLinearGamma";
      UNIMPLEMENTED;
      break;
    case flutter::DlColorFilterType::kLinearToSrgbGamma:
      FML_LOG(ERROR) << "requested DlColorFilterType::kLinearToSrgbGamma";
      UNIMPLEMENTED;
      break;
    case flutter::DlColorFilterType::kUnknown:
      FML_LOG(ERROR) << "requested DlColorFilterType::kUnknown";
      UNIMPLEMENTED;
      break;
  }
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setInvertColors(bool invert) {
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setBlendMode(flutter::DlBlendMode dl_mode) {
  paint_.blend_mode = ToBlendMode(dl_mode);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setBlender(sk_sp<SkBlender> blender) {
  // Needs https://github.com/flutter/flutter/issues/95434
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setPathEffect(const flutter::DlPathEffect* effect) {
  // Needs https://github.com/flutter/flutter/issues/95434
  UNIMPLEMENTED;
}

static FilterContents::BlurStyle ToBlurStyle(SkBlurStyle blur_style) {
  switch (blur_style) {
    case kNormal_SkBlurStyle:
      return FilterContents::BlurStyle::kNormal;
    case kSolid_SkBlurStyle:
      return FilterContents::BlurStyle::kSolid;
    case kOuter_SkBlurStyle:
      return FilterContents::BlurStyle::kOuter;
    case kInner_SkBlurStyle:
      return FilterContents::BlurStyle::kInner;
  }
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setMaskFilter(const flutter::DlMaskFilter* filter) {
  // Needs https://github.com/flutter/flutter/issues/95434
  if (filter == nullptr) {
    paint_.mask_blur_descriptor = std::nullopt;
    return;
  }
  switch (filter->type()) {
    case flutter::DlMaskFilterType::kBlur: {
      auto blur = filter->asBlur();

      paint_.mask_blur_descriptor = {
          .style = ToBlurStyle(blur->style()),
          .sigma = Sigma(blur->sigma()),
      };
      break;
    }
    case flutter::DlMaskFilterType::kUnknown:
      UNIMPLEMENTED;
      break;
  }
}

static std::optional<Paint::ImageFilterProc> ToImageFilterProc(
    const flutter::DlImageFilter* filter,
    const Vector2& effect_scale = {1, 1}) {
  if (filter == nullptr) {
    return std::nullopt;
  }

  switch (filter->type()) {
    case flutter::DlImageFilterType::kBlur: {
      auto blur = filter->asBlur();
      Vector2 scaled_blur =
          Vector2(blur->sigma_x(), blur->sigma_y()) * effect_scale;
      auto sigma_x = Sigma(scaled_blur.x);
      auto sigma_y = Sigma(scaled_blur.y);
      auto tile_mode = ToTileMode(blur->tile_mode());

      return [sigma_x, sigma_y, tile_mode](FilterInput::Ref input) {
        return FilterContents::MakeGaussianBlur(
            input, sigma_x, sigma_y, FilterContents::BlurStyle::kNormal,
            tile_mode);
      };

      break;
    }
    case flutter::DlImageFilterType::kDilate:
    case flutter::DlImageFilterType::kErode:
    case flutter::DlImageFilterType::kMatrix:
    case flutter::DlImageFilterType::kLocalMatrixFilter:
    case flutter::DlImageFilterType::kComposeFilter:
    case flutter::DlImageFilterType::kColorFilter:
    case flutter::DlImageFilterType::kUnknown:
      return std::nullopt;
  }
}

// |flutter::Dispatcher|
void DisplayListDispatcher::setImageFilter(
    const flutter::DlImageFilter* filter) {
  paint_.image_filter = ToImageFilterProc(filter);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::save() {
  canvas_.Save();
}

static std::optional<Rect> ToRect(const SkRect* rect) {
  if (rect == nullptr) {
    return std::nullopt;
  }
  return Rect::MakeLTRB(rect->fLeft, rect->fTop, rect->fRight, rect->fBottom);
}

static std::vector<Rect> ToRects(const SkRect tex[], int count) {
  auto result = std::vector<Rect>();
  for (int i = 0; i < count; i++) {
    result.push_back(ToRect(&tex[i]).value());
  }
  return result;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::saveLayer(const SkRect* bounds,
                                      const flutter::SaveLayerOptions options,
                                      const flutter::DlImageFilter* backdrop) {
  auto paint = options.renders_with_attributes() ? paint_ : Paint{};
  auto scale = canvas_.GetCurrentTransformation().GetScale();
  canvas_.SaveLayer(
      paint, ToRect(bounds),
      ToImageFilterProc(backdrop, Vector2::MakeXY(scale.x, scale.y)));
}

// |flutter::Dispatcher|
void DisplayListDispatcher::restore() {
  canvas_.Restore();
}

// |flutter::Dispatcher|
void DisplayListDispatcher::translate(SkScalar tx, SkScalar ty) {
  canvas_.Translate({tx, ty, 0.0});
}

// |flutter::Dispatcher|
void DisplayListDispatcher::scale(SkScalar sx, SkScalar sy) {
  canvas_.Scale({sx, sy, 1.0});
}

// |flutter::Dispatcher|
void DisplayListDispatcher::rotate(SkScalar degrees) {
  canvas_.Rotate(Degrees{degrees});
}

// |flutter::Dispatcher|
void DisplayListDispatcher::skew(SkScalar sx, SkScalar sy) {
  canvas_.Skew(sx, sy);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::transform2DAffine(SkScalar mxx,
                                              SkScalar mxy,
                                              SkScalar mxt,
                                              SkScalar myx,
                                              SkScalar myy,
                                              SkScalar myt) {
  // clang-format off
  transformFullPerspective(
    mxx, mxy,  0, mxt,
    myx, myy,  0, myt,
    0  ,   0,  1,   0,
    0  ,   0,  0,   1
  );
  // clang-format on
}

// |flutter::Dispatcher|
void DisplayListDispatcher::transformFullPerspective(SkScalar mxx,
                                                     SkScalar mxy,
                                                     SkScalar mxz,
                                                     SkScalar mxt,
                                                     SkScalar myx,
                                                     SkScalar myy,
                                                     SkScalar myz,
                                                     SkScalar myt,
                                                     SkScalar mzx,
                                                     SkScalar mzy,
                                                     SkScalar mzz,
                                                     SkScalar mzt,
                                                     SkScalar mwx,
                                                     SkScalar mwy,
                                                     SkScalar mwz,
                                                     SkScalar mwt) {
  // The order of arguments is row-major but Impeller matrices are column-major.
  // clang-format off
  auto xformation = Matrix{
    mxx, myx, mzx, mwx,
    mxy, myy, mzy, mwy,
    mxz, myz, mzz, mwz,
    mxt, myt, mzt, mwt
  };
  // clang-format on
  canvas_.Transform(xformation);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::transformReset() {
  canvas_.ResetTransform();
}

static Rect ToRect(const SkRect& rect) {
  return Rect::MakeLTRB(rect.fLeft, rect.fTop, rect.fRight, rect.fBottom);
}

static Entity::ClipOperation ToClipOperation(SkClipOp clip_op) {
  switch (clip_op) {
    case SkClipOp::kDifference:
      return Entity::ClipOperation::kDifference;
    case SkClipOp::kIntersect:
      return Entity::ClipOperation::kIntersect;
  }
}

// |flutter::Dispatcher|
void DisplayListDispatcher::clipRect(const SkRect& rect,
                                     SkClipOp clip_op,
                                     bool is_aa) {
  auto path = PathBuilder{}.AddRect(ToRect(rect)).TakePath();
  canvas_.ClipPath(std::move(path), ToClipOperation(clip_op));
}

static PathBuilder::RoundingRadii ToRoundingRadii(const SkRRect& rrect) {
  using Corner = SkRRect::Corner;
  PathBuilder::RoundingRadii radii;
  radii.bottom_left = ToPoint(rrect.radii(Corner::kLowerLeft_Corner));
  radii.bottom_right = ToPoint(rrect.radii(Corner::kLowerRight_Corner));
  radii.top_left = ToPoint(rrect.radii(Corner::kUpperLeft_Corner));
  radii.top_right = ToPoint(rrect.radii(Corner::kUpperRight_Corner));
  return radii;
}

static Path ToPath(const SkPath& path) {
  auto iterator = SkPath::Iter(path, false);

  struct PathData {
    union {
      SkPoint points[4];
    };
  };

  PathBuilder builder;
  PathData data;
  auto verb = SkPath::Verb::kDone_Verb;
  do {
    verb = iterator.next(data.points);
    switch (verb) {
      case SkPath::kMove_Verb:
        builder.MoveTo(ToPoint(data.points[0]));
        break;
      case SkPath::kLine_Verb:
        builder.LineTo(ToPoint(data.points[1]));
        break;
      case SkPath::kQuad_Verb:
        builder.QuadraticCurveTo(ToPoint(data.points[1]),
                                 ToPoint(data.points[2]));
        break;
      case SkPath::kConic_Verb: {
        constexpr auto kPow2 = 1;  // Only works for sweeps up to 90 degrees.
        constexpr auto kQuadCount = 1 + (2 * (1 << kPow2));
        SkPoint points[kQuadCount];
        const auto curve_count =
            SkPath::ConvertConicToQuads(data.points[0],          //
                                        data.points[1],          //
                                        data.points[2],          //
                                        iterator.conicWeight(),  //
                                        points,                  //
                                        kPow2                    //
            );

        for (int curve_index = 0, point_index = 0;  //
             curve_index < curve_count;             //
             curve_index++, point_index += 2        //
        ) {
          builder.QuadraticCurveTo(ToPoint(points[point_index + 1]),
                                   ToPoint(points[point_index + 2]));
        }
      } break;
      case SkPath::kCubic_Verb:
        builder.CubicCurveTo(ToPoint(data.points[1]), ToPoint(data.points[2]),
                             ToPoint(data.points[3]));
        break;
      case SkPath::kClose_Verb:
        builder.Close();
        break;
      case SkPath::kDone_Verb:
        break;
    }
  } while (verb != SkPath::Verb::kDone_Verb);

  FillType fill_type;
  switch (path.getFillType()) {
    case SkPathFillType::kWinding:
      fill_type = FillType::kNonZero;
      break;
    case SkPathFillType::kEvenOdd:
      fill_type = FillType::kOdd;
      break;
    case SkPathFillType::kInverseWinding:
    case SkPathFillType::kInverseEvenOdd:
      // TODO(104848): Support the inverse winding modes.
      UNIMPLEMENTED;
      fill_type = FillType::kNonZero;
      break;
  }
  return builder.TakePath(fill_type);
}

static Path ToPath(const SkRRect& rrect) {
  return PathBuilder{}
      .AddRoundedRect(ToRect(rrect.getBounds()), ToRoundingRadii(rrect))
      .TakePath();
}

static Vertices ToVertices(const flutter::DlVertices* vertices) {
  std::vector<Point> points;
  std::vector<uint16_t> indices;
  std::vector<Color> colors;
  for (int i = 0; i < vertices->vertex_count(); i++) {
    auto point = vertices->vertices()[i];
    points.push_back(Point(point.x(), point.y()));
  }
  for (int i = 0; i < vertices->index_count(); i++) {
    auto index = vertices->indices()[i];
    indices.push_back(index);
  }

  auto* dl_colors = vertices->colors();
  if (dl_colors != nullptr) {
    auto color_length = vertices->index_count() > 0 ? vertices->index_count()
                                                    : vertices->vertex_count();
    for (int i = 0; i < color_length; i++) {
      auto dl_color = dl_colors[i];
      colors.push_back({
          dl_color.getRedF(),
          dl_color.getGreenF(),
          dl_color.getBlueF(),
          dl_color.getAlphaF(),
      });
    }
  }
  VertexMode mode;
  switch (vertices->mode()) {
    case flutter::DlVertexMode::kTriangles:
      mode = VertexMode::kTriangle;
      break;
    case flutter::DlVertexMode::kTriangleStrip:
      mode = VertexMode::kTriangleStrip;
      break;
    case flutter::DlVertexMode::kTriangleFan:
      FML_DLOG(ERROR) << "Unimplemented vertex mode TriangleFan in "
                      << __FUNCTION__;
      mode = VertexMode::kTriangle;
      break;
  }

  auto bounds = vertices->bounds();
  return Vertices(std::move(points), std::move(indices), std::move(colors),
                  mode, ToRect(bounds));
}

// |flutter::Dispatcher|
void DisplayListDispatcher::clipRRect(const SkRRect& rrect,
                                      SkClipOp clip_op,
                                      bool is_aa) {
  canvas_.ClipPath(ToPath(rrect), ToClipOperation(clip_op));
}

// |flutter::Dispatcher|
void DisplayListDispatcher::clipPath(const SkPath& path,
                                     SkClipOp clip_op,
                                     bool is_aa) {
  canvas_.ClipPath(ToPath(path), ToClipOperation(clip_op));
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawColor(flutter::DlColor color,
                                      flutter::DlBlendMode dl_mode) {
  Paint paint;
  paint.color = ToColor(color);
  paint.blend_mode = ToBlendMode(dl_mode);
  canvas_.DrawPaint(paint);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawPaint() {
  canvas_.DrawPaint(paint_);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawLine(const SkPoint& p0, const SkPoint& p1) {
  auto path = PathBuilder{}.AddLine(ToPoint(p0), ToPoint(p1)).TakePath();
  Paint paint = paint_;
  paint.style = Paint::Style::kStroke;
  canvas_.DrawPath(std::move(path), std::move(paint));
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawRect(const SkRect& rect) {
  canvas_.DrawRect(ToRect(rect), paint_);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawOval(const SkRect& bounds) {
  auto path = PathBuilder{}.AddOval(ToRect(bounds)).TakePath();
  canvas_.DrawPath(std::move(path), paint_);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawCircle(const SkPoint& center, SkScalar radius) {
  auto path = PathBuilder{}.AddCircle(ToPoint(center), radius).TakePath();
  canvas_.DrawPath(std::move(path), paint_);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawRRect(const SkRRect& rrect) {
  if (rrect.isSimple()) {
    canvas_.DrawRRect(ToRect(rrect.rect()), rrect.getSimpleRadii().fX, paint_);
  } else {
    canvas_.DrawPath(ToPath(rrect), paint_);
  }
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawDRRect(const SkRRect& outer,
                                       const SkRRect& inner) {
  PathBuilder builder;
  builder.AddPath(ToPath(outer));
  builder.AddPath(ToPath(inner));
  canvas_.DrawPath(builder.TakePath(FillType::kOdd), paint_);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawPath(const SkPath& path) {
  canvas_.DrawPath(ToPath(path), paint_);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawArc(const SkRect& oval_bounds,
                                    SkScalar start_degrees,
                                    SkScalar sweep_degrees,
                                    bool use_center) {
  PathBuilder builder;
  builder.AddArc(ToRect(oval_bounds), Degrees(start_degrees),
                 Degrees(sweep_degrees), use_center);
  canvas_.DrawPath(builder.TakePath(), paint_);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawPoints(SkCanvas::PointMode mode,
                                       uint32_t count,
                                       const SkPoint points[]) {
  Paint paint = paint_;
  paint.style = Paint::Style::kStroke;
  switch (mode) {
    case SkCanvas::kPoints_PointMode:
      if (paint.stroke_cap == SolidStrokeContents::Cap::kButt) {
        paint.stroke_cap = SolidStrokeContents::Cap::kSquare;
      }
      for (uint32_t i = 0; i < count; i++) {
        Point p0 = ToPoint(points[i]);
        auto path = PathBuilder{}.AddLine(p0, p0).TakePath();
        canvas_.DrawPath(std::move(path), paint);
      }
      break;
    case SkCanvas::kLines_PointMode:
      for (uint32_t i = 1; i < count; i += 2) {
        Point p0 = ToPoint(points[i - 1]);
        Point p1 = ToPoint(points[i]);
        auto path = PathBuilder{}.AddLine(p0, p1).TakePath();
        canvas_.DrawPath(std::move(path), paint);
      }
      break;
    case SkCanvas::kPolygon_PointMode:
      if (count > 1) {
        Point p0 = ToPoint(points[0]);
        for (uint32_t i = 1; i < count; i++) {
          Point p1 = ToPoint(points[i]);
          auto path = PathBuilder{}.AddLine(p0, p1).TakePath();
          canvas_.DrawPath(std::move(path), paint);
          p0 = p1;
        }
      }
      break;
  }
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawSkVertices(const sk_sp<SkVertices> vertices,
                                           SkBlendMode mode) {
  // Needs https://github.com/flutter/flutter/issues/95434
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawVertices(const flutter::DlVertices* vertices,
                                         flutter::DlBlendMode dl_mode) {
  canvas_.DrawVertices(ToVertices(vertices), ToBlendMode(dl_mode), paint_);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawImage(const sk_sp<flutter::DlImage> image,
                                      const SkPoint point,
                                      flutter::DlImageSampling sampling,
                                      bool render_with_attributes) {
  if (!image) {
    return;
  }

  auto texture = image->impeller_texture();
  if (!texture) {
    return;
  }

  const auto size = texture->GetSize();
  const auto src = SkRect::MakeWH(size.width, size.height);
  const auto dest =
      SkRect::MakeXYWH(point.fX, point.fY, size.width, size.height);

  drawImageRect(
      image,                   // image
      src,                     // source rect
      dest,                    // destination rect
      sampling,                // sampling options
      render_with_attributes,  // render with attributes
      SkCanvas::SrcRectConstraint::kStrict_SrcRectConstraint  // constraint
  );
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawImageRect(
    const sk_sp<flutter::DlImage> image,
    const SkRect& src,
    const SkRect& dst,
    flutter::DlImageSampling sampling,
    bool render_with_attributes,
    SkCanvas::SrcRectConstraint constraint) {
  canvas_.DrawImageRect(
      std::make_shared<Image>(image->impeller_texture()),  // image
      ToRect(src),                                         // source rect
      ToRect(dst),                                         // destination rect
      paint_,                                              // paint
      ToSamplerDescriptor(sampling)                        // sampling
  );
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawImageNine(const sk_sp<flutter::DlImage> image,
                                          const SkIRect& center,
                                          const SkRect& dst,
                                          flutter::DlFilterMode filter,
                                          bool render_with_attributes) {
  NinePatchConverter converter = {};
  converter.DrawNinePatch(
      std::make_shared<Image>(image->impeller_texture()),
      Rect::MakeLTRB(center.fLeft, center.fTop, center.fRight, center.fBottom),
      ToRect(dst), ToSamplerDescriptor(filter), &canvas_, &paint_);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawImageLattice(
    const sk_sp<flutter::DlImage> image,
    const SkCanvas::Lattice& lattice,
    const SkRect& dst,
    flutter::DlFilterMode filter,
    bool render_with_attributes) {
  // Needs https://github.com/flutter/flutter/issues/95434
  // Don't implement this one since it is not exposed by flutter,
  // Skia internally converts calls to drawImageNine into this method,
  // which is then converted back to drawImageNine by display list.
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawAtlas(const sk_sp<flutter::DlImage> atlas,
                                      const SkRSXform xform[],
                                      const SkRect tex[],
                                      const flutter::DlColor colors[],
                                      int count,
                                      flutter::DlBlendMode mode,
                                      flutter::DlImageSampling sampling,
                                      const SkRect* cull_rect,
                                      bool render_with_attributes) {
  canvas_.DrawAtlas(std::make_shared<Image>(atlas->impeller_texture()),
                    ToRSXForms(xform, count), ToRects(tex, count),
                    ToColors(colors, count), ToBlendMode(mode),
                    ToSamplerDescriptor(sampling), ToRect(cull_rect), paint_);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawPicture(const sk_sp<SkPicture> picture,
                                        const SkMatrix* matrix,
                                        bool render_with_attributes) {
  // Needs https://github.com/flutter/flutter/issues/95434
  UNIMPLEMENTED;
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawDisplayList(
    const sk_sp<flutter::DisplayList> display_list) {
  int saveCount = canvas_.GetSaveCount();
  Paint savePaint = paint_;
  paint_ = Paint();
  display_list->Dispatch(*this);
  paint_ = savePaint;
  canvas_.RestoreToCount(saveCount);
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawTextBlob(const sk_sp<SkTextBlob> blob,
                                         SkScalar x,
                                         SkScalar y) {
  Scalar scale = canvas_.GetCurrentTransformation().GetMaxBasisLength();
  canvas_.DrawTextFrame(TextFrameFromTextBlob(blob, scale),  //
                        impeller::Point{x, y},               //
                        paint_                               //
  );
}

// |flutter::Dispatcher|
void DisplayListDispatcher::drawShadow(const SkPath& path,
                                       const flutter::DlColor color,
                                       const SkScalar elevation,
                                       bool transparent_occluder,
                                       SkScalar dpr) {
  UNIMPLEMENTED;
}

Picture DisplayListDispatcher::EndRecordingAsPicture() {
  TRACE_EVENT0("impeller", "DisplayListDispatcher::EndRecordingAsPicture");
  return canvas_.EndRecordingAsPicture();
}

}  // namespace impeller
