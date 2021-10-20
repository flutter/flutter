// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/device_buffer.h"

namespace impeller {

class DeviceBufferMTL final : public DeviceBuffer {
 public:
  DeviceBufferMTL();

  ~DeviceBufferMTL() override;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(DeviceBufferMTL);
};

}  // namespace impeller
