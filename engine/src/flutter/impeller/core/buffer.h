// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_CORE_BUFFER_H_
#define FLUTTER_IMPELLER_CORE_BUFFER_H_

#include <memory>

namespace impeller {

class DeviceBuffer;
class Allocator;

class Buffer {
 public:
  virtual ~Buffer();

  virtual std::shared_ptr<const DeviceBuffer> GetDeviceBuffer(
      Allocator& allocator) const = 0;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_CORE_BUFFER_H_
