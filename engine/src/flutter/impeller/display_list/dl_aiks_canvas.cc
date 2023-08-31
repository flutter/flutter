// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/display_list/dl_aiks_canvas.h"

#include <algorithm>
#include <cstring>
#include <memory>
#include <optional>
#include <unordered_map>
#include <utility>
#include <vector>

#include "display_list/dl_paint.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "impeller/aiks/color_filter.h"
#include "impeller/core/formats.h"
#include "impeller/display_list/dl_image_impeller.h"
#include "impeller/display_list/dl_vertices_geometry.h"
#include "impeller/display_list/nine_patch_converter.h"
#include "impeller/display_list/skia_conversions.h"
#include "impeller/entity/contents/conical_gradient_contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"
#include "impeller/entity/contents/linear_gradient_contents.h"
#include "impeller/entity/contents/radial_gradient_contents.h"
#include "impeller/entity/contents/runtime_effect_contents.h"
#include "impeller/entity/contents/sweep_gradient_contents.h"
#include "impeller/entity/contents/tiled_texture_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/geometry/scalar.h"
#include "impeller/geometry/sigma.h"
#include "impeller/typographer/backends/skia/text_frame_skia.h"

#if IMPELLER_ENABLE_3D
#include "impeller/entity/contents/scene_contents.h"  // nogncheck
#endif                                                // IMPELLER_ENABLE_3D

