// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_TOOLS_EMBED_DATA_H_
#define MOJO_TOOLS_EMBED_DATA_H_

#include <stddef.h>  // For size_t.

namespace mojo {
namespace embed {

struct Data {
  const char* const hash;
  const char* const data;
  const size_t size;
};

}  // namespace embed
}  // namespace mojo

#endif  // MOJO_TOOLS_EMBED_DATA_H_
