// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/gaussian_blur_filter_contents.h"

#include <valarray>

#include "impeller/base/validation.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/scalar.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/render_target.h"
#include "impeller/renderer/sampler_descriptor.h"
#include "impeller/renderer/sampler_library.h"

namespace impeller {

DirectionalGaussianBlurFilterContents::DirectionalGaussianBlurFilterContents() =
    default;

DirectionalGaussianBlurFilterContents::
    ~DirectionalGaussianBlurFilterContents() = default;

void DirectionalGaussianBlurFilterContents::SetSigma(Sigma sigma) {
  if (sigma.sigma < kEhCloseEnough) {
    // This cutoff is an implementation detail of the blur that's tied to the
    // fragment shader. When the blur is set to 0, having a value slightly above
    // zero makes the shader do 1 finite sample to pass the image through with
    // no blur (while retaining correct alpha mask behavior).
    blur_sigma_ = Sigma{kEhCloseEnough};
    return;
  }
  blur_sigma_ = sigma;
}

void DirectionalGaussianBlurFilterContents::SetDirection(Vector2 direction) {
  blur_direction_ = direction.Normalize();
  if (blur_direction_.IsZero()) {
    blur_direction_ = Vector2(0, 1);
  }
}

void DirectionalGaussianBlurFilterContents::SetBlurStyle(BlurStyle blur_style) {
  blur_style_ = blur_style;

  switch (blur_style) {
    case FilterContents::BlurStyle::kNormal:
      src_color_factor_ = false;
      inner_blur_factor_ = true;
      outer_blur_factor_ = true;
      break;
    case FilterContents::BlurStyle::kSolid:
      src_color_factor_ = true;
      inner_blur_factor_ = false;
      outer_blur_factor_ = true;
      break;
    case FilterContents::BlurStyle::kOuter:
      src_color_factor_ = false;
      inner_blur_factor_ = false;
      outer_blur_factor_ = true;
      break;
    case FilterContents::BlurStyle::kInner:
      src_color_factor_ = false;
      inner_blur_factor_ = true;
      outer_blur_factor_ = false;
      break;
  }
}

void DirectionalGaussianBlurFilterContents::SetTileMode(
    Entity::TileMode tile_mode) {
  tile_mode_ = tile_mode;
}

void DirectionalGaussianBlurFilterContents::SetSourceOverride(
    FilterInput::Ref source_override) {
  source_override_ = source_override;
}

std::optional<Snapshot> DirectionalGaussianBlurFilterContents::RenderFilter(
    const FilterInput::Vector& inputs,
    const ContentContext& renderer,
    const Entity& entity,
    const Rect& coverage) const {
  using VS = GaussianBlurPipeline::VertexShader;
  using FS = GaussianBlurPipeline::FragmentShader;

  //----------------------------------------------------------------------------
  /// Handle inputs.
  ///

  if (inputs.empty()) {
    return std::nullopt;
  }

  // Input 0 snapshot and UV mapping.

  auto input_snapshot = inputs[0]->GetSnapshot(renderer, entity);
  if (!input_snapshot.has_value()) {
    return std::nullopt;
  }
  auto maybe_input_uvs = input_snapshot->GetCoverageUVs(coverage);
  if (!maybe_input_uvs.has_value()) {
    return std::nullopt;
  }
  auto input_uvs = maybe_input_uvs.value();

  // Source override snapshot and UV mapping.

  auto source = source_override_ ? source_override_ : inputs[0];
  auto source_snapshot = source->GetSnapshot(renderer, entity);
  if (!source_snapshot.has_value()) {
    return std::nullopt;
  }
  auto maybe_source_uvs = source_snapshot->GetCoverageUVs(coverage);
  if (!maybe_source_uvs.has_value()) {
    return std::nullopt;
  }
  auto source_uvs = maybe_source_uvs.value();

  //----------------------------------------------------------------------------
  /// Render to texture.
  ///

  ContentContext::SubpassCallback callback = [&](const ContentContext& renderer,
                                                 RenderPass& pass) {
    auto& host_buffer = pass.GetTransientsBuffer();

    VertexBufferBuilder<VS::PerVertexData> vtx_builder;
    vtx_builder.AddVertices({
        {Point(0, 0), input_uvs[0], source_uvs[0]},
        {Point(1, 0), input_uvs[1], source_uvs[1]},
        {Point(1, 1), input_uvs[3], source_uvs[3]},
        {Point(0, 0), input_uvs[0], source_uvs[0]},
        {Point(1, 1), input_uvs[3], source_uvs[3]},
        {Point(0, 1), input_uvs[2], source_uvs[2]},
    });
    auto vtx_buffer = vtx_builder.CreateVertexBuffer(host_buffer);

    auto transformed_blur = entity.GetTransformation().TransformDirection(
        blur_direction_ * blur_sigma_.sigma);

    VS::FrameInfo frame_info;
    frame_info.mvp = Matrix::MakeOrthographic(ISize(1, 1));

    FS::FragInfo frag_info;
    frag_info.texture_sampler_y_coord_scale =
        input_snapshot->texture->GetYCoordScale();
    frag_info.alpha_mask_sampler_y_coord_scale =
        source_snapshot->texture->GetYCoordScale();
    frag_info.blur_sigma = transformed_blur.GetLength();
    frag_info.blur_radius = Radius{Sigma{frag_info.blur_sigma}}.radius;
    frag_info.blur_direction = input_snapshot->transform.Invert()
                                   .TransformDirection(transformed_blur)
                                   .Normalize();
    frag_info.tile_mode = static_cast<Scalar>(tile_mode_);
    frag_info.src_factor = src_color_factor_;
    frag_info.inner_blur_factor = inner_blur_factor_;
    frag_info.outer_blur_factor = outer_blur_factor_;
    frag_info.texture_size = Point(input_snapshot->GetCoverage().value().size);

    SamplerDescriptor sampler_desc;
    sampler_desc.min_filter = MinMagFilter::kLinear;
    sampler_desc.mag_filter = MinMagFilter::kLinear;
    auto sampler =
        renderer.GetContext()->GetSamplerLibrary()->GetSampler(sampler_desc);

    Command cmd;
    cmd.label = "Gaussian Blur Filter";
    auto options = OptionsFromPass(pass);
    options.blend_mode = Entity::BlendMode::kSource;
    cmd.pipeline = renderer.GetGaussianBlurPipeline(options);
    cmd.BindVertices(vtx_buffer);

    FS::BindTextureSampler(cmd, input_snapshot->texture, sampler);
    FS::BindAlphaMaskSampler(cmd, source_snapshot->texture, sampler);
    VS::BindFrameInfo(cmd, host_buffer.EmplaceUniform(frame_info));
    FS::BindFragInfo(cmd, host_buffer.EmplaceUniform(frag_info));

    return pass.AddCommand(cmd);
  };

  auto out_texture = renderer.MakeSubpass(ISize(coverage.size), callback);
  if (!out_texture) {
    return std::nullopt;
  }
  out_texture->SetLabel("DirectionalGaussianBlurFilter Texture");

  return Snapshot{.texture = out_texture,
                  .transform = Matrix::MakeTranslation(coverage.origin)};
}

std::optional<Rect> DirectionalGaussianBlurFilterContents::GetFilterCoverage(
    const FilterInput::Vector& inputs,
    const Entity& entity) const {
  if (inputs.empty()) {
    return std::nullopt;
  }

  auto coverage = inputs[0]->GetCoverage(entity);
  if (!coverage.has_value()) {
    return std::nullopt;
  }

  auto transformed_blur_vector =
      inputs[0]
          ->GetTransform(entity)
          .TransformDirection(blur_direction_ * Radius{blur_sigma_}.radius)
          .Abs();
  auto extent = coverage->size + transformed_blur_vector * 2;
  return Rect(coverage->origin - transformed_blur_vector,
              Size(extent.x, extent.y));
}

}  // namespace impeller
