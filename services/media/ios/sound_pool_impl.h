// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SERVICES_MEDIA_IOS_SOUND_POOL_IMPL_H_
#define FLUTTER_SERVICES_MEDIA_IOS_SOUND_POOL_IMPL_H_

#include "base/macros.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "flutter/services/media/media.mojom.h"
#include "flutter/services/media/ios/media_player_impl.h"

#if __OBJC__
@class SoundPoolClient;
#else   // __OBJC__
class SoundPoolClient;
#endif  // __OBJC__

namespace sky {
namespace services {
namespace media {

class SoundPoolImpl : public ::media::SoundPool {
 public:
  explicit SoundPoolImpl(mojo::InterfaceRequest<::media::SoundPool> request);

  ~SoundPoolImpl() override;

  void Load(mojo::ScopedDataPipeConsumerHandle data_source,
            const ::media::SoundPool::LoadCallback& callback) override;

  void Play(int32_t sound_id,
            int32_t stream_id,
            mojo::Array<float> channel_volumes,
            bool loop,
            float rate,
            const ::media::SoundPool::PlayCallback& callback) override;

  void Stop(int32_t stream_id) override;

  void Pause(int32_t stream_id) override;

  void Resume(int32_t stream_id) override;

  void SetRate(int32_t stream_id, float rate) override;

  void SetVolume(int32_t stream_id,
                 mojo::Array<float> channel_volumes) override;

  void PauseAll() override;

  void ResumeAll() override;

 private:
  mojo::StrongBinding<::media::SoundPool> binding_;
  SoundPoolClient* sound_pool_;
  std::vector<base::FilePath> temp_files_;

  void onCopyToTemp(const ::media::SoundPool::LoadCallback& callback,
                    base::FilePath path,
                    bool success);

  DISALLOW_COPY_AND_ASSIGN(SoundPoolImpl);
};

}  // namespace media
}  // namespace services
}  // namespace sky

#endif  // FLUTTER_SERVICES_MEDIA_IOS_SOUND_POOL_IMPL_H_
