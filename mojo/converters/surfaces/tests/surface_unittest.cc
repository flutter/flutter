// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "cc/quads/render_pass.h"
#include "cc/quads/solid_color_draw_quad.h"
#include "cc/quads/surface_draw_quad.h"
#include "cc/quads/texture_draw_quad.h"
#include "gpu/command_buffer/common/mailbox.h"
#include "gpu/command_buffer/common/mailbox_holder.h"
#include "mojo/converters/geometry/geometry_type_converters.h"
#include "mojo/converters/surfaces/surfaces_type_converters.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkXfermode.h"

namespace mojo {
namespace {

TEST(SurfaceLibTest, SurfaceIdConverterNullId) {
  cc::SurfaceId null_id;
  cc::SurfaceId round_trip = SurfaceId::From(null_id).To<cc::SurfaceId>();
  EXPECT_TRUE(round_trip.is_null());
}

TEST(SurfaceLibTest, SurfaceIdConverterValidId) {
  cc::SurfaceId valid_id(7);
  cc::SurfaceId round_trip = SurfaceId::From(valid_id).To<cc::SurfaceId>();
  EXPECT_FALSE(round_trip.is_null());
  EXPECT_EQ(valid_id, round_trip);
}

TEST(SurfaceLibTest, Color) {
  SkColor arbitrary_color = SK_ColorMAGENTA;
  SkColor round_trip = Color::From(arbitrary_color).To<SkColor>();
  EXPECT_EQ(arbitrary_color, round_trip);
}

class SurfaceLibQuadTest : public testing::Test {
 public:
  SurfaceLibQuadTest()
      : rect(5, 7, 13, 19),
        opaque_rect(rect),
        visible_rect(9, 11, 5, 7),
        needs_blending(false) {
    pass = cc::RenderPass::Create();
    sqs = pass->CreateAndAppendSharedQuadState();
  }

