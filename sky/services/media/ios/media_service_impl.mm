// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/logging.h"
#include "sky/services/media/ios/media_service_impl.h"

namespace sky {
namespace services {
namespace media {

MediaServiceImpl::MediaServiceImpl(
    mojo::InterfaceRequest<::media::MediaService> request)
    : binding_(this, request.Pass()) {}

MediaServiceImpl::~MediaServiceImpl() {}

void MediaServiceImpl::CreatePlayer(
    mojo::InterfaceRequest<::media::MediaPlayer> player) {
  new MediaPlayerImpl(player.Pass());
}

void MediaServiceImpl::CreateSoundPool(
    mojo::InterfaceRequest<::media::SoundPool> pool,
    int32_t max_streams) {
  new SoundPoolImpl(pool.Pass());
}

}  // namespace media
}  // namespace services
}  // namespace sky
