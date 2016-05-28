// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SERVICES_MEDIA_IOS_MEDIA_SERVICE_IMPL_H_
#define SKY_SERVICES_MEDIA_IOS_MEDIA_SERVICE_IMPL_H_

#include "base/macros.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "sky/services/media/media.mojom.h"
#include "sky/services/media/ios/media_player_impl.h"
#include "sky/services/media/ios/sound_pool_impl.h"

namespace sky {
namespace services {
namespace media {

class MediaServiceImpl : public ::media::MediaService {
 public:
  MediaServiceImpl(mojo::InterfaceRequest<::media::MediaService> request);
  ~MediaServiceImpl() override;

  void CreatePlayer(
      mojo::InterfaceRequest<::media::MediaPlayer> player) override;

  void CreateSoundPool(mojo::InterfaceRequest<::media::SoundPool> pool,
                       int32_t max_streams) override;

 private:
  mojo::StrongBinding<::media::MediaService> binding_;

  DISALLOW_COPY_AND_ASSIGN(MediaServiceImpl);
};

}  // namespace media
}  // namespace services
}  // namespace sky

#endif  // SKY_SERVICES_MEDIA_IOS_MEDIA_SERVICE_IMPL_H_
