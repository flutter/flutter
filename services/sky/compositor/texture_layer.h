// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_COMPOSITOR_TEXTURE_LAYER_H_
#define SKY_VIEWER_COMPOSITOR_TEXTURE_LAYER_H_

#include "base/memory/ref_counted.h"
#include "mojo/gpu/gl_texture.h"
#include "services/sky/compositor/layer_client.h"
#include "services/sky/compositor/rasterizer.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "ui/gfx/geometry/rect.h"

namespace sky {

class LayerHost;

class TextureLayer : public base::RefCounted<TextureLayer> {
 public:
  explicit TextureLayer(LayerClient* client);

  void SetSize(const gfx::Size& size);
  void Display();

  scoped_ptr<mojo::GLTexture> GetTexture();

  const gfx::Size& size() const { return size_; }

  void set_rasterizer(scoped_ptr<Rasterizer> rasterizer) {
    rasterizer_ = rasterizer.Pass();
  }

 private:
  friend class base::RefCounted<TextureLayer>;
  ~TextureLayer();

  PassRefPtr<SkPicture> RecordPicture();

  LayerClient* client_;
  gfx::Size size_;
  scoped_ptr<mojo::GLTexture> texture_;
  scoped_ptr<Rasterizer> rasterizer_;

  DISALLOW_COPY_AND_ASSIGN(TextureLayer);
};

}  // namespace sky

#endif  // SKY_VIEWER_COMPOSITOR_TEXTURE_LAYER_H_
