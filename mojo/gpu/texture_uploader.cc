// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/gpu/texture_uploader.h"

#ifndef GL_GLEXT_PROTOTYPES
#define GL_GLEXT_PROTOTYPES
#endif

#include <GLES2/gl2.h>
#include <GLES2/gl2chromium.h>
#include <GLES2/gl2extchromium.h>

#include "mojo/public/c/gles2/gles2.h"
#include "mojo/services/geometry/public/cpp/geometry_util.h"
#include "mojo/services/surfaces/public/cpp/surfaces_utils.h"

namespace mojo {

mojo::FramePtr TextureUploader::GetUploadFrame(
    base::WeakPtr<mojo::GLContext> context,
    uint32_t resource_id,
    const scoped_ptr<mojo::GLTexture>& texture) {
  if (!context) {
    return mojo::FramePtr();
  }

  mojo::Size size = texture->size();

  mojo::FramePtr frame = mojo::Frame::New();
  frame->resources.resize(0u);

  mojo::Rect bounds;
  bounds.width = size.width;
  bounds.height = size.height;
  mojo::PassPtr pass = mojo::CreateDefaultPass(1, bounds);
  pass->quads.resize(0u);
  pass->shared_quad_states.push_back(mojo::CreateDefaultSQS(size));

  context->MakeCurrent();
  glBindTexture(GL_TEXTURE_2D, texture->texture_id());
  GLbyte mailbox[GL_MAILBOX_SIZE_CHROMIUM];
  glGenMailboxCHROMIUM(mailbox);
  glProduceTextureCHROMIUM(GL_TEXTURE_2D, mailbox);
  GLuint sync_point = glInsertSyncPointCHROMIUM();

  mojo::TransferableResourcePtr resource = mojo::TransferableResource::New();
  resource->id = resource_id;
  resource->format = mojo::RESOURCE_FORMAT_RGBA_8888;
  resource->filter = GL_LINEAR;
  resource->size = size.Clone();
  mojo::MailboxHolderPtr mailbox_holder = mojo::MailboxHolder::New();
  mailbox_holder->mailbox = mojo::Mailbox::New();
  for (int i = 0; i < GL_MAILBOX_SIZE_CHROMIUM; ++i)
    mailbox_holder->mailbox->name.push_back(mailbox[i]);
  mailbox_holder->texture_target = GL_TEXTURE_2D;
  mailbox_holder->sync_point = sync_point;
  resource->mailbox_holder = mailbox_holder.Pass();
  resource->is_repeated = false;
  resource->is_software = false;

  mojo::QuadPtr quad = mojo::Quad::New();
  quad->material = mojo::MATERIAL_TEXTURE_CONTENT;

  mojo::RectPtr rect = mojo::Rect::New();
  rect->width = size.width;
  rect->height = size.height;
  quad->rect = rect.Clone();
  quad->opaque_rect = rect.Clone();
  quad->visible_rect = rect.Clone();
  quad->needs_blending = true;
  quad->shared_quad_state_index = 0u;

  mojo::TextureQuadStatePtr texture_state = mojo::TextureQuadState::New();
  texture_state->resource_id = resource->id;
  texture_state->premultiplied_alpha = true;
  texture_state->uv_top_left = mojo::PointF::New();
  texture_state->uv_bottom_right = mojo::PointF::New();
  texture_state->uv_bottom_right->x = 1.f;
  texture_state->uv_bottom_right->y = 1.f;
  texture_state->background_color = mojo::Color::New();
  texture_state->background_color->rgba = 0;
  for (int i = 0; i < 4; ++i)
    texture_state->vertex_opacity.push_back(1.f);
  texture_state->flipped = false;

  frame->resources.push_back(resource.Pass());
  quad->texture_quad_state = texture_state.Pass();
  pass->quads.push_back(quad.Pass());

  frame->passes.push_back(pass.Pass());
  return frame.Pass();
}

}  // namespace mojo
