// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "image_pipe_producer_endpoint.h"

namespace image_pipe {

void ImagePipeProducerEndpoint::CloseEndpoint() {
  image_pipe_ptr_.reset();
  endpoint_closed_callback_();
}

ImagePipeProducerEndpoint::ImagePipeProducerEndpoint(
    mojo::gfx::ImagePipePtr image_pipe,
    std::function<void()> endpoint_closed_callback)
    : state_tracker_(true, [this]() { CloseEndpoint(); }),
      image_pipe_ptr_(image_pipe.Pass()) {
  endpoint_closed_callback_ = endpoint_closed_callback;
  image_pipe_ptr_.set_connection_error_handler([this] { CloseEndpoint(); });
}

ImagePipeProducerEndpoint::~ImagePipeProducerEndpoint() {}

bool ImagePipeProducerEndpoint::AcquireImage(uint32_t* out_id) {
  return state_tracker_.AcquireNextImage(out_id);
}

bool ImagePipeProducerEndpoint::AcquireImageBlocking(uint32_t* out_id,
                                                     MojoDeadline deadline) {
  MojoDeadline remaining_deadline_ = deadline;
  bool have_image = false;
  do {
    have_image = state_tracker_.AcquireNextImage(out_id);
    if (!have_image && remaining_deadline_ > 0) {
      if (image_pipe_ptr_.encountered_error())
        break;
      MojoTimeTicks wait_start = MojoGetTimeTicksNow();
      image_pipe_ptr_.WaitForIncomingResponseWithTimeout(remaining_deadline_);
      MojoTimeTicks wait_end = MojoGetTimeTicksNow();
      MojoTimeTicks wait_time = wait_end - wait_start;

      MOJO_DCHECK(wait_time >= 0);

      if (static_cast<MojoDeadline>(wait_time) > remaining_deadline_) {
        remaining_deadline_ = 0;  // just to be safe
      } else {
        remaining_deadline_ -= wait_time;
      }

      if (image_pipe_ptr_.encountered_error())
        break;
    }
  } while (!have_image);

  return have_image;
}

void ImagePipeProducerEndpoint::AddImage(mojo::gfx::ImagePtr image,
                                         uint32_t id) {
  state_tracker_.ProducerAdd(id);
  image_pipe_ptr_->AddImage(image.Pass(), id);
}

void ImagePipeProducerEndpoint::RemoveImage(uint32_t id) {
  state_tracker_.ProducerRemove(id);
  image_pipe_ptr_->RemoveImage(id);
}

void ImagePipeProducerEndpoint::ConsumerReleaseInternal(
    uint32_t id,
    mojo::gfx::PresentationStatus status) {
  state_tracker_.ConsumerRelease(id, status);
}

void ImagePipeProducerEndpoint::PresentImage(
    uint32_t id,
    const PresentImageCallback& callback) {
  state_tracker_.ProducerPresent(id, callback);
  image_pipe_ptr_->PresentImage(
      id, [this, id](mojo::gfx::PresentationStatus status) {
        ConsumerReleaseInternal(id, status);
      });
}

void ImagePipeProducerEndpoint::FlushImages() {
  state_tracker_.ProducerFlush();
  image_pipe_ptr_->FlushImages();
}

void ImagePipeProducerEndpoint::DisableFatalErrorsForTesting() {
  state_tracker_.DisableFatalErrorsForTesting();
}

bool ImagePipeProducerEndpoint::HasEncounteredError() {
  return image_pipe_ptr_.encountered_error();
}

}  // namespace image_pipe
