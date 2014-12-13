// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_DISPLAY_DELEGATE_BITMAP_H_
#define SKY_COMPOSITOR_DISPLAY_DELEGATE_BITMAP_H_

#include "sky/compositor/display_delegate.h"

namespace sky {

class LayerClient;

class DisplayDelegateBitmap final : public DisplayDelegate {
 public:
  explicit DisplayDelegateBitmap(LayerClient* client);
  ~DisplayDelegateBitmap() override;

  static DisplayDelegate* create(LayerClient* client);

  void GetPixelsForTesting(std::vector<unsigned char>* pixels) override;
  void Paint(mojo::GaneshSurface& surface, const gfx::Rect& size) override;

 private:
  SkBitmap bitmap_;
  LayerClient* client_;

  DISALLOW_COPY_AND_ASSIGN(DisplayDelegateBitmap);
};

}  // namespace sky

#endif  // SKY_COMPOSITOR_DISPLAY_DELEGATE_BITMAP_H_
