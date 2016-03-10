// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_GFX_IMAGES_INTERFACES_IMAGE_PIPE_PRODUCER_ENDPOINT_H_
#define MOJO_SERVICES_GFX_IMAGES_INTERFACES_IMAGE_PIPE_PRODUCER_ENDPOINT_H_

#include "image_pipe_endpoint.h"
#include "mojo/public/c/system/macros.h"
#include "mojo/services/gfx/images/interfaces/image_pipe.mojom.h"

namespace image_pipe {

// This class wraps the producer end of an ImagePipe and validates the sanity
// of both the producer actions and the consumer actions coming over the
// message pipe. It also tracks the state of Images in the pipe's image pool
// and provides conviennce mechanisms for accessing this state (like the ability
// to get the ID of an available image without having to manually track the
// lifecycle of these images.
class ImagePipeProducerEndpoint : public mojo::gfx::ImagePipe {
 public:
  ImagePipeProducerEndpoint(mojo::gfx::ImagePipePtr image_pipe,
                            std::function<void()> endpoint_closed_callback);

  ~ImagePipeProducerEndpoint() override;

  // Ask the endpoint for an available image to draw into
  // returns false if no images are available, otherwise returns true and
  // sets |id| to the acquired ID.
  bool AcquireImage(uint32_t* out_id);

  // The blocking version of the above function. This function will block until
  // an Image is available or the deadline is met. If there are no images in the
  // pool or the underlying message pipe has errors then false will be returned
  bool AcquireImageBlocking(uint32_t* out_id, MojoDeadline deadline);

  // Inherited from mojo::gfx::ImagePipe, see image_pipe.mojom for comments
  void AddImage(mojo::gfx::ImagePtr image, uint32_t id) override;
  void RemoveImage(uint32_t id) override;
  void PresentImage(uint32_t id, const PresentImageCallback& callback) override;
  void FlushImages() override;

  // Returns true if and only if the message pipe underlying the image pipe has
  // enountered errors or closed
  bool HasEncounteredError();

  // For testing only, makes fatal errors not quite fatal, which allows tests
  // to cause a fatal error and check that it was caught correctly without
  // dying a horrible death in the process. If you are using this for something
  // other than testing you are probably doing something very wrong.
  void DisableFatalErrorsForTesting();

 private:
  void CloseEndpoint();

  // This exists wrap ImagePipeEndpoint::ConsumerRelease because for some reason
  // GCC doesnt like us calling protected methods on our base class from inside
  // a lambda that captures 'this', which breaks the fnl build. Clang handles it
  // fine, but its unclear whos right here, so we trampoline it as a workaround
  void ConsumerReleaseInternal(uint32_t id,
                               mojo::gfx::PresentationStatus status);

  ImagePipeEndpoint state_tracker_;
  mojo::gfx::ImagePipePtr image_pipe_ptr_;
  std::function<void()> endpoint_closed_callback_;
};

}  // namespace image_pipe

#endif  // MOJO_SERVICES_GFX_IMAGES_INTERFACES_IMAGE_PIPE_PRODUCER_ENDPOINT_H_