 protected:
  gfx::Rect rect;
  gfx::Rect opaque_rect;
  gfx::Rect visible_rect;
  bool needs_blending;
  scoped_ptr<cc::RenderPass> pass;
  cc::SharedQuadState* sqs;
};

TEST_F(SurfaceLibQuadTest, ColorQuad) {
  cc::SolidColorDrawQuad* color_quad =
      pass->CreateAndAppendDrawQuad<cc::SolidColorDrawQuad>();
  SkColor arbitrary_color = SK_ColorGREEN;
  bool force_anti_aliasing_off = true;
  color_quad->SetAll(sqs,
                     rect,
                     opaque_rect,
                     visible_rect,
                     needs_blending,
                     arbitrary_color,
                     force_anti_aliasing_off);

  QuadPtr mojo_quad = Quad::From<cc::DrawQuad>(*color_quad);
  ASSERT_FALSE(mojo_quad.is_null());
  EXPECT_EQ(MATERIAL_SOLID_COLOR, mojo_quad->material);
  EXPECT_EQ(Rect::From(rect), mojo_quad->rect);
  EXPECT_EQ(Rect::From(opaque_rect), mojo_quad->opaque_rect);
  EXPECT_EQ(Rect::From(visible_rect), mojo_quad->visible_rect);
  EXPECT_EQ(needs_blending, mojo_quad->needs_blending);
  ASSERT_TRUE(mojo_quad->solid_color_quad_state);
  SolidColorQuadStatePtr& mojo_color_state = mojo_quad->solid_color_quad_state;
  EXPECT_EQ(Color::From(arbitrary_color), mojo_color_state->color);
  EXPECT_EQ(force_anti_aliasing_off, mojo_color_state->force_anti_aliasing_off);
}

TEST_F(SurfaceLibQuadTest, SurfaceQuad) {
  cc::SurfaceDrawQuad* surface_quad =
      pass->CreateAndAppendDrawQuad<cc::SurfaceDrawQuad>();
  cc::SurfaceId arbitrary_id(5);
  surface_quad->SetAll(
      sqs, rect, opaque_rect, visible_rect, needs_blending, arbitrary_id);

  QuadPtr mojo_quad = Quad::From<cc::DrawQuad>(*surface_quad);
  ASSERT_FALSE(mojo_quad.is_null());
  EXPECT_EQ(MATERIAL_SURFACE_CONTENT, mojo_quad->material);
  ASSERT_TRUE(mojo_quad->surface_quad_state);
  SurfaceQuadStatePtr& mojo_surface_state = mojo_quad->surface_quad_state;
  EXPECT_EQ(SurfaceId::From(arbitrary_id),
            mojo_surface_state->surface);
}

TEST_F(SurfaceLibQuadTest, TextureQuad) {
  cc::TextureDrawQuad* texture_quad =
      pass->CreateAndAppendDrawQuad<cc::TextureDrawQuad>();
  unsigned resource_id = 9;
  bool premultiplied_alpha = true;
  gfx::PointF uv_top_left(1.7f, 2.1f);
  gfx::PointF uv_bottom_right(-7.f, 16.3f);
  SkColor background_color = SK_ColorYELLOW;
  float vertex_opacity[4] = {0.1f, 0.5f, 0.4f, 0.8f};
  bool flipped = false;
  bool nearest_neighbor = false;
  texture_quad->SetAll(sqs,
                       rect,
                       opaque_rect,
                       visible_rect,
                       needs_blending,
                       resource_id,
                       premultiplied_alpha,
                       uv_top_left,
                       uv_bottom_right,
                       background_color,
                       vertex_opacity,
                       flipped,
                       nearest_neighbor);

  QuadPtr mojo_quad = Quad::From<cc::DrawQuad>(*texture_quad);
  ASSERT_FALSE(mojo_quad.is_null());
  EXPECT_EQ(MATERIAL_TEXTURE_CONTENT, mojo_quad->material);
  ASSERT_TRUE(mojo_quad->texture_quad_state);
  TextureQuadStatePtr& mojo_texture_state = mojo_quad->texture_quad_state;
  EXPECT_EQ(resource_id, mojo_texture_state->resource_id);
  EXPECT_EQ(premultiplied_alpha, mojo_texture_state->premultiplied_alpha);
  EXPECT_EQ(PointF::From(uv_top_left), mojo_texture_state->uv_top_left);
  EXPECT_EQ(PointF::From(uv_bottom_right), mojo_texture_state->uv_bottom_right);
  EXPECT_EQ(Color::From(background_color),
            mojo_texture_state->background_color);
  for (size_t i = 0; i < 4; ++i) {
    EXPECT_EQ(vertex_opacity[i], mojo_texture_state->vertex_opacity[i]) << i;
  }
  EXPECT_EQ(flipped, mojo_texture_state->flipped);
}

TEST_F(SurfaceLibQuadTest, TextureQuadEmptyVertexOpacity) {
  QuadPtr mojo_texture_quad = Quad::New();
  mojo_texture_quad->material = MATERIAL_TEXTURE_CONTENT;
  TextureQuadStatePtr mojo_texture_state = TextureQuadState::New();
  mojo_texture_state->background_color = Color::New();
  mojo_texture_quad->texture_quad_state = mojo_texture_state.Pass();
  PassPtr mojo_pass = Pass::New();
  mojo_pass->quads.push_back(mojo_texture_quad.Pass());
  SharedQuadStatePtr mojo_sqs = SharedQuadState::New();
  mojo_pass->shared_quad_states.push_back(mojo_sqs.Pass());

  scoped_ptr<cc::RenderPass> pass = mojo_pass.To<scoped_ptr<cc::RenderPass> >();

  EXPECT_FALSE(pass);
}

TEST_F(SurfaceLibQuadTest, TextureQuadEmptyBackgroundColor) {
  QuadPtr mojo_texture_quad = Quad::New();
  mojo_texture_quad->material = MATERIAL_TEXTURE_CONTENT;
  TextureQuadStatePtr mojo_texture_state = TextureQuadState::New();
  mojo_texture_state->vertex_opacity = mojo::Array<float>::New(4);
  mojo_texture_quad->texture_quad_state = mojo_texture_state.Pass();
  PassPtr mojo_pass = Pass::New();
  mojo_pass->quads.push_back(mojo_texture_quad.Pass());
  SharedQuadStatePtr mojo_sqs = SharedQuadState::New();
  mojo_pass->shared_quad_states.push_back(mojo_sqs.Pass());

  scoped_ptr<cc::RenderPass> pass = mojo_pass.To<scoped_ptr<cc::RenderPass> >();
  EXPECT_FALSE(pass);
}

TEST(SurfaceLibTest, SharedQuadState) {
  gfx::Transform content_to_target_transform;
  content_to_target_transform.Scale3d(0.3f, 0.7f, 0.9f);
  gfx::Size content_bounds(57, 39);
  gfx::Rect visible_content_rect(3, 7, 28, 42);
  gfx::Rect clip_rect(9, 12, 21, 31);
  bool is_clipped = true;
  float opacity = 0.65f;
  int sorting_context_id = 13;
  ::SkXfermode::Mode blend_mode = ::SkXfermode::kSrcOver_Mode;
  scoped_ptr<cc::RenderPass> pass = cc::RenderPass::Create();
  cc::SharedQuadState* sqs = pass->CreateAndAppendSharedQuadState();
  sqs->SetAll(content_to_target_transform,
              content_bounds,
              visible_content_rect,
              clip_rect,
              is_clipped,
              opacity,
              blend_mode,
              sorting_context_id);

  SharedQuadStatePtr mojo_sqs = SharedQuadState::From(*sqs);
  ASSERT_FALSE(mojo_sqs.is_null());
  EXPECT_EQ(Transform::From(content_to_target_transform),
            mojo_sqs->content_to_target_transform);
  EXPECT_EQ(Size::From(content_bounds), mojo_sqs->content_bounds);
  EXPECT_EQ(Rect::From(visible_content_rect), mojo_sqs->visible_content_rect);
  EXPECT_EQ(Rect::From(clip_rect), mojo_sqs->clip_rect);
  EXPECT_EQ(is_clipped, mojo_sqs->is_clipped);
  EXPECT_EQ(opacity, mojo_sqs->opacity);
  EXPECT_EQ(sorting_context_id, mojo_sqs->sorting_context_id);
}

TEST(SurfaceLibTest, RenderPass) {
  scoped_ptr<cc::RenderPass> pass = cc::RenderPass::Create();
  cc::RenderPassId pass_id(1, 6);
  gfx::Rect output_rect(4, 9, 13, 71);
  gfx::Rect damage_rect(9, 17, 41, 45);
  gfx::Transform transform_to_root_target;
  transform_to_root_target.SkewY(43.0);
  bool has_transparent_background = false;
  pass->SetAll(pass_id,
               output_rect,
               damage_rect,
               transform_to_root_target,
               has_transparent_background);

  gfx::Transform content_to_target_transform;
  content_to_target_transform.Scale3d(0.3f, 0.7f, 0.9f);
  gfx::Size content_bounds(57, 39);
  gfx::Rect visible_content_rect(3, 7, 28, 42);
  gfx::Rect clip_rect(9, 12, 21, 31);
  bool is_clipped = true;
  float opacity = 0.65f;
  int sorting_context_id = 13;
  ::SkXfermode::Mode blend_mode = ::SkXfermode::kSrcOver_Mode;
  cc::SharedQuadState* sqs = pass->CreateAndAppendSharedQuadState();
  sqs->SetAll(content_to_target_transform,
              content_bounds,
              visible_content_rect,
              clip_rect,
              is_clipped,
              opacity,
              blend_mode,
              sorting_context_id);

  gfx::Rect rect(5, 7, 13, 19);
  gfx::Rect opaque_rect(rect);
  gfx::Rect visible_rect(9, 11, 5, 7);
  bool needs_blending = false;

  cc::SolidColorDrawQuad* color_quad =
      pass->CreateAndAppendDrawQuad<cc::SolidColorDrawQuad>();
  SkColor arbitrary_color = SK_ColorGREEN;
  bool force_anti_aliasing_off = true;
  color_quad->SetAll(pass->shared_quad_state_list.back(),
                     rect,
                     opaque_rect,
                     visible_rect,
                     needs_blending,
                     arbitrary_color,
                     force_anti_aliasing_off);

  cc::SurfaceDrawQuad* surface_quad =
      pass->CreateAndAppendDrawQuad<cc::SurfaceDrawQuad>();
  cc::SurfaceId arbitrary_id(5);
  surface_quad->SetAll(
      sqs, rect, opaque_rect, visible_rect, needs_blending, arbitrary_id);

  cc::TextureDrawQuad* texture_quad =
      pass->CreateAndAppendDrawQuad<cc::TextureDrawQuad>();
  unsigned resource_id = 9;
  bool premultiplied_alpha = true;
  gfx::PointF uv_top_left(1.7f, 2.1f);
  gfx::PointF uv_bottom_right(-7.f, 16.3f);
  SkColor background_color = SK_ColorYELLOW;
  float vertex_opacity[4] = {0.1f, 0.5f, 0.4f, 0.8f};
  bool flipped = false;
  bool nearest_neighbor = false;
  texture_quad->SetAll(sqs,
                       rect,
                       opaque_rect,
                       visible_rect,
                       needs_blending,
                       resource_id,
                       premultiplied_alpha,
                       uv_top_left,
                       uv_bottom_right,
                       background_color,
                       vertex_opacity,
                       flipped,
                       nearest_neighbor);

  PassPtr mojo_pass = Pass::From(*pass);
  ASSERT_FALSE(mojo_pass.is_null());
  EXPECT_EQ(6, mojo_pass->id);
  EXPECT_EQ(Rect::From(output_rect), mojo_pass->output_rect);
  EXPECT_EQ(Rect::From(damage_rect), mojo_pass->damage_rect);
  EXPECT_EQ(Transform::From(transform_to_root_target),
            mojo_pass->transform_to_root_target);
  EXPECT_EQ(has_transparent_background, mojo_pass->has_transparent_background);
  ASSERT_EQ(1u, mojo_pass->shared_quad_states.size());
  ASSERT_EQ(3u, mojo_pass->quads.size());
  EXPECT_EQ(0u, mojo_pass->quads[0]->shared_quad_state_index);

  scoped_ptr<cc::RenderPass> round_trip_pass =
      mojo_pass.To<scoped_ptr<cc::RenderPass> >();
  EXPECT_EQ(pass_id, round_trip_pass->id);
  EXPECT_EQ(output_rect, round_trip_pass->output_rect);
  EXPECT_EQ(damage_rect, round_trip_pass->damage_rect);
  EXPECT_EQ(transform_to_root_target,
            round_trip_pass->transform_to_root_target);
  EXPECT_EQ(has_transparent_background,
            round_trip_pass->has_transparent_background);
  ASSERT_EQ(1u, round_trip_pass->shared_quad_state_list.size());
  ASSERT_EQ(3u, round_trip_pass->quad_list.size());
  EXPECT_EQ(round_trip_pass->shared_quad_state_list.front(),
            round_trip_pass->quad_list.front()->shared_quad_state);

  cc::SharedQuadState* round_trip_sqs =
      round_trip_pass->shared_quad_state_list.front();
  EXPECT_EQ(content_to_target_transform,
            round_trip_sqs->content_to_target_transform);
  EXPECT_EQ(content_bounds, round_trip_sqs->content_bounds);
  EXPECT_EQ(visible_content_rect, round_trip_sqs->visible_content_rect);
  EXPECT_EQ(clip_rect, round_trip_sqs->clip_rect);
  EXPECT_EQ(is_clipped, round_trip_sqs->is_clipped);
  EXPECT_EQ(opacity, round_trip_sqs->opacity);
  EXPECT_EQ(sorting_context_id, round_trip_sqs->sorting_context_id);

  cc::DrawQuad* round_trip_quad = round_trip_pass->quad_list.front();
  // First is solid color quad.
  ASSERT_EQ(cc::DrawQuad::SOLID_COLOR, round_trip_quad->material);
  EXPECT_EQ(rect, round_trip_quad->rect);
  EXPECT_EQ(opaque_rect, round_trip_quad->opaque_rect);
  EXPECT_EQ(visible_rect, round_trip_quad->visible_rect);
  EXPECT_EQ(needs_blending, round_trip_quad->needs_blending);
  const cc::SolidColorDrawQuad* round_trip_color_quad =
      cc::SolidColorDrawQuad::MaterialCast(round_trip_quad);
  EXPECT_EQ(arbitrary_color, round_trip_color_quad->color);
  EXPECT_EQ(force_anti_aliasing_off,
            round_trip_color_quad->force_anti_aliasing_off);

  round_trip_quad = round_trip_pass->quad_list.ElementAt(1);
  // Second is surface quad.
  ASSERT_EQ(cc::DrawQuad::SURFACE_CONTENT, round_trip_quad->material);
  const cc::SurfaceDrawQuad* round_trip_surface_quad =
      cc::SurfaceDrawQuad::MaterialCast(round_trip_quad);
  EXPECT_EQ(arbitrary_id, round_trip_surface_quad->surface_id);

  round_trip_quad = round_trip_pass->quad_list.ElementAt(2);
  // Third is texture quad.
  ASSERT_EQ(cc::DrawQuad::TEXTURE_CONTENT, round_trip_quad->material);
  const cc::TextureDrawQuad* round_trip_texture_quad =
      cc::TextureDrawQuad::MaterialCast(round_trip_quad);
  EXPECT_EQ(resource_id, round_trip_texture_quad->resource_id);
  EXPECT_EQ(premultiplied_alpha, round_trip_texture_quad->premultiplied_alpha);
  EXPECT_EQ(uv_top_left, round_trip_texture_quad->uv_top_left);
  EXPECT_EQ(uv_bottom_right, round_trip_texture_quad->uv_bottom_right);
  EXPECT_EQ(background_color, round_trip_texture_quad->background_color);
  for (size_t i = 0; i < 4; ++i) {
    EXPECT_EQ(vertex_opacity[i], round_trip_texture_quad->vertex_opacity[i])
        << i;
  }
  EXPECT_EQ(flipped, round_trip_texture_quad->flipped);
}

TEST(SurfaceLibTest, Mailbox) {
  gpu::Mailbox mailbox;
  mailbox.Generate();

  MailboxPtr mojo_mailbox = Mailbox::From(mailbox);
  EXPECT_EQ(0, memcmp(mailbox.name, &mojo_mailbox->name.storage()[0], 64));

  gpu::Mailbox round_trip_mailbox = mojo_mailbox.To<gpu::Mailbox>();
  EXPECT_EQ(mailbox, round_trip_mailbox);
}

TEST(SurfaceLibTest, MailboxEmptyName) {
  MailboxPtr mojo_mailbox = Mailbox::New();

  gpu::Mailbox converted_mailbox = mojo_mailbox.To<gpu::Mailbox>();
  EXPECT_TRUE(converted_mailbox.IsZero());
}

TEST(SurfaceLibTest, MailboxHolder) {
  gpu::Mailbox mailbox;
  mailbox.Generate();
  uint32_t texture_target = GL_TEXTURE_2D;
  uint32_t sync_point = 7u;
  gpu::MailboxHolder holder(mailbox, texture_target, sync_point);

  MailboxHolderPtr mojo_holder = MailboxHolder::From(holder);
  EXPECT_EQ(texture_target, mojo_holder->texture_target);
  EXPECT_EQ(sync_point, mojo_holder->sync_point);

  gpu::MailboxHolder round_trip_holder = mojo_holder.To<gpu::MailboxHolder>();
  EXPECT_EQ(mailbox, round_trip_holder.mailbox);
  EXPECT_EQ(texture_target, round_trip_holder.texture_target);
  EXPECT_EQ(sync_point, round_trip_holder.sync_point);
}

TEST(SurfaceLibTest, TransferableResource) {
  uint32_t id = 7u;
  cc::ResourceFormat format = cc::BGRA_8888;
  uint32_t filter = 123u;
  gfx::Size size(17, 18);
  gpu::MailboxHolder mailbox_holder;
  bool is_repeated = false;
  ;
  bool is_software = false;
  cc::TransferableResource resource;
  resource.id = id;
  resource.format = format;
  resource.filter = filter;
  resource.size = size;
  resource.mailbox_holder = mailbox_holder;
  resource.is_repeated = is_repeated;
  resource.is_software = is_software;

  TransferableResourcePtr mojo_resource = TransferableResource::From(resource);
  EXPECT_EQ(id, mojo_resource->id);
  EXPECT_EQ(static_cast<ResourceFormat>(format),
            mojo_resource->format);
  EXPECT_EQ(filter, mojo_resource->filter);
  EXPECT_EQ(Size::From(size), mojo_resource->size);
  EXPECT_EQ(is_repeated, mojo_resource->is_repeated);
  EXPECT_EQ(is_software, mojo_resource->is_software);

  cc::TransferableResource round_trip_resource =
      mojo_resource.To<cc::TransferableResource>();
  EXPECT_EQ(id, round_trip_resource.id);
  EXPECT_EQ(format, round_trip_resource.format);
  EXPECT_EQ(filter, round_trip_resource.filter);
  EXPECT_EQ(size, round_trip_resource.size);
  EXPECT_EQ(mailbox_holder.mailbox, round_trip_resource.mailbox_holder.mailbox);
  EXPECT_EQ(mailbox_holder.texture_target,
            round_trip_resource.mailbox_holder.texture_target);
  EXPECT_EQ(mailbox_holder.sync_point,
            round_trip_resource.mailbox_holder.sync_point);
  EXPECT_EQ(is_repeated, round_trip_resource.is_repeated);
  EXPECT_EQ(is_software, round_trip_resource.is_software);
}

TEST(SurfaceLibTest, ReturnedResource) {
  uint32_t id = 5u;
  uint32_t sync_point = 24u;
  int count = 2;
  bool lost = false;
  cc::ReturnedResource resource;
  resource.id = id;
  resource.sync_point = sync_point;
  resource.count = count;
  resource.lost = lost;

  ReturnedResourcePtr mojo_resource = ReturnedResource::From(resource);
  EXPECT_EQ(id, mojo_resource->id);
  EXPECT_EQ(sync_point, mojo_resource->sync_point);
  EXPECT_EQ(count, mojo_resource->count);
  EXPECT_EQ(lost, mojo_resource->lost);

  cc::ReturnedResource round_trip_resource =
      mojo_resource.To<cc::ReturnedResource>();
  EXPECT_EQ(id, round_trip_resource.id);
  EXPECT_EQ(sync_point, round_trip_resource.sync_point);
  EXPECT_EQ(count, round_trip_resource.count);
  EXPECT_EQ(lost, round_trip_resource.lost);
}

}  // namespace
}  // namespace mojo