namespace impeller {

#define UNIMPLEMENTED \
  FML_DLOG(ERROR) << "Unimplemented detail in " << __FUNCTION__;

DlAiksCanvas::DlAiksCanvas(const SkRect& cull_rect, bool prepare_rtree)
    : canvas_(skia_conversions::ToRect(cull_rect)) {
  if (prepare_rtree) {
    accumulator_ = std::make_unique<flutter::RTreeBoundsAccumulator>();
  }
}

DlAiksCanvas::DlAiksCanvas(const SkIRect& cull_rect, bool prepare_rtree)
    : DlAiksCanvas(SkRect::Make(cull_rect), prepare_rtree) {}

DlAiksCanvas::~DlAiksCanvas() = default;

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

static Cap ToStrokeCap(flutter::DlStrokeCap cap) {
  switch (cap) {
    case flutter::DlStrokeCap::kButt:
      return Cap::kButt;
    case flutter::DlStrokeCap::kRound:
      return Cap::kRound;
    case flutter::DlStrokeCap::kSquare:
      return Cap::kSquare;
  }
  FML_UNREACHABLE();
}

static Matrix ToMatrix(const SkMatrix& m) {
  return Matrix{
      // clang-format off
      m[0], m[3], 0, m[6],
      m[1], m[4], 0, m[7],
      0,    0,    1, 0,
      m[2], m[5], 0, m[8],
      // clang-format on
  };
}

static Matrix ToMatrix(const SkM44& m) {
  return Matrix{
      // clang-format off
      m.rc(0, 0), m.rc(1, 0), m.rc(2, 0), m.rc(3, 0),
      m.rc(0, 1), m.rc(1, 1), m.rc(2, 1), m.rc(3, 1),
      m.rc(0, 2), m.rc(1, 2), m.rc(2, 2), m.rc(3, 2),
      m.rc(0, 3), m.rc(1, 3), m.rc(2, 3), m.rc(3, 3),
      // clang-format on
  };
}

static Join ToStrokeJoin(flutter::DlStrokeJoin join) {
  switch (join) {
    case flutter::DlStrokeJoin::kMiter:
      return Join::kMiter;
    case flutter::DlStrokeJoin::kRound:
      return Join::kRound;
    case flutter::DlStrokeJoin::kBevel:
      return Join::kBevel;
  }
  FML_UNREACHABLE();
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
    // Impeller doesn't support cubic sampling, but linear is closer to correct
    // than nearest for this case.
    case flutter::DlImageSampling::kCubic:
      desc.min_filter = desc.mag_filter = impeller::MinMagFilter::kLinear;
      desc.label = "Linear Sampler";
      break;
    case flutter::DlImageSampling::kMipmapLinear:
      desc.min_filter = desc.mag_filter = impeller::MinMagFilter::kLinear;
      desc.mip_filter = impeller::MipFilter::kLinear;
      desc.label = "Mipmap Linear Sampler";
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

static FilterContents::BlurStyle ToBlurStyle(flutter::DlBlurStyle blur_style) {
  switch (blur_style) {
    case flutter::DlBlurStyle::kNormal:
      return FilterContents::BlurStyle::kNormal;
    case flutter::DlBlurStyle::kSolid:
      return FilterContents::BlurStyle::kSolid;
    case flutter::DlBlurStyle::kOuter:
      return FilterContents::BlurStyle::kOuter;
    case flutter::DlBlurStyle::kInner:
      return FilterContents::BlurStyle::kInner;
  }
}

static std::optional<Paint::MaskBlurDescriptor> ToMaskBlurDescriptor(
    const flutter::DlMaskFilter* filter) {
  if (filter == nullptr) {
    return std::nullopt;
  }
  switch (filter->type()) {
    case flutter::DlMaskFilterType::kBlur: {
      auto blur = filter->asBlur();

      return Paint::MaskBlurDescriptor{
          .style = ToBlurStyle(blur->style()),
          .sigma = Sigma(blur->sigma()),
      };
    }
  }

  return std::nullopt;
}

static BlendMode ToBlendMode(flutter::DlBlendMode mode) {
  switch (mode) {
    case flutter::DlBlendMode::kClear:
      return BlendMode::kClear;
    case flutter::DlBlendMode::kSrc:
      return BlendMode::kSource;
    case flutter::DlBlendMode::kDst:
      return BlendMode::kDestination;
    case flutter::DlBlendMode::kSrcOver:
      return BlendMode::kSourceOver;
    case flutter::DlBlendMode::kDstOver:
      return BlendMode::kDestinationOver;
    case flutter::DlBlendMode::kSrcIn:
      return BlendMode::kSourceIn;
    case flutter::DlBlendMode::kDstIn:
      return BlendMode::kDestinationIn;
    case flutter::DlBlendMode::kSrcOut:
      return BlendMode::kSourceOut;
    case flutter::DlBlendMode::kDstOut:
      return BlendMode::kDestinationOut;
    case flutter::DlBlendMode::kSrcATop:
      return BlendMode::kSourceATop;
    case flutter::DlBlendMode::kDstATop:
      return BlendMode::kDestinationATop;
    case flutter::DlBlendMode::kXor:
      return BlendMode::kXor;
    case flutter::DlBlendMode::kPlus:
      return BlendMode::kPlus;
    case flutter::DlBlendMode::kModulate:
      return BlendMode::kModulate;
    case flutter::DlBlendMode::kScreen:
      return BlendMode::kScreen;
    case flutter::DlBlendMode::kOverlay:
      return BlendMode::kOverlay;
    case flutter::DlBlendMode::kDarken:
      return BlendMode::kDarken;
    case flutter::DlBlendMode::kLighten:
      return BlendMode::kLighten;
    case flutter::DlBlendMode::kColorDodge:
      return BlendMode::kColorDodge;
    case flutter::DlBlendMode::kColorBurn:
      return BlendMode::kColorBurn;
    case flutter::DlBlendMode::kHardLight:
      return BlendMode::kHardLight;
    case flutter::DlBlendMode::kSoftLight:
      return BlendMode::kSoftLight;
    case flutter::DlBlendMode::kDifference:
      return BlendMode::kDifference;
    case flutter::DlBlendMode::kExclusion:
      return BlendMode::kExclusion;
    case flutter::DlBlendMode::kMultiply:
      return BlendMode::kMultiply;
    case flutter::DlBlendMode::kHue:
      return BlendMode::kHue;
    case flutter::DlBlendMode::kSaturation:
      return BlendMode::kSaturation;
    case flutter::DlBlendMode::kColor:
      return BlendMode::kColor;
    case flutter::DlBlendMode::kLuminosity:
      return BlendMode::kLuminosity;
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

static Color ToColor(const flutter::DlColor& color) {
  return {
      color.getRedF(),
      color.getGreenF(),
      color.getBlueF(),
      color.getAlphaF(),
  };
}

static std::vector<Color> ToColors(const flutter::DlColor colors[], int count) {
  auto result = std::vector<Color>();
  if (colors == nullptr) {
    return result;
  }
  for (int i = 0; i < count; i++) {
    result.push_back(skia_conversions::ToColor(colors[i]));
  }
  return result;
}

// Convert display list colors + stops into impeller colors and stops, taking
// care to ensure that the stops always start with 0.0 and end with 1.0.
template <typename T>
static void ConvertStops(T* gradient,
                         std::vector<Color>* colors,
                         std::vector<float>* stops) {
  FML_DCHECK(gradient->stop_count() >= 2);

  auto* dl_colors = gradient->colors();
  auto* dl_stops = gradient->stops();
  if (dl_stops[0] != 0.0) {
    colors->emplace_back(skia_conversions::ToColor(dl_colors[0]));
    stops->emplace_back(0);
  }
  for (auto i = 0; i < gradient->stop_count(); i++) {
    colors->emplace_back(skia_conversions::ToColor(dl_colors[i]));
    stops->emplace_back(dl_stops[i]);
  }
  if (stops->back() != 1.0) {
    colors->emplace_back(colors->back());
    stops->emplace_back(1.0);
  }
}

static std::optional<ColorSource::Type> ToColorSourceType(
    flutter::DlColorSourceType type) {
  switch (type) {
    case flutter::DlColorSourceType::kColor:
      return ColorSource::Type::kColor;
    case flutter::DlColorSourceType::kImage:
      return ColorSource::Type::kImage;
    case flutter::DlColorSourceType::kLinearGradient:
      return ColorSource::Type::kLinearGradient;
    case flutter::DlColorSourceType::kRadialGradient:
      return ColorSource::Type::kRadialGradient;
    case flutter::DlColorSourceType::kConicalGradient:
      return ColorSource::Type::kConicalGradient;
    case flutter::DlColorSourceType::kSweepGradient:
      return ColorSource::Type::kSweepGradient;
    case flutter::DlColorSourceType::kRuntimeEffect:
      return ColorSource::Type::kRuntimeEffect;
#ifdef IMPELLER_ENABLE_3D
    case flutter::DlColorSourceType::kScene:
      return ColorSource::Type::kScene;
#endif  // IMPELLER_ENABLE_3D
  }
}

ColorSource ToColorSource(const flutter::DlColorSource* source, Paint* paint) {
  if (!source) {
    return ColorSource::MakeColor();
  }

  std::optional<ColorSource::Type> type = ToColorSourceType(source->type());

  if (!type.has_value()) {
    FML_LOG(ERROR) << "Requested ColorSourceType::kUnknown";
    return ColorSource::MakeColor();
  }

  switch (type.value()) {
    case ColorSource::Type::kColor: {
      const flutter::DlColorColorSource* color = source->asColor();
      FML_DCHECK(color);
      FML_DCHECK(paint);
      paint->color = ToColor(color->color());
      return ColorSource::MakeColor();
    }
    case ColorSource::Type::kLinearGradient: {
      const flutter::DlLinearGradientColorSource* linear =
          source->asLinearGradient();
      FML_DCHECK(linear);
      auto start_point = skia_conversions::ToPoint(linear->start_point());
      auto end_point = skia_conversions::ToPoint(linear->end_point());
      std::vector<Color> colors;
      std::vector<float> stops;
      ConvertStops(linear, &colors, &stops);

      auto tile_mode = ToTileMode(linear->tile_mode());
      auto matrix = ToMatrix(linear->matrix());

      return ColorSource::MakeLinearGradient(
          start_point, end_point, std::move(colors), std::move(stops),
          tile_mode, matrix);
    }
    case ColorSource::Type::kConicalGradient: {
      const flutter::DlConicalGradientColorSource* conical_gradient =
          source->asConicalGradient();
      FML_DCHECK(conical_gradient);
      Point center = skia_conversions::ToPoint(conical_gradient->end_center());
      SkScalar radius = conical_gradient->end_radius();
      Point focus_center =
          skia_conversions::ToPoint(conical_gradient->start_center());
      SkScalar focus_radius = conical_gradient->start_radius();
      std::vector<Color> colors;
      std::vector<float> stops;
      ConvertStops(conical_gradient, &colors, &stops);

      auto tile_mode = ToTileMode(conical_gradient->tile_mode());
      auto matrix = ToMatrix(conical_gradient->matrix());

      return ColorSource::MakeConicalGradient(center, radius, std::move(colors),
                                              std::move(stops), focus_center,
                                              focus_radius, tile_mode, matrix);
    }
    case ColorSource::Type::kRadialGradient: {
      const flutter::DlRadialGradientColorSource* radialGradient =
          source->asRadialGradient();
      FML_DCHECK(radialGradient);
      auto center = skia_conversions::ToPoint(radialGradient->center());
      auto radius = radialGradient->radius();
      std::vector<Color> colors;
      std::vector<float> stops;
      ConvertStops(radialGradient, &colors, &stops);

      auto tile_mode = ToTileMode(radialGradient->tile_mode());
      auto matrix = ToMatrix(radialGradient->matrix());
      return ColorSource::MakeRadialGradient(center, radius, std::move(colors),
                                             std::move(stops), tile_mode,
                                             matrix);
    }
    case ColorSource::Type::kSweepGradient: {
      const flutter::DlSweepGradientColorSource* sweepGradient =
          source->asSweepGradient();
      FML_DCHECK(sweepGradient);

      auto center = skia_conversions::ToPoint(sweepGradient->center());
      auto start_angle = Degrees(sweepGradient->start());
      auto end_angle = Degrees(sweepGradient->end());
      std::vector<Color> colors;
      std::vector<float> stops;
      ConvertStops(sweepGradient, &colors, &stops);

      auto tile_mode = ToTileMode(sweepGradient->tile_mode());
      auto matrix = ToMatrix(sweepGradient->matrix());
      return ColorSource::MakeSweepGradient(center, start_angle, end_angle,
                                            std::move(colors), std::move(stops),
                                            tile_mode, matrix);
    }
    case ColorSource::Type::kImage: {
      const flutter::DlImageColorSource* image_color_source = source->asImage();
      FML_DCHECK(image_color_source &&
                 image_color_source->image()->impeller_texture());
      auto texture = image_color_source->image()->impeller_texture();
      auto x_tile_mode = ToTileMode(image_color_source->horizontal_tile_mode());
      auto y_tile_mode = ToTileMode(image_color_source->vertical_tile_mode());
      auto desc = ToSamplerDescriptor(image_color_source->sampling());
      auto matrix = ToMatrix(image_color_source->matrix());
      return ColorSource::MakeImage(texture, x_tile_mode, y_tile_mode, desc,
                                    matrix);
    }
    case ColorSource::Type::kRuntimeEffect: {
      const flutter::DlRuntimeEffectColorSource* runtime_effect_color_source =
          source->asRuntimeEffect();
      auto runtime_stage =
          runtime_effect_color_source->runtime_effect()->runtime_stage();
      auto uniform_data = runtime_effect_color_source->uniform_data();
      auto samplers = runtime_effect_color_source->samplers();

      std::vector<RuntimeEffectContents::TextureInput> texture_inputs;

      for (auto& sampler : samplers) {
        if (sampler == nullptr) {
          return ColorSource::MakeColor();
        }
        auto* image = sampler->asImage();
        if (!sampler->asImage()) {
          UNIMPLEMENTED;
          return ColorSource::MakeColor();
        }
        FML_DCHECK(image->image()->impeller_texture());
        texture_inputs.push_back({
            .sampler_descriptor = ToSamplerDescriptor(image->sampling()),
            .texture = image->image()->impeller_texture(),
        });
      }

      return ColorSource::MakeRuntimeEffect(runtime_stage, uniform_data,
                                            texture_inputs);
    }
    case ColorSource::Type::kScene: {
#ifdef IMPELLER_ENABLE_3D
      const flutter::DlSceneColorSource* scene_color_source = source->asScene();
      std::shared_ptr<scene::Node> scene_node =
          scene_color_source->scene_node();
      Matrix camera_transform = scene_color_source->camera_matrix();

      return ColorSource::MakeScene(scene_node, camera_transform);
#else   // IMPELLER_ENABLE_3D
      FML_LOG(ERROR) << "ColorSourceType::kScene can only be used if Impeller "
                        "Scene is enabled.";
      return ColorSource::MakeColor();
#endif  // IMPELLER_ENABLE_3D
    }
  }
}

static std::shared_ptr<ColorFilter> ToColorFilter(
    const flutter::DlColorFilter* filter) {
  if (filter == nullptr) {
    return nullptr;
  }
  switch (filter->type()) {
    case flutter::DlColorFilterType::kBlend: {
      auto dl_blend = filter->asBlend();
      auto blend_mode = ToBlendMode(dl_blend->mode());
      auto color = skia_conversions::ToColor(dl_blend->color());
      return ColorFilter::MakeBlend(blend_mode, color);
    }
    case flutter::DlColorFilterType::kMatrix: {
      const flutter::DlMatrixColorFilter* dl_matrix = filter->asMatrix();
      impeller::ColorMatrix color_matrix;
      dl_matrix->get_matrix(color_matrix.array);
      return ColorFilter::MakeMatrix(color_matrix);
    }
    case flutter::DlColorFilterType::kSrgbToLinearGamma:
      return ColorFilter::MakeSrgbToLinear();
    case flutter::DlColorFilterType::kLinearToSrgbGamma:
      return ColorFilter::MakeLinearToSrgb();
  }
  return nullptr;
}

static Paint::ImageFilterProc ToImageFilterProc(
    const flutter::DlImageFilter* filter) {
  if (filter == nullptr) {
    return nullptr;
  }

  switch (filter->type()) {
    case flutter::DlImageFilterType::kBlur: {
      auto blur = filter->asBlur();
      auto sigma_x = Sigma(blur->sigma_x());
      auto sigma_y = Sigma(blur->sigma_y());
      auto tile_mode = ToTileMode(blur->tile_mode());

      return [sigma_x, sigma_y, tile_mode](const FilterInput::Ref& input,
                                           const Matrix& effect_transform,
                                           bool is_subpass) {
        return FilterContents::MakeGaussianBlur(
            input, sigma_x, sigma_y, FilterContents::BlurStyle::kNormal,
            tile_mode, effect_transform);
      };
    }
    case flutter::DlImageFilterType::kDilate: {
      auto dilate = filter->asDilate();
      FML_DCHECK(dilate);
      if (dilate->radius_x() < 0 || dilate->radius_y() < 0) {
        return nullptr;
      }
      auto radius_x = Radius(dilate->radius_x());
      auto radius_y = Radius(dilate->radius_y());
      return [radius_x, radius_y](FilterInput::Ref input,
                                  const Matrix& effect_transform,
                                  bool is_subpass) {
        return FilterContents::MakeMorphology(
            std::move(input), radius_x, radius_y,
            FilterContents::MorphType::kDilate, effect_transform);
      };
    }
    case flutter::DlImageFilterType::kErode: {
      auto erode = filter->asErode();
      FML_DCHECK(erode);
      if (erode->radius_x() < 0 || erode->radius_y() < 0) {
        return nullptr;
      }
      auto radius_x = Radius(erode->radius_x());
      auto radius_y = Radius(erode->radius_y());
      return [radius_x, radius_y](FilterInput::Ref input,
                                  const Matrix& effect_transform,
                                  bool is_subpass) {
        return FilterContents::MakeMorphology(
            std::move(input), radius_x, radius_y,
            FilterContents::MorphType::kErode, effect_transform);
      };
    }
    case flutter::DlImageFilterType::kMatrix: {
      auto matrix_filter = filter->asMatrix();
      FML_DCHECK(matrix_filter);
      auto matrix = ToMatrix(matrix_filter->matrix());
      auto desc = ToSamplerDescriptor(matrix_filter->sampling());
      return [matrix, desc](FilterInput::Ref input,
                            const Matrix& effect_transform, bool is_subpass) {
        return FilterContents::MakeMatrixFilter(std::move(input), matrix, desc,
                                                effect_transform, is_subpass);
      };
    }
    case flutter::DlImageFilterType::kCompose: {
      auto compose = filter->asCompose();
      FML_DCHECK(compose);
      auto outer = compose->outer();
      auto inner = compose->inner();
      auto outer_proc = ToImageFilterProc(outer.get());
      auto inner_proc = ToImageFilterProc(inner.get());
      if (!outer_proc) {
        return inner_proc;
      }
      if (!inner_proc) {
        return outer_proc;
      }
      FML_DCHECK(outer_proc && inner_proc);
      return [outer_filter = outer_proc, inner_filter = inner_proc](
                 FilterInput::Ref input, const Matrix& effect_transform,
                 bool is_subpass) {
        auto contents =
            inner_filter(std::move(input), effect_transform, is_subpass);
        contents = outer_filter(FilterInput::Make(contents), effect_transform,
                                is_subpass);
        return contents;
      };
    }
    case flutter::DlImageFilterType::kColorFilter: {
      auto color_filter_image_filter = filter->asColorFilter();
      FML_DCHECK(color_filter_image_filter);
      auto color_filter =
          ToColorFilter(color_filter_image_filter->color_filter().get());
      if (!color_filter) {
        return nullptr;
      }
      return [color_filter](FilterInput::Ref input,
                            const Matrix& effect_transform, bool is_subpass) {
        // When color filters are used as image filters, set the color filter's
        // "absorb opacity" flag to false. For image filters, the snapshot
        // opacity needs to be deferred until the result of the filter chain is
        // being blended with the layer.
        return color_filter->WrapWithGPUColorFilter(std::move(input), false);
      };
    }
    case flutter::DlImageFilterType::kLocalMatrix: {
      auto local_matrix_filter = filter->asLocalMatrix();
      FML_DCHECK(local_matrix_filter);
      auto internal_filter = local_matrix_filter->image_filter();
      FML_DCHECK(internal_filter);

      auto image_filter_proc = ToImageFilterProc(internal_filter.get());
      if (!image_filter_proc) {
        return nullptr;
      }

      auto matrix = ToMatrix(local_matrix_filter->matrix());

      return [matrix, filter_proc = image_filter_proc](
                 FilterInput::Ref input, const Matrix& effect_transform,
                 bool is_subpass) {
        std::shared_ptr<FilterContents> filter =
            filter_proc(std::move(input), effect_transform, is_subpass);
        return FilterContents::MakeLocalMatrixFilter(FilterInput::Make(filter),
                                                     matrix);
      };
    }
  }
}

static Paint ToPaint(const flutter::DlPaint& dl_paint) {
  Paint paint;
  paint.style = ToStyle(dl_paint.getDrawStyle());
  paint.color = ToColor(dl_paint.getColor());
  paint.stroke_width = dl_paint.getStrokeWidth();
  paint.stroke_miter = dl_paint.getStrokeMiter();
  paint.stroke_cap = ToStrokeCap(dl_paint.getStrokeCap());
  paint.stroke_join = ToStrokeJoin(dl_paint.getStrokeJoin());
  paint.color_source = ToColorSource(dl_paint.getColorSourcePtr(), &paint);
  paint.color_filter = ToColorFilter(dl_paint.getColorFilterPtr());
  paint.invert_colors = dl_paint.isInvertColors();
  paint.blend_mode = ToBlendMode(dl_paint.getBlendMode());
  if (dl_paint.getPathEffect()) {
    UNIMPLEMENTED;
  }
  paint.mask_blur_descriptor =
      ToMaskBlurDescriptor(dl_paint.getMaskFilterPtr());
  paint.image_filter = ToImageFilterProc(dl_paint.getImageFilterPtr());
  return paint;
}

static Paint ToPaint(const flutter::DlPaint* dl_paint) {
  if (!dl_paint) {
    return Paint();
  }
  return ToPaint(*dl_paint);
}

// |flutter::DlCanvas|
void DlAiksCanvas::Save() {
  canvas_.Save();
  if (accumulator_) {
    accumulator_->save();
  }
}

// |flutter::DlCanvas|
void DlAiksCanvas::SaveLayer(const SkRect* bounds,
                             const flutter::DlPaint* paint,
                             const flutter::DlImageFilter* backdrop) {
  Paint impeller_paint = paint ? ToPaint(paint) : Paint();
  std::optional<Rect> impeller_bounds =
      bounds ? skia_conversions::ToRect(bounds) : std::nullopt;
  Paint::ImageFilterProc proc =
      backdrop ? ToImageFilterProc(backdrop) : nullptr;

  canvas_.SaveLayer(impeller_paint, impeller_bounds, proc);
}

// |flutter::DlCanvas|
void DlAiksCanvas::Restore() {
  canvas_.Restore();
}

// |flutter::DlCanvas|
void DlAiksCanvas::Translate(SkScalar tx, SkScalar ty) {
  canvas_.Translate({tx, ty, 0.0});
}

// |flutter::DlCanvas|
void DlAiksCanvas::Scale(SkScalar sx, SkScalar sy) {
  canvas_.Scale({sx, sy, 1.0});
}

// |flutter::DlCanvas|
void DlAiksCanvas::Rotate(SkScalar degrees) {
  canvas_.Rotate(Degrees{degrees});
}

// |flutter::DlCanvas|
void DlAiksCanvas::Skew(SkScalar sx, SkScalar sy) {
  canvas_.Skew(sx, sy);
}

// |flutter::DlCanvas|
void DlAiksCanvas::Transform2DAffine(SkScalar mxx,
                                     SkScalar mxy,
                                     SkScalar mxt,
                                     SkScalar myx,
                                     SkScalar myy,
                                     SkScalar myt) {
  // clang-format off
  TransformFullPerspective(
    mxx, mxy,  0, mxt,
    myx, myy,  0, myt,
    0  ,   0,  1,   0,
    0  ,   0,  0,   1
  );
  // clang-format on
}

// |flutter::DlCanvas|
void DlAiksCanvas::TransformFullPerspective(SkScalar mxx,
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
  // The order of arguments is row-major but Impeller matrices are
  // column-major.
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

// |flutter::DlCanvas|
void DlAiksCanvas::TransformReset() {
  canvas_.ResetTransform();
}

// |flutter::DlCanvas|
void DlAiksCanvas::Transform(const SkMatrix* matrix) {
  if (!matrix) {
    return;
  }
  canvas_.Transform(ToMatrix(*matrix));
}

void DlAiksCanvas::Transform(const SkM44* matrix44) {
  if (!matrix44) {
    return;
  }
  canvas_.Transform(ToMatrix(*matrix44));
}

static Entity::ClipOperation ToClipOperation(
    flutter::DlCanvas::ClipOp clip_op) {
  switch (clip_op) {
    case flutter::DlCanvas::ClipOp::kDifference:
      return Entity::ClipOperation::kDifference;
    case flutter::DlCanvas::ClipOp::kIntersect:
      return Entity::ClipOperation::kIntersect;
  }
}

// |flutter::DlCanvas|
void DlAiksCanvas::ClipRect(const SkRect& rect, ClipOp clip_op, bool is_aa) {
  canvas_.ClipRect(skia_conversions::ToRect(rect), ToClipOperation(clip_op));
}

// |flutter::DlCanvas|
void DlAiksCanvas::ClipRRect(const SkRRect& rrect, ClipOp clip_op, bool is_aa) {
  if (rrect.isSimple()) {
    canvas_.ClipRRect(skia_conversions::ToRect(rrect.rect()),
                      rrect.getSimpleRadii().fX, ToClipOperation(clip_op));
  } else {
    canvas_.ClipPath(skia_conversions::ToPath(rrect), ToClipOperation(clip_op));
  }
}

// |flutter::DlCanvas|
void DlAiksCanvas::ClipPath(const SkPath& path, ClipOp clip_op, bool is_aa) {
  canvas_.ClipPath(skia_conversions::ToPath(path), ToClipOperation(clip_op));
}

// |flutter::DlCanvas|
void DlAiksCanvas::DrawColor(flutter::DlColor color,
                             flutter::DlBlendMode dl_mode) {
  Paint paint;
  paint.color = skia_conversions::ToColor(color);
  paint.blend_mode = ToBlendMode(dl_mode);
  canvas_.DrawPaint(paint);
}

// |flutter::DlCanvas|
void DlAiksCanvas::DrawPaint(const flutter::DlPaint& paint) {
  canvas_.DrawPaint(ToPaint(paint));
}

// |flutter::DlCanvas|
void DlAiksCanvas::DrawLine(const SkPoint& p0,
                            const SkPoint& p1,
                            const flutter::DlPaint& paint) {
  auto path =
      PathBuilder{}
          .AddLine(skia_conversions::ToPoint(p0), skia_conversions::ToPoint(p1))
          .SetConvexity(Convexity::kConvex)
          .TakePath();
  auto aiks_paint = ToPaint(paint);
  aiks_paint.style = Paint::Style::kStroke;
  canvas_.DrawPath(path, aiks_paint);
}

// |flutter::DlCanvas|
void DlAiksCanvas::DrawRect(const SkRect& rect, const flutter::DlPaint& paint) {
  canvas_.DrawRect(skia_conversions::ToRect(rect), ToPaint(paint));
}

// |flutter::DlCanvas|
void DlAiksCanvas::DrawOval(const SkRect& bounds,
                            const flutter::DlPaint& paint) {
  if (bounds.width() == bounds.height()) {
    canvas_.DrawCircle(skia_conversions::ToPoint(bounds.center()),
                       bounds.width() * 0.5, ToPaint(paint));
  } else {
    auto path = PathBuilder{}
                    .AddOval(skia_conversions::ToRect(bounds))
                    .SetConvexity(Convexity::kConvex)
                    .TakePath();
    canvas_.DrawPath(path, ToPaint(paint));
  }
}

// |flutter::DlCanvas|
void DlAiksCanvas::DrawCircle(const SkPoint& center,
                              SkScalar radius,
                              const flutter::DlPaint& paint) {
  canvas_.DrawCircle(skia_conversions::ToPoint(center), radius, ToPaint(paint));
}

// |flutter::DlCanvas|
void DlAiksCanvas::DrawRRect(const SkRRect& rrect,
                             const flutter::DlPaint& paint) {
  if (rrect.isSimple()) {
    canvas_.DrawRRect(skia_conversions::ToRect(rrect.rect()),
                      rrect.getSimpleRadii().fX, ToPaint(paint));
  } else {
    canvas_.DrawPath(skia_conversions::ToPath(rrect), ToPaint(paint));
  }
}

// |flutter::DlCanvas|
void DlAiksCanvas::DrawDRRect(const SkRRect& outer,
                              const SkRRect& inner,
                              const flutter::DlPaint& paint) {
  PathBuilder builder;
  builder.AddPath(skia_conversions::ToPath(outer));
  builder.AddPath(skia_conversions::ToPath(inner));
  canvas_.DrawPath(builder.TakePath(FillType::kOdd), ToPaint(paint));
}

// |flutter::DlCanvas|
void DlAiksCanvas::DrawPath(const SkPath& path, const flutter::DlPaint& paint) {
  SkRect rect;
  SkRRect rrect;
  SkRect oval;
  if (path.isRect(&rect)) {
    canvas_.DrawRect(skia_conversions::ToRect(rect), ToPaint(paint));
  } else if (path.isRRect(&rrect) && rrect.isSimple()) {
    canvas_.DrawRRect(skia_conversions::ToRect(rrect.rect()),
                      rrect.getSimpleRadii().fX, ToPaint(paint));
  } else if (path.isOval(&oval) && oval.width() == oval.height()) {
    canvas_.DrawCircle(skia_conversions::ToPoint(oval.center()),
                       oval.width() * 0.5, ToPaint(paint));
  } else {
    canvas_.DrawPath(skia_conversions::ToPath(path), ToPaint(paint));
  }
}

// |flutter::DlCanvas|
void DlAiksCanvas::DrawArc(const SkRect& oval_bounds,
                           SkScalar start_degrees,
                           SkScalar sweep_degrees,
                           bool use_center,
                           const flutter::DlPaint& paint) {
  PathBuilder builder;
  builder.AddArc(skia_conversions::ToRect(oval_bounds), Degrees(start_degrees),
                 Degrees(sweep_degrees), use_center);
  canvas_.DrawPath(builder.TakePath(), ToPaint(paint));
}

// |flutter::DlCanvas|
void DlAiksCanvas::DrawPoints(PointMode mode,
                              uint32_t count,
                              const SkPoint points[],
                              const flutter::DlPaint& paint) {
  auto aiks_paint = ToPaint(paint);
  switch (mode) {
    case flutter::DlCanvas::PointMode::kPoints: {
      // Cap::kButt is also treated as a square.
      auto point_style = aiks_paint.stroke_cap == Cap::kRound
                             ? PointStyle::kRound
                             : PointStyle::kSquare;
      auto radius = aiks_paint.stroke_width;
      if (radius > 0) {
        radius /= 2.0;
      }
      canvas_.DrawPoints(skia_conversions::ToPoints(points, count), radius,
                         aiks_paint, point_style);
    } break;
    case flutter::DlCanvas::PointMode::kLines:
      for (uint32_t i = 1; i < count; i += 2) {
        Point p0 = skia_conversions::ToPoint(points[i - 1]);
        Point p1 = skia_conversions::ToPoint(points[i]);
        auto path = PathBuilder{}.AddLine(p0, p1).TakePath();
        canvas_.DrawPath(path, aiks_paint);
      }
      break;
    case flutter::DlCanvas::PointMode::kPolygon:
      if (count > 1) {
        Point p0 = skia_conversions::ToPoint(points[0]);
        for (uint32_t i = 1; i < count; i++) {
          Point p1 = skia_conversions::ToPoint(points[i]);
          auto path = PathBuilder{}.AddLine(p0, p1).TakePath();
          canvas_.DrawPath(path, aiks_paint);
          p0 = p1;
        }
      }
      break;
  }
}

// |flutter::DlCanvas|
void DlAiksCanvas::DrawVertices(const flutter::DlVertices* vertices,
                                flutter::DlBlendMode dl_mode,
                                const flutter::DlPaint& paint) {
  canvas_.DrawVertices(DlVerticesGeometry::MakeVertices(vertices),
                       ToBlendMode(dl_mode), ToPaint(paint));
}

// |flutter::DlCanvas|
void DlAiksCanvas::DrawImage(const sk_sp<flutter::DlImage>& image,
                             const SkPoint point,
                             flutter::DlImageSampling sampling,
                             const flutter::DlPaint* paint) {
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

  DrawImageRect(image,                      // image
                src,                        // source rect
                dest,                       // destination rect
                sampling,                   // sampling options
                paint,                      // paint
                SrcRectConstraint::kStrict  // constraint
  );
}

// |flutter::DlCanvas|
void DlAiksCanvas::DrawImageRect(const sk_sp<flutter::DlImage>& image,
                                 const SkRect& src,
                                 const SkRect& dst,
                                 flutter::DlImageSampling sampling,
                                 const flutter::DlPaint* paint,
                                 SrcRectConstraint constraint) {
  canvas_.DrawImageRect(
      std::make_shared<Image>(image->impeller_texture()),  // image
      skia_conversions::ToRect(src),                       // source rect
      skia_conversions::ToRect(dst),                       // destination rect
      ToPaint(paint),                                      // paint
      ToSamplerDescriptor(sampling)                        // sampling
  );
}

// |flutter::DlCanvas|
void DlAiksCanvas::DrawImageNine(const sk_sp<flutter::DlImage>& image,
                                 const SkIRect& center,
                                 const SkRect& dst,
                                 flutter::DlFilterMode filter,
                                 const flutter::DlPaint* paint) {
  NinePatchConverter converter = {};
  auto aiks_paint = ToPaint(paint);
  converter.DrawNinePatch(
      std::make_shared<Image>(image->impeller_texture()),
      Rect::MakeLTRB(center.fLeft, center.fTop, center.fRight, center.fBottom),
      skia_conversions::ToRect(dst), ToSamplerDescriptor(filter), &canvas_,
      &aiks_paint);
}

// |flutter::DlCanvas|
void DlAiksCanvas::DrawAtlas(const sk_sp<flutter::DlImage>& atlas,
                             const SkRSXform xform[],
                             const SkRect tex[],
                             const flutter::DlColor colors[],
                             int count,
                             flutter::DlBlendMode mode,
                             flutter::DlImageSampling sampling,
                             const SkRect* cull_rect,
                             const flutter::DlPaint* paint) {
  canvas_.DrawAtlas(std::make_shared<Image>(atlas->impeller_texture()),
                    skia_conversions::ToRSXForms(xform, count),
                    skia_conversions::ToRects(tex, count),
                    ToColors(colors, count), ToBlendMode(mode),
                    ToSamplerDescriptor(sampling),
                    skia_conversions::ToRect(cull_rect), ToPaint(paint));
}

// |flutter::DlCanvas|
void DlAiksCanvas::DrawDisplayList(
    const sk_sp<flutter::DisplayList> display_list,
    SkScalar opacity) {
  FML_DCHECK(false);
}

// |flutter::DlCanvas|
void DlAiksCanvas::DrawImpellerPicture(
    const std::shared_ptr<const impeller::Picture>& picture,
    SkScalar opacity) {
  if (!picture) {
    return;
  }
  FML_DCHECK(opacity == 1);
  canvas_.DrawPicture(*picture);
}

// |flutter::DlCanvas|
void DlAiksCanvas::DrawTextBlob(const sk_sp<SkTextBlob>& blob,
                                SkScalar x,
                                SkScalar y,
                                const flutter::DlPaint& paint) {
  const auto maybe_text_frame = MakeTextFrameFromTextBlobSkia(blob);
  if (!maybe_text_frame.has_value()) {
    return;
  }
  auto text_frame = maybe_text_frame.value();
  if (paint.getDrawStyle() == flutter::DlDrawStyle::kStroke) {
    auto path = skia_conversions::PathDataFromTextBlob(blob);
    auto bounds = text_frame.GetBounds();
    canvas_.Save();
    canvas_.Translate({x + bounds.origin.x, y + bounds.origin.y, 0.0});
    canvas_.DrawPath(path, ToPaint(paint));
    canvas_.Restore();
    return;
  }

  canvas_.DrawTextFrame(text_frame,             //
                        impeller::Point{x, y},  //
                        ToPaint(paint)          //
  );
}

// |flutter::DlCanvas|
void DlAiksCanvas::DrawShadow(const SkPath& path,
                              const flutter::DlColor color,
                              const SkScalar elevation,
                              bool transparent_occluder,
                              SkScalar dpr) {
  Color spot_color = skia_conversions::ToColor(color);
  spot_color.alpha *= 0.25;

  // Compute the spot color -- ported from SkShadowUtils::ComputeTonalColors.
  {
    Scalar max =
        std::max(std::max(spot_color.red, spot_color.green), spot_color.blue);
    Scalar min =
        std::min(std::min(spot_color.red, spot_color.green), spot_color.blue);
    Scalar luminance = (min + max) * 0.5;

    Scalar alpha_adjust =
        (2.6f + (-2.66667f + 1.06667f * spot_color.alpha) * spot_color.alpha) *
        spot_color.alpha;
    Scalar color_alpha =
        (3.544762f + (-4.891428f + 2.3466f * luminance) * luminance) *
        luminance;
    color_alpha = std::clamp(alpha_adjust * color_alpha, 0.0f, 1.0f);

    Scalar greyscale_alpha =
        std::clamp(spot_color.alpha * (1 - 0.4f * luminance), 0.0f, 1.0f);

    Scalar color_scale = color_alpha * (1 - greyscale_alpha);
    Scalar tonal_alpha = color_scale + greyscale_alpha;
    Scalar unpremul_scale = tonal_alpha != 0 ? color_scale / tonal_alpha : 0;
    spot_color = Color(unpremul_scale * spot_color.red,
                       unpremul_scale * spot_color.green,
                       unpremul_scale * spot_color.blue, tonal_alpha);
  }

  Vector3 light_position(0, -1, 1);
  Scalar occluder_z = dpr * elevation;

  constexpr Scalar kLightRadius = 800 / 600;  // Light radius / light height

  Paint paint;
  paint.style = Paint::Style::kFill;
  paint.color = spot_color;
  paint.mask_blur_descriptor = Paint::MaskBlurDescriptor{
      .style = FilterContents::BlurStyle::kNormal,
      .sigma = Radius{kLightRadius * occluder_z /
                      canvas_.GetCurrentTransformation().GetScale().y},
  };

  canvas_.Save();
  canvas_.PreConcat(
      Matrix::MakeTranslation(Vector2(0, -occluder_z * light_position.y)));

  SkRect rect;
  SkRRect rrect;
  SkRect oval;
  if (path.isRect(&rect)) {
    canvas_.DrawRect(skia_conversions::ToRect(rect), paint);
  } else if (path.isRRect(&rrect) && rrect.isSimple()) {
    canvas_.DrawRRect(skia_conversions::ToRect(rrect.rect()),
                      rrect.getSimpleRadii().fX, paint);
  } else if (path.isOval(&oval) && oval.width() == oval.height()) {
    canvas_.DrawCircle(skia_conversions::ToPoint(oval.center()),
                       oval.width() * 0.5, paint);
  } else {
    canvas_.DrawPath(skia_conversions::ToPath(path), paint);
  }

  canvas_.Restore();
}

// |flutter::DlCanvas|
bool DlAiksCanvas::QuickReject(const SkRect& bounds) const {
  auto maybe_cull_rect = canvas_.GetCurrentLocalCullingBounds();
  if (!maybe_cull_rect.has_value()) {
    return false;
  }
  auto cull_rect = maybe_cull_rect.value();
  if (cull_rect.IsEmpty() || bounds.isEmpty()) {
    return true;
  }
  auto transform = canvas_.GetCurrentTransformation();
  // There are no fast paths right now to checking whther impeller::Matrix can
  // be inverted. Skip that check.
  if (transform.HasPerspective()) {
    return false;
  }

  return !skia_conversions::ToRect(bounds).IntersectsWithRect(cull_rect);
}

// |flutter::DlCanvas|
void DlAiksCanvas::RestoreToCount(int restore_count) {
  canvas_.RestoreToCount(restore_count);
}

// |flutter::DlCanvas|
SkISize DlAiksCanvas::GetBaseLayerSize() const {
  auto size = canvas_.BaseCullRect().value_or(Rect::Giant()).size.Round();
  return SkISize::Make(size.width, size.height);
}

// |flutter::DlCanvas|
SkImageInfo DlAiksCanvas::GetImageInfo() const {
  SkISize size = GetBaseLayerSize();
  return SkImageInfo::MakeUnknown(size.width(), size.height());
}

Picture DlAiksCanvas::EndRecordingAsPicture() {
  return canvas_.EndRecordingAsPicture();
}

}  // namespace impeller
