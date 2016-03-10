// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_GFX_IMAGES_CPP_IMAGE_PIPE_ENDPOINT_H_
#define MOJO_SERVICES_GFX_IMAGES_CPP_IMAGE_PIPE_ENDPOINT_H_

#include <deque>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "mojo/public/c/system/macros.h"
#include "mojo/services/gfx/images/interfaces/image_pipe.mojom.h"

namespace image_pipe {

class ImagePipeEndpoint {
 public:
  ImagePipeEndpoint(bool is_producer,
                    std::function<void()> fatal_error_handler);
  virtual ~ImagePipeEndpoint();

  void ProducerFatalError(const std::string& message, uint32_t id);
  void ConsumerFatalError(const std::string& message, uint32_t id);

  bool AcquireNextImage(uint32_t* out_id);

  void ProducerAdd(uint32_t id);
  void ProducerRemove(uint32_t id);
  void ProducerPresent(uint32_t id,
                       mojo::gfx::ImagePipe::PresentImageCallback callback);
  void ConsumerRelease(uint32_t id, mojo::gfx::PresentationStatus status);
  void ProducerFlush();

  // For testing only, makes fatal errors not quite fatal, which allows tests
  // to cause a fatal error and check that it was caught correctly without
  // dying a horrible death in the process. If you are using this for something
  // other than testing you are probably doing something very wrong.
  void DisableFatalErrorsForTesting();

 private:
  bool IsInPool(uint32_t id) const;
  bool IsConsumerOwned(uint32_t id) const;
  bool IsConsumerAcquirable(uint32_t id) const;
  bool IsProducerOwned(uint32_t id) const;
  bool IsProducerAcquirable(uint32_t id) const;
  void CallPresentCallback(uint32_t id, mojo::gfx::PresentationStatus status);
  void ReleaseInternal(uint32_t id, bool released_by_producer);

  static void ImagePipeLogError(const std::string& entity,
                                const std::string& message,
                                uint32_t id);

  // Used for internal state tracking and validation
  std::unordered_map<uint32_t, mojo::gfx::ImagePipe::PresentImageCallback>
      present_callback_map_;

  // ids that have been added to the pipe's image pool and have not been removed
  std::unordered_set<uint32_t> image_pool_ids_;

  // images that have been aquired by the consumer
  std::unordered_set<uint32_t> consumer_owned_ids_;
  // images that have been presented by the producer but have not been aquired
  // by the consumer
  std::deque<uint32_t> consumer_acquirable_ids_;

  // images that have been aquired by the producer
  std::unordered_set<uint32_t> producer_owned_ids_;
  // images that have been released by the producer but have not been aquired
  // by the consumer
  std::deque<uint32_t> producer_acquirable_ids_;

  bool is_producer_;
  bool is_checked_;
  std::function<void()> fatal_error_handler_;
};
}

#endif  // MOJO_SERVICES_GFX_IMAGES_CPP_IMAGE_PIPE_ENDPOINT_H_
