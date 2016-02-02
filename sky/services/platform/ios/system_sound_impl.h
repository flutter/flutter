// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SERVICES_PLATFORM_IOS_SYSTEM_SOUND_IMPL_H_
#define SKY_SERVICES_PLATFORM_IOS_SYSTEM_SOUND_IMPL_H_

#include "base/macros.h"
#include "mojo/public/cpp/application/interface_factory.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "sky/services/platform/system_sound.mojom.h"

namespace flutter {
namespace platform {

class SystemSoundImpl : public SystemSound {
 public:
  explicit SystemSoundImpl(mojo::InterfaceRequest<SystemSound> request);

  ~SystemSoundImpl() override;

  void Play(SystemSoundType type, const PlayCallback& callback) override;

 private:
  mojo::StrongBinding<SystemSound> binding_;

  DISALLOW_COPY_AND_ASSIGN(SystemSoundImpl);
};

class SystemSoundFactory : public mojo::InterfaceFactory<SystemSound> {
 public:
  void Create(mojo::ApplicationConnection* connection,
              mojo::InterfaceRequest<SystemSound> request) override;
};

}  // namespace platform
}  // namespace flutter

#endif  // SKY_SERVICES_PLATFORM_IOS_SYSTEM_SOUND_IMPL_H_
