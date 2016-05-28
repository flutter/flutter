// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SERVICES_MEDIA_IOS_MEDIA_PLAYER_IMPL_H_
#define SKY_SERVICES_MEDIA_IOS_MEDIA_PLAYER_IMPL_H_

#include "base/files/file_path.h"
#include "base/macros.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "sky/services/media/media.mojom.h"

#if __OBJC__
@class AudioClient;
#else   // __OBJC__
class AudioClient;
#endif  // __OBJC__

namespace sky {
namespace services {
namespace media {

class MediaPlayerImpl : public ::media::MediaPlayer {
 public:
  explicit MediaPlayerImpl(
      mojo::InterfaceRequest<::media::MediaPlayer> request);
  ~MediaPlayerImpl() override;

  void Prepare(mojo::ScopedDataPipeConsumerHandle data_source,
               const ::media::MediaPlayer::PrepareCallback& callback) override;
  void Start() override;
  void Pause() override;
  void SeekTo(uint32_t msec) override;
  void SetVolume(float volume) override;
  void SetLooping(bool looping) override;

 private:
  mojo::StrongBinding<::media::MediaPlayer> binding_;
  AudioClient* audio_client_;

  void onCopyToTemp(const ::media::MediaPlayer::PrepareCallback& callback,
                    base::FilePath path,
                    bool success);
  void reset();

  DISALLOW_COPY_AND_ASSIGN(MediaPlayerImpl);
};

}  // namespace media
}  // namespace services
}  // namespace sky

#endif  // SKY_SERVICES_MEDIA_IOS_MEDIA_PLAYER_IMPL_H_
