// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GL_GLEXT_PROTOTYPES
#define GL_GLEXT_PROTOTYPES
#endif

#include <GLES2/gl2extchromium.h>

#include "mojo/gpu/gl_context.h"
#include "mojo/gpu/gl_texture.h"
#include "mojo/gpu/texture_cache.h"
#include "mojo/services/geometry/public/interfaces/geometry.mojom.h"

namespace mojo {

TextureCache::TextureInfo::TextureInfo() : texture_(), resource_id_(0u) {
}
TextureCache::TextureInfo::TextureInfo(scoped_ptr<mojo::GLTexture> texture,
                                       uint32_t resource_id)
    : texture_(texture.Pass()), resource_id_(resource_id) {
}
TextureCache::TextureInfo::~TextureInfo() {
}

TextureCache::TextureCache(base::WeakPtr<mojo::GLContext> gl_context,
                           mojo::ResourceReturnerPtr* out_resource_returner)
    : gl_context_(gl_context), returner_binding_(this), next_resource_id_(0u) {
  if (out_resource_returner) {
    returner_binding_.Bind(GetProxy(out_resource_returner));
  }
}

TextureCache::~TextureCache() {
}

scoped_ptr<TextureCache::TextureInfo> TextureCache::GetTexture(
    const mojo::Size& requested_size) {
  // Sift through our available textures to find one the correct size.  If one
  // exists use it.  As we find textures of the wrong size, clean them up.
  while (!available_textures_.empty()) {
    // Get the next available texture's resource id.
    uint32_t available_resource_id = available_textures_.front();
    available_textures_.pop_front();

    // Get the texture information from the texture map.
    auto texture_iterator =
        resource_to_texture_map_.find(available_resource_id);
    mojo::Size texture_size = texture_iterator->second->size();
    scoped_ptr<TextureInfo> texture_info(new TextureInfo(
        texture_iterator->second.Pass(), texture_iterator->first));
    resource_to_texture_map_.erase(texture_iterator);

    // Get the sync point from the sync point map.
    auto sync_point_iterator =
        resource_to_sync_point_map_.find(available_resource_id);
    int sync_point = sync_point_iterator->second;
    resource_to_sync_point_map_.erase(sync_point_iterator);

    // If the texture is the right size, use it.
    if (texture_size.width == requested_size.width &&
        texture_size.height == requested_size.height) {
      glWaitSyncPointCHROMIUM(sync_point);
      return texture_info.Pass();
    }
  }

  // If our context is invalid return an empty scoped ptr.
  if (!gl_context_) {
    return scoped_ptr<TextureInfo>();
  }

  // We couldn't find an existing texture to reuse, create a new one!
  scoped_ptr<mojo::GLTexture> new_texture(
      new mojo::GLTexture(gl_context_, requested_size));
  next_resource_id_++;
  scoped_ptr<TextureInfo> texture_info(
      new TextureInfo(new_texture.Pass(), next_resource_id_));
  return texture_info.Pass();
}

void TextureCache::NotifyPendingResourceReturn(
    uint32_t resource_id,
    scoped_ptr<mojo::GLTexture> texture) {
  resource_to_texture_map_[resource_id] = texture.Pass();
}

// mojo::ResourceReturner
void TextureCache::ReturnResources(
    mojo::Array<mojo::ReturnedResourcePtr> resources) {
  if (!gl_context_) {
    return;
  }
  gl_context_->MakeCurrent();
  for (size_t i = 0u; i < resources.size(); ++i) {
    mojo::ReturnedResourcePtr resource = resources[i].Pass();
    DCHECK_EQ(1, resource->count);
    auto it = resource_to_texture_map_.find(resource->id);
    // Ignore the returned resource if we haven't been notified of its pending
    // return.
    if (it != resource_to_texture_map_.end()) {
      available_textures_.push_back(resource->id);
      resource_to_sync_point_map_[resource->id] = resource->sync_point;
    }
  }
}
}  // namespace mojo
