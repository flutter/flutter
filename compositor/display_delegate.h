// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_DISPLAY_DELEGATE_H_
#define SKY_COMPOSITOR_DISPLAY_DELEGATE_H_

#include <vector>

#include "mojo/skia/ganesh_surface.h"

class SkCanvas;

namespace gfx {
class Rect;
}

namespace sky {

class DisplayDelegate;
class LayerClient;

typedef DisplayDelegate* (*CreateDisplayDelegate)(LayerClient*);

class DisplayDelegate {
 public:
  DisplayDelegate() {}
  virtual ~DisplayDelegate() {}

  static DisplayDelegate* create(LayerClient*);
  static void setDisplayDelegateCreateFunction(CreateDisplayDelegate);

  virtual void GetPixelsForTesting(std::vector<unsigned char>* pixels) = 0;
  virtual void Paint(mojo::GaneshSurface& surface, const gfx::Rect& size) = 0;

  DISALLOW_COPY_AND_ASSIGN(DisplayDelegate);
};



}  // namespace sky

#endif  // SKY_COMPOSITOR_DISPLAY_DELEGATE_H_
