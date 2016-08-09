// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/gpu/mojo/gl_texture_recycler.h"

#ifndef GL_GLEXT_PROTOTYPES
#define GL_GLEXT_PROTOTYPES
#endif
#include <GLES2/gl2.h>
#include <GLES2/gl2extmojo.h>

#include "mojo/gpu/gl_context.h"
#include "mojo/gpu/gl_texture.h"

namespace sky {
namespace shell {

GLTextureRecycler::GLTextureRecycler(scoped_refptr<mojo::GLContext> gl_context,
                                     uint32_t max_recycled_textures)
    : gl_context_(gl_context),
      max_recycled_textures_(max_recycled_textures),
      weak_factory_(this) {}

GLTextureRecycler::~GLTextureRecycler() {}

std::unique_ptr<mojo::GLTexture> GLTextureRecycler::GetTexture(
    const mojo::Size& requested_size) {
  if (gl_context_->is_lost()) {
    recycled_textures_.clear();
    return nullptr;
  }

  mojo::GLContext::Scope scope(gl_context_);

  while (!recycled_textures_.empty()) {
    GLRecycledTextureInfo texture_info(std::move(recycled_textures_.front()));
    recycled_textures_.pop_front();
    if (texture_info.first->size().Equals(requested_size)) {
      glWaitSyncPointCHROMIUM(texture_info.second);
      return std::move(texture_info.first);
    }
  }

  return std::unique_ptr<mojo::GLTexture>(
      new mojo::GLTexture(scope, requested_size));
}

mojo::gfx::composition::ResourcePtr GLTextureRecycler::BindTextureResource(
    std::unique_ptr<mojo::GLTexture> texture) {
  if (gl_context_->is_lost())
    return nullptr;

  // Produce the texture.
  mojo::GLContext::Scope scope(gl_context_);
  glBindTexture(GL_TEXTURE_2D, texture->texture_id());
  GLbyte mailbox[GL_MAILBOX_SIZE_CHROMIUM];
  glGenMailboxCHROMIUM(mailbox);
  glProduceTextureCHROMIUM(GL_TEXTURE_2D, mailbox);
  glBindTexture(GL_TEXTURE_2D, 0);
  GLuint sync_point = glInsertSyncPointCHROMIUM();

  // Populate the resource description.
  auto resource = mojo::gfx::composition::Resource::New();
  resource->set_mailbox_texture(
      mojo::gfx::composition::MailboxTextureResource::New());
  resource->get_mailbox_texture()->mailbox_name.resize(sizeof(mailbox));
  memcpy(resource->get_mailbox_texture()->mailbox_name.data(), mailbox,
         sizeof(mailbox));
  resource->get_mailbox_texture()->sync_point = sync_point;
  resource->get_mailbox_texture()->size = texture->size().Clone();
  resource->get_mailbox_texture()->callback =
      (new GLTextureReleaser(
           weak_factory_.GetWeakPtr(),
           GLRecycledTextureInfo(std::move(texture), sync_point)))
          ->StrongBind()
          .Pass();

  bound_textures_++;
  DVLOG(2) << "bind: bound_textures=" << bound_textures_;
  return resource;
}

void GLTextureRecycler::ReleaseTexture(GLRecycledTextureInfo texture_info,
                                       bool recyclable) {
  DCHECK(bound_textures_);
  bound_textures_--;
  if (recyclable && recycled_textures_.size() < max_recycled_textures_) {
    recycled_textures_.emplace_back(std::move(texture_info));
  }
  DVLOG(2) << "release: bound_textures=" << bound_textures_
           << ", recycled_textures=" << recycled_textures_.size();
}

GLTextureRecycler::GLTextureReleaser::GLTextureReleaser(
    const ftl::WeakPtr<GLTextureRecycler>& provider,
    GLRecycledTextureInfo info)
    : provider_(provider), texture_info_(std::move(info)), binding_(this) {}

GLTextureRecycler::GLTextureReleaser::~GLTextureReleaser() {
  // It's possible for the object to be destroyed due to a connection
  // error on the callback pipe.  When this happens we don't want to
  // recycle the texture since we have too little knowledge about its
  // state to confirm that it will be safe to do so.
  Release(false /*recyclable*/);
}

mojo::gfx::composition::MailboxTextureCallbackPtr
GLTextureRecycler::GLTextureReleaser::StrongBind() {
  mojo::gfx::composition::MailboxTextureCallbackPtr callback;
  binding_.Bind(mojo::GetProxy(&callback));
  return callback;
}

void GLTextureRecycler::GLTextureReleaser::OnMailboxTextureReleased() {
  Release(true /*recyclable*/);
}

void GLTextureRecycler::GLTextureReleaser::Release(bool recyclable) {
  if (provider_) {
    provider_->ReleaseTexture(std::move(texture_info_), recyclable);
    provider_.reset();
  }
}

}  // namespace shell
}  // namespace sky
