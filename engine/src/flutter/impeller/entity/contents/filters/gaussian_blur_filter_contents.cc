// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/gaussian_blur_filter_contents.h"

#include <cmath>

#include "flutter/fml/make_copyable.h"
#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/texture_fill.frag.h"
#include "impeller/entity/texture_fill.vert.h"
#include "impeller/renderer/command.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/texture_mipmap.h"
#include "impeller/renderer/vertex_buffer_builder.h"

namespace impeller {

using GaussianBlurVertexShader = KernelPipeline::VertexShader;
using GaussianBlurFragmentShader = KernelPipeline::FragmentShader;

const int32_t GaussianBlurFilterContents::kBlurFilterRequiredMipCount = 4;

namespace {

// 48 comes from kernel.glsl.
const int32_t kMaxKernelSize = 48;

SamplerDescriptor MakeSamplerDescriptor(MinMagFilter filter,
                                        SamplerAddressMode address_mode) {
  SamplerDescriptor sampler_desc;
  sampler_desc.min_filter = filter;
  sampler_desc.mag_filter = filter;
  sampler_desc.width_address_mode = address_mode;
  sampler_desc.height_address_mode = address_mode;
  return sampler_desc;
}

template <typename T>
void BindVertices(RenderPass& pass,
                  HostBuffer& host_buffer,
                  std::initializer_list<typename T::PerVertexData>&& vertices) {
  VertexBufferBuilder<typename T::PerVertexData> vtx_builder;
  vtx_builder.AddVertices(vertices);
  pass.SetVertexBuffer(vtx_builder.CreateVertexBuffer(host_buffer));
}

void SetTileMode(SamplerDescriptor* descriptor,
                 const ContentContext& renderer,
                 Entity::TileMode tile_mode) {
  switch (tile_mode) {
    case Entity::TileMode::kDecal:
      if (renderer.GetDeviceCapabilities().SupportsDecalSamplerAddressMode()) {
        descriptor->width_address_mode = SamplerAddressMode::kDecal;
        descriptor->height_address_mode = SamplerAddressMode::kDecal;
      }
      break;
    case Entity::TileMode::kClamp:
      descriptor->width_address_mode = SamplerAddressMode::kClampToEdge;
      descriptor->height_address_mode = SamplerAddressMode::kClampToEdge;
      break;
    case Entity::TileMode::kMirror:
      descriptor->width_address_mode = SamplerAddressMode::kMirror;
      descriptor->height_address_mode = SamplerAddressMode::kMirror;
      break;
    case Entity::TileMode::kRepeat:
      descriptor->width_address_mode = SamplerAddressMode::kRepeat;
      descriptor->height_address_mode = SamplerAddressMode::kRepeat;
      break;
  }
}

/// Makes a subpass that will render the scaled down input and add the
/// transparent gutter required for the blur halo.
fml::StatusOr<RenderTarget> MakeDownsampleSubpass(
    const ContentContext& renderer,
    std::shared_ptr<Texture> input_texture,
    const SamplerDescriptor& sampler_descriptor,
    const Quad& uvs,
    const ISize& subpass_size,
    Entity::TileMode tile_mode) {
  ContentContext::SubpassCallback subpass_callback =
      [&](const ContentContext& renderer, RenderPass& pass) {
        HostBuffer& host_buffer = renderer.GetTransientsBuffer();

        pass.SetCommandLabel("Gaussian blur downsample");
        auto pipeline_options = OptionsFromPass(pass);
        pipeline_options.primitive_type = PrimitiveType::kTriangleStrip;
        pass.SetPipeline(renderer.GetTexturePipeline(pipeline_options));

        TextureFillVertexShader::FrameInfo frame_info;
        frame_info.mvp = Matrix::MakeOrthographic(ISize(1, 1));
        frame_info.texture_sampler_y_coord_scale = 1.0;
        frame_info.alpha = 1.0;

        BindVertices<TextureFillVertexShader>(pass, host_buffer,
                                              {
                                                  {Point(0, 0), uvs[0]},
                                                  {Point(1, 0), uvs[1]},
                                                  {Point(0, 1), uvs[2]},
                                                  {Point(1, 1), uvs[3]},
                                              });

        SamplerDescriptor linear_sampler_descriptor = sampler_descriptor;
        SetTileMode(&linear_sampler_descriptor, renderer, tile_mode);
        linear_sampler_descriptor.mag_filter = MinMagFilter::kLinear;
        linear_sampler_descriptor.min_filter = MinMagFilter::kLinear;
        TextureFillVertexShader::BindFrameInfo(
            pass, host_buffer.EmplaceUniform(frame_info));
        TextureFillFragmentShader::BindTextureSampler(
            pass, input_texture,
            renderer.GetContext()->GetSamplerLibrary()->GetSampler(
                linear_sampler_descriptor));

        return pass.Draw().ok();
      };
  fml::StatusOr<RenderTarget> render_target = renderer.MakeSubpass(
      "Gaussian Blur Filter", subpass_size, subpass_callback);
  return render_target;
}

fml::StatusOr<RenderTarget> MakeBlurSubpass(
    const ContentContext& renderer,
    const RenderTarget& input_pass,
    const SamplerDescriptor& sampler_descriptor,
    Entity::TileMode tile_mode,
    const BlurParameters& blur_info,
    std::optional<RenderTarget> destination_target,
    const Quad& blur_uvs) {
  if (blur_info.blur_sigma < kEhCloseEnough) {
    return input_pass;
  }

  std::shared_ptr<Texture> input_texture = input_pass.GetRenderTargetTexture();

  // TODO(gaaclarke): This blurs the whole image, but because we know the clip
  //                  region we could focus on just blurring that.
  ISize subpass_size = input_texture->GetSize();
  ContentContext::SubpassCallback subpass_callback =
      [&](const ContentContext& renderer, RenderPass& pass) {
        GaussianBlurVertexShader::FrameInfo frame_info{
            .mvp = Matrix::MakeOrthographic(ISize(1, 1)),
            .texture_sampler_y_coord_scale = 1.0};

        HostBuffer& host_buffer = renderer.GetTransientsBuffer();

        ContentContextOptions options = OptionsFromPass(pass);
        options.primitive_type = PrimitiveType::kTriangleStrip;

        if (tile_mode == Entity::TileMode::kDecal &&
            !renderer.GetDeviceCapabilities()
                 .SupportsDecalSamplerAddressMode()) {
          pass.SetPipeline(renderer.GetKernelDecalPipeline(options));
        } else {
          pass.SetPipeline(renderer.GetKernelPipeline(options));
        }

        BindVertices<GaussianBlurVertexShader>(pass, host_buffer,
                                               {
                                                   {blur_uvs[0], blur_uvs[0]},
                                                   {blur_uvs[1], blur_uvs[1]},
                                                   {blur_uvs[2], blur_uvs[2]},
                                                   {blur_uvs[3], blur_uvs[3]},
                                               });

        SamplerDescriptor linear_sampler_descriptor = sampler_descriptor;
        linear_sampler_descriptor.mag_filter = MinMagFilter::kLinear;
        linear_sampler_descriptor.min_filter = MinMagFilter::kLinear;
        GaussianBlurFragmentShader::BindTextureSampler(
            pass, input_texture,
            renderer.GetContext()->GetSamplerLibrary()->GetSampler(
                linear_sampler_descriptor));
        GaussianBlurVertexShader::BindFrameInfo(
            pass, host_buffer.EmplaceUniform(frame_info));
        KernelPipeline::FragmentShader::KernelSamples kernel_samples =
            LerpHackKernelSamples(GenerateBlurInfo(blur_info));
        FML_CHECK(kernel_samples.sample_count < kMaxKernelSize);
        GaussianBlurFragmentShader::BindKernelSamples(
            pass, host_buffer.EmplaceUniform(kernel_samples));
        return pass.Draw().ok();
      };
  if (destination_target.has_value()) {
    return renderer.MakeSubpass("Gaussian Blur Filter",
                                destination_target.value(), subpass_callback);
  } else {
    return renderer.MakeSubpass("Gaussian Blur Filter", subpass_size,
                                subpass_callback);
  }
}

/// Returns `rect` relative to `reference`, where Rect::MakeXYWH(0,0,1,1) will
/// be returned when `rect` == `reference`.
Rect MakeReferenceUVs(const Rect& reference, const Rect& rect) {
  Rect result = Rect::MakeOriginSize(rect.GetOrigin() - reference.GetOrigin(),
                                     rect.GetSize());
  return result.Scale(1.0f / Vector2(reference.GetSize()));
}

int ScaleBlurRadius(Scalar radius, Scalar scalar) {
  return static_cast<int>(std::round(radius * scalar));
}

Entity ApplyClippedBlurStyle(Entity::ClipOperation clip_operation,
                             const Entity& entity,
                             const std::shared_ptr<FilterInput>& input,
                             const Snapshot& input_snapshot,
                             Entity blur_entity,
                             const std::shared_ptr<Geometry>& geometry) {
  auto clip_contents = std::make_shared<ClipContents>();
  clip_contents->SetClipOperation(clip_operation);
  clip_contents->SetGeometry(geometry);
  Entity clipper;
  clipper.SetContents(clip_contents);
  auto restore = std::make_unique<ClipRestoreContents>();
  Matrix entity_transform = entity.GetTransform();
  Matrix blur_transform = blur_entity.GetTransform();
  auto renderer = fml::MakeCopyable(
      [blur_entity = blur_entity.Clone(), clipper = std::move(clipper),
       restore = std::move(restore), entity_transform,
       blur_transform](const ContentContext& renderer, const Entity& entity,
                       RenderPass& pass) mutable {
        bool result = true;
        clipper.SetNewClipDepth(entity.GetNewClipDepth());
        clipper.SetTransform(entity.GetTransform() * entity_transform);
        result = clipper.Render(renderer, pass) && result;
        blur_entity.SetNewClipDepth(entity.GetNewClipDepth());
        blur_entity.SetTransform(entity.GetTransform() * blur_transform);
        result = blur_entity.Render(renderer, pass) && result;
        if constexpr (!ContentContext::kEnableStencilThenCover) {
          result = restore->Render(renderer, entity, pass) && result;
        }
        return result;
      });
  auto coverage =
      fml::MakeCopyable([blur_entity = std::move(blur_entity),
                         blur_transform](const Entity& entity) mutable {
        blur_entity.SetTransform(entity.GetTransform() * blur_transform);
        return blur_entity.GetCoverage();
      });
  Entity result;
  result.SetContents(Contents::MakeAnonymous(renderer, coverage));
  return result;
}

Entity ApplyBlurStyle(FilterContents::BlurStyle blur_style,
                      const Entity& entity,
                      const std::shared_ptr<FilterInput>& input,
                      const Snapshot& input_snapshot,
                      Entity blur_entity,
                      const std::shared_ptr<Geometry>& geometry) {
  switch (blur_style) {
    case FilterContents::BlurStyle::kNormal:
      return blur_entity;
    case FilterContents::BlurStyle::kInner:
      return ApplyClippedBlurStyle(Entity::ClipOperation::kIntersect, entity,
                                   input, input_snapshot,
                                   std::move(blur_entity), geometry);
      break;
    case FilterContents::BlurStyle::kOuter:
      return ApplyClippedBlurStyle(Entity::ClipOperation::kDifference, entity,
                                   input, input_snapshot,
                                   std::move(blur_entity), geometry);
    case FilterContents::BlurStyle::kSolid: {
      Entity snapshot_entity = Entity::FromSnapshot(
          input_snapshot, entity.GetBlendMode(), entity.GetClipDepth());
      Entity result;
      Matrix blurred_transform = blur_entity.GetTransform();
      Matrix snapshot_transform = snapshot_entity.GetTransform();
      result.SetContents(Contents::MakeAnonymous(
          fml::MakeCopyable([blur_entity = blur_entity.Clone(),
                             blurred_transform, snapshot_transform,
                             snapshot_entity = std::move(snapshot_entity)](
                                const ContentContext& renderer,
                                const Entity& entity,
                                RenderPass& pass) mutable {
            bool result = true;
            blur_entity.SetNewClipDepth(entity.GetNewClipDepth());
            blur_entity.SetTransform(entity.GetTransform() * blurred_transform);
            result = result && blur_entity.Render(renderer, pass);
            snapshot_entity.SetTransform(entity.GetTransform() *
                                         snapshot_transform);
            snapshot_entity.SetNewClipDepth(entity.GetNewClipDepth());
            result = result && snapshot_entity.Render(renderer, pass);
            return result;
          }),
          fml::MakeCopyable([blur_entity = blur_entity.Clone(),
                             blurred_transform](const Entity& entity) mutable {
            blur_entity.SetTransform(entity.GetTransform() * blurred_transform);
            return blur_entity.GetCoverage();
          })));
      return result;
    }
  }
}
}  // namespace

std::string_view GaussianBlurFilterContents::kNoMipsError =
    "Applying gaussian blur without mipmap.";

GaussianBlurFilterContents::GaussianBlurFilterContents(
    Scalar sigma_x,
    Scalar sigma_y,
    Entity::TileMode tile_mode,
    BlurStyle mask_blur_style,
    const std::shared_ptr<Geometry>& mask_geometry)
    : sigma_x_(sigma_x),
      sigma_y_(sigma_y),
      tile_mode_(tile_mode),
      mask_blur_style_(mask_blur_style),
      mask_geometry_(mask_geometry) {
  // This is supposed to be enforced at a higher level.
  FML_DCHECK(mask_blur_style == BlurStyle::kNormal || mask_geometry);
}

// This value was extracted from Skia, see:
//  * https://github.com/google/skia/blob/d29cc3fe182f6e8a8539004a6a4ee8251677a6fd/src/gpu/ganesh/GrBlurUtils.cpp#L2561-L2576
//  * https://github.com/google/skia/blob/d29cc3fe182f6e8a8539004a6a4ee8251677a6fd/src/gpu/BlurUtils.h#L57
Scalar GaussianBlurFilterContents::CalculateScale(Scalar sigma) {
  if (sigma <= 4) {
    return 1.0;
  }
  Scalar raw_result = 4.0 / sigma;
  // Round to the nearest 1/(2^n) to get the best quality down scaling.
  Scalar exponent = round(log2f(raw_result));
  // Don't scale down below 1/16th to preserve signal.
  exponent = std::max(-4.0f, exponent);
  Scalar rounded = powf(2.0f, exponent);
  Scalar result = rounded;
  // Extend the range of the 1/8th downsample based on the effective kernel size
  // for the blur.
  if (rounded < 0.125f) {
    Scalar rounded_plus = powf(2.0f, exponent + 1);
    Scalar blur_radius = CalculateBlurRadius(sigma);
    int kernel_size_plus = (ScaleBlurRadius(blur_radius, rounded_plus) * 2) + 1;
    // This constant was picked by looking at the results to make sure no
    // shimmering was introduced at the highest sigma values that downscale to
    // 1/16th.
    static constexpr int32_t kEighthDownsampleKernalWidthMax = 41;
    result = kernel_size_plus <= kEighthDownsampleKernalWidthMax ? rounded_plus
                                                                 : rounded;
  }
  return result;
};

std::optional<Rect> GaussianBlurFilterContents::GetFilterSourceCoverage(
    const Matrix& effect_transform,
    const Rect& output_limit) const {
  Vector2 scaled_sigma = {ScaleSigma(sigma_x_), ScaleSigma(sigma_y_)};
  Vector2 blur_radius = {CalculateBlurRadius(scaled_sigma.x),
                         CalculateBlurRadius(scaled_sigma.y)};
  Vector3 blur_radii =
      effect_transform.Basis() * Vector3{blur_radius.x, blur_radius.y, 0.0};
  return output_limit.Expand(Point(blur_radii.x, blur_radii.y));
}

std::optional<Rect> GaussianBlurFilterContents::GetFilterCoverage(
    const FilterInput::Vector& inputs,
    const Entity& entity,
    const Matrix& effect_transform) const {
  if (inputs.empty()) {
    return {};
  }

  std::optional<Rect> input_coverage = inputs[0]->GetCoverage(entity);
  if (!input_coverage.has_value()) {
    return {};
  }

  Vector2 scaled_sigma = (effect_transform.Basis() *
                          Vector2(ScaleSigma(sigma_x_), ScaleSigma(sigma_y_)))
                             .Abs();
  Vector2 blur_radius = Vector2(CalculateBlurRadius(scaled_sigma.x),
                                CalculateBlurRadius(scaled_sigma.y));
  Vector2 padding(ceil(blur_radius.x), ceil(blur_radius.y));
  Vector2 local_padding = (entity.GetTransform().Basis() * padding).Abs();
  return input_coverage.value().Expand(Point(local_padding.x, local_padding.y));
}

std::optional<Entity> GaussianBlurFilterContents::RenderFilter(
    const FilterInput::Vector& inputs,
    const ContentContext& renderer,
    const Entity& entity,
    const Matrix& effect_transform,
    const Rect& coverage,
    const std::optional<Rect>& coverage_hint) const {
  if (inputs.empty()) {
    return std::nullopt;
  }

  Vector2 scaled_sigma = (effect_transform.Basis() *
                          Vector2(ScaleSigma(sigma_x_), ScaleSigma(sigma_y_)))
                             .Abs();
  Vector2 blur_radius = Vector2(CalculateBlurRadius(scaled_sigma.x),
                                CalculateBlurRadius(scaled_sigma.y));
  Vector2 padding(ceil(blur_radius.x), ceil(blur_radius.y));
  Vector2 local_padding = (entity.GetTransform().Basis() * padding).Abs();

  // Apply as much of the desired padding as possible from the source. This may
  // be ignored so must be accounted for in the downsample pass by adding a
  // transparent gutter.
  std::optional<Rect> expanded_coverage_hint;
  if (coverage_hint.has_value()) {
    expanded_coverage_hint = coverage_hint->Expand(local_padding);
  }

  int32_t mip_count = kBlurFilterRequiredMipCount;
  if (renderer.GetContext()->GetBackendType() ==
      Context::BackendType::kOpenGLES) {
    // TODO(https://github.com/flutter/flutter/issues/141732): Implement mip map
    // generation on opengles.
    mip_count = 1;
  }

  std::optional<Snapshot> input_snapshot =
      inputs[0]->GetSnapshot("GaussianBlur", renderer, entity,
                             /*coverage_limit=*/expanded_coverage_hint,
                             /*mip_count=*/mip_count);
  if (!input_snapshot.has_value()) {
    return std::nullopt;
  }

  if (scaled_sigma.x < kEhCloseEnough && scaled_sigma.y < kEhCloseEnough) {
    return Entity::FromSnapshot(input_snapshot.value(), entity.GetBlendMode(),
                                entity.GetClipDepth());  // No blur to render.
  }

  // In order to avoid shimmering in downsampling step, we should have mips.
  if (input_snapshot->texture->GetMipCount() <= 1) {
    FML_DLOG(ERROR) << kNoMipsError;
  }
  FML_DCHECK(!input_snapshot->texture->NeedsMipmapGeneration());

  Scalar desired_scalar =
      std::min(CalculateScale(scaled_sigma.x), CalculateScale(scaled_sigma.y));
  // TODO(jonahwilliams): If desired_scalar is 1.0 and we fully acquired the
  // gutter from the expanded_coverage_hint, we can skip the downsample pass.
  // pass.
  Vector2 downsample_scalar(desired_scalar, desired_scalar);
  Rect source_rect = Rect::MakeSize(input_snapshot->texture->GetSize());
  Rect source_rect_padded = source_rect.Expand(padding);
  Matrix padding_snapshot_adjustment = Matrix::MakeTranslation(-padding);
  // TODO(gaaclarke): The padding could be removed if we know it's not needed or
  //   resized to account for the expanded_clip_coverage. There doesn't appear
  //   to be the math to make those calculations though. The following
  //   optimization works, but causes a shimmer as a result of
  //   https://github.com/flutter/flutter/issues/140193 so it isn't applied.
  //
  //   !input_snapshot->GetCoverage()->Expand(-local_padding)
  //     .Contains(coverage_hint.value()))
  Vector2 downsampled_size = source_rect_padded.GetSize() * downsample_scalar;
  ISize subpass_size =
      ISize(round(downsampled_size.x), round(downsampled_size.y));
  Vector2 effective_scalar =
      Vector2(subpass_size) / source_rect_padded.GetSize();

  Quad uvs = CalculateUVs(inputs[0], entity, source_rect_padded,
                          input_snapshot->texture->GetSize());

  fml::StatusOr<RenderTarget> pass1_out = MakeDownsampleSubpass(
      renderer, input_snapshot->texture, input_snapshot->sampler_descriptor,
      uvs, subpass_size, tile_mode_);

  if (!pass1_out.ok()) {
    return std::nullopt;
  }

  Vector2 pass1_pixel_size =
      1.0 / Vector2(pass1_out.value().GetRenderTargetTexture()->GetSize());

  std::optional<Rect> input_snapshot_coverage = input_snapshot->GetCoverage();
  Quad blur_uvs = {Point(0, 0), Point(1, 0), Point(0, 1), Point(1, 1)};
  if (expanded_coverage_hint.has_value() &&
      input_snapshot_coverage.has_value() &&
      // TODO(https://github.com/flutter/flutter/issues/140890): Remove this
      //   condition. There is some flaw in coverage stopping us from using this
      //   today. I attempted to use source coordinates to calculate the uvs,
      //   but that didn't work either.
      input_snapshot.has_value() &&
      input_snapshot.value().transform.IsTranslationScaleOnly()) {
    // Only process the uvs where the blur is happening, not the whole texture.
    std::optional<Rect> uvs = MakeReferenceUVs(input_snapshot_coverage.value(),
                                               expanded_coverage_hint.value())
                                  .Intersection(Rect::MakeSize(Size(1, 1)));
    FML_DCHECK(uvs.has_value());
    if (uvs.has_value()) {
      blur_uvs[0] = uvs->GetLeftTop();
      blur_uvs[1] = uvs->GetRightTop();
      blur_uvs[2] = uvs->GetLeftBottom();
      blur_uvs[3] = uvs->GetRightBottom();
    }
  }

  fml::StatusOr<RenderTarget> pass2_out = MakeBlurSubpass(
      renderer, /*input_pass=*/pass1_out.value(),
      input_snapshot->sampler_descriptor, tile_mode_,
      BlurParameters{
          .blur_uv_offset = Point(0.0, pass1_pixel_size.y),
          .blur_sigma = scaled_sigma.y * effective_scalar.y,
          .blur_radius = ScaleBlurRadius(blur_radius.y, effective_scalar.y),
          .step_size = 1,
      },
      /*destination_target=*/std::nullopt, blur_uvs);

  if (!pass2_out.ok()) {
    return std::nullopt;
  }

  // Only ping pong if the first pass actually created a render target.
  auto pass3_destination = pass2_out.value().GetRenderTargetTexture() !=
                                   pass1_out.value().GetRenderTargetTexture()
                               ? std::optional<RenderTarget>(pass1_out.value())
                               : std::optional<RenderTarget>(std::nullopt);

  fml::StatusOr<RenderTarget> pass3_out = MakeBlurSubpass(
      renderer, /*input_pass=*/pass2_out.value(),
      input_snapshot->sampler_descriptor, tile_mode_,
      BlurParameters{
          .blur_uv_offset = Point(pass1_pixel_size.x, 0.0),
          .blur_sigma = scaled_sigma.x * effective_scalar.x,
          .blur_radius = ScaleBlurRadius(blur_radius.x, effective_scalar.x),
          .step_size = 1,
      },
      pass3_destination, blur_uvs);

  if (!pass3_out.ok()) {
    return std::nullopt;
  }

  // The ping-pong approach requires that each render pass output has the same
  // size.
  FML_DCHECK((pass1_out.value().GetRenderTargetSize() ==
              pass2_out.value().GetRenderTargetSize()) &&
             (pass2_out.value().GetRenderTargetSize() ==
              pass3_out.value().GetRenderTargetSize()));

  SamplerDescriptor sampler_desc = MakeSamplerDescriptor(
      MinMagFilter::kLinear, SamplerAddressMode::kClampToEdge);

  Entity blur_output_entity = Entity::FromSnapshot(
      Snapshot{.texture = pass3_out.value().GetRenderTargetTexture(),
               .transform = input_snapshot->transform *
                            padding_snapshot_adjustment *
                            Matrix::MakeScale(1 / effective_scalar),
               .sampler_descriptor = sampler_desc,
               .opacity = input_snapshot->opacity},
      entity.GetBlendMode(), entity.GetClipDepth());

  return ApplyBlurStyle(mask_blur_style_, entity, inputs[0],
                        input_snapshot.value(), std::move(blur_output_entity),
                        mask_geometry_);
}

Scalar GaussianBlurFilterContents::CalculateBlurRadius(Scalar sigma) {
  return static_cast<Radius>(Sigma(sigma)).radius;
}

Quad GaussianBlurFilterContents::CalculateUVs(
    const std::shared_ptr<FilterInput>& filter_input,
    const Entity& entity,
    const Rect& source_rect,
    const ISize& texture_size) {
  Matrix input_transform = filter_input->GetLocalTransform(entity);
  Quad coverage_quad = source_rect.GetTransformedPoints(input_transform);

  Matrix uv_transform = Matrix::MakeScale(
      {1.0f / texture_size.width, 1.0f / texture_size.height, 1.0f});
  return uv_transform.Transform(coverage_quad);
}

// This function was calculated by observing Skia's behavior. Its blur at 500
// seemed to be 0.15.  Since we clamp at 500 I solved the quadratic equation
// that puts the minima there and a f(0)=1.
Scalar GaussianBlurFilterContents::ScaleSigma(Scalar sigma) {
  // Limit the kernel size to 1000x1000 pixels, like Skia does.
  Scalar clamped = std::min(sigma, 500.0f);
  constexpr Scalar a = 3.4e-06;
  constexpr Scalar b = -3.4e-3;
  constexpr Scalar c = 1.f;
  Scalar scalar = c + b * clamped + a * clamped * clamped;
  return clamped * scalar;
}

KernelPipeline::FragmentShader::KernelSamples GenerateBlurInfo(
    BlurParameters parameters) {
  KernelPipeline::FragmentShader::KernelSamples result;
  result.sample_count =
      ((2 * parameters.blur_radius) / parameters.step_size) + 1;

  // Chop off the last samples if the radius >= 3 where they account for < 1.56%
  // of the result.
  int x_offset = 0;
  if (parameters.blur_radius >= 3) {
    result.sample_count -= 2;
    x_offset = 1;
  }

  Scalar tally = 0.0f;
  for (int i = 0; i < result.sample_count; ++i) {
    int x = x_offset + (i * parameters.step_size) - parameters.blur_radius;
    result.samples[i] = KernelPipeline::FragmentShader::KernelSample{
        .uv_offset = parameters.blur_uv_offset * x,
        .coefficient = expf(-0.5f * (x * x) /
                            (parameters.blur_sigma * parameters.blur_sigma)) /
                       (sqrtf(2.0f * M_PI) * parameters.blur_sigma),
    };
    tally += result.samples[i].coefficient;
  }

  // Make sure everything adds up to 1.
  for (auto& sample : result.samples) {
    sample.coefficient /= tally;
  }

  return result;
}

// This works by shrinking the kernel size by 2 and relying on lerp to read
// between the samples.
KernelPipeline::FragmentShader::KernelSamples LerpHackKernelSamples(
    KernelPipeline::FragmentShader::KernelSamples parameters) {
  KernelPipeline::FragmentShader::KernelSamples result;
  result.sample_count = ((parameters.sample_count - 1) / 2) + 1;
  int32_t middle = result.sample_count / 2;
  int32_t j = 0;
  for (int i = 0; i < result.sample_count; i++) {
    if (i == middle) {
      result.samples[i] = parameters.samples[j++];
    } else {
      KernelPipeline::FragmentShader::KernelSample left = parameters.samples[j];
      KernelPipeline::FragmentShader::KernelSample right =
          parameters.samples[j + 1];
      result.samples[i] = KernelPipeline::FragmentShader::KernelSample{
          .uv_offset = (left.uv_offset * left.coefficient +
                        right.uv_offset * right.coefficient) /
                       (left.coefficient + right.coefficient),
          .coefficient = left.coefficient + right.coefficient,
      };
      j += 2;
    }
  }

  return result;
}

}  // namespace impeller
