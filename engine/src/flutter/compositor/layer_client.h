// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_LAYER_CLIENT_H_
#define SKY_COMPOSITOR_LAYER_CLIENT_H_

class SkCanvas;

namespace gfx {
class Rect;
}

namespace sky {

class LayerClient {
 public:
  virtual void PaintContents(SkCanvas* canvas, const gfx::Rect& clip) = 0;

 protected:
  virtual ~LayerClient();
};

}  // namespace sky

#endif  // SKY_COMPOSITOR_LAYER_CLIENT_H_
