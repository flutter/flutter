// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_GFX_IMAGES_CPP_IMAGE_PIPE_CONSUMER_DELEGATE_H_
#define MOJO_SERVICES_GFX_IMAGES_CPP_IMAGE_PIPE_CONSUMER_DELEGATE_H_

#include "mojo/services/gfx/images/interfaces/image.mojom.h"

namespace image_pipe {

// Pure virtual class for platform dependent handling of
// asynchronous calls on the consumer end of the image pipe.
class ImagePipeConsumerDelegate {
 public:
  virtual ~ImagePipeConsumerDelegate() {}

  virtual void AddImage(mojo::gfx::ImagePtr image, uint32_t id) = 0;
  virtual void RemoveImage(uint32_t id) = 0;
  virtual void PresentImage(uint32_t id) = 0;
  virtual void HandleEndpointClosed() = 0;
};
}

#endif  // MOJO_SERVICES_GFX_IMAGES_CPP_IMAGE_PIPE_CONSUMER_DELEGATE_H_