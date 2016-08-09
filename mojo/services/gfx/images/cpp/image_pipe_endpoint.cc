// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "image_pipe_endpoint.h"

namespace image_pipe {

void ImagePipeEndpoint::ImagePipeLogError(const std::string& entity,
                                          const std::string& message,
                                          uint32_t id) {
  MOJO_LOG(ERROR) << "ImagePipe " << entity << " Error on Image ID " << id
                  << ": " << message;
}

void ImagePipeEndpoint::ProducerFatalError(const std::string& message,
                                           uint32_t id) {
  if (is_checked_) {
    ImagePipeLogError("Producer", message, id);
    if (is_producer_) {
      MOJO_CHECK(false);
    } else {
      fatal_error_handler_();
    }
  }
}

void ImagePipeEndpoint::ConsumerFatalError(const std::string& message,
                                           uint32_t id) {
  ImagePipeLogError("Consumer", message, id);
  if (is_producer_) {
    fatal_error_handler_();
  } else {
    if (is_checked_) {
      MOJO_CHECK(false);
    } else {
      fatal_error_handler_();
    }
  }
}

ImagePipeEndpoint::ImagePipeEndpoint(bool is_producer,
                                     std::function<void()> fatal_error_handler)
    : is_producer_(is_producer),
      is_checked_(true),
      fatal_error_handler_(fatal_error_handler) {}

ImagePipeEndpoint::~ImagePipeEndpoint() {}

void ImagePipeEndpoint::ProducerAdd(uint32_t id) {
  if (IsInPool(id)) {
    ProducerFatalError("Attempting to add an image that is already in the pool",
                       id);
  } else {
    image_pool_ids_.insert(id);
    if (is_producer_) {
      producer_acquirable_ids_.push_back(id);
    } else {
      producer_owned_ids_.insert(id);
    }
  }
}

bool ImagePipeEndpoint::AcquireNextImage(uint32_t* out_id) {
  auto acquirable_ids_ =
      is_producer_ ? &producer_acquirable_ids_ : &consumer_acquirable_ids_;
  auto owned_ids_ = is_producer_ ? &producer_owned_ids_ : &consumer_owned_ids_;

  if (acquirable_ids_->empty()) {
    return false;
  }

  int id = acquirable_ids_->front();
  acquirable_ids_->pop_front();
  owned_ids_->insert(id);
  *out_id = id;
  return true;
}

void ImagePipeEndpoint::ProducerRemove(uint32_t id) {
  if (IsInPool(id)) {
    if ((IsConsumerOwned(id) || IsConsumerAcquirable(id))) {
      ProducerFatalError(
          "Attempting to remove an image that has been presented "
          "but has not been released by the consumer",
          id);
    } else {
      auto image_pool_ids_iter =
          std::find(image_pool_ids_.begin(), image_pool_ids_.end(), id);
      image_pool_ids_.erase(image_pool_ids_iter);
      MOJO_DCHECK(!is_checked_ || IsProducerOwned(id) ||
                  IsProducerAcquirable(id));
      if (IsProducerOwned(id)) {
        MOJO_DCHECK(!is_checked_ || !IsProducerAcquirable(id));
        auto producer_owned_ids_iter = std::find(producer_owned_ids_.begin(),
                                                 producer_owned_ids_.end(), id);
        producer_owned_ids_.erase(producer_owned_ids_iter);
        MOJO_DCHECK(!is_checked_ || !IsProducerOwned(id));
      } else {
        MOJO_DCHECK(!is_checked_ || IsProducerAcquirable(id));
        auto producer_acquirable_ids_iter =
            std::find(producer_acquirable_ids_.begin(),
                      producer_acquirable_ids_.end(), id);
        producer_acquirable_ids_.erase(producer_acquirable_ids_iter);
        MOJO_DCHECK(!is_checked_ || !IsProducerAcquirable(id));
      }
    }
  } else {
    ProducerFatalError(
        "Attempting to remove an image that is not in the image pool", id);
  }
}

// Private method to ensure that produce/release logic is symmetric between
// producer and consumer since they represent the same action from a state
// tracking perspective.
void ImagePipeEndpoint::ReleaseInternal(uint32_t id,
                                        bool released_by_producer) {
  // Here we define the concept of a releaser and a releasee, where the releaser
  // is the entity that owns |id| before the function, and the releasee is the
  // entity on the other end of the ImagePipe.
  auto& releaser_owned_ids =
      released_by_producer ? producer_owned_ids_ : consumer_owned_ids_;
  auto& releasee_owned_ids =
      !released_by_producer ? producer_owned_ids_ : consumer_owned_ids_;

  auto& releasee_acquirable_ids = !released_by_producer
                                      ? producer_acquirable_ids_
                                      : consumer_acquirable_ids_;

  auto IsReleaserOwned = released_by_producer
                             ? &ImagePipeEndpoint::IsProducerOwned
                             : &ImagePipeEndpoint::IsConsumerOwned;

  // Now that we have the releaser and the releasee containers, we do all of the
  // ownership change semantics generically based on those containers.
  MOJO_DCHECK(!is_checked_ || (this->*IsReleaserOwned)(id));
  auto releaser_owned_ids_iter =
      std::find(releaser_owned_ids.begin(), releaser_owned_ids.end(), id);
  releaser_owned_ids.erase(releaser_owned_ids_iter);
  MOJO_DCHECK(!is_checked_ || !(this->*IsReleaserOwned)(id));

  // If the release action is coming from our side of the pipe, we wont see the
  // acquire events, so we just pretend the other side immediately aquires
  // everything to simplify state tracking.
  if (released_by_producer == is_producer_) {
    releasee_owned_ids.insert(id);
  } else {
    releasee_acquirable_ids.push_back(id);
  }
}

void ImagePipeEndpoint::ProducerPresent(
    uint32_t id,
    mojo::gfx::ImagePipe::PresentImageCallback callback) {
  if (IsProducerOwned(id)) {
    MOJO_DCHECK(!is_checked_ || (IsInPool(id) && !IsConsumerOwned(id) &&
                                 !IsConsumerAcquirable(id)));
    ReleaseInternal(id, true);
    present_callback_map_[id] = callback;
  } else if (!IsInPool(id)) {
    ProducerFatalError(
        "Attempting to present an image that is not in the image pool", id);
  } else if (IsProducerAcquirable(id)) {
    ProducerFatalError(
        "Attempting to present an image that has not been acquired", id);
  } else if (IsConsumerOwned(id) || IsConsumerAcquirable(id)) {
    ProducerFatalError(
        "Attempting to present an image that has already been presented", id);
  }
}

void ImagePipeEndpoint::ConsumerRelease(uint32_t id,
                                        mojo::gfx::PresentationStatus status) {
  if (IsConsumerOwned(id)) {
    MOJO_DCHECK(!is_checked_ || (IsInPool(id) && !IsProducerOwned(id) &&
                                 !IsProducerAcquirable(id)));
    ReleaseInternal(id, false);
    CallPresentCallback(id, status);
  } else if (!IsInPool(id)) {
    ConsumerFatalError(
        "Attempting to release an image that is not in the image pool", id);
  } else if (IsConsumerAcquirable(id)) {
    ConsumerFatalError(
        "Attempting to release an image that has not been acquired", id);
  } else if (IsProducerOwned(id) || IsProducerAcquirable(id)) {
    ConsumerFatalError(
        "Attempting to release an image that has not been presented", id);
  }
}

void ImagePipeEndpoint::ProducerFlush() {
  if (!is_producer_) {
    for (auto id : consumer_acquirable_ids_) {
      MOJO_DCHECK(!is_checked_ || (IsInPool(id) && !IsConsumerOwned(id) &&
                                   !IsProducerOwned(id)));
      CallPresentCallback(id,
                          mojo::gfx::PresentationStatus::NOT_PRESENTED_FLUSHED);
    }
    consumer_acquirable_ids_.clear();
  }
}

void ImagePipeEndpoint::CallPresentCallback(
    uint32_t id,
    mojo::gfx::PresentationStatus status) {
  auto present_callback_iter = present_callback_map_.find(id);
  MOJO_DCHECK(present_callback_iter != present_callback_map_.end());
  auto present_callback = present_callback_iter->second;
  present_callback_map_.erase(present_callback_iter);
  present_callback.Run(status);
}

bool ImagePipeEndpoint::IsInPool(uint32_t id) const {
  auto& container = image_pool_ids_;
  return std::find(container.begin(), container.end(), id) != container.end();
}

bool ImagePipeEndpoint::IsConsumerOwned(uint32_t id) const {
  auto& container = consumer_owned_ids_;
  return std::find(container.begin(), container.end(), id) != container.end();
}

bool ImagePipeEndpoint::IsConsumerAcquirable(uint32_t id) const {
  auto& container = consumer_acquirable_ids_;
  return std::find(container.begin(), container.end(), id) != container.end();
}

bool ImagePipeEndpoint::IsProducerOwned(uint32_t id) const {
  auto& container = producer_owned_ids_;
  return std::find(container.begin(), container.end(), id) != container.end();
}

bool ImagePipeEndpoint::IsProducerAcquirable(uint32_t id) const {
  auto& container = producer_acquirable_ids_;
  return std::find(container.begin(), container.end(), id) != container.end();
}

void ImagePipeEndpoint::DisableFatalErrorsForTesting() {
  is_checked_ = false;
}

}  // namespace image_pipe