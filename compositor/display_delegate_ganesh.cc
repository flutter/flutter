// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/display_delegate_ganesh.h"

#include "sky/compositor/layer_client.h"
#include "third_party/skia/include/core/SkCanvas.h"

namespace sky {

DisplayDelegate* DisplayDelegateGanesh::create(LayerClient* client) {
  return new DisplayDelegateGanesh(client);
}

void DisplayDelegateGanesh::GetPixelsForTesting(std::vector<unsigned char>* pixels) {
  // TODO(ojan): When we change notifyTestComplete to only GetPixelsForTesting
  // in pixel/ref tests, add a NOTREACHED() here.
}

void DisplayDelegateGanesh::Paint(mojo::GaneshSurface& surface, const gfx::Rect& size) {
  SkCanvas* canvas = surface.canvas();
  client_->PaintContents(canvas, size);
  canvas->flush();
}

}  // namespace sky
