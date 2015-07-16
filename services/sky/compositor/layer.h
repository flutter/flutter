// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_COMPOSITOR_LAYER_H_
#define SKY_VIEWER_COMPOSITOR_LAYER_H_

#include "base/memory/ref_counted.h"
#include "mojo/gpu/gl_texture.h"
#include "services/sky/compositor/layer_client.h"
#include "services/sky/compositor/rasterizer.h"
#include "skia/ext/refptr.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "ui/gfx/geometry/rect.h"

namespace sky {

class LayerHost;

class Layer : public base::RefCounted<Layer> {
 public:
  explicit Layer(LayerClient* client);

  void SetSize(const gfx::Size& size);
  void Display();

  scoped_ptr<mojo::GLTexture> GetTexture();

  const gfx::Size& size() const { return size_; }

  void set_rasterizer(scoped_ptr<Rasterizer> rasterizer) {
    rasterizer_ = rasterizer.Pass();
  }

 private:
  friend class base::RefCounted<Layer>;
  ~Layer();

  skia::RefPtr<SkPicture> RecordPicture();

  LayerClient* client_;
  gfx::Size size_;
  scoped_ptr<mojo::GLTexture> texture_;
  scoped_ptr<Rasterizer> rasterizer_;

  DISALLOW_COPY_AND_ASSIGN(Layer);
};

}  // namespace sky

#endif  // SKY_VIEWER_COMPOSITOR_LAYER_H_
