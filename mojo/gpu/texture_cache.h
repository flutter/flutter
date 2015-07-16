// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_GPU_TEXTURE_CACHE_H_
#define MOJO_GPU_TEXTURE_CACHE_H_

#include <GLES2/gl2.h>
#include <deque>
#include <map>

#include "base/macros.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/weak_ptr.h"
#include "mojo/public/cpp/bindings/binding.h"
#include "mojo/services/surfaces/public/interfaces/surfaces.mojom.h"

namespace mojo {

class GLContext;
class GLTexture;
class Size;

// Represents a cache of textures which can be drawn to and submitted to a
// surface.
// Each |texture| in the cache has an associated |resource_id| which must be
// used when the texture is submitted to a surface via a
// TransferableResourcePtr.  This class must also be hooked up to the surface as
// a ResourceReturner such that the resources are properly marked as available
// to be used again.
class TextureCache : public mojo::ResourceReturner {
 public:
  class TextureInfo {
   public:
    TextureInfo();
    TextureInfo(scoped_ptr<mojo::GLTexture> texture, uint32_t resource_id);
    ~TextureInfo();
    scoped_ptr<mojo::GLTexture> Texture() { return texture_.Pass(); }
    uint32_t ResourceId() { return resource_id_; }

   private:
    scoped_ptr<mojo::GLTexture> texture_;
    uint32_t resource_id_;

    DISALLOW_COPY_AND_ASSIGN(TextureInfo);
  };

  // Returns the ResourceReturner to be given to the surface the textures will
  // be uploaded to via |out_resource_returner|.
  TextureCache(base::WeakPtr<mojo::GLContext> gl_context,
               mojo::ResourceReturnerPtr* out_resource_returner);
  ~TextureCache() override;

  // Returns a texture for the given size.  If no texture is available the
  // scoped_ptr will be empty.
  scoped_ptr<TextureInfo> GetTexture(const mojo::Size& requested_size);

  // Notifies the TextureCache to expect the given resource to be returned
  // shortly.
  void NotifyPendingResourceReturn(uint32_t resource_id,
                                   scoped_ptr<mojo::GLTexture> texture);

 private:
  // mojo::ResourceReturner
  void ReturnResources(
      mojo::Array<mojo::ReturnedResourcePtr> resources) override;

  base::WeakPtr<mojo::GLContext> gl_context_;
  mojo::Binding<mojo::ResourceReturner> returner_binding_;
  std::deque<uint32_t> available_textures_;
  std::map<uint32_t, scoped_ptr<mojo::GLTexture>> resource_to_texture_map_;
  std::map<uint32_t, GLuint> resource_to_sync_point_map_;
  uint32_t next_resource_id_;

  DISALLOW_COPY_AND_ASSIGN(TextureCache);
};

}  // namespace mojo

#endif  // MOJO_GPU_TEXTURE_CACHE_H_
