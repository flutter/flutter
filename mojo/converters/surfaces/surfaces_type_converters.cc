// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/converters/surfaces/surfaces_type_converters.h"

#include "base/macros.h"
#include "cc/output/compositor_frame.h"
#include "cc/output/delegated_frame_data.h"
#include "cc/quads/draw_quad.h"
#include "cc/quads/render_pass.h"
#include "cc/quads/render_pass_draw_quad.h"
#include "cc/quads/shared_quad_state.h"
#include "cc/quads/solid_color_draw_quad.h"
#include "cc/quads/surface_draw_quad.h"
#include "cc/quads/texture_draw_quad.h"
#include "cc/quads/tile_draw_quad.h"
#include "cc/quads/yuv_video_draw_quad.h"
#include "cc/surfaces/surface_id_allocator.h"
#include "mojo/converters/geometry/geometry_type_converters.h"

namespace mojo {

#define ASSERT_ENUM_VALUES_EQUAL(value)                                      \
  COMPILE_ASSERT(cc::DrawQuad::value == static_cast<cc::DrawQuad::Material>( \
                                            MATERIAL_##value),     \
                 value##_enum_value_matches)

ASSERT_ENUM_VALUES_EQUAL(CHECKERBOARD);
ASSERT_ENUM_VALUES_EQUAL(DEBUG_BORDER);
ASSERT_ENUM_VALUES_EQUAL(IO_SURFACE_CONTENT);
ASSERT_ENUM_VALUES_EQUAL(RENDER_PASS);
ASSERT_ENUM_VALUES_EQUAL(SOLID_COLOR);
ASSERT_ENUM_VALUES_EQUAL(STREAM_VIDEO_CONTENT);
ASSERT_ENUM_VALUES_EQUAL(SURFACE_CONTENT);
ASSERT_ENUM_VALUES_EQUAL(TEXTURE_CONTENT);
ASSERT_ENUM_VALUES_EQUAL(TILED_CONTENT);
ASSERT_ENUM_VALUES_EQUAL(YUV_VIDEO_CONTENT);

COMPILE_ASSERT(
    cc::YUVVideoDrawQuad::REC_601 ==
        static_cast<cc::YUVVideoDrawQuad::ColorSpace>(YUV_COLOR_SPACE_REC_601),
    rec_601_enum_matches);
COMPILE_ASSERT(cc::YUVVideoDrawQuad::JPEG ==
                   static_cast<cc::YUVVideoDrawQuad::ColorSpace>(
                       YUV_COLOR_SPACE_JPEG),
               rec_601_jpeg_enum_matches);

namespace {

cc::SharedQuadState* ConvertSharedQuadState(const SharedQuadStatePtr& input,
                                            cc::RenderPass* render_pass) {
  cc::SharedQuadState* state = render_pass->CreateAndAppendSharedQuadState();
  state->SetAll(input->content_to_target_transform.To<gfx::Transform>(),
                input->content_bounds.To<gfx::Size>(),
                input->visible_content_rect.To<gfx::Rect>(),
                input->clip_rect.To<gfx::Rect>(),
                input->is_clipped,
                input->opacity,
                static_cast<::SkXfermode::Mode>(input->blend_mode),
                input->sorting_context_id);
  return state;
}

bool ConvertDrawQuad(const QuadPtr& input,
                     cc::SharedQuadState* sqs,
                     cc::RenderPass* render_pass) {
  switch (input->material) {
    case MATERIAL_RENDER_PASS: {
      cc::RenderPassDrawQuad* render_pass_quad =
          render_pass->CreateAndAppendDrawQuad<cc::RenderPassDrawQuad>();
      RenderPassQuadState* render_pass_quad_state =
          input->render_pass_quad_state.get();
      gfx::PointF mask_uv_scale_as_point =
          render_pass_quad_state->mask_uv_scale.To<gfx::PointF>();
      gfx::PointF filter_scale_as_point =
          render_pass_quad_state->filters_scale.To<gfx::PointF>();
      render_pass_quad->SetAll(
          sqs,
          input->rect.To<gfx::Rect>(),
          input->opaque_rect.To<gfx::Rect>(),
          input->visible_rect.To<gfx::Rect>(),
          input->needs_blending,
          render_pass_quad_state->render_pass_id.To<cc::RenderPassId>(),
          render_pass_quad_state->mask_resource_id,
          mask_uv_scale_as_point.OffsetFromOrigin(),
          render_pass_quad_state->mask_texture_size.To<gfx::Size>(),
          cc::FilterOperations(),  // TODO(jamesr): filters
          filter_scale_as_point.OffsetFromOrigin(),
          cc::FilterOperations());  // TODO(jamesr): background_filters
      break;
    }
    case MATERIAL_SOLID_COLOR: {
      if (input->solid_color_quad_state.is_null())
        return false;
      cc::SolidColorDrawQuad* color_quad =
          render_pass->CreateAndAppendDrawQuad<cc::SolidColorDrawQuad>();
      color_quad->SetAll(
          sqs,
          input->rect.To<gfx::Rect>(),
          input->opaque_rect.To<gfx::Rect>(),
          input->visible_rect.To<gfx::Rect>(),
          input->needs_blending,
          input->solid_color_quad_state->color.To<SkColor>(),
          input->solid_color_quad_state->force_anti_aliasing_off);
      break;
    }
    case MATERIAL_SURFACE_CONTENT: {
      if (input->surface_quad_state.is_null())
        return false;
      cc::SurfaceDrawQuad* surface_quad =
          render_pass->CreateAndAppendDrawQuad<cc::SurfaceDrawQuad>();
      surface_quad->SetAll(
          sqs,
          input->rect.To<gfx::Rect>(),
          input->opaque_rect.To<gfx::Rect>(),
          input->visible_rect.To<gfx::Rect>(),
          input->needs_blending,
          input->surface_quad_state->surface.To<cc::SurfaceId>());
      break;
    }
    case MATERIAL_TEXTURE_CONTENT: {
      TextureQuadStatePtr& texture_quad_state =
          input->texture_quad_state;
      if (texture_quad_state.is_null() ||
          texture_quad_state->vertex_opacity.is_null() ||
          texture_quad_state->background_color.is_null())
        return false;
      cc::TextureDrawQuad* texture_quad =
          render_pass->CreateAndAppendDrawQuad<cc::TextureDrawQuad>();
      texture_quad->SetAll(
          sqs,
          input->rect.To<gfx::Rect>(),
          input->opaque_rect.To<gfx::Rect>(),
          input->visible_rect.To<gfx::Rect>(),
          input->needs_blending,
          texture_quad_state->resource_id,
          texture_quad_state->premultiplied_alpha,
          texture_quad_state->uv_top_left.To<gfx::PointF>(),
          texture_quad_state->uv_bottom_right.To<gfx::PointF>(),
          texture_quad_state->background_color.To<SkColor>(),
          &texture_quad_state->vertex_opacity.storage()[0],
          texture_quad_state->flipped,
          texture_quad_state->nearest_neighbor);
      break;
    }
    case MATERIAL_TILED_CONTENT: {
      TileQuadStatePtr& tile_state = input->tile_quad_state;
      if (tile_state.is_null())
        return false;
      cc::TileDrawQuad* tile_quad =
          render_pass->CreateAndAppendDrawQuad<cc::TileDrawQuad>();
      tile_quad->SetAll(sqs,
                        input->rect.To<gfx::Rect>(),
                        input->opaque_rect.To<gfx::Rect>(),
                        input->visible_rect.To<gfx::Rect>(),
                        input->needs_blending,
                        tile_state->resource_id,
                        tile_state->tex_coord_rect.To<gfx::RectF>(),
                        tile_state->texture_size.To<gfx::Size>(),
                        tile_state->swizzle_contents,
                        tile_state->nearest_neighbor);
      break;
    }
    case MATERIAL_YUV_VIDEO_CONTENT: {
      YUVVideoQuadStatePtr& yuv_state = input->yuv_video_quad_state;
      if (yuv_state.is_null())
        return false;
      cc::YUVVideoDrawQuad* yuv_quad =
          render_pass->CreateAndAppendDrawQuad<cc::YUVVideoDrawQuad>();
      yuv_quad->SetAll(sqs,
                       input->rect.To<gfx::Rect>(),
                       input->opaque_rect.To<gfx::Rect>(),
                       input->visible_rect.To<gfx::Rect>(),
                       input->needs_blending,
                       yuv_state->tex_coord_rect.To<gfx::RectF>(),
                       gfx::Size(),  // TODO(jamesr): texture size
                       yuv_state->y_plane_resource_id,
                       yuv_state->u_plane_resource_id,
                       yuv_state->v_plane_resource_id,
                       yuv_state->a_plane_resource_id,
                       static_cast<cc::YUVVideoDrawQuad::ColorSpace>(
                           yuv_state->color_space));
      break;
    }
    default:
      NOTREACHED() << "Unsupported material " << input->material;
      return false;
  }
  return true;
}

}  // namespace

// static
SurfaceIdPtr TypeConverter<SurfaceIdPtr, cc::SurfaceId>::Convert(
    const cc::SurfaceId& input) {
  SurfaceIdPtr id(SurfaceId::New());
  id->local = static_cast<uint32_t>(input.id);
  id->id_namespace = cc::SurfaceIdAllocator::NamespaceForId(input);
  return id.Pass();
}

// static
cc::SurfaceId TypeConverter<cc::SurfaceId, SurfaceIdPtr>::Convert(
    const SurfaceIdPtr& input) {
  uint64_t packed_id = input->id_namespace;
  packed_id <<= 32ull;
  packed_id |= input->local;
  return cc::SurfaceId(packed_id);
}

// static
ColorPtr TypeConverter<ColorPtr, SkColor>::Convert(const SkColor& input) {
  ColorPtr color(Color::New());
  color->rgba = input;
  return color.Pass();
}

// static
SkColor TypeConverter<SkColor, ColorPtr>::Convert(const ColorPtr& input) {
  return input->rgba;
}

// static
RenderPassIdPtr TypeConverter<RenderPassIdPtr, cc::RenderPassId>::Convert(
    const cc::RenderPassId& input) {
  RenderPassIdPtr pass_id(RenderPassId::New());
  pass_id->layer_id = input.layer_id;
  pass_id->index = input.index;
  return pass_id.Pass();
}

// static
cc::RenderPassId TypeConverter<cc::RenderPassId, RenderPassIdPtr>::Convert(
    const RenderPassIdPtr& input) {
  return cc::RenderPassId(input->layer_id, input->index);
}

// static
QuadPtr TypeConverter<QuadPtr, cc::DrawQuad>::Convert(
    const cc::DrawQuad& input) {
  QuadPtr quad = Quad::New();
  quad->material = static_cast<Material>(input.material);
  quad->rect = Rect::From(input.rect);
  quad->opaque_rect = Rect::From(input.opaque_rect);
  quad->visible_rect = Rect::From(input.visible_rect);
  quad->needs_blending = input.needs_blending;
  // This is intentionally left set to an invalid value here. It's set when
  // converting an entire pass since it's an index into the pass' shared quad
  // state list.
  quad->shared_quad_state_index = UINT32_MAX;
  switch (input.material) {
    case cc::DrawQuad::RENDER_PASS: {
      const cc::RenderPassDrawQuad* render_pass_quad =
          cc::RenderPassDrawQuad::MaterialCast(&input);
      RenderPassQuadStatePtr pass_state = RenderPassQuadState::New();
      pass_state->render_pass_id =
          RenderPassId::From(render_pass_quad->render_pass_id);
      pass_state->mask_resource_id = render_pass_quad->mask_resource_id;
      pass_state->mask_uv_scale = PointF::From(
          gfx::PointAtOffsetFromOrigin(render_pass_quad->mask_uv_scale));
      pass_state->mask_texture_size =
          Size::From(render_pass_quad->mask_texture_size);
      // TODO(jamesr): pass_state->filters
      pass_state->filters_scale = PointF::From(
          gfx::PointAtOffsetFromOrigin(render_pass_quad->filters_scale));
      // TODO(jamesr): pass_state->background_filters
      quad->render_pass_quad_state = pass_state.Pass();
      break;
    }
    case cc::DrawQuad::SOLID_COLOR: {
      const cc::SolidColorDrawQuad* color_quad =
          cc::SolidColorDrawQuad::MaterialCast(&input);
      SolidColorQuadStatePtr color_state = SolidColorQuadState::New();
      color_state->color = Color::From(color_quad->color);
      color_state->force_anti_aliasing_off =
          color_quad->force_anti_aliasing_off;
      quad->solid_color_quad_state = color_state.Pass();
      break;
    }
    case cc::DrawQuad::SURFACE_CONTENT: {
      const cc::SurfaceDrawQuad* surface_quad =
          cc::SurfaceDrawQuad::MaterialCast(&input);
      SurfaceQuadStatePtr surface_state =
          SurfaceQuadState::New();
      surface_state->surface = SurfaceId::From(surface_quad->surface_id);
      quad->surface_quad_state = surface_state.Pass();
      break;
    }
    case cc::DrawQuad::TEXTURE_CONTENT: {
      const cc::TextureDrawQuad* texture_quad =
          cc::TextureDrawQuad::MaterialCast(&input);
      TextureQuadStatePtr texture_state = TextureQuadState::New();
      texture_state->resource_id = texture_quad->resource_id;
      texture_state->premultiplied_alpha = texture_quad->premultiplied_alpha;
      texture_state->uv_top_left = PointF::From(texture_quad->uv_top_left);
      texture_state->uv_bottom_right =
          PointF::From(texture_quad->uv_bottom_right);
      texture_state->background_color =
          Color::From(texture_quad->background_color);
      Array<float> vertex_opacity(4);
      for (size_t i = 0; i < 4; ++i) {
        vertex_opacity[i] = texture_quad->vertex_opacity[i];
      }
      texture_state->vertex_opacity = vertex_opacity.Pass();
      texture_state->flipped = texture_quad->flipped;
      quad->texture_quad_state = texture_state.Pass();
      break;
    }
    case cc::DrawQuad::TILED_CONTENT: {
      const cc::TileDrawQuad* tile_quad =
          cc::TileDrawQuad::MaterialCast(&input);
      TileQuadStatePtr tile_state = TileQuadState::New();
      tile_state->tex_coord_rect = RectF::From(tile_quad->tex_coord_rect);
      tile_state->texture_size = Size::From(tile_quad->texture_size);
      tile_state->swizzle_contents = tile_quad->swizzle_contents;
      tile_state->resource_id = tile_quad->resource_id;
      quad->tile_quad_state = tile_state.Pass();
      break;
    }
    case cc::DrawQuad::YUV_VIDEO_CONTENT: {
      const cc::YUVVideoDrawQuad* yuv_quad =
          cc::YUVVideoDrawQuad::MaterialCast(&input);
      YUVVideoQuadStatePtr yuv_state = YUVVideoQuadState::New();
      yuv_state->tex_coord_rect = RectF::From(yuv_quad->tex_coord_rect);
      yuv_state->y_plane_resource_id = yuv_quad->y_plane_resource_id;
      yuv_state->u_plane_resource_id = yuv_quad->u_plane_resource_id;
      yuv_state->v_plane_resource_id = yuv_quad->v_plane_resource_id;
      yuv_state->a_plane_resource_id = yuv_quad->a_plane_resource_id;
      yuv_state->color_space =
          static_cast<YUVColorSpace>(yuv_quad->color_space);
      quad->yuv_video_quad_state = yuv_state.Pass();
      break;
    }

    default:
      NOTREACHED() << "Unsupported material " << input.material;
  }
  return quad.Pass();
}

// static
SharedQuadStatePtr
TypeConverter<SharedQuadStatePtr, cc::SharedQuadState>::Convert(
    const cc::SharedQuadState& input) {
  SharedQuadStatePtr state = SharedQuadState::New();
  state->content_to_target_transform =
      Transform::From(input.content_to_target_transform);
  state->content_bounds = Size::From(input.content_bounds);
  state->visible_content_rect = Rect::From(input.visible_content_rect);
  state->clip_rect = Rect::From(input.clip_rect);
  state->is_clipped = input.is_clipped;
  state->opacity = input.opacity;
  state->blend_mode = static_cast<SkXfermode>(input.blend_mode);
  state->sorting_context_id = input.sorting_context_id;
  return state.Pass();
}

// static
PassPtr TypeConverter<PassPtr, cc::RenderPass>::Convert(
    const cc::RenderPass& input) {
  PassPtr pass = Pass::New();
  pass->id = input.id.index;
  pass->output_rect = Rect::From(input.output_rect);
  pass->damage_rect = Rect::From(input.damage_rect);
  pass->transform_to_root_target =
      Transform::From(input.transform_to_root_target);
  pass->has_transparent_background = input.has_transparent_background;
  Array<QuadPtr> quads(input.quad_list.size());
  Array<SharedQuadStatePtr> shared_quad_state(
      input.shared_quad_state_list.size());
  const cc::SharedQuadState* last_sqs = nullptr;
  cc::SharedQuadStateList::ConstIterator next_sqs_iter =
      input.shared_quad_state_list.begin();
  for (auto iter = input.quad_list.cbegin(); iter != input.quad_list.cend();
       ++iter) {
    const cc::DrawQuad& quad = **iter;
    quads[iter.index()] = Quad::From(quad);
    if (quad.shared_quad_state != last_sqs) {
      shared_quad_state[next_sqs_iter.index()] =
          SharedQuadState::From(**next_sqs_iter);
      last_sqs = *next_sqs_iter;
      ++next_sqs_iter;
    }
    DCHECK_LE(next_sqs_iter.index() - 1, UINT32_MAX);
    quads[iter.index()]->shared_quad_state_index =
        static_cast<uint32_t>(next_sqs_iter.index() - 1);
  }
  // We should copy all shared quad states.
  DCHECK_EQ(next_sqs_iter.index(), shared_quad_state.size());
  pass->quads = quads.Pass();
  pass->shared_quad_states = shared_quad_state.Pass();
  return pass.Pass();
}

// static
scoped_ptr<cc::RenderPass>
TypeConverter<scoped_ptr<cc::RenderPass>, PassPtr>::Convert(
    const PassPtr& input) {
  scoped_ptr<cc::RenderPass> pass = cc::RenderPass::Create(
      input->shared_quad_states.size(), input->quads.size());
  pass->SetAll(cc::RenderPassId(1, input->id),
               input->output_rect.To<gfx::Rect>(),
               input->damage_rect.To<gfx::Rect>(),
               input->transform_to_root_target.To<gfx::Transform>(),
               input->has_transparent_background);
  for (size_t i = 0; i < input->shared_quad_states.size(); ++i) {
    ConvertSharedQuadState(input->shared_quad_states[i], pass.get());
  }
  cc::SharedQuadStateList::Iterator sqs_iter =
      pass->shared_quad_state_list.begin();
  for (size_t i = 0; i < input->quads.size(); ++i) {
    QuadPtr quad = input->quads[i].Pass();
    while (quad->shared_quad_state_index > sqs_iter.index()) {
      ++sqs_iter;
    }
    if (!ConvertDrawQuad(quad, *sqs_iter, pass.get()))
      return scoped_ptr<cc::RenderPass>();
  }
  return pass.Pass();
}

// static
MailboxPtr TypeConverter<MailboxPtr, gpu::Mailbox>::Convert(
    const gpu::Mailbox& input) {
  Array<int8_t> name(64);
  for (int i = 0; i < 64; ++i) {
    name[i] = input.name[i];
  }
  MailboxPtr mailbox(Mailbox::New());
  mailbox->name = name.Pass();
  return mailbox.Pass();
}

// static
gpu::Mailbox TypeConverter<gpu::Mailbox, MailboxPtr>::Convert(
    const MailboxPtr& input) {
  gpu::Mailbox mailbox;
  if (!input->name.is_null())
    mailbox.SetName(&input->name.storage()[0]);
  return mailbox;
}

// static
MailboxHolderPtr TypeConverter<MailboxHolderPtr, gpu::MailboxHolder>::Convert(
    const gpu::MailboxHolder& input) {
  MailboxHolderPtr holder(MailboxHolder::New());
  holder->mailbox = Mailbox::From<gpu::Mailbox>(input.mailbox);
  holder->texture_target = input.texture_target;
  holder->sync_point = input.sync_point;
  return holder.Pass();
}

// static
gpu::MailboxHolder TypeConverter<gpu::MailboxHolder, MailboxHolderPtr>::Convert(
    const MailboxHolderPtr& input) {
  gpu::MailboxHolder holder;
  holder.mailbox = input->mailbox.To<gpu::Mailbox>();
  holder.texture_target = input->texture_target;
  holder.sync_point = input->sync_point;
  return holder;
}

// static
TransferableResourcePtr
TypeConverter<TransferableResourcePtr, cc::TransferableResource>::Convert(
    const cc::TransferableResource& input) {
  TransferableResourcePtr transferable = TransferableResource::New();
  transferable->id = input.id;
  transferable->format = static_cast<ResourceFormat>(input.format);
  transferable->filter = input.filter;
  transferable->size = Size::From(input.size);
  transferable->mailbox_holder = MailboxHolder::From(input.mailbox_holder);
  transferable->is_repeated = input.is_repeated;
  transferable->is_software = input.is_software;
  return transferable.Pass();
}

// static
cc::TransferableResource
TypeConverter<cc::TransferableResource, TransferableResourcePtr>::Convert(
    const TransferableResourcePtr& input) {
  cc::TransferableResource transferable;
  transferable.id = input->id;
  transferable.format = static_cast<cc::ResourceFormat>(input->format);
  transferable.filter = input->filter;
  transferable.size = input->size.To<gfx::Size>();
  transferable.mailbox_holder = input->mailbox_holder.To<gpu::MailboxHolder>();
  transferable.is_repeated = input->is_repeated;
  transferable.is_software = input->is_software;
  return transferable;
}

// static
Array<TransferableResourcePtr> TypeConverter<
    Array<TransferableResourcePtr>,
    cc::TransferableResourceArray>::Convert(const cc::TransferableResourceArray&
                                                input) {
  Array<TransferableResourcePtr> resources(input.size());
  for (size_t i = 0; i < input.size(); ++i) {
    resources[i] = TransferableResource::From(input[i]);
  }
  return resources.Pass();
}

// static
cc::TransferableResourceArray
TypeConverter<cc::TransferableResourceArray, Array<TransferableResourcePtr> >::
    Convert(const Array<TransferableResourcePtr>& input) {
  cc::TransferableResourceArray resources(input.size());
  for (size_t i = 0; i < input.size(); ++i) {
    resources[i] = input[i].To<cc::TransferableResource>();
  }
  return resources;
}

// static
ReturnedResourcePtr
TypeConverter<ReturnedResourcePtr, cc::ReturnedResource>::Convert(
    const cc::ReturnedResource& input) {
  ReturnedResourcePtr returned = ReturnedResource::New();
  returned->id = input.id;
  returned->sync_point = input.sync_point;
  returned->count = input.count;
  returned->lost = input.lost;
  return returned.Pass();
}

// static
cc::ReturnedResource
TypeConverter<cc::ReturnedResource, ReturnedResourcePtr>::Convert(
    const ReturnedResourcePtr& input) {
  cc::ReturnedResource returned;
  returned.id = input->id;
  returned.sync_point = input->sync_point;
  returned.count = input->count;
  returned.lost = input->lost;
  return returned;
}

// static
Array<ReturnedResourcePtr>
TypeConverter<Array<ReturnedResourcePtr>, cc::ReturnedResourceArray>::Convert(
    const cc::ReturnedResourceArray& input) {
  Array<ReturnedResourcePtr> resources(input.size());
  for (size_t i = 0; i < input.size(); ++i) {
    resources[i] = ReturnedResource::From(input[i]);
  }
  return resources.Pass();
}

// static
FramePtr TypeConverter<FramePtr, cc::CompositorFrame>::Convert(
    const cc::CompositorFrame& input) {
  FramePtr frame = Frame::New();
  DCHECK(input.delegated_frame_data);
  cc::DelegatedFrameData* frame_data = input.delegated_frame_data.get();
  frame->resources =
      Array<TransferableResourcePtr>::From(frame_data->resource_list);
  const cc::RenderPassList& pass_list = frame_data->render_pass_list;
  frame->passes = Array<PassPtr>::New(pass_list.size());
  for (size_t i = 0; i < pass_list.size(); ++i) {
    frame->passes[i] = Pass::From(*pass_list[i]);
  }
  return frame.Pass();
}

// static
scoped_ptr<cc::CompositorFrame>
TypeConverter<scoped_ptr<cc::CompositorFrame>, FramePtr>::Convert(
    const FramePtr& input) {
  scoped_ptr<cc::DelegatedFrameData> frame_data(new cc::DelegatedFrameData);
  frame_data->device_scale_factor = 1.f;
  frame_data->resource_list =
      input->resources.To<cc::TransferableResourceArray>();
  frame_data->render_pass_list.reserve(input->passes.size());
  for (size_t i = 0; i < input->passes.size(); ++i) {
    scoped_ptr<cc::RenderPass> pass =
        input->passes[i].To<scoped_ptr<cc::RenderPass> >();
    if (!pass)
      return scoped_ptr<cc::CompositorFrame>();
    frame_data->render_pass_list.push_back(pass.Pass());
  }
  scoped_ptr<cc::CompositorFrame> frame(new cc::CompositorFrame);
  frame->delegated_frame_data = frame_data.Pass();
  return frame.Pass();
}

}  // namespace mojo
