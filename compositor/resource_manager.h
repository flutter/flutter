// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_RESOURCE_MANAGER_H_
#define SKY_COMPOSITOR_RESOURCE_MANAGER_H_

#include "base/containers/hash_tables.h"
#include "base/memory/scoped_ptr.h"
#include "base/memory/scoped_vector.h"
#include "base/memory/weak_ptr.h"
#include "mojo/services/surfaces/public/interfaces/surfaces.mojom.h"
#include "sky/compositor/texture_cache.h"

namespace gfx {
class Size;
}

namespace mojo {
class GLContext;
class GLTexture;
}

namespace sky {
class Layer;
class LayerHost;

class ResourceManager {
 public:
  explicit ResourceManager(base::WeakPtr<mojo::GLContext> gl_context);
  ~ResourceManager();

  scoped_ptr<mojo::GLTexture> CreateTexture(const gfx::Size& size);

  mojo::TransferableResourcePtr CreateTransferableResource(Layer* layer);
  void ReturnResources(mojo::Array<mojo::ReturnedResourcePtr> resources);

 private:
  base::WeakPtr<mojo::GLContext> gl_context_;
  uint32_t next_resource_id_;
  base::hash_map<uint32_t, mojo::GLTexture*> resource_to_texture_map_;
  TextureCache texture_cache_;

  DISALLOW_COPY_AND_ASSIGN(ResourceManager);
};

}  // namespace sky

#endif  // SKY_COMPOSITOR_RESOURCE_MANAGER_H_
