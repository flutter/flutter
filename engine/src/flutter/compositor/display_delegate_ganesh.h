// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_DISPLAY_DELEGATE_GANESH_H_
#define SKY_COMPOSITOR_DISPLAY_DELEGATE_GANESH_H_

#include "sky/compositor/display_delegate.h"

namespace sky {

class LayerClient;

class DisplayDelegateGanesh final : public DisplayDelegate {
 public:
  explicit DisplayDelegateGanesh(LayerClient* client) : client_(client) {}
  ~DisplayDelegateGanesh() override {}

  static DisplayDelegate* create(LayerClient* client);

  void GetPixelsForTesting(std::vector<unsigned char>* pixels) override;
  void Paint(mojo::GaneshSurface& surface, const gfx::Rect& size) override;

 private:
  LayerClient* client_;
  DISALLOW_COPY_AND_ASSIGN(DisplayDelegateGanesh);
};

}  // namespace sky

#endif  // SKY_COMPOSITOR_DISPLAY_DELEGATE_GANESH_H_
