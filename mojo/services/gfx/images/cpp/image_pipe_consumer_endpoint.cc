// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "image_pipe_consumer_endpoint.h"

namespace image_pipe {

void ImagePipeConsumerEndpoint::CloseEndpoint() {
  image_pipe_binding_.Close();
  delegate_->HandleEndpointClosed();
}

ImagePipeConsumerEndpoint::ImagePipeConsumerEndpoint(
    mojo::InterfaceRequest<mojo::gfx::ImagePipe> request,
    ImagePipeConsumerDelegate* delegate)
    : state_tracker_(false, [this]() { CloseEndpoint(); }),
      delegate_(delegate),
      image_pipe_binding_(this, request.Pass()) {
  image_pipe_binding_.set_connection_error_handler([this]() {
    MOJO_LOG(ERROR) << "Image Pipe Connection Error for Consumer!";
    CloseEndpoint();
  });
}

ImagePipeConsumerEndpoint::~ImagePipeConsumerEndpoint() {}

void ImagePipeConsumerEndpoint::ReleaseImage(
    uint32_t id,
    mojo::gfx::PresentationStatus status) {
  state_tracker_.ConsumerRelease(id, status);
}

// mojo::gfx::ImagePipe implementation
void ImagePipeConsumerEndpoint::AddImage(mojo::gfx::ImagePtr image,
                                         uint32_t id) {
  state_tracker_.ProducerAdd(id);
  delegate_->AddImage(image.Pass(), id);
}

void ImagePipeConsumerEndpoint::RemoveImage(uint32_t id) {
  state_tracker_.ProducerRemove(id);
  delegate_->RemoveImage(id);
}

void ImagePipeConsumerEndpoint::PresentImage(
    uint32_t id,
    const PresentImageCallback& callback) {
  state_tracker_.ProducerPresent(id, callback);
  delegate_->PresentImage(id);
}

void ImagePipeConsumerEndpoint::FlushImages() {
  state_tracker_.ProducerFlush();
}

bool ImagePipeConsumerEndpoint::AcquireNextImage(uint32_t* out_id) {
  return state_tracker_.AcquireNextImage(out_id);
}

void ImagePipeConsumerEndpoint::DisableFatalErrorsForTesting() {
  state_tracker_.DisableFatalErrorsForTesting();
}

}  // namespace image_pipe