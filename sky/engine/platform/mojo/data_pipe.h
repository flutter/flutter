// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_PLATFORM_MOJO_DATA_PIPE_H_
#define SKY_ENGINE_PLATFORM_MOJO_DATA_PIPE_H_

#include "base/callback.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "sky/engine/platform/SharedBuffer.h"

namespace blink {

void DrainDataPipe(
    mojo::ScopedDataPipeConsumerHandle handle,
    base::Callback<void(PassRefPtr<SharedBuffer>)> callback);

}  // namespace blink

#endif  // SKY_ENGINE_PLATFORM_MOJO_DATA_PIPE_H_
