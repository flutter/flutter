// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/filters/runtime_effect_filter_contents.h"

#include <cstring>
#include <optional>

#include "impeller/base/validation.h"
#include "impeller/entity/contents/anonymous_contents.h"
#include "impeller/entity/contents/runtime_effect_contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/geometry/size.h"

namespace impeller {

void RuntimeEffectFilterContents::SetRuntimeStage(
    std::shared_ptr<RuntimeStage> runtime_stage) {
  runtime_stage_ = std::move(runtime_stage);
}

void RuntimeEffectFilterContents::SetUniforms(
    std::shared_ptr<std::vector<uint8_t>> uniforms) {
  uniforms_ = std::move(uniforms);
}

void RuntimeEffectFilterContents::SetTextureInputs(
    std::vector<RuntimeEffectContents::TextureInput> texture_inputs) {
  texture_inputs_ = std::move(texture_inputs);
}

// |FilterContents|
std::optional<Entity> RuntimeEffectFilterContents::RenderFilter(
    const FilterInput::Vector& inputs,
    const ContentContext& renderer,
    const Entity& entity,
    const Matrix& effect_transform,
    const Rect& coverage,
    const std::optional<Rect>& coverage_hint) const {
  if (inputs.empty()) {
    return std::nullopt;
  }

  std::optional<Snapshot> input_snapshot =
      inputs[0]->GetSnapshot("RuntimeEffectContents", renderer, entity);
  if (!input_snapshot.has_value()) {
    return std::nullopt;
  }

  std::optional<Rect> maybe_input_coverage = input_snapshot->GetCoverage();
  if (!maybe_input_coverage.has_value()) {
    return std::nullopt;
  }

  // If the input snapshot does not have an identity transform the
  // ImageFilter.shader will not correctly render as it does not know what the
  // transform is in order to incorporate this into sampling. We need to
  // re-rasterize the input snapshot so that the transform is absorbed into the
  // texture.
  // We can technically render this only when the snapshot is just a translated
  // version of the original. Unfortunately there isn't a way to test for that
  // though. Blur with low sigmas will return a transform that doesn't scale but
  // has a tiny offset to account for the blur radius. That's indistinguishable
  // from `ImageFilter.compose` which slightly increase the size to account for
  // rounding errors and add an offset. Said another way; ideally we would skip
  // this branch for the unit test `ComposePaintRuntimeOuter`, but do it for
  // `ComposeBackdropRuntimeOuterBlurInner`.
  if (input_snapshot->ShouldRasterizeForRuntimeEffects()) {
    Matrix inverse = input_snapshot->transform.Invert();
    Quad quad = inverse.Transform(Quad{
        coverage.GetLeftTop(),     //
        coverage.GetRightTop(),    //
        coverage.GetLeftBottom(),  //
        coverage.GetRightBottom()  //
    });
    TextureContents texture_contents;
    texture_contents.SetTexture(input_snapshot->texture);
    std::optional<Rect> bounds =
        Rect::MakePointBounds(quad.begin(), quad.end());
    if (bounds.has_value()) {
      texture_contents.SetSourceRect(bounds.value());
      texture_contents.SetDestinationRect(coverage);
      texture_contents.SetStencilEnabled(false);
      texture_contents.SetSamplerDescriptor(input_snapshot->sampler_descriptor);

      Entity entity;
      // In order to maintain precise coordinates in the fragment shader we need
      // to eliminate the padding typically given to RenderToSnapshot results.
      input_snapshot = texture_contents.RenderToSnapshot(
          renderer, entity, {.coverage_expansion = 0});
      if (!input_snapshot.has_value()) {
        return std::nullopt;
      }
    }
  }

  // The shader is required to have at least one sampler, the first of
  // which is treated as the input and a vec2 size uniform to compute the
  // offsets. These are validated at the dart:ui layer, but to avoid crashes we
  // check here too.
  if (texture_inputs_.size() < 1 || uniforms_->size() < 8) {
    VALIDATION_LOG
        << "Invalid fragment shader in RuntimeEffectFilterContents. "
        << "Shader must have at least one sampler and a vec2 size uniform.";
    return std::nullopt;
  }

  // Update uniform values.
  std::vector<RuntimeEffectContents::TextureInput> texture_input_copy =
      texture_inputs_;
  texture_input_copy[0].texture = input_snapshot->texture;

  Size size = Size(input_snapshot->texture->GetSize());
  memcpy(uniforms_->data(), &size, sizeof(Size));

  Matrix snapshot_transform = input_snapshot->transform;
  //----------------------------------------------------------------------------
  /// Create AnonymousContents for rendering.
  ///
  RenderProc render_proc =
      [snapshot_transform, input_snapshot, runtime_stage = runtime_stage_,
       uniforms = uniforms_, texture_inputs = texture_input_copy](
          const ContentContext& renderer, const Entity& entity,
          RenderPass& pass) -> bool {
    RuntimeEffectContents contents;
    FillRectGeometry geom(Rect::MakeSize(input_snapshot->texture->GetSize()));
    contents.SetRuntimeStage(runtime_stage);
    contents.SetUniformData(uniforms);
    contents.SetTextureInputs(texture_inputs);
    contents.SetGeometry(&geom);
    Entity offset_entity = entity.Clone();
    offset_entity.SetTransform(entity.GetTransform() * snapshot_transform);
    return contents.Render(renderer, offset_entity, pass);
  };

  CoverageProc coverage_proc =
      [coverage](const Entity& entity) -> std::optional<Rect> {
    return coverage;
  };

  auto contents = AnonymousContents::Make(render_proc, coverage_proc);

  Entity sub_entity;
  sub_entity.SetContents(std::move(contents));
  sub_entity.SetBlendMode(entity.GetBlendMode());
  sub_entity.SetTransform(input_snapshot->transform *
                          snapshot_transform.Invert());

  return sub_entity;
}

// |FilterContents|
std::optional<Rect> RuntimeEffectFilterContents::GetFilterSourceCoverage(
    const Matrix& effect_transform,
    const Rect& output_limit) const {
  return output_limit;
}

}  // namespace impeller
