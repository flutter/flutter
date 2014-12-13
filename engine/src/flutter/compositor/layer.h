// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_LAYER_H_
#define SKY_COMPOSITOR_LAYER_H_

#include "base/memory/ref_counted.h"
#include "mojo/gpu/gl_texture.h"
#include "sky/compositor/layer_client.h"
#include "ui/gfx/geometry/rect.h"

namespace sky {

class DisplayDelegate;
class LayerHost;

class Layer : public base::RefCounted<Layer> {
 public:
  explicit Layer(LayerClient* client);

  void SetSize(const gfx::Size& size);
  void GetPixelsForTesting(std::vector<unsigned char>* pixels);
  void Display();

  scoped_ptr<mojo::GLTexture> GetTexture();

  const gfx::Size& size() const { return size_; }

  void set_host(LayerHost* host) { host_ = host; }

 private:
  friend class base::RefCounted<Layer>;
  ~Layer();

  LayerClient* client_;
  LayerHost* host_;
  gfx::Size size_;
  scoped_ptr<mojo::GLTexture> texture_;
  scoped_ptr<DisplayDelegate> delegate_;

  DISALLOW_COPY_AND_ASSIGN(Layer);
};

}  // namespace sky

#endif  // SKY_COMPOSITOR_LAYER_H_
