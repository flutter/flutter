// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/skia/dl_sk_conversions.h"

namespace flutter {

sk_sp<SkShader> ToSk(const DlColorSource* source) {
  if (!source) {
    return nullptr;
  }
  static auto ToSkColors = [](const DlGradientColorSourceBase* gradient) {
    return reinterpret_cast<const SkColor*>(gradient->colors());
  };
  switch (source->type()) {
    case DlColorSourceType::kColor: {
      const DlColorColorSource* color_source = source->asColor();
      FML_DCHECK(color_source != nullptr);
      return SkShaders::Color(color_source->color());
    }
    case DlColorSourceType::kImage: {
      const DlImageColorSource* image_source = source->asImage();
      FML_DCHECK(image_source != nullptr);
      auto image = image_source->image();
      if (!image || !image->skia_image()) {
        return nullptr;
      }
      return image->skia_image()->makeShader(
          ToSk(image_source->horizontal_tile_mode()),
          ToSk(image_source->vertical_tile_mode()),
          ToSk(image_source->sampling()), image_source->matrix_ptr());
    }
    case DlColorSourceType::kLinearGradient: {
      const DlLinearGradientColorSource* linear_source =
          source->asLinearGradient();
      FML_DCHECK(linear_source != nullptr);
      SkPoint pts[] = {linear_source->start_point(),
                       linear_source->end_point()};
      return SkGradientShader::MakeLinear(
          pts, ToSkColors(linear_source), linear_source->stops(),
          linear_source->stop_count(), ToSk(linear_source->tile_mode()), 0,
          linear_source->matrix_ptr());
    }
    case DlColorSourceType::kRadialGradient: {
      const DlRadialGradientColorSource* radial_source =
          source->asRadialGradient();
      FML_DCHECK(radial_source != nullptr);
      return SkGradientShader::MakeRadial(
          radial_source->center(), radial_source->radius(),
          ToSkColors(radial_source), radial_source->stops(),
          radial_source->stop_count(), ToSk(radial_source->tile_mode()), 0,
          radial_source->matrix_ptr());
    }
    case DlColorSourceType::kConicalGradient: {
      const DlConicalGradientColorSource* conical_source =
          source->asConicalGradient();
      FML_DCHECK(conical_source != nullptr);
      return SkGradientShader::MakeTwoPointConical(
          conical_source->start_center(), conical_source->start_radius(),
          conical_source->end_center(), conical_source->end_radius(),
          ToSkColors(conical_source), conical_source->stops(),
          conical_source->stop_count(), ToSk(conical_source->tile_mode()), 0,
          conical_source->matrix_ptr());
    }
    case DlColorSourceType::kSweepGradient: {
      const DlSweepGradientColorSource* sweep_source =
          source->asSweepGradient();
      FML_DCHECK(sweep_source != nullptr);
      return SkGradientShader::MakeSweep(
          sweep_source->center().x(), sweep_source->center().y(),
          ToSkColors(sweep_source), sweep_source->stops(),
          sweep_source->stop_count(), ToSk(sweep_source->tile_mode()),
          sweep_source->start(), sweep_source->end(), 0,
          sweep_source->matrix_ptr());
    }
    case DlColorSourceType::kRuntimeEffect: {
      const DlRuntimeEffectColorSource* runtime_source =
          source->asRuntimeEffect();
      FML_DCHECK(runtime_source != nullptr);
      auto runtime_effect = runtime_source->runtime_effect();
      if (!runtime_effect || !runtime_effect->skia_runtime_effect()) {
        return nullptr;
      }

      auto samplers = runtime_source->samplers();
      std::vector<sk_sp<SkShader>> sk_samplers(samplers.size());
      for (size_t i = 0; i < samplers.size(); i++) {
        auto sampler = samplers[i];
        if (sampler == nullptr) {
          return nullptr;
        }
        sk_samplers[i] = ToSk(sampler);
      }

      auto uniform_data = runtime_source->uniform_data();
      auto ref = new std::shared_ptr<std::vector<uint8_t>>(uniform_data);
      auto sk_uniform_data = SkData::MakeWithProc(
          uniform_data->data(), uniform_data->size(),
          [](const void* ptr, void* context) {
            delete reinterpret_cast<std::shared_ptr<std::vector<uint8_t>>*>(
                context);
          },
          ref);

      return runtime_effect->skia_runtime_effect()->makeShader(
          sk_uniform_data, sk_samplers.data(), sk_samplers.size());
    }
#ifdef IMPELLER_ENABLE_3D
    case DlColorSourceType::kScene: {
      return nullptr;
    }
#endif  // IMPELLER_ENABLE_3D
  }
}

sk_sp<SkImageFilter> ToSk(const DlImageFilter* filter) {
  if (!filter) {
    return nullptr;
  }
  switch (filter->type()) {
    case DlImageFilterType::kBlur: {
      const DlBlurImageFilter* blur_filter = filter->asBlur();
      FML_DCHECK(blur_filter != nullptr);
      return SkImageFilters::Blur(blur_filter->sigma_x(),
                                  blur_filter->sigma_y(),
                                  ToSk(blur_filter->tile_mode()), nullptr);
    }
    case DlImageFilterType::kDilate: {
      const DlDilateImageFilter* dilate_filter = filter->asDilate();
      FML_DCHECK(dilate_filter != nullptr);
      return SkImageFilters::Dilate(dilate_filter->radius_x(),
                                    dilate_filter->radius_y(), nullptr);
    }
    case DlImageFilterType::kErode: {
      const DlErodeImageFilter* erode_filter = filter->asErode();
      FML_DCHECK(erode_filter != nullptr);
      return SkImageFilters::Erode(erode_filter->radius_x(),
                                   erode_filter->radius_y(), nullptr);
    }
    case DlImageFilterType::kMatrix: {
      const DlMatrixImageFilter* matrix_filter = filter->asMatrix();
      FML_DCHECK(matrix_filter != nullptr);
      return SkImageFilters::MatrixTransform(
          matrix_filter->matrix(), ToSk(matrix_filter->sampling()), nullptr);
    }
    case DlImageFilterType::kCompose: {
      const DlComposeImageFilter* compose_filter = filter->asCompose();
      FML_DCHECK(compose_filter != nullptr);
      return SkImageFilters::Compose(ToSk(compose_filter->outer()),
                                     ToSk(compose_filter->inner()));
    }
    case DlImageFilterType::kColorFilter: {
      const DlColorFilterImageFilter* cf_filter = filter->asColorFilter();
      FML_DCHECK(cf_filter != nullptr);
      return SkImageFilters::ColorFilter(ToSk(cf_filter->color_filter()),
                                         nullptr);
    }
    case DlImageFilterType::kLocalMatrix: {
      const DlLocalMatrixImageFilter* lm_filter = filter->asLocalMatrix();
      FML_DCHECK(lm_filter != nullptr);
      sk_sp<SkImageFilter> skia_filter = ToSk(lm_filter->image_filter());
      // The image_filter property itself might have been null, or the
      // construction of the SkImageFilter might be optimized to null
      // for any number of reasons. In any case, if the filter is null
      // or optimizaed away, let's then optimize away this local matrix
      // case by returning null.
      if (!skia_filter) {
        return nullptr;
      }
      return skia_filter->makeWithLocalMatrix(lm_filter->matrix());
    }
  }
}

sk_sp<SkColorFilter> ToSk(const DlColorFilter* filter) {
  if (!filter) {
    return nullptr;
  }
  switch (filter->type()) {
    case DlColorFilterType::kBlend: {
      const DlBlendColorFilter* blend_filter = filter->asBlend();
      FML_DCHECK(blend_filter != nullptr);
      return SkColorFilters::Blend(blend_filter->color(),
                                   ToSk(blend_filter->mode()));
    }
    case DlColorFilterType::kMatrix: {
      const DlMatrixColorFilter* matrix_filter = filter->asMatrix();
      FML_DCHECK(matrix_filter != nullptr);
      float matrix[20];
      matrix_filter->get_matrix(matrix);
      return SkColorFilters::Matrix(matrix);
    }
    case DlColorFilterType::kSrgbToLinearGamma: {
      return SkColorFilters::SRGBToLinearGamma();
    }
    case DlColorFilterType::kLinearToSrgbGamma: {
      return SkColorFilters::LinearToSRGBGamma();
    }
  }
}

sk_sp<SkMaskFilter> ToSk(const DlMaskFilter* filter) {
  if (!filter) {
    return nullptr;
  }
  switch (filter->type()) {
    case DlMaskFilterType::kBlur: {
      const DlBlurMaskFilter* blur_filter = filter->asBlur();
      FML_DCHECK(blur_filter != nullptr);
      return SkMaskFilter::MakeBlur(blur_filter->style(), blur_filter->sigma(),
                                    blur_filter->respectCTM());
    }
  }
}

sk_sp<SkPathEffect> ToSk(const DlPathEffect* effect) {
  if (!effect) {
    return nullptr;
  }
  switch (effect->type()) {
    case DlPathEffectType::kDash: {
      const DlDashPathEffect* dash_effect = effect->asDash();
      FML_DCHECK(dash_effect != nullptr);
      return SkDashPathEffect::Make(dash_effect->intervals(),
                                    dash_effect->count(), dash_effect->phase());
    }
  }
}

sk_sp<SkVertices> ToSk(const DlVertices* vertices) {
  const SkColor* sk_colors =
      reinterpret_cast<const SkColor*>(vertices->colors());
  return SkVertices::MakeCopy(ToSk(vertices->mode()), vertices->vertex_count(),
                              vertices->vertices(),
                              vertices->texture_coordinates(), sk_colors,
                              vertices->index_count(), vertices->indices());
}

}  // namespace flutter
