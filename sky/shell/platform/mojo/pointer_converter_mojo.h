// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_MOJO_POINTER_CONVERTER_MOJO_H_
#define SKY_SHELL_PLATFORM_MOJO_POINTER_CONVERTER_MOJO_H_

#include <map>

#include "lib/ftl/macros.h"
#include "mojo/services/input_events/interfaces/input_events.mojom.h"
#include "sky/services/pointer/pointer.mojom.h"

namespace sky {
namespace shell {

class PointerConverterMojo {
 public:
  PointerConverterMojo();
  ~PointerConverterMojo();

  pointer::PointerPacketPtr ConvertEvent(mojo::EventPtr event);

 private:
  pointer::PointerPtr CreatePointer(pointer::PointerType type,
                                    mojo::Event* event,
                                    mojo::PointerData* data);

  std::map<int, std::pair<float, float>> pointer_positions_;

  FTL_DISALLOW_COPY_AND_ASSIGN(PointerConverterMojo);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_MOJO_POINTER_CONVERTER_MOJO_H_
