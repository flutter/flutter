// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/contents/contents.h"
#include <optional>

#include "fml/logging.h"
#include "impeller/base/strings.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {

ContentContextOptions OptionsFromPass(const RenderPass& pass) {
  ContentContextOptions opts;
  opts.sample_count = pass.GetRenderTarget().GetSampleCount();
  opts.color_attachment_pixel_format =
      pass.GetRenderTarget().GetRenderTargetPixelFormat();
  opts.has_stencil_attachment =
      pass.GetRenderTarget().GetStencilAttachment().has_value();
  return opts;
}

ContentContextOptions OptionsFromPassAndEntity(const RenderPass& pass,
                                               const Entity& entity) {
  ContentContextOptions opts;
  opts.sample_count = pass.GetRenderTarget().GetSampleCount();
  opts.color_attachment_pixel_format =
      pass.GetRenderTarget().GetRenderTargetPixelFormat();
  opts.has_stencil_attachment =
      pass.GetRenderTarget().GetStencilAttachment().has_value();
  opts.blend_mode = entity.GetBlendMode();
  return opts;
}

std::optional<Entity> Contents::EntityFromSnapshot(
    const std::optional<Snapshot>& snapshot,
    BlendMode blend_mode,
    uint32_t stencil_depth) {
  if (!snapshot.has_value()) {
    return std::nullopt;
  }

  auto texture_rect = Rect::MakeSize(snapshot->texture->GetSize());

  auto contents = TextureContents::MakeRect(texture_rect);
  contents->SetTexture(snapshot->texture);
  contents->SetSamplerDescriptor(snapshot->sampler_descriptor);
  contents->SetSourceRect(texture_rect);
  contents->SetOpacity(snapshot->opacity);

  Entity entity;
  entity.SetBlendMode(blend_mode);
  entity.SetStencilDepth(stencil_depth);
  entity.SetTransformation(snapshot->transform);
  entity.SetContents(contents);
  return entity;
}

Contents::Contents() = default;

Contents::~Contents() = default;

Contents::StencilCoverage Contents::GetStencilCoverage(
    const Entity& entity,
    const std::optional<Rect>& current_stencil_coverage) const {
  return {.type = StencilCoverage::Type::kNone,
          .coverage = current_stencil_coverage};
}

std::optional<Snapshot> Contents::RenderToSnapshot(
    const ContentContext& renderer,
    const Entity& entity,
    const std::optional<SamplerDescriptor>& sampler_descriptor,
    bool msaa_enabled) const {
  auto coverage = GetCoverage(entity);
  if (!coverage.has_value()) {
    return std::nullopt;
  }

  auto texture = renderer.MakeSubpass(
      "Snapshot", ISize::Ceil(coverage->size),
      [&contents = *this, &entity, &coverage](const ContentContext& renderer,
                                              RenderPass& pass) -> bool {
        Entity sub_entity;
        sub_entity.SetBlendMode(BlendMode::kSourceOver);
        sub_entity.SetTransformation(
            Matrix::MakeTranslation(Vector3(-coverage->origin)) *
            entity.GetTransformation());
        return contents.Render(renderer, sub_entity, pass);
      },
      msaa_enabled);

  if (!texture) {
    return std::nullopt;
  }

  auto snapshot = Snapshot{
      .texture = texture,
      .transform = Matrix::MakeTranslation(coverage->origin),
  };
  if (sampler_descriptor.has_value()) {
    snapshot.sampler_descriptor = sampler_descriptor.value();
  }

  return snapshot;
}

bool Contents::ShouldRender(const Entity& entity,
                            const std::optional<Rect>& stencil_coverage) const {
  if (!stencil_coverage.has_value()) {
    return false;
  }
  if (Entity::BlendModeShouldCoverWholeScreen(entity.GetBlendMode())) {
    return true;
  }

  auto coverage = GetCoverage(entity);
  if (!coverage.has_value()) {
    return false;
  }
  if (coverage == Rect::MakeMaximum()) {
    return true;
  }
  return stencil_coverage->IntersectsWithRect(coverage.value());
}

}  // namespace impeller
