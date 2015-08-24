// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  media_player_.Create(nullptr, player.Pass());
}

void MediaServiceFactory::Create(
    mojo::ApplicationConnection* connection,
    mojo::InterfaceRequest<::media::MediaService> request) {
  new MediaServiceImpl(request.Pass());
}

}  // namespace media
}  // namespace services
}  // namespace sky
