// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#ifndef MOJO_SERVICES_GFX_IMAGES_INTERFACES_IMAGE_PIPE_CONSUMER_ENDPOINT_H_
#define MOJO_SERVICES_GFX_IMAGES_INTERFACES_IMAGE_PIPE_CONSUMER_ENDPOINT_H_

#include "image_pipe_endpoint.h"
#include "mojo/public/c/system/macros.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/services/gfx/images/cpp/image_pipe_consumer_delegate.h"
#include "mojo/services/gfx/images/interfaces/image_pipe.mojom.h"

namespace image_pipe {

// |ImagePipeConsumerEndpoint| is a state tracking wrapper for the consumer end
// of an |ImagePipe| that enforces the constraints documented in the mojom
// interface. Using |ImagePipeConsumerEndpoint| is not required to use
// |ImagePipe|, but it may help you use it correctly
class ImagePipeConsumerEndpoint : private mojo::gfx::ImagePipe {
 public:
  ImagePipeConsumerEndpoint(
      mojo::InterfaceRequest<mojo::gfx::ImagePipe> request,
      ImagePipeConsumerDelegate* delegate);
  ~ImagePipeConsumerEndpoint() override;

  // Aquire the Image presented least recently (queue like behavior). If no
  // images are available that match the selection criteria this function will
  // return false otherwise it will write the selected id into its id argument
  // and return true.
  bool AcquireNextImage(uint32_t* out_id);

  // Releases an image back to the producer.
  void ReleaseImage(uint32_t id, mojo::gfx::PresentationStatus status);

  // For testing only, makes fatal errors not quite fatal, which allows tests
  // to cause a fatal error and check that it was caught correctly without
  // dying a horrible death in the process. If you are using this for something
  // other than testing you are probably doing something very wrong.
  void DisableFatalErrorsForTesting();

 private:
  void CloseEndpoint();

  // Inherited from mojo::gfx::ImagePipe, see image_pipe.mojom for comments
  void AddImage(mojo::gfx::ImagePtr image, uint32_t id) override;
  void RemoveImage(uint32_t id) override;
  void PresentImage(uint32_t id, const PresentImageCallback& callback) override;
  void FlushImages() override;

  ImagePipeEndpoint state_tracker_;
  ImagePipeConsumerDelegate* delegate_;

  mojo::Binding<mojo::gfx::ImagePipe> image_pipe_binding_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ImagePipeConsumerEndpoint);
};

}  // namespace image_pipe

#endif  // MOJO_SERVICES_GFX_IMAGES_INTERFACES_IMAGE_PIPE_CONSUMER_ENDPOINT_H_